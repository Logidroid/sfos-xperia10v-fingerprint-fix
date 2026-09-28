#!/bin/sh
# Documente (sans télécharger) les blobs nécessaires à la piste community overlay.
# Les binaires Sony sont propriétaires : ne PAS les committer dans ce dépôt.
set -eu

cat <<'EOF'
Blobs nécessaires (firmware stock Sony zambezi, ex. 68.1.A.2.270)
================================================================

Depuis vendor extrait du firmware officiel Sony (pas depuis ce git) :

  vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service
  vendor/lib64/hw/fingerprint.default.so
  vendor/lib64/vendor.semc.hardware.fingerprint-*.so   # selon build
  vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc
  vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml
  vendor/etc/vintf/manifest/vendor.egistec.hardware.fingerprint.xml
  vendor/etc/permissions/android.hardware.fingerprint.xml

Firmware TrustZone (doit rester accessible, ne pas overlay-masquer) :

  /vendor/firmware_mnt/image/egista.mdt
  /vendor/firmware_mnt/image/egista.b0*

Sur le port Sharks, l’approche droid-config était :
  sparse/overlays/vendor/...  +  mount-overlays (overlayfs upperdir)
  → attention : overlay trop large casse firmware_mnt (Wi‑Fi + FP).

Références :
  https://github.com/sharks-dev/sailfish-on-murray/issues/1
  https://github.com/sharks-dev/droid-config-pdx235/commit/11f39a7

Ce script n’extrait rien. Place manuellement les fichiers dans
  ./vendor-blobs/  (gitignored) si tu expérimentes en local.
EOF

mkdir -p "$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)/vendor-blobs"
echo
echo "Dossier local prêt (gitignored) : vendor-blobs/"
