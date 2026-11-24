# Maintainer: realazizk <https://github.com/realazizk>
# T3 Code desktop app built from source as a private build:
#   - product analytics off, no in-app update feed (pacman owns updates)
#   - no T3 account sign-in and no T3 Connect relay/tunnel (Clerk removed)
#   - no Google favicon lookups, spellcheck downloads, or automatic model/price/version
#     lookups (Settings > "provider update checks" turns the lookups back on)
#   - pairing by tailnet hostname/MagicDNS over plain http from phones and browsers
#   - mobile sources patched for a Play-Services-free Android build
#     (apps/mobile/scripts/build-android-private.sh; not built by this PKGBUILD)
#
# Build requirements pulled in by makedepends: Node.js 26.13+, npm (installs the
# pinned vite-plus/vp + pnpm toolchain locally), Rust (resource monitor and
# KDE/Hyprland capture helpers), libsecret headers (browser-import helper),
# ImageMagick (icon set), git.

pkgname=t3code
pkgver=0.1.11
pkgrel=1
pkgdesc='Desktop control surface for local coding agents (private build: no telemetry, accounts, or cloud relay)'
arch=('x86_64')
url='https://github.com/pingdotgg/t3code'
license=('MIT')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'cairo'
  'dbus'
  'expat'
  'gdk-pixbuf2'
  'glib2'
  'glibc'
  'gtk3'
  'hicolor-icon-theme'
  'libcups'
  'libdrm'
  'libgcc'
  'libsecret'
  'libstdc++'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'libxss'
  'libxtst'
  'mesa'
  'nspr'
  'nss'
  'pango'
  'systemd-libs'
  'xdg-utils'
  'zlib'
)
makedepends=(
  'cargo'
  'git'
  'imagemagick'
  'libsecret'
  'nodejs>=26.13'
  'npm'
  'pkgconf'
  'rust'
)
install=t3code.install
source=(
  "t3code-$pkgver.tar.gz::https://github.com/pingdotgg/t3code/archive/refs/tags/v$pkgver.tar.gz"
  '0001-disable-analytics-telemetry-default.patch'
  '0002-no-update-feed.patch'
  '0003-remove-accounts-and-connect.patch'
  '0004-no-phone-home.patch'
  '0005-tailnet-hostname-pairing.patch'
  '0006-mobile-degoogled.patch'
  '0007-lockfile.patch'
  't3code.sh'
  't3code.desktop'
)
sha256sums=('9c1bbaa24a12c357d073125d74b4a7829a83654cda3536e60e5ceccab3b12358'
            'a7094263067aa966cb0c70bf1f5cd73eb3807b38513d8b4571e43bfa93f4e617'
            'be45d8e36c678868cbe4ad1ba3fcc08bc4f7094d01ac4c0c23e3fd4f46a73f12'
            'd74c241fad4e1e4c7bfc9454cbf956d87b2472370632bd8b4187194c918a4adb'
            'f50459c97f25f6fafd7de1e0d72e7e48464a48f931fb5c22cea847056a652a4e'
            'a12fcf6d345e5f46be18888b472a24649b54b1ca163d109cb7b68da2a9e7f07d'
            '723abd74d6629e785c386270ee2244ff07f38dbd492924755bf2f11716701053'
            '4fdb97e693becc69544f6c2315067961020c564333264b7401de2b4568d51d47'
            '3c3349d80453f2c372e16782a914b8742c3b68faac0e15555008cef6e1bc5814'
            'b32e0562db7e04fb98075a6aa7b3978d293d3c52a303c8d062bd1fb4331205e4')

