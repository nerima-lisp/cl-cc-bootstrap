# API Reference

## `cl-cc/bootstrap` (`src/package.lisp`, `src/runtime-helpers.lisp`)

Pre-interned bootstrap symbols. Most are defined downstream (`cl-cc/compile`,
`cl-cc/parse`, `cl-cc/vm`, ...) and only pre-interned here; the two runtime
helpers are implemented here.

- `rt-plist-put` — return a new plist with an indicator set to a value,
  non-destructively; replaces an existing indicator rather than duplicating it.
- `rt-slot-set` — set a CLOS slot by name and return the value set.
- `our-eval`, `our-load`, `run-string-repl` — defined in `cl-cc/compile`;
  referenced here so `cl-cc/expand` can see them before `cl-cc/compile` loads.
- `*vm-runtime-callable-installer*` and eight sibling VM bootstrap installer
  specials — defined in `cl-cc/vm`, consumed by runtime/parse/expand/selfhost.
- `binop`, `const`, `var`, `cmp`, `integer-type`, `boolean-type`,
  `env-lookup` — Prolog pattern atoms used by `cl-cc/optimize`'s egraph rules.
- `make-cst-token`, `lexer-token-p`, `lexer-token-type`,
  `lexer-token-value` — the CST token bridge, defined in `cl-cc/parse`.
- `backquote`, `unquote`, `unquote-splicing` — quasiquote reader symbols
  shared between `cl-cc/parse` and `cl-cc`.

## `cl-cc/backend-protocol` (`src/backend-protocol.lisp`)

### Registry

- `*registered-backends*` — alist of `(language . backend)`, most recently
  registered first.
- `register-backend language backend` — register `backend` under `language`,
  replacing any previous registration. Defined in terms of
  `call-with-backend-registration`, continuing with `#'identity` and a
  continuation that keeps the new backend.
- `call-with-backend-registration language backend registered replaced` — CPS
  dispatch on whether `language` had a prior registration: call `registered`
  with `backend` if not, or `replaced` with `backend` and the previous one if
  so. The registry update happens exactly once, before either continuation
  runs.
- `registered-backend language` — return the backend registered under
  `language`, or `nil`. Defined in terms of `call-with-registered-backend`,
  continuing with `#'identity` and a `nil`-returning thunk.
- `call-with-registered-backend language found not-found` — CPS dispatch on
  presence: call `found` with the backend if `language` is registered, else
  call `not-found` with no arguments.

### Backend hooks

Each defined by the shared `define-backend-hook` macro, which builds a
`defgeneric` with a default method ignoring its arguments and returning a
fixed default.

- `backend-bridge-symbols backend` — the fbound symbols `backend` wants
  callable from compiled code. Defaults to `()`.
- `backend-global-symbols backend` — the bound special variables `backend`
  wants seeded into VM globals. Defaults to `()`.
- `install-backend-vm-integration backend integration` — give `backend` the
  VM capabilities in `integration`. Defaults to a no-op.

### VM integration

- `vm-integration` / `make-vm-integration` / `vm-integration-p` — a struct of
  six capability closures (`closure-p`, `call-closure`, `global-bound-p`,
  `global-value`, `set-global`, `remove-global`), each defaulting to a
  closure returning `nil`. Defined via the shared `define-capability-struct`
  macro, which builds a `defstruct` of nil-returning-closure-defaulted slots
  from a flat list of capability names.
- `vm-integration-closure-p`, `vm-integration-call-closure`,
  `vm-integration-global-bound-p`, `vm-integration-global-value`,
  `vm-integration-set-global`, `vm-integration-remove-global` — the six slot
  accessors.
