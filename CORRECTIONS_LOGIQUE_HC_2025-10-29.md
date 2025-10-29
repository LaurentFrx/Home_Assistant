# CORRECTIONS LOGIQUE HC - 29 Octobre 2025

## 🎯 Problème Identifié

**Scénario problématique** :
1. Cumulus démarre en HC (23h00)
2. Température max atteinte à 03h00 (thermostat coupe)
3. Automatisation "Fin chauffe universelle" active le **verrou jour immédiatement**
4. Entre 03h00 et 08h10 : **Impossible de chauffer en PV** (verrou actif)
5. Reset quotidien à 08h10 : Trop tard, soleil déjà levé

**Conséquence** : Perte d'opportunité de chauffe PV entre la fin HC (07h00) et le reset (08h10)

---

## ✅ Solutions Appliquées

### 1. Automatisation "Fin chauffe universelle" - MODIFIÉE

**Fichier** : `automations/cumulus.yaml` (ligne ~217-228)

**Changement** : Ne plus activer le verrou immédiatement si en HC

**Avant** :
```yaml
- service: input_boolean.turn_on
  target:
    entity_id: input_boolean.cumulus_temp_atteinte_aujourdhui
- service: input_boolean.turn_on
  target:
    entity_id: input_boolean.cumulus_verrou_jour
```

**Après** :
```yaml
- service: input_boolean.turn_on
  target:
    entity_id: input_boolean.cumulus_temp_atteinte_aujourdhui
# ✅ CORRECTION : Ne PAS activer verrou si en HC
- choose:
    - conditions:
        - condition: state
          entity_id: binary_sensor.cumulus_en_hc
          state: "off"  # Seulement si HORS HC
      sequence:
        - service: input_boolean.turn_on
          target:
            entity_id: input_boolean.cumulus_verrou_jour
  default:
    - service: logbook.log
      data:
        name: "Cumulus Temp Max HC"
        message: "Température atteinte pendant HC - verrou activé à la fin HC"
```

**Résultat** : Si température atteinte pendant HC → Verrou PAS activé immédiatement

---

### 2. Automatisation "OFF fin HC" - AMÉLIORÉE

**Fichier** : `automations/cumulus.yaml` (ligne ~476)

**Changement** : Activer le verrou à la fin des HC si température a été atteinte pendant la nuit

**Ajout AVANT `switch.turn_off`** :
```yaml
# ✅ Si température atteinte pendant HC, activer verrou maintenant
- choose:
    - conditions:
        - condition: state
          entity_id: input_boolean.cumulus_temp_atteinte_aujourdhui
          state: "on"
      sequence:
        - service: input_boolean.turn_on
          target:
            entity_id: input_boolean.cumulus_verrou_jour
        - service: logbook.log
          data:
            name: "Cumulus Fin HC - Verrou Activé"
            message: "Température atteinte pendant HC - verrou jour activé"
  default:
    - service: logbook.log
      data:
        name: "Cumulus Fin HC"
        message: "Fin HC - température non atteinte, chauffe PV possible"
```

**Résultat** : À la fin des HC (07h00) → Si température atteinte pendant la nuit → Verrou activé

---

### 3. Reset Quotidien - HEURE MODIFIÉE

**Fichier** : `automations/cumulus.yaml` (ligne ~508)

**Changement** : 08:05 → 08:10

```yaml
trigger:
  - id: daily_reset
    platform: time
    at: "08:10:00"  # Modifié de 08:05 à 08:10
```

**Résultat** : Une seule heure de reset au lieu de deux (08:05 et 08:10)

---

### 4. Suppression Doublon - packages/cumulus.yaml

**Fichier** : `packages/cumulus.yaml` (ligne 783-793)

**Automatisation supprimée** :
```yaml
- id: cumulus_reset_daily_flags
  alias: Cumulus — Reset journalier (après HC)
  trigger:
    - platform: time
      at: "08:10:00"
  action:
    - service: input_boolean.turn_off
      target: { entity_id: input_boolean.temp_atteinte_aujourdhui }
    - service: input_boolean.turn_off
      target: { entity_id: input_boolean.cumulus_verrou_jour }
```

**Remplacé par** :
```yaml
# 7) Reset du tag "temp atteinte" - SUPPRIMÉ (doublon)
# L'automatisation "Reset quotidien & Override" dans automations/cumulus.yaml
# gère le reset à 08:10 + la fonctionnalité override manuel
```

**Résultat** : Plus de doublon, une seule automatisation de reset

---

## 📊 Nouvelle Timeline Intelligente

**Exemple avec température atteinte pendant HC** :

| Heure | Événement | Verrou Jour | Commentaire |
|-------|-----------|-------------|-------------|
| 23:00 | Début HC | OFF | Cumulus démarre |
| 03:00 | Temp max atteinte | **OFF** | ✅ Verrou PAS activé (en HC) |
| 07:00 | Fin HC | **ON** | ✅ Verrou activé maintenant |
| 08:10 | Reset quotidien | OFF | Nouveau jour |

**Exemple avec température NON atteinte pendant HC** :

| Heure | Événement | Verrou Jour | Commentaire |
|-------|-----------|-------------|-------------|
| 23:00 | Début HC | OFF | Cumulus démarre |
| 03:00 | Limiteur coupe | OFF | Température non atteinte |
| 07:00 | Fin HC | **OFF** | ✅ Verrou PAS activé |
| 10:00 | Chauffe PV | OFF | ✅ Chauffe PV possible ! |
| 14:00 | Temp max PV | ON | Verrou activé après chauffe PV |

---

## 🎯 Bénéfices

1. ✅ **Chauffe PV possible après HC** si température non atteinte la nuit
2. ✅ **Pas de verrou prématuré** pendant les heures creuses
3. ✅ **Une seule automatisation de reset** (suppression doublon)
4. ✅ **Logique cohérente** : Verrou activé au bon moment

---

## 🧪 Tests Recommandés

### Test 1 : Température Atteinte en HC
1. Activer override et démarrer cumulus à 03:00
2. Laisser chauffer jusqu'à température max
3. **Vérifier** : `input_boolean.cumulus_verrou_jour` reste OFF
4. **Attendre 07:00** (ou simuler fin HC)
5. **Vérifier** : Verrou passe à ON

### Test 2 : Température NON Atteinte en HC
1. Démarrer cumulus en HC
2. Arrêter avant température max
3. **Vérifier** : Verrou reste OFF après fin HC
4. **Vérifier** : Chauffe PV possible après 07:00

### Test 3 : Reset Quotidien
1. **Vérifier** : Une seule automatisation de reset à 08:10
2. **Vérifier** : Plus de doublon à 08:05

---

**Date** : 29 Octobre 2025
**Version** : v2025-10-29-fix-hc-logic
**Auteur** : Laurent Feroux
**Assistance** : Claude Code