prepare() {
  cd "t3code-$pkgver"
  # Vendored reference repos (~170 MiB) are documentation, not build inputs.
  rm -rf .repos
  # git-format patches (file deletions included). The ceiling keeps git from finding a
  # repository above $srcdir (a clone of this repo): inside one, git apply skips every file.
  local p
  for p in "${source[@]}"; do
    if [[ $p == *.patch ]]; then
      GIT_CEILING_DIRECTORIES="$srcdir" git apply --whitespace=nowarn "$srcdir/$p"
    fi
  done
  # Belt and braces: never pick up a cloud .env from the tarball.
  rm -f .env .env.local
  # Upstream caps native modules at Ubuntu 24.04's glibc so its AppImage stays portable. This
  # package targets (and depends on) the system glibc, so raise the cap to the build host's.
  local glibc
  glibc="$(getconf GNU_LIBC_VERSION | cut -d' ' -f2)"
  sed -i "s/^const GLIBC_BUILD_CEILING = \".*\";/const GLIBC_BUILD_CEILING = \"$glibc\";/" \
    scripts/linux-glibc.ts
  grep -q "^const GLIBC_BUILD_CEILING = \"$glibc\";" scripts/linux-glibc.ts
}

build() {
  cd "t3code-$pkgver"
  export T3CODE_TELEMETRY_CHANNEL=stable
  export ELECTRON_SKIP_BINARY_DOWNLOAD=1
  export npm_config_cache="$srcdir/npm-cache"
  export CARGO_HOME="${CARGO_HOME:-$srcdir/cargo-home}"

  # The toolchain versions the source pins (package.json packageManager, workspace catalog).
  local pnpm_version vp_version
  pnpm_version="$(sed -n 's/.*"packageManager": "pnpm@\([^"]*\)".*/\1/p' package.json)"
  vp_version="$(sed -n 's/^  vite-plus: \([0-9][^ ]*\)$/\1/p' pnpm-workspace.yaml)"
  npm install --prefix "$srcdir/toolchain" "vite-plus@$vp_version" "pnpm@$pnpm_version"
  export PATH="$srcdir/toolchain/node_modules/.bin:$PATH"

  # Full workspace install: the desktop bundle builds against server + web.
  vp install

  # Same version alignment the official release workflow performs.
  node scripts/update-release-package-versions.ts "$pkgver"

  # Server + web + Electron bundles, Rust helpers, staged deps, electron-builder.
  node scripts/build-desktop-artifact.ts \
    --platform linux --target dir --arch x64 \
    --build-version "$pkgver" \
    --output-dir "$srcdir/artifacts"
}

package() {
  local appdir="$srcdir/artifacts/linux-unpacked"
  [[ -d "$appdir" ]] || appdir="$srcdir/artifacts/linux-x64-unpacked"
  [[ -d "$appdir" ]] || { echo "unpacked app not found in artifacts" >&2; exit 1; }

  install -d "$pkgdir/usr/lib/t3code"
  cp -a --no-preserve=ownership "$appdir/." "$pkgdir/usr/lib/t3code/"
  chmod -R u=rwX,go=rX "$pkgdir/usr/lib/t3code"
  chmod 755 "$pkgdir/usr/lib/t3code/t3code"
  local helper
  for helper in \
    resources/resource-monitor/t3-resource-monitor \
    resources/hyprland-capture/t3-hyprland-snap-shot \
    resources/kde-capture/t3-kde-snap-shot \
    resources/browser-secret/t3-browser-secret; do
    [[ -e "$pkgdir/usr/lib/t3code/$helper" ]] &&
      chmod 755 "$pkgdir/usr/lib/t3code/$helper"
  done

  install -Dm755 "$srcdir/t3code.sh" "$pkgdir/usr/bin/t3code"
  install -Dm644 "$srcdir/t3code.desktop" "$pkgdir/usr/share/applications/t3code.desktop"

  # Icon set, generated the same way the official build stages it
  # (scripts/build-desktop-artifact.ts stageLinuxIcons).
  local size
  for size in 16 22 24 32 48 64 128 256 512; do
    install -d "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps"
    magick "t3code-$pkgver/assets/prod/black-universal-1024.png" \
      -resize "${size}x${size}" \
      "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps/t3code.png"
  done

  install -Dm644 "t3code-$pkgver/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
