# boilerplate-cli-ui-machin

A CLI with an embedded web UI, written in **[machin](https://github.com/javimosch/machin)** (MFL — the Machine-First Language). Compiles through C to a **single native binary** — no runtime, no interpreter, no dependencies.

Part of the SuperCLI boilerplate family (Go, Rust, Zig, Node, …); this is the machin entry.

| Stack | Repo | Binary | SDK Size |
|-------|------|--------|----------|
| Go + inline HTML | [boilerplate-cli-ui-go](https://github.com/javimosch/boilerplate-cli-ui-go) | ~5MB | ~150MB |
| Go + Vue 3 CDN | [boilerplate-cli-ui-go-v2-vue](https://github.com/javimosch/boilerplate-cli-ui-go-v2-vue) | ~5MB | ~150MB |
| Go + React 18 CDN | [boilerplate-cli-ui-go-v2-react](https://github.com/javimosch/boilerplate-cli-ui-go-v2-react) | ~5MB | ~150MB |
| Deno + vanilla JS | [boilerplate-cli-ui-deno](https://github.com/javimosch/boilerplate-cli-ui-deno) | ~76MB | ~100MB |
| Node.js + vanilla JS | [boilerplate-cli-ui-node](https://github.com/javimosch/boilerplate-cli-ui-node) | ~123MB | ~500MB+ |
| Python + React CDN | [boilerplate-cli-ui-python](https://github.com/javimosch/boilerplate-cli-ui-python) | ~10MB | ~300MB |
| Rust + vanilla JS | [boilerplate-cli-ui-rust](https://github.com/javimosch/boilerplate-cli-ui-rust) | ~1.1MB | ~800MB |
| .NET 8 + Vue 3 | [boilerplate-cli-ui-dotnet](https://github.com/javimosch/boilerplate-cli-ui-dotnet) | ~89MB | ~600MB |
| C++ + Vue 3 | [boilerplate-cli-ui-cpp](https://github.com/javimosch/boilerplate-cli-ui-cpp) | ~493KB | ~2GB+ |
| Nim + Vue 3 | [boilerplate-cli-ui-nim](https://github.com/javimosch/boilerplate-cli-ui-nim) | ~364KB | ~50MB |
| Zig + Vue 3 | [boilerplate-cli-ui-zig](https://github.com/javimosch/boilerplate-cli-ui-zig) | ~190KB | ~50MB |
| Dart + Vue 3 | [boilerplate-cli-ui-dart](https://github.com/javimosch/boilerplate-cli-ui-dart) | ~6.4MB | ~400MB |
| **machin + React 18 CDN** | **boilerplate-cli-ui-machin** | **~27KB** | **~2MB** |

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
