#!/bin/sh
# Remove diagnostic helpers installed by install.sh.
set -eu

FIX="${HOME}/fingerprint-fix"

echo "==> Uninstall sfos-xperia10v-fingerprint-fix diagnostics"

rm -f "${HOME}/bin/diagnose-fingerprint.sh"
rm -rf "${FIX}"

echo "==> Done."
