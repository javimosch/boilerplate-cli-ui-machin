#!/usr/bin/env bash
# Build the single native binary: embed the UI, compose the MFL sources, compile.
set -euo pipefail
cd "$(dirname "$0")"

# machin compiler: on PATH, or set MACHIN=/path/to/machin (build it from
# https://github.com/javimosch/machin with `go build -o machin .`).
MACHIN="${MACHIN:-machin}"
command -v "$MACHIN" >/dev/null 2>&1 || { echo "error: '$MACHIN' not found (set MACHIN=/path/to/machin)"; exit 1; }

# 1. Embed ui/index.html as an MFL function. JSON string escaping (", \, \n) is
#    exactly MFL's string-literal escaping, so json.dumps yields a valid literal.
python3 - <<'PY' > src/ui_gen.src
import json
html = open('ui/index.html').read()
print('func index_html() (h) { h = ' + json.dumps(html) + ' }')
PY

# 2. Compose every source into one canonical .mfl, then 3. compile to native.
"$MACHIN" encode src/*.src > app.mfl
"$MACHIN" build app.mfl -o boilerplate-cli-ui-machin

echo "built ./boilerplate-cli-ui-machin  (try: ./boilerplate-cli-ui-machin start)"
