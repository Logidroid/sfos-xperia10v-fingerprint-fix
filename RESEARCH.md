# Recherche approfondie — empreinte Xperia 10 V (zambezi)

Date : 2026-09-28. Sources : docs Sailfish HADK, forum SFOS, IRC
`#sailfishos-porters`, GitHub Sharks / Sony / sailfishos-open.

## 1. Stack attendue sous Sailfish

```
UI Settings / lockscreen
        │  D-Bus org.sailfishos.fingerprint1
        ▼
sailfish-fpd  (+ slave fermé Jolla)
   ou sailfish-fpd-community  (ports communauté)
        │  libbiometry / HIDL client
        ▼
android.hardware.biometrics.fingerprint@2.1::IBiometricsFingerprint
        │
        ▼
HAL Sony / EgisTec  →  /dev + TrustZone (egista.mdt)  →  capteur SPI
```

Sans le service `@2.1` (ou un équivalent AIDL branché dans fpd), l’UI
empreinte reste morte même si le nœud input `egis_fp` existe.

## 2. Matériel & interfaces sur zambezi / murray

| Couche | Observation |
|--------|-------------|
| Capteur | EgisTec (input `egis_fp` présent sur le port Lineage) |
| HIDL proprio | `vendor.egistec.hardware.fingerprint@4.0::{IBiometricsFingerprintRbs,IBiometricsFingerprintBix}` |
| AIDL | `android.hardware.biometrics.fingerprint.IFingerprint/default` (A15) |
| Firmware TZ | `/vendor/firmware_mnt/image/egista.mdt` (+ fragments `.b0x`) |
| Kernel SODP | Driver EgisTec longtemps incomplet (IRQ / ID `0`) — Sony #796 |

