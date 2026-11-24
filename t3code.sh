#!/bin/sh
# T3 Code desktop launcher. Runs the system-packaged Electron app.
#
# Privacy backstops. The build already removes these features; the launcher also makes sure
# a stray variable in a shell profile cannot turn any of them back on. The app only copies
# shell variables that are unset here, so these values win.
export T3CODE_TELEMETRY_ENABLED=0
export T3CODE_DISABLE_AUTO_UPDATE=1
unset T3CODE_RELAY_URL T3CODE_CLERK_PUBLISHABLE_KEY T3CODE_CLERK_JWT_TEMPLATE \
  T3CODE_CLERK_CLI_OAUTH_CLIENT_ID T3CODE_HOSTED_APP_URL \
  T3CODE_RELAY_CLIENT_OTLP_TRACES_URL T3CODE_RELAY_CLIENT_OTLP_TRACES_DATASET \
  T3CODE_RELAY_CLIENT_OTLP_TRACES_TOKEN T3CODE_POSTHOG_KEY T3CODE_POSTHOG_HOST

# Chromium's sandbox runs through unprivileged user namespaces on Arch kernels, so the
# renderer (including web previews) stays sandboxed. Set T3CODE_NO_SANDBOX=1 only if
# your kernel has user namespaces disabled.
if [ "${T3CODE_NO_SANDBOX:-0}" = 1 ]; then
  exec /usr/lib/t3code/t3code --no-sandbox "$@"
fi
exec /usr/lib/t3code/t3code "$@"
