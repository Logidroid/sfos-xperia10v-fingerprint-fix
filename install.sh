#!/bin/sh
# Install diagnostic helpers only — does NOT enable fingerprint on official SFOS.
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
FIX="${HOME}/fingerprint-fix"

echo "==> sfos-xperia10v-fingerprint-fix v0 (diagnostics)"
echo "==> Install dir: ${FIX}"
echo
echo "NOTE: There is no known userspace unlock for official Jolla SFOS on"
echo "      Xperia 10 V yet. See README.md / RESEARCH.md."
echo

mkdir -p "${FIX}" "${HOME}/bin"
cp "${REPO_DIR}/scripts/diagnose-fingerprint.sh" "${FIX}/diagnose-fingerprint.sh"
cp "${REPO_DIR}/scripts/root-try-enable-fpd.sh" "${FIX}/root-try-enable-fpd.sh"
cp "${REPO_DIR}/scripts/list-required-blobs.sh" "${FIX}/list-required-blobs.sh"
cp "${FIX}/diagnose-fingerprint.sh" "${HOME}/bin/diagnose-fingerprint.sh"
chmod +x "${FIX}/diagnose-fingerprint.sh" "${FIX}/root-try-enable-fpd.sh" \
  "${FIX}/list-required-blobs.sh" "${HOME}/bin/diagnose-fingerprint.sh"
cp "${REPO_DIR}/README.md" "${FIX}/README.md"
cp "${REPO_DIR}/RESEARCH.md" "${FIX}/RESEARCH.md"

echo "==> Installed:"
echo "    ${HOME}/bin/diagnose-fingerprint.sh"
echo "    ${FIX}/diagnose-fingerprint.sh"
echo "    ${FIX}/root-try-enable-fpd.sh"
echo
echo "Run:     diagnose-fingerprint.sh | tee ~/fingerprint-diag.txt"
echo "Root:    devel-su sh ${FIX}/root-try-enable-fpd.sh"
