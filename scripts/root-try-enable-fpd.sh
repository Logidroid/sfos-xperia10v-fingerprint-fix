#!/bin/sh
# À lancer SUR le téléphone, en root (devel-su).
# Installe sailfish-fpd manquant + tente de démarrer le HAL Sony @2.1.
#
# Ne garantit PAS une empreinte fonctionnelle : le kernel EgisTec est
# probablement encore incomplet. Sert à collecter les logs d’échec.
set -eu

echo "==> sfos-xperia10v-fingerprint-fix : root experiment"

if [ "$(id -u)" -ne 0 ]; then
  echo "Relance avec :  devel-su sh $0"
  exit 1
fi

echo "==> 1/4 install sailfish-fpd + slave-binder"
pkcon install -y sailfish-fpd sailfish-fpd-slave-binder

echo "==> 2/4 enable/start sailfish-fpd (si unit présente)"
systemctl daemon-reload || true
if systemctl list-unit-files | grep -q '^sailfish-fpd.service'; then
  systemctl enable sailfish-fpd.service || true
  systemctl restart sailfish-fpd.service || true
  systemctl --no-pager status sailfish-fpd.service || true
else
  echo "WARN: sailfish-fpd.service introuvable après install"
fi

echo "==> 3/4 start fps_hal (vendor HAL @2.1)"
setprop ctl.start fps_hal || true
sleep 2
getprop init.svc.fps_hal || true
ps -A | grep -i fingerprint || true

echo "==> 4/4 binder + logs"
if command -v binder-list >/dev/null 2>&1; then
  binder-list -d /dev/hwbinder | grep -iE 'finger|egis|biometr' || echo "(pas d'interface finger sur hwbinder)"
fi
echo "--- dmesg ---"
dmesg | grep -iE 'egis|fingerprint|fps_hal|fp_egis' | tail -40 || true
echo "--- logcat ---"
logcat -d 2>/dev/null | grep -iE 'fingerprint|egis|fps_hal|Biometrics|sailfish-fpd' | tail -60 || true

echo
echo "Ensuite : diagnose-fingerprint.sh | tee ~/fingerprint-diag-after-root.txt"
echo "Si fps_hal reste mort : kernel/TZ toujours le blocage (voir RESEARCH.md)."