Le callback EgisTec `@4.0` n’expose **pas** `onEnrollResult` /
`onAuthenticated` standards, seulement `ipc_callback(a1..a5)` opaque.
Brancher sailfish-fpd-community dessus en changeant juste le type HIDL
**échoue** (essai Sharks, murray#1).

## 3. Image officielle Jolla — constats **sur ton XQ-DC54** (2026-09-28)

Appareil : SFOS **5.1.0.11**, HA `xqdc54` **1.0.0.9**, kernel `5.4.210-sodp`,
vendor AOSP14 `eng.jolla.20250114` (`pdx235`).

| Couche | État observé |
|--------|----------------|
| Package `sailfish-devicelock-fpd` | **Installé** (plugin lipstick `encsfa-fpd`) |
| Packages `sailfish-fpd` + `sailfish-fpd-slave-binder` | **Absents** mais **disponibles** dans les repos Jolla |
| `wait_for_keymaster.service` | Actif (`Before=sailfish-fpd.service`) — fpd prévu mais jamais installé |
| Binaire HAL | **Présent** : `/vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service.sony` |
| Init | `fps_hal` class `late_start` ; `droid.late_start=trigger_late_start` |
| `init.svc.fps_hal` | **Absent** → le service n’est pas (plus) vivant |
| hwbinder `@2.1::IBiometricsFingerprint` | **Non enregistré** |
| DT / sysfs | Nœud `soc:fp_egistec` présent (devlinks regulator/pinctrl) |
| Input `egis_fp` / module / chardev | **Absents** |
| `egista.mdt` sous `firmware_mnt` | Non listable (perm) / pas de match visible |
| `fingerprint.default.so` | **Absent** de `/vendor/lib64/hw/` |

Documentation HADK : *Fingerprint doesn’t work* (kernel + userspace unfinished),
lien Sony [#796](https://github.com/sonyxperiadev/bug_tracker/issues/796).

**Interprétation :** Jolla a livré le HAL Sony OSS + le plugin lock fpd, mais
a omis d’installer le daemon `sailfish-fpd` (HW non prêt). Même en installant
fpd + en démarrant `fps_hal`, le driver kernel EgisTec ne crée pas encore le
device → même classe d’échec que #796 (`open` → `fd=-1`).

Conséquence : pas de fix « camera-style » fiable tant que kernel/TZ ne
fournissent pas le nœud + `egista.*`. Première expérience utile (root) :

1. `pkcon install sailfish-fpd sailfish-fpd-slave-binder`
2. `devel-su setprop ctl.start fps_hal` (ou service systemd wrapper)
3. Relire `diagnose-fingerprint.sh` + `logcat` / `dmesg` pour le crash HAL

## 4. Port communauté Lineage 22.2 (Sharks)

Repo : https://github.com/sharks-dev/sailfish-on-zambezi  
Base : LineageOS 22.2 (Android 15), même classe que murray (10 IV).

### 4.1 Ce qui a marché sur Murray (10 IV)

Approche gagnante (murray#1, tag ~0.0.11, commit `793e8f3`) :

1. Extraire du **firmware stock A14 Sony** :
   - `android.hardware.biometrics.fingerprint@2.1-service`
   - `fingerprint.default.so`
   - manifests VINTF `@2.1` + `vendor.egistec…`
   - init `.rc`, permissions XML
   - libs associées (`vendor.semc.hardware.fingerprint-…`)
2. Les monter via **overlayfs ciblé** (pas un overlay de tout `/vendor` —
   ça masquait `firmware_mnt` → Wi‑Fi mort + `egista.mdt` introuvable).
3. Une fois `@2.1` vivant + firmware TZ accessible → fpd OK.

Leçon critique : l’overlay doit **préserver** `/vendor/firmware_mnt`.

### 4.2 Tentative Zambezi (10 V)

- Commit `11f39a7` sur `droid-config-pdx235` : mêmes blobs depuis
  firmware `68.1.A.2.270`, script `mount-overlays`, packages fpd.
- Test juz : **fonctionnel un court instant**, puis **inconsistant**.
- Revert (commentaire 2026-09-15) : Sharks estime avoir besoin d’un
  10 V physique pour debugger.

Forum (fin août 2026) : Sharks indique que l’empreinte est son focus
courant, « closer every day », sans garantie de délai.

### 4.3 Voies alternatives explorées (Sharks)

| Voie | Résultat |
|------|----------|
| Mapper fpd-community sur EgisTec `@4.0` | Échec (API ipc opaque) |
| `vendor-sony-oss-fingerprint` dans tree A15 | Build cassé (Android.mk / libc++ ABI / headers kernel) |
| Blobs `@2.1` stock | **Gagnant** sur Murray ; fragile sur Zambezi |
| AIDL via biometryd UBports (gbinder) | Prometteur long terme, gros portage |

## 5. Classement des solutions

### A — Meilleure (pratique, court/moyen terme)

**Rester / passer sur le port communauté Sharks** et contribuer à
stabiliser l’overlay blobs + `egista.mdt` + fpd sur pdx235.

Pourquoi : seul chemin où l’empreinte a déjà été vue vivante sur 10 V
et où le 10 IV prouve que la méthode est bonne.

Travail utile à faire ici (ce dépôt) :

1. `diagnose-fingerprint.sh` avant/après overlay.
2. Extraire proprement les blobs `68.1.A.*` (script documenté, **sans**
   republier de blobs propriétaires dans le git public).
3. Overlay **fichier-par-fichier** (bind-mount) plutôt qu’overlay dir
   entière de `/vendor`.
4. Vérifier présence de `egista.mdt` et logs `fingerprint@2.1` / fpd
   au boot.
5. Remonter les résultats à Sharks / juz.

### B — Technique OSS propre (moyen/long)

Porter / builder `vendor-sony-oss-fingerprint` pour Lineage 22.2
(Android.bp, fix ABI), puis brancher `sailfish-fpd-community`.

Avantage : pas de blobs stock fermés dans droid-config.  
Coût : compile A15 + validation TZ/kernel.

### C — Future-proof

Importer le client AIDL de
[biometryd MR !48](https://gitlab.com/ubports/development/core/biometryd/-/merge_requests/48)
dans sailfish-fpd-community (libgbinder, hors Android.mk).

### D — Image officielle Jolla

Attendre un kernel + HAL finis côté SODP/Jolla. Aucun patch userspace
local crédible. Les workarounds camera/jack **ne s’appliquent pas**.

## 6. Pièges connus

- Overlayfs large sur `/vendor` → casse `firmware_mnt` (Wi‑Fi, TZ FP).
- Relancer seulement `sailfish-fpd` sans HAL `@2.1` → inutile.
- Confondre présence de `egis_fp` dans `/proc/bus/input/devices` avec
  un HAL fonctionnel.
- Copier des blobs A14 sur base A15 peut segfault dans
  `setActiveGroup` si dépendances / SELinux / firmware incomplets
  (vu sur Murray avant le fix firmware_mnt).

## 7. Références

- https://docs.sailfishos.org/Develop/HW_Adaptation/Sailfish_X_Xperia_Android_13_Build_and_Flash/
- https://github.com/sonyxperiadev/bug_tracker/issues/796
- https://github.com/sonyxperiadev/vendor-sony-oss-fingerprint
- https://github.com/sailfishos-open/sailfish-fpd-community
- https://github.com/sharks-dev/sailfish-on-murray/issues/1
- https://github.com/sharks-dev/sailfish-on-zambezi
- https://github.com/sharks-dev/droid-config-pdx235/commit/11f39a7
- IRC 2026-09-01 `#sailfishos-porters` (Sharks / T42 / rinigus)
- Forum : https://forum.sailfishos.org/t/lineage-based-port-for-xperia-10-v-zambezi/31348
