# 📋 CHANGELOG — Cumulus v2025-10-12a

**Date de déploiement :** 2025-10-12
**Version précédente :** v2025-10-10c
**Fichier modifié :** `packages/cumulus.yaml`

---

## 🎯 OBJECTIF DE CETTE VERSION

Améliorer la précision du déclenchement PV en prenant en compte :
- Le coefficient d'efficacité réel de l'onduleur APS
- Le facteur de charge PV (ratio production actuelle / max théorique)
- La puissance SolarBank disponible
- Diagnostic automatique des refus de démarrage

---

## ✨ NOUVEAUTÉS

### **1. Helper modifiable : Coefficient α_APS**
- **Entité :** `input_number.cumulus_alpha_aps`
- **Valeur par défaut :** 0.88 (88% d'efficacité)
- **Plage :** 0.5 à 1.0 (step 0.01)
- **Usage :** Ajustable via l'interface pour affiner le calcul PV effectif

### **2. Sensor : Capacity Factor**
- **Entité :** `sensor.cumulus_capacity_factor`
- **Calcul :** `PV_actuel / (SB_max + APS_max)`
- **Usage :** Détecte automatiquement si le système tourne à pleine capacité

### **3. Sensor : PV Effectif**
- **Entité :** `sensor.cumulus_pv_effectif_w`
- **Formule :** `PV_brut × α_APS × capacity_factor`
- **Attributs exposés :**
  - `pv_brut_w`
  - `alpha_aps`
  - `capacity_factor`
  - `formule` (pour référence)

### **4. Sensor : SolarBank Disponible**
- **Entité :** `sensor.cumulus_sb_dispo_w`
- **Calcul :** `SB_max - (Conso_maison - PV_total)`
- **Fallback :** Retourne 0 si calcul négatif

### **5. Automation : Diagnostic Refus Démarrage**
- **ID :** `cumulus_log_refus_demarrage`
- **Déclencheur :** PV effectif > seuil pendant 30s MAIS cumulus OFF
- **Actions :**
  - Notification persistante avec raisons du blocage
  - Log dans `home-assistant.log` (niveau WARNING)
- **Raisons détectées :**
  - Mode INTERDIT/VACANCES actif
  - Verrou journalier actif
  - Température atteinte
  - Deadband en cours
  - Appareil prioritaire actif
  - SOC trop bas

---

## 🔧 MODIFICATIONS D'ENTITÉS EXISTANTES

### **Sensor : `cumulus_seuil_pv_dynamique_w`**
- ✅ Ajout attributs `pv_effectif_actuel_w` et `pv_brut_actuel_w` (debug)
- ℹ️ Logique de calcul INCHANGÉE

### **Automation : `ce_on_pv_simple`**
- ⚠️ **BREAKING CHANGE** : Utilise `sensor.cumulus_pv_effectif_w` au lieu de `sensor.cumulus_pv_power_w`
- **Impact :** Déclenchement plus conservateur (PV effectif < PV brut)
- **Zones modifiées :**
  - Trigger `value_template`
  - Condition `value_template` (ligne ~902)
  - Condition avant action (lignes ~944 et ~954)

---

## 📊 RÉSUMÉ DES CHANGEMENTS

| Type | Créations | Modifications | Suppressions |
|------|-----------|---------------|--------------|
| **input_number** | 1 | 0 | 0 |
| **Sensors** | 3 | 1 | 0 |
| **Automations** | 1 | 1 | 0 |
| **TOTAL** | **5** | **2** | **0** |

---

## ⚠️ POINTS D'ATTENTION

### **Breaking Change : Automation ON PV**
L'utilisation de `pv_effectif_w` peut retarder le démarrage si :
- Le coefficient α_APS est faible (< 0.85)
- Le capacity factor est bas (nuages intermittents)

**Mitigation :** Ajuster `input_number.cumulus_alpha_aps` si nécessaire.

### **Nouveaux sensors à surveiller**
Vérifier dans Developer Tools > States que les nouveaux sensors affichent des valeurs cohérentes :
- `sensor.cumulus_capacity_factor` entre 0.0 et 1.0
- `sensor.cumulus_pv_effectif_w` ≤ `sensor.cumulus_pv_power_w`
- `sensor.cumulus_sb_dispo_w` ≥ 0

---

## 🧪 TESTS RECOMMANDÉS

Voir fichier `TEST_CHECKLIST_cumulus_v2025-10-12a.md`

---

## 📦 FICHIERS CONCERNÉS

- ✅ `packages/cumulus.yaml` (modifié)
- ✅ `packages/cumulus_backup_20251012_100120.yaml` (backup créé)
- ℹ️ `lovelace_carte_cumulus.yaml` (à mettre à jour ultérieurement)
- ℹ️ `lovelace_carte_cumulus_utilisateur.yaml` (à mettre à jour ultérieurement)

---

**🤖 Généré automatiquement par Claude Code**
