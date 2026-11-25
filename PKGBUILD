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
pkgver=0.1.12
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
sha256sums=('c57a856c2104ad5e3fcdcf96239b2d688521fc7450a69cdeb17844bcb13101b3'
            '450a298a5ee32eda0b6720cb087302a25350019a535ca190855f8ae7e2a4cdbf'
            '39be8b28ba168178a156b3a2119f62477a2f611a51e7db8200c9fbbc519e18b4'
            '0d2ffe75d1dd1afd51371ebf1618a8b2f17051e63387458644c96e98cf6167b8'
            '36eb147843372e534a6c274b2d1d31d4f9accb76898a0b5c25f435f82043331b'
            '17def80926447d88ebbf87b0440087802267cfa6847bf8a88ed3b56cb5dfbb9c'
            '4e8d6d577ac9bbb41eba2dceabbcdbeecc8ef723539e87d53968f3153cd290ed'
            '7f0b76aaef218371502f062894f08ea93ee8eec1ea5c536bc77c105f38e8b278'
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
  # Keep the workspace's prepare step (vp config) from installing git hooks into an enclosing clone.
  export GIT_CEILING_DIRECTORIES="$srcdir"
  export T3CODE_TELEMETRY_CHANNEL=stable
  export ELECTRON_SKIP_BINARY_DOWNLOAD=1
  export npm_config_cache="$srcdir/npm-cache"
  export CARGO_HOME="${CARGO_HOME:-$srcdir/cargo-home}"

  # The toolchain versions the source pins (package.json packageManager, workspace catalog).
  local pnpm_version vp_version
  pnpm_version="$(sed -n 's/.*"packageManager": "pnpm@\([^"]*\)".*/\1/p' package.json)"
  vp_version="$(sed -n 's/^  vite-plus: \([0-9][^ ]*\)$/\1/p' pnpm-workspace.yaml)"
  npm install --prefix "$srcdir/toolchain" "vite-plus@$vp_version" "pnpm@$pnpm_version"
  # npm releases that block install scripts leave pnpm's shebang-less placeholder, which vp
  # cannot exec; pnpm's own setup links the native binary in its place.
  node "$srcdir/toolchain/node_modules/pnpm/install.js"
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
