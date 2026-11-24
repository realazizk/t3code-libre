#!/usr/bin/env bash
# Builds the desktop app from the patched source directory (the current directory).
#   scripts/ci/build-desktop.sh <linux|win|mac> <AppImage|nsis|dmg|dir> [arch]
# Output goes to ../artifacts.
set -euo pipefail

platform="$1"
target="$2"
arch="${3:-x64}"
version="${PKGVER:?set PKGVER to the upstream version, e.g. 0.1.11}"

"$(dirname "${BASH_SOURCE[0]}")/install-toolchain.sh"
export PATH="$(cd .. && pwd)/toolchain/node_modules/.bin:$PATH"

export T3CODE_TELEMETRY_CHANNEL=stable
if [[ "$platform" == win ]]; then
  # Upstream cross-builds Windows on Linux and caps the app at 80 files. A native Windows build
  # leaves a few more native-module files, so allow some headroom while still catching bloat.
  sed -i 's/^export const WINDOWS_PACKAGED_PAYLOAD_FILE_LIMIT = 80;/export const WINDOWS_PACKAGED_PAYLOAD_FILE_LIMIT = 120;/' \
    scripts/build-desktop-artifact.ts
  grep -q 'WINDOWS_PACKAGED_PAYLOAD_FILE_LIMIT = 120;' scripts/build-desktop-artifact.ts
fi
node scripts/update-release-package-versions.ts "$version"
node scripts/build-desktop-artifact.ts \
  --platform "$platform" --target "$target" --arch "$arch" \
  --build-version "$version" \
  --output-dir "$(cd .. && pwd)/artifacts"
