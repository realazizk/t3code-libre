#!/usr/bin/env bash
# Downloads the upstream T3 Code release tarball named in PKGBUILD, checks its sha256,
# and applies the privacy patches. The result is the same patched tree makepkg builds,
# for building on macOS, for Android, or on a Linux distro other than Arch.
#
#   scripts/prepare-source.sh [output-dir]     # default: ./build
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$REPO_DIR/build}"

# Version and tarball checksum come from PKGBUILD so there is one source of truth.
pkgver="$(sed -n 's/^pkgver=//p' "$REPO_DIR/PKGBUILD")"
tarball_sha="$(sed -n "s/^sha256sums=('\([0-9a-f]*\)'.*/\1/p" "$REPO_DIR/PKGBUILD")"
[[ -n "$pkgver" && -n "$tarball_sha" ]] || { echo "error: could not read pkgver/sha256 from PKGBUILD" >&2; exit 1; }

tarball="$REPO_DIR/t3code-$pkgver.tar.gz"
if [[ ! -f "$tarball" ]]; then
  echo "==> Downloading t3code v$pkgver"
  curl -fL -o "$tarball.part" "https://github.com/pingdotgg/t3code/archive/refs/tags/v$pkgver.tar.gz"
  mv "$tarball.part" "$tarball"
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_sha="$(sha256sum "$tarball" | cut -d' ' -f1)"
else
  actual_sha="$(shasum -a 256 "$tarball" | cut -d' ' -f1)"   # macOS
fi
[[ "$actual_sha" == "$tarball_sha" ]] || { echo "error: sha256 mismatch for $tarball" >&2; exit 1; }

mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
src="$OUT_DIR/t3code-$pkgver"
[[ -e "$src" ]] && { echo "error: $src already exists; remove it first" >&2; exit 1; }
tar -xzf "$tarball" -C "$OUT_DIR"
cd "$src"

# Same steps as prepare() in PKGBUILD.
rm -rf .repos
# The ceiling keeps git from finding a repository above the tree (OUT_DIR defaults to a
# folder inside this repo): inside one, git apply silently skips every file.
for p in "$REPO_DIR"/0*.patch; do
  GIT_CEILING_DIRECTORIES="$OUT_DIR" git apply --whitespace=nowarn "$p"
done
rm -f .env .env.local

echo "==> Patched source ready: $src"
