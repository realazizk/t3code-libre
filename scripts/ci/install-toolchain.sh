#!/usr/bin/env bash
# Installs the pnpm and vite-plus versions the patched source pins, then the workspace
# dependencies. Run from the patched source directory; the toolchain goes next to it.
set -euo pipefail

pnpm_version="$(sed -n 's/.*"packageManager": "pnpm@\([^"]*\)".*/\1/p' package.json)"
vp_version="$(sed -n 's/^  vite-plus: \([0-9][^ ]*\)$/\1/p' pnpm-workspace.yaml)"
toolchain="$(cd .. && pwd)/toolchain"

npm install --prefix "$toolchain" "vite-plus@$vp_version" "pnpm@$pnpm_version"
# npm releases that block install scripts leave pnpm's shebang-less placeholder, which vp
# cannot exec; pnpm's own setup links the native binary in its place.
if [[ "$OSTYPE" == linux* ]]; then
  node "$toolchain/node_modules/pnpm/install.js"
fi
export PATH="$toolchain/node_modules/.bin:$PATH"
[[ -n "${GITHUB_PATH:-}" ]] && echo "$toolchain/node_modules/.bin" >> "$GITHUB_PATH"

vp install
