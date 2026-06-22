# AGENTS.md — machin CLI + embedded UI boilerplate

Guidance for agents extending this boilerplate. It is written in **machin** (MFL);
the language reference lives at https://github.com/javimosch/machin (`SPEC.md`).

## Philosophy (agent-first)

- **JSON-by-default** — the API at `/api/*` returns JSON; `stdout` is for data.
- **Single binary** — the UI is embedded at compile time; no runtime deps (libc only).
- **Machine-first source** — MFL is terse, type-inferred, one declaration per line.

## Layout & where things go

| File | Responsibility |
|------|----------------|
| `src/main.src` | CLI: `args()` dispatch, flags (`-port`, `-daemon`, `$PORT`) |
| `src/http.src` | HTTP server: `serve(port)`, `handle_conn`, routing by path |
| `src/api.src` | endpoint payloads: `Status` struct, `status_json`, `health_json` |
| `src/daemon.src` | `start_daemon`/`stop_daemon`/`daemon_status` via FFI + pid file |
| `src/sys.src` | `extern` blocks declaring the libc functions used |
| `ui/index.html` | the React UI (CDN; edit as normal HTML) |

`src/ui_gen.src` is **generated** by `build.sh` from `ui/index.html` — never edit
it (it is git-ignored).

## How to change things

- **Add an API endpoint** — add a branch in `handle_conn` (`src/http.src`) and a
  payload function in `src/api.src`. Return JSON with `http_json(...)`; build
  structured data with a `type` + `json(value)`.
- **Add a CLI command** — add a branch in `main` (`src/main.src`).
- **Change the UI** — edit `ui/index.html`, then `./build.sh`. It is plain
  React/Tailwind from CDN; no npm.
- **Call more C** — declare functions in an `extern` block in `src/sys.src`
  (scalars, `cstruct` structs, `ptr` handles). See machin's FFI (SPEC §15).

## Build & run

```bash
./build.sh        # embed UI → compose src/*.src → compile to native
./run.sh          # build + start
```

`build.sh` runs `machin encode src/*.src > app.mfl` then `machin build app.mfl`.
Source order does not matter (functions/types/externs resolve across files).

## Conventions

- Keep each `src/*.src` focused; one declaration per line is the canonical MFL form.
- The server runs one goroutine per connection (`go handle_conn(...)`).
- The daemon writes its pid to `/tmp/boilerplate-cli-ui-machin.pid`; `stop`
  removes it. Foreground `start` does not use a pid file.
