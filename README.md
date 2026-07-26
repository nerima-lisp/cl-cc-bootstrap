# cl-cc-bootstrap

Pre-interned bootstrap symbols and the backend registration protocol for the
[cl-cc](https://github.com/nerima-lisp/cl-cc) Common Lisp compiler.

Two things live here, and they share a system because they share one property:
everything else in cl-cc may depend on them, and they depend on nothing.

- **`src/package.lisp`** — the symbols `cl-cc/optimize` and `cl-cc/compile` must
  both see interned before either package is defined. cl-cc compiles itself, so
  a symbol read in one phase and written in another has to be the same symbol;
  interning them here, first, is what makes that true.
- **`src/backend-protocol.lisp`** — `cl-cc/backend-protocol`, the registry a
  language backend registers itself with. It exists so `cl-cc/pipeline` never
  names a backend's package: PHP and JavaScript answer for their own bridge
  symbols and VM integration rather than being scanned from outside. See §5-1 of
  cl-cc's `docs/notes/repo-split-design.md`.

It holds no VM code on purpose. The registry is a `defvar` and a few generic
functions; the pipeline is the only participant that depends on `cl-cc/vm`, so
calling `vm-register-host-bridge` stays there.

## Usage

```lisp
(asdf:load-system "cl-cc-bootstrap")
```

## Development

```sh
nix develop
nix flake check
```

## License

MIT
