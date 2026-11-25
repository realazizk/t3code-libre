# t3code-libre

A private build of [T3 Code](https://github.com/pingdotgg/t3code) (v0.1.12): upstream source
plus a set of patches. This repo holds only the patches and packaging, not the source itself.

## Downloads

[Releases](https://github.com/realazizk/t3code-libre/releases) carry an AppImage, a Windows
installer, an Arch package and the patched source. The Android APK isn't built by CI yet; build
it yourself (see [Android](#android)). GitHub Actions builds every file
from this repo ([workflow](.github/workflows/release.yml)), so you can check where a file came from:

```sh
sha256sum -c SHA256SUMS --ignore-missing
gh attestation verify T3-Code-libre-0.1.12-1-x86_64.AppImage --repo realazizk/t3code-libre
```

The Windows installer is not code-signed, so SmartScreen warns the first time you run it.

What the patches change:

| Patch | Change |
| --- | --- |
| `0001` | Product analytics (PostHog) off by default |
| `0002` | No in-app update feed; your package manager handles updates |
| `0003` | T3 accounts (Clerk) and the T3 Connect relay/tunnel removed |
| `0004` | No Google favicon lookups, spellcheck downloads, or automatic model/price/version lookups |
| `0005` | Pair devices by tailnet hostname / MagicDNS over plain http |
| `0006` | Android app without Google Play Services, Firebase, ML Kit, telemetry, or accounts |
| `0007` | Lockfile matching the removed dependencies |

## Requirements (all platforms)

- Node.js **26.13+** (upstream pins 26.13.1). If your distro's Node is older, install 26 with
  [mise](https://mise.jdx.dev) or nvm.
- Rust (`cargo`) and git.

## Arch Linux

```sh
git clone https://github.com/realazizk/t3code-libre && cd t3code-libre
makepkg -si
```

If your `nodejs` package is older than 26, put Node 26 first in `PATH` and skip the
dependency check: `PATH=/path/to/node26/bin:$PATH makepkg -sid`.

## Getting the patched source (Windows, macOS, Android, other Linux)

```sh
scripts/prepare-source.sh          # → build/t3code-0.1.12
cd build/t3code-0.1.12
../../scripts/ci/install-toolchain.sh   # pinned pnpm + vite-plus, then the workspace install
export PATH="$PWD/../toolchain/node_modules/.bin:$PATH"
```

The script downloads the upstream release tarball, checks it against the sha256 in
`PKGBUILD`, and applies the patches the same way `makepkg` does.

## Desktop builds (AppImage, Windows, macOS)

From the patched source, after the steps above:

```sh
export PKGVER=0.1.12
../../scripts/ci/build-desktop.sh linux AppImage      # other Linux distros
../../scripts/ci/build-desktop.sh win nsis            # on Windows, in Git Bash
../../scripts/ci/build-desktop.sh mac dmg arm64       # on a Mac; x64 for Intel
```

The output lands in `build/artifacts`. Linux needs `libsecret` development headers and
ImageMagick. Windows needs Visual Studio's C++ build tools (with the Spectre-mitigated libraries)
and Rust. The macOS build is untested: build it on a Mac with the Xcode command line tools
(`xcode-select --install`). The app is unsigned, so Gatekeeper blocks it the first time; right-click
it and choose **Open**, or run `xattr -dr com.apple.quarantine "/Applications/T3 Code.app"`.

## Android

Requirements: the Android SDK (platform 36, build-tools, NDK 27.1) and JDK 17 or 21. From
the patched source:

```sh
export ANDROID_HOME=~/Android/Sdk
export JAVA_HOME=/path/to/jdk-21
export GRADLE_OPTS=-Dorg.gradle.workers.max=4   # otherwise Metro can run out of memory
export ORG_GRADLE_PROJECT_reactNativeArchitectures=arm64-v8a   # optional: arm64 phones only, much faster

# Signing: create a keystore once and keep it. Updates must be signed with the same key.
#   keytool -genkeypair -v -keystore ~/t3code.jks -alias t3code -keyalg RSA -keysize 4096 -validity 10000
export T3CODE_ANDROID_KEYSTORE=~/t3code.jks
export T3CODE_ANDROID_KEYSTORE_ALIAS=t3code
export T3CODE_ANDROID_KEYSTORE_PASSWORD='...'

apps/mobile/scripts/build-android-private.sh
```

The build fails if any Google Play / Firebase / ML Kit library or Firebase messaging entry
ends up in the APK. The signed APK goes to
`apps/mobile/android/app/build/outputs/apk/release/t3code-private-signed.apk`, and its app id
is `com.t3tools.t3code.libre`, so it installs alongside the official app.

iOS is not covered.

## Updating the patches

The patches are exported from a git branch on top of the upstream source
(`git format-patch --start-number 3 <base>` for `0003`+). After changing them, run `updpkgsums`,
bump `pkgrel`, and run `makepkg --printsrcinfo > .SRCINFO`.

## Releasing

Push a tag named after the PKGBUILD version, e.g. `v0.1.12-1`. The workflow builds everything,
writes `SHA256SUMS`, attests each file's build provenance and publishes the release.

The APK is built unsigned, then a separate job that runs only `zipalign` and `apksigner` signs it,
so no build dependency ever sees the key. The key lives in the `android-signing` environment's
secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`), and only
`v*` tags can deploy to that environment. Keep using the same key, or Android refuses to install
updates over the old app.

## License

Upstream T3 Code is MIT-licensed, © T3 Tools Inc.
