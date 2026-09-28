#!/bin/sh
# Cartographie de la stack empreinte sur Xperia 10 V (officiel ou community).
# Sortie texte : à capturer (tee) pour comparaison.
set -eu

section() {
  printf '\n======== %s ========\n' "$1"
}

run() {
  printf '+ %s\n' "$*"
  # shellcheck disable=SC2086
  "$@" 2>&1 || true
}

section "device / OS"
run cat /etc/sailfish-release
run cat /etc/hw-release
run uname -a
run getprop ro.product.device
run getprop ro.build.product
run getprop ro.vendor.build.fingerprint

section "RPM fingerprint / lock"
rpm -qa 2>/dev/null | grep -iE 'fpd|fingerprint|biometr|devicelock' | sort || echo "(none)"

section "systemd units (system)"
systemctl list-units --all --no-pager 2>/dev/null | grep -iE 'fpd|finger|biometr' || echo "(none)"
systemctl list-unit-files --no-pager 2>/dev/null | grep -iE 'fpd|finger|biometr' || echo "(none)"

section "HAL binaries under /vendor /odm"
ls -la /vendor/bin/hw/ 2>/dev/null | grep -iE 'finger|egis|rbs|biometr' || echo "(no matching vendor bin)"
ls -la /odm/bin/hw/ 2>/dev/null | grep -iE 'finger|egis|rbs|biometr' || echo "(no matching odm bin)"
find /vendor/lib64 /vendor/lib /odm/lib64 -iname '*finger*' -o -iname '*egis*' 2>/dev/null | head -80 || true

section "VINTF manifests"
ls /vendor/etc/vintf/manifest/ 2>/dev/null | grep -iE 'finger|egis' || echo "(no finger manifest names)"
grep -RniE 'finger|egistec|biometrics' /vendor/etc/vintf/ /odm/etc/vintf/ 2>/dev/null | head -60 || true

section "binder / hwbinder fingerprint interfaces"
if command -v binder-list >/dev/null 2>&1; then
  binder-list -d /dev/hwbinder 2>/dev/null | grep -iE 'finger|egis|biometr' || echo "(no hwbinder finger)"
  binder-list -d /dev/binder 2>/dev/null | grep -iE 'finger|egis|biometr' || echo "(no binder finger)"
else
  echo "binder-list not installed"
fi

section "kernel modules / chardevs / sysfs"
lsmod 2>/dev/null | grep -iE 'egis|finger|fpsensor|goodix' || echo "(no fp modules loaded)"
ls -la /dev/esfp* /dev/egis* /dev/goodix* /dev/fpsensor* /dev/spidev* 2>/dev/null || echo "(no obvious fp chardevs)"
ls -la /sys/class/fingerprint 2>/dev/null || echo "(no /sys/class/fingerprint)"
find /sys -maxdepth 4 -iname '*egis*' 2>/dev/null | head -40 || true

section "input devices (egis_fp?)"
if [ -r /proc/bus/input/devices ]; then
  awk 'BEGIN{RS="";FS="\n"} tolower($0) ~ /egis|finger|fp_/{print;print ""}' /proc/bus/input/devices \
    || echo "(no egis/finger input block)"
else
  echo "/proc/bus/input/devices unreadable"
fi

section "TZ / firmware egista"
ls -la /vendor/firmware_mnt/image/egista* 2>/dev/null || echo "(no egista* under firmware_mnt/image)"
ls -la /vendor/firmware/egista* 2>/dev/null || echo "(no egista* under /vendor/firmware)"
mount 2>/dev/null | grep -E 'firmware|vendor|overlay' || true

section "getprop biometrics"
getprop 2>/dev/null | grep -iE 'finger|biometr|egis|fpd' || echo "(no matching props)"

section "dconf device lock"
if command -v dconf >/dev/null 2>&1; then
  dconf dump /desktop/nemo/devicelock/ 2>/dev/null || true
else
  echo "dconf missing"
fi

section "recent log hints (best-effort)"
if command -v journalctl >/dev/null 2>&1; then
  journalctl -b --no-pager 2>/dev/null | grep -iE 'fingerprint|sailfish-fpd|egis|egista|BiometricsFingerprint' | tail -80 || true
fi
logcat -d 2>/dev/null | grep -iE 'fingerprint|egis|egista|BiometricsFingerprint' | tail -80 || echo "(no logcat or no matches)"

section "done"
echo "Save this output and compare against RESEARCH.md expectations."
