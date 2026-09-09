# boilerplate-cli-ui-machin

A CLI with an embedded web UI, written in **[machin](https://github.com/javimosch/machin)** (MFL — the Machine-First Language). Compiles through C to a **single native binary** — no runtime, no interpreter, no dependencies.

Part of the SuperCLI boilerplate family (Go, Rust, Zig, Node, …); this is the machin entry. See also [**awesome-machin**](https://github.com/javimosch/awesome-machin) — the machin ecosystem.

<!-- FLEET-TABLE:BEGIN -->

| Stack | Binary | Cold start | Idle RSS | Specs | SDK |
|-------|--------|-----------:|---------:|:-----:|----:|
| **machin + React 18 CDN** | **63 KB** | **2 ms** | **3.1 MB** | **28/28** | **~2 MB** |
| [machin isomorphic (wasm UI)](https://github.com/javimosch/boilerplate-cli-ui-machin-isomorphic) | 76 KB | 2 ms | 3.1 MB | 28/28 | ~2 MB |
| [C++ + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-cpp) | 692 KB | 3 ms | 7.2 MB | 28/28 | ~2000 MB |
| [Zig + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-zig) | 971 KB | 1 ms | 2.0 MB | 28/28 | ~50 MB |
| [Rust + vanilla JS](https://github.com/javimosch/boilerplate-cli-ui-rust) | 1003 KB | 1 ms | 2.5 MB | 28/28 | ~800 MB |
| [Go + Vue 3 CDN](https://github.com/javimosch/boilerplate-cli-ui-go-v2-vue) | 5.5 MB | 2 ms | 5.9 MB | 28/28 | ~150 MB |
| [Go + React 18 CDN](https://github.com/javimosch/boilerplate-cli-ui-go-v2-react) | 5.5 MB | 2 ms | 5.8 MB | 28/28 | ~150 MB |
| [Deno + vanilla JS](https://github.com/javimosch/boilerplate-cli-ui-deno) | 76.1 MB | 24 ms | 43.8 MB | 28/28 | ~100 MB |
| [Node.js + vanilla JS](https://github.com/javimosch/boilerplate-cli-ui-node) | 122.8 MB | 66 ms | 52.2 MB | 28/28 | ~500 MB |

Not measured in this run (toolchain unavailable): [Nim + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-nim), [V + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-v), [Crystal + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-crystal), [Dart + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-dart), [Python + React CDN](https://github.com/javimosch/boilerplate-cli-ui-python), [.NET 8 + Vue 3](https://github.com/javimosch/boilerplate-cli-ui-dotnet).

*Binary size, cold start (median of 11 `version` runs) and idle RSS measured on Linux-x86_64 on 2026-09-09. **Specs** is the [cli-spec-conformance](https://github.com/javimosch/cli-spec-conformance) score across cli-output-spec, cli-guide-spec and cli-daemon-spec, taken by running each binary — not claimed. Every row builds the same reference app and implements the same agent-first contract, which is what makes the sizes comparable: a 63 KB binary that scores 28/28 is doing the work a 122 MB one does. Rows whose toolchain is missing on the measuring host are left out rather than given a stale number; each is gated on the same conformance check in its own CI. Regenerate with [boilerplate-cli-ui-fleet](https://github.com/javimosch/boilerplate-cli-ui-fleet); never edit this table by hand.*

<!-- FLEET-TABLE:END -->

The smallest binary in the family — and it links only libc.

## What it does

- A native CLI: `start` / `stop` / `status` / `version` / `help`.
- An HTTP server (`start`) that serves a React dashboard at `/` and a JSON API at `/api/*`.
- A background **daemon** (`start -daemon`) — fork/detach + pid file + `stop`/`status`, implemented through machin's **C FFI** (`fork`, `setsid`, `getpid`, `kill`, `unlink`, `open`).

## Architecture

```
boilerplate-cli-ui-machin/
├── src/
│   ├── main.src     # CLI: args() dispatch, flags ($PORT / -port / -daemon)
│   ├── http.src     # self-contained HTTP server (listen/accept/route), 1 goroutine/conn
│   ├── api.src      # /api/status + /api/health JSON (json(struct))
│   ├── daemon.src   # fork/pidfile/signals via the C FFI
│   └── sys.src      # extern blocks: libc fork/kill/open/atoi/…
├── ui/
│   └── index.html   # the React 18 + Tailwind UI (edit normally)
├── build.sh         # embed ui/index.html, compose sources, compile to native
├── run.sh           # build + start
└── AGENTS.md
```

### How the UI is embedded

`ui/index.html` is a normal HTML file (React from CDN — no npm, no build step). `build.sh` turns it into an MFL string with one line of Python — JSON string escaping is exactly MFL's string-literal escaping:

```python
print('func index_html() (h) { h = ' + json.dumps(open("ui/index.html").read()) + ' }')
```

That generated `src/ui_gen.src` is compiled into the binary, so the UI ships *inside* the executable (machin's equivalent of `go:embed`). Edit the HTML, rerun `build.sh`.

## Build

Needs the [machin](https://github.com/javimosch/machin) compiler on `PATH` (or `MACHIN=/path/to/machin`) and a C compiler.

```bash
./build.sh                 # → ./boilerplate-cli-ui-machin
# or, pointing at a local machin build:
MACHIN=~/ai/machin/machin ./build.sh
```

## Usage

```bash
./boilerplate-cli-ui-machin start                # foreground on :8080
./boilerplate-cli-ui-machin start -port 3000     # custom port
PORT=3000 ./boilerplate-cli-ui-machin start      # or via $PORT
./boilerplate-cli-ui-machin start -daemon        # background
./boilerplate-cli-ui-machin status               # running? (pid)
./boilerplate-cli-ui-machin stop                 # stop the daemon
./boilerplate-cli-ui-machin version
```

## API

| Endpoint | Response |
|----------|----------|
| `GET /` | the web UI (HTML) |
| `GET /api/status` | `{"status","port","uptime","version"}` |
| `GET /api/health` | `{"status":"healthy"}` |

## Why machin

The binary is **truly self-contained** — it links only libc. (A *GUI* binary would need the system graphics stack; a headless CLI/server like this does not.) The whole program is MFL: terse, type-inferred, one declaration per line, compiled to C-speed native code.
