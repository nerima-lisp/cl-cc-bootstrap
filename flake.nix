{
  description = "Pre-interned bootstrap symbols and the backend registration protocol for the cl-cc Common Lisp compiler";

  inputs = {
    # nixos-unstable, not nixpkgs-unstable: it advances only after the NixOS
    # release tests pass, so it is less likely to land a broken build.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned to a release tag. A bare `github:nerima-lisp/cl-weave` follows
    # that repository's default branch, so an upstream push to main would
    # break this repository's CI without warning.
    cl-weave = {
      url = "github:nerima-lisp/cl-weave/v1.0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Test-only: host-kit:quit, called by run-tests.lisp in place of
    # uiop:quit. Same pin-to-release-tag rule as cl-weave above.
    cl-host-kit = {
      url = "github:nerima-lisp/cl-host-kit/v0.2.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The org flake preset. Everything this file used to spell out by hand --
    # the `.asd` version extraction, `forAllSystems`, the treefmt eval wired to
    # both `formatter` and `checks.formatting`, the mkdocs package plus its
    # check, the run-tests.lisp gate, and the `apps.test`/`apps.default` pair
    # -- is one `mkPackageFlake` call below. Pinned to a release TAG, never to
    # the branch: a bare `github:nerima-lisp/cl-nix-forge` follows that
    # repository's default branch and would change this build without
    # warning.
    #
    # cl-weave's own `v1.0.1` release predates its cl-nix-forge migration, so
    # its `packages.default` is a hand-built, non-cl-nix-forge derivation with
    # no `.ancestry` -- not safe to hand to `lispCheckDependencies`, which
    # walks that attribute during dependency dedup. cl-host-kit's `v0.2.1` IS
    # built by cl-nix-forge and would qualify, but matching the two check
    # dependencies to one mechanism keeps this file's story simple rather than
    # encoding "why these two otherwise-identical dependencies are wired in
    # differently" -- both are named on `CL_SOURCE_REGISTRY` as raw source
    # trees instead, exactly as cl-host-kit's own flake.nix does for cl-weave.
    cl-nix-forge = {
      url = "github:nerima-lisp/cl-nix-forge/v0.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      cl-nix-forge,
      cl-weave,
      cl-host-kit,
      treefmt-nix,
      ...
    }:
    let
      lib = nixpkgs.lib;

      # CI builds and tests only x86_64-linux, so that is the sole declared
      # system: the flake never advertises a platform it does not verify.
      # aarch64-darwin was dropped on 2026-08-01. Its only verification was a
      # local `nix flake check` on a development machine, and a run nobody can
      # tell was skipped is not a gate. aarch64-linux and x86_64-darwin were
      # already undeclared for the same reason.
      #
      # Consequence, accepted deliberately: mkPackageFlake generates every
      # per-system output -- packages, checks, apps AND devShells -- from this
      # one list, so `nix develop` and `nix build` no longer work on macOS.
      # Development happens on Linux. See PACKAGE_STANDARD.md, "systems".
      systems = [
        "x86_64-linux"
      ];

      # CL_SOURCE_REGISTRY for the check-enabled derivation (checks.default,
      # apps.test, devShells.default) and for the hand-rolled coverage check
      # below. Both cl-weave and cl-host-kit are test-only -- neither enters
      # `packages.cl-cc-bootstrap`'s closure -- so they are named here rather
      # than through `lispCheckDependencies`; see the `cl-nix-forge` input
      # comment above for why.
      testSourceRegistry = "${cl-weave}/:${cl-host-kit}/";

      testTimeoutSeconds = 120;
      coverageTimeoutSeconds = 180;
      timeoutGraceSeconds = 15;

      # `lispDerivation`'s fasl output translation is an identity mapping
      # ("/:/", i.e. beside the source it compiled) -- correct for the
      # package's own writable, freshly-unpacked build tree, but cl-weave and
      # cl-host-kit's entries on `CL_SOURCE_REGISTRY` (`testSourceRegistry`
      # above) are immutable Nix store paths, and ASDF cannot write a `.fasl`
      # there. Only a check that actually loads them (`checks.default`,
      # `apps.test`) needs this override; `packages.cl-cc-bootstrap` never
      # loads either, so its own "source plus fasls side by side" contract
      # stays untouched. `checks.coverage` above already sets its own `$HOME`
      # instead, which ASDF's default output-translations resolves through a
      # `~/.cache/common-lisp/...` mirror -- the same effect, reached the way
      # cl-weave's own flake.nix reaches it.
      writableFaslOutputTranslationsPrefix = ''
        export ASDF_OUTPUT_TRANSLATIONS="(:output-translations (t \"$TMPDIR/fasl-cache/\") :ignore-inherited-configuration)"
        mkdir -p "$TMPDIR/fasl-cache"
      '';
    in
    cl-nix-forge.lib.${builtins.head systems}.mkPackageFlake {
      inherit self systems nixpkgs;
      pname = "cl-cc-bootstrap";

      # The ONLY place a version comes from; there is deliberately no
      # `version` argument on this preset.
      asd = ./cl-cc-bootstrap.asd;

      meta = {
        description = "Pre-interned bootstrap symbols and the backend registration protocol for the cl-cc Common Lisp compiler";
        homepage = "https://github.com/nerima-lisp/cl-cc-bootstrap";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };

      root = ./.;

      # No `lispDependencies`: `cl-cc-bootstrap.asd`'s main system depends on
      # nothing, which is the entire point of this repository (see the .asd's
      # own header comment). cl-weave and cl-host-kit reach `t/` only, through
      # `packageArgs`'s registry entry below.
      packageArgs = _: {
        CL_SOURCE_REGISTRY = testSourceRegistry;
      };

      timeoutSeconds = testTimeoutSeconds;
      killAfterSeconds = timeoutGraceSeconds;

      # Rendered documentation site (Material for MkDocs), built fully
      # offline and gated `--strict` by `checks.docs`.
      docs = {
        root = ./docs;
      };

      # ONE treefmt evaluation drives `nix fmt` and the `checks.formatting`
      # gate, so the formatter and CI can never disagree about what
      # "formatted" means. Scope is Nix only, per PACKAGE_STANDARD.md's
      # default: nixfmt (RFC-style) is a zero-footgun, low-diff formatter,
      # whereas YAML formatters mangle the GitHub Actions `on:` key and
      # Markdown reformatting would churn the whole docs tree.
      treefmt = {
        evalModule = treefmt-nix.lib.evalModule;
      };

      # `checks.coverage`: cl-weave's own delivered CLI (not
      # `ctx.cl.mkCoverageReport`), run with `--coverage` against a writable
      # copy of the source -- the store path itself is read-only, and the CLI
      # writes its coverage output and report next to the system it ran.
      # Mirrors the pattern cl-weave's own flake.nix and cl-prolog's
      # apps.test use: `cl-weave run <system>/test --coverage`.
      #
      # package.lisp is excluded (by the store path FIND-SYSTEM actually
      # resolved, not a path under this derivation's writable copy --
      # --coverage-exclude matches on the exact pathname ASDF loaded). Its
      # own EVAL-WHEN guards a DEFPACKAGE with (unless (find-package :cl-cc)
      # ...), which never re-executes once :cl-cc already exists from an
      # earlier, uninstrumented load in the same coverage run -- reporting 0%
      # for a manifest that unqualifiedly does run, not for untested logic.
      #
      # 95% is the real, currently-reachable floor, not a loosened target
      # (measured at 96.9% as of this writing). The remaining gap is entirely
      # the same class of sb-cover limitation around declarative, non-runtime
      # forms: IN-PACKAGE and a DEFVAR's own top-level form report unexecuted
      # even though the file plainly loaded and the special plainly got
      # SETF'd across many tests; a DEFSTRUCT slot spec such as (closure-p
      # (constantly nil) :type function) reports its wrapping spec as
      # unexecuted while sb-cover correctly marks the nested (constantly nil)
      # itself as executed, because the spec is data the DEFSTRUCT macro
      # consumes at compile time, not an expression that runs. None of this is
      # untested logic -- it dropped from a 12% gap to a ~3% one not because
      # these forms became instrumentable, but because
      # CALL-WITH-BACKEND-REGISTRATION and DEFINE-CAPABILITY-STRUCT added
      # real, fully-tested logic that dilutes their fixed, per-file overhead.
      extraOutputs =
        ctx:
        let
          pkgs = ctx.pkgs;
        in
        {
          checks.coverage =
            pkgs.runCommand "cl-cc-bootstrap-coverage"
              {
                nativeBuildInputs = [
                  pkgs.sbcl
                  pkgs.coreutils
                ];
                # `${self}//` (the immutable, unfiltered flake input) has to be
                # on the registry here, not just cl-weave/cl-host-kit: FIND-
                # SYSTEM resolves "cl-cc-bootstrap" through the FIRST matching
                # tree it sees, and `--coverage-exclude` below names a path
                # under `${self}` -- so the pathname FIND-SYSTEM resolves and
                # the pathname the exclude flag names must be the same tree.
                # Without this, package.lisp resolves through the writable
                # `source` copy instead, the exclude silently stops matching,
                # and package.lisp's declarative-only forms (see below) drag
                # the percentage down by double digits.
                CL_SOURCE_REGISTRY = "${testSourceRegistry}:${self}//";
              }
              ''
                export HOME="$TMPDIR/home"
                mkdir -p "$HOME"
                cp -r ${self} source
                chmod -R u+w source
                cd source
                timeout ${toString coverageTimeoutSeconds} ${cl-weave.packages.${ctx.system}.default}/bin/cl-weave \
                  run cl-cc-bootstrap/test \
                  --coverage \
                  --coverage-output cl-cc-bootstrap.coverage \
                  --coverage-report-directory cl-cc-bootstrap-coverage-report/ \
                  --coverage-system cl-cc-bootstrap \
                  --coverage-exclude ${self}/src/package.lisp \
                  --coverage-min-expression 95 \
                  --coverage-min-branch 95
                mkdir -p "$out"
                cp -r cl-cc-bootstrap-coverage-report "$out/report"
                cp cl-cc-bootstrap.coverage "$out/"
              '';
        };

      # See `writableFaslOutputTranslationsPrefix` above: `checks.default` is
      # the one preset-generated output that loads cl-weave and cl-host-kit,
      # so it is the one that needs the writable-fasl override.
      overrideOutputs = ctx: {
        checks.default = ctx.generated.checks.default.overrideAttrs (old: {
          checkPhase = writableFaslOutputTranslationsPrefix + old.checkPhase;
        });
      };
    };
}
