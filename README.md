# sfos-xperia10v-fingerprint-fix

Recherche et pistes pour le **lecteur d’empreintes** sur **Sony Xperia 10 V**
(`pdx235` / XQ-DC54 / zambezi) sous Sailfish OS.

## Verdict (sept. 2026)

Il n’existe **pas** de workaround utilisateurspace du type « démarrer un service
désactivé » (contrairement à la caméra). Le capteur EgisTec exige une chaîne
complète : **kernel → TZ firmware → HAL → sailfish-fpd**.

| Environnement | Empreinte | Meilleure piste |
|---------------|-----------|-----------------|
| **SFOS officiel Jolla** | Cassé (doc HADK) | Kernel/HAL incomplets — pas de fix userland réaliste |
| **Port communauté Lineage 22.2** (Sharks) | Instable / en cours | Overlay des blobs vendor stock Sony + `sailfish-fpd*` |

Détail technique : [RESEARCH.md](RESEARCH.md).

## Cause (résumé)

1. Capteur **EgisTec** exposé en HIDL propriétaire  
   `vendor.egistec.hardware.fingerprint@4.0::IBiometricsFingerprintRbs`  
   (callbacks `ipc_callback` non documentés) et/ou AIDL `IFingerprint` v4.
2. `sailfish-fpd` / `sailfish-fpd-community` attendent  
   `android.hardware.biometrics.fingerprint@2.1`.
3. Sur le port officiel A13/A14 Jolla : driver kernel + userspace **non finis**  
   ([docs Sailfish](https://docs.sailfishos.org/Develop/HW_Adaptation/Sailfish_X_Xperia_Android_13_Build_and_Flash/),  
   [Sony #796](https://github.com/sonyxperiadev/bug_tracker/issues/796)).
4. Sur Murray (10 IV), Sharks a débloqué via **blobs `@2.1` du firmware stock**  
   + overlay soigneux (ne pas masquer `/vendor/firmware_mnt` → `egista.mdt`).  
   Sur Zambezi : même approche a **marché brièvement** puis a été **revertée**  
   (instable ; debug difficile sans 10 V sous la main) —  
   [murray#1](https://github.com/sharks-dev/sailfish-on-murray/issues/1).

## Ce que fait ce dépôt (v0)

- Scripts de **diagnostic** (déjà exécuté sur ton 10 V officiel → voir
  `fingerprint-diag-official.txt`).
- Expérience root : installer `sailfish-fpd` manquant + démarrer `fps_hal`.
- Doc de la **meilleure solution** (community overlay) et des voies mortes.
- Pas encore de fix magique pour l’image officielle.

## Diagnostic (sur le téléphone)

```sh
cd sfos-xperia10v-fingerprint-fix
chmod +x scripts/*.sh install.sh uninstall.sh
./install.sh
diagnose-fingerprint.sh | tee ~/fingerprint-diag.txt
```

## Expérience root (officielle) — besoin de ton code devel

`pkcon` / `setprop ctl.start` exigent root. Sur le téléphone :

```sh
devel-su sh ~/fingerprint-fix/../sfos-xperia10v-fingerprint-fix/scripts/root-try-enable-fpd.sh
# ou, si le repo est cloné dans ~ :
devel-su sh ~/sfos-xperia10v-fingerprint-fix/scripts/root-try-enable-fpd.sh
```

Si `devel-su` affiche `Authentication token manipulation error`, définis un
mot de passe développeur : Réglages → Développement.

## Pistes classées (meilleure → pire)

1. **Port communauté + overlay blobs stock** (validé Murray, partiel Zambezi)  
   — suivre / contribuer à [sailfish-on-zambezi](https://github.com/sharks-dev/sailfish-on-zambezi)  
   et [murray#1](https://github.com/sharks-dev/sailfish-on-murray/issues/1).
2. **`vendor-sony-oss-fingerprint`** → wrapper EgisTec → `@2.1` +  
   `sailfish-fpd-community` — bloqué par build Android 15 / ABI.
3. **Porter biometryd AIDL (UBports/gbinder)** dans sailfish-fpd-community  
   — gros chantier, plus pérenne.
4. **Attendre Jolla** sur l’image officielle — pas d’ETA publique.

## Licence

MIT — voir [LICENSE](LICENSE).
