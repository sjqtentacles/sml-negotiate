# sml-negotiate

[![CI](https://github.com/sjqtentacles/sml-negotiate/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-negotiate/actions/workflows/ci.yml)

Pure, I/O-free HTTP proactive content negotiation for Standard ML
([RFC 9110 §5.3](https://www.rfc-editor.org/rfc/rfc9110#section-5.3)). Parses
`Accept`, `Accept-Encoding`, and `Accept-Language` header values into weighted
(q-value) entries and selects the best matching offer from a server's list.

Deterministic; builds and tests identically under **MLton** and **Poly/ML**.
Vendors [`sml-http`](https://github.com/sjqtentacles/sml-http).

## Features

- **`parse`**: a comma-separated weighted list into `{ value, q }` entries
  (whitespace-tolerant, missing `q` defaults to 1.0, clamped to `[0,1]`).
- **`best`**: generic highest-q selection with a custom `matches` predicate;
  ties broken by the server's offer order (stable).
- **`acceptMedia`**: media types with `*/*` and `type/*` wildcards.
- **`acceptEncoding`**: with `*` and the implicit `identity` rule (acceptable
  unless explicitly `q=0`).
- **`acceptLanguage`**: RFC 4647 basic prefix matching (`en` matches `en-US`).

`q=0` excludes a candidate. An empty header means "no preference" and yields the
server's first offer.

## API sketch

```sml
type entry = { value : string, q : real }
val parse : string -> entry list
val best  : { matches : string * string -> bool }
            -> entry list -> string list -> string option
val acceptMedia    : { header : string, offers : string list } -> string option
val acceptEncoding : { header : string, offers : string list } -> string option
val acceptLanguage : { header : string, offers : string list } -> string option
```

## Example

```sml
(* json (implicit q=1) beats html (q=0.8) *)
val SOME "application/json" =
  Negotiate.acceptMedia
    { header = "text/html;q=0.8, application/json"
    , offers = ["text/html", "application/json"] }

val SOME "gzip" =
  Negotiate.acceptEncoding { header = "gzip, deflate;q=0.5", offers = ["deflate", "gzip"] }

val SOME "en-US" =
  Negotiate.acceptLanguage { header = "en", offers = ["fr", "en-US"] }
```

## Build

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
```

**19 deterministic checks** against RFC 9110 examples, green under both
compilers.

## Installation

```
require {
  github.com/sjqtentacles/sml-negotiate
}
```

then `smlpkg sync`, or vendor under `lib/github.com/sjqtentacles/sml-negotiate/`
and reference `sml-negotiate.mlb`.

## Layout

```
lib/github.com/sjqtentacles/
  sml-negotiate/
    negotiate.{sig,sml}  Accept / Accept-Encoding / Accept-Language q-value negotiation
    sources.mlb sml-negotiate.mlb
  sml-http/ sml-uri/     vendored dependencies (committed)
test/                    Harness suite (19 checks)
```

## License

MIT. See [LICENSE](LICENSE).
