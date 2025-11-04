# RÉSUMÉ CORRECTIONS AUTOMATISATIONS CUMULUS
## 29 Octobre 2025

---

## 🎯 Problèmes Résolus

Vous avez dû désactiver **2 automatisations** qui éteignaient le cumulus à mauvais escient lors d'allumages manuels :

1. **"Cumulus — Fin détectée par import (OFF + verrou + tag du jour)"** dans `packages/cumulus.yaml`
2. **"Cumulus — Fin chauffe universelle"** dans `automations/cumulus.yaml`

---

## ✅ CORRECTION #1 : Automatisation "Fin détectée par import"

### Fichier : `packages/cumulus.yaml`

**Problème** :
- Délai trop court : 5 secondes seulement
- Pas de vérification de durée réelle de chauffe
- Pas d'exclusion pour allumages manuels

**Solution Appliquée** :
- ✅ **Automatisation DÉSACTIVÉE par défaut** (`initial_state: false`)
- ✅ Conditions renforcées si réactivée :
  - Délai augmenté : 5s → 30s
  - Vérification chauffe réelle depuis >5 minutes
  - Exclusion si `input_boolean.cumulus_override` actif
  - Logs de traçabilité ajoutés

**Résultat** :
- L'automatisation ne se déclenchera plus automatiquement
- L'automatisation 4b "Fin chauffe universelle" (dans packages) reste active (méthode recommandée)

---

## ✅ CORRECTION #2 : Automatisation "Fin chauffe universelle"

### Fichier : `automations/cumulus.yaml`

**Problème** :
- Délai trop court : 20 secondes seulement
- Pas d'exclusion pour allumages manuels
- Se déclenchait avant que le système détecte la chauffe réelle

**Solution Appliquée** :
- ✅ **Délai augmenté** : 20s → 60s
  - Trigger : `binary_sensor.cumulus_chauffe_reelle` OFF pendant 60s (au lieu de 20s)
- ✅ **Condition override ajoutée** :
  - Ne se déclenche PAS si `input_boolean.cumulus_override` est actif
  - Protection complète des allumages manuels
- ✅ **Conditions existantes conservées** :
  - Durée minimale de chauffe >= 120s
  - Vérification `input_boolean.cumulus_interdit_depart`

**Résultat** :
- Plus d'extinction intempestive lors d'allumage manuel
- Détection fiable après chauffes complètes uniquement

---

## 🔧 Bonus : Correction Encodage UTF-8

**Problème** :
- Caractères mal encodés dans tout le fichier `packages/cumulus.yaml`
- Exemples : â€" → —, Ã© → é, Ã  → à, etc.

**Solution** :
- ✅ Tous les caractères corrigés
- ✅ Amélioration de la lisibilité du code

---

## 📊 Commits GitHub

1. **556cbff** - Fix automatisation packages + encodage UTF-8
2. **bd0d263** - Fix automatisation universelle automations
3. **2e62c75** - Documentation

**Repository** : https://github.com/LaurentFrx/Home_Assistant

---

## 🧪 Tests Recommandés

### Test 1 : Allumage Manuel
1. Activer `input_boolean.cumulus_override`
2. Allumer le cumulus manuellement via l'app Shelly
3. **✅ VÉRIFIER** : Le cumulus ne s'éteint PAS automatiquement
4. Désactiver `input_boolean.cumulus_override` quand terminé

### Test 2 : Chauffe Complète Automatique
1. Laisser le système démarrer une chauffe PV automatiquement
2. Laisser chauffer jusqu'à température max (thermostat coupe)
3. **✅ VÉRIFIER** : Après 60s, l'automatisation détecte la fin
4. **✅ VÉRIFIER** : Le verrou jour s'active
5. **✅ VÉRIFIER** : L'historique est mis à jour

### Test 3 : Chauffe HC
1. Attendre le début des heures creuses
2. Si besoin urgent, le cumulus démarre automatiquement
3. Laisser chauffer en HC
4. **✅ VÉRIFIER** : Fin détectée correctement
5. **✅ VÉRIFIER** : Verrou activé si température atteinte

---

## 📁 Fichiers Modifiés

| Fichier | Modifications |
|---------|---------------|
| `packages/cumulus.yaml` | Automatisation #4 désactivée + encodage UTF-8 |
| `automations/cumulus.yaml` | Automatisation universelle : délai 60s + condition override |
| `FIX_AUTOMATION_2025-10-29.md` | Documentation (créé) |

---

## 🔄 Automatisations Actives vs Désactivées

### ✅ ACTIVES (Recommandées)

| Fichier | Automatisation | Statut |
|---------|----------------|--------|
| `automations/cumulus.yaml` | Fin chauffe universelle | ✅ ACTIVE (corrigée) |
| `packages/cumulus.yaml` | Fin chauffe universelle (4b) | ✅ ACTIVE |

### ❌ DÉSACTIVÉES (Obsolètes)

| Fichier | Automatisation | Statut |
|---------|----------------|--------|
| `packages/cumulus.yaml` | Fin détectée par import (#4) | ❌ DÉSACTIVÉE |

---

## 💡 Recommandations

1. **Utiliser `input_boolean.cumulus_override`** :
   - Activez-le AVANT tout allumage manuel
   - Le système ne coupera pas le cumulus
   - Désactivez-le après utilisation

2. **Surveiller les logs** :
   - Vérifier le logbook Home Assistant
   - Chercher "Cumulus" dans les logs
   - Identifier toute extinction non désirée

3. **Ne pas réactiver l'automatisation #4** :
   - L'automatisation universelle est plus fiable
   - Laissez-la désactivée sauf cas spécifique

---

## 🆘 En Cas de Problème

Si le cumulus s'éteint encore à mauvais escient :

1. **Vérifier l'état de `input_boolean.cumulus_override`**
   - Doit être ON lors d'allumages manuels

2. **Vérifier les logs** :
   ```
   Outils développeur → Logbook → Rechercher "Cumulus"
   ```

3. **Vérifier les automatisations actives** :
   ```
   Paramètres → Automatisations → Rechercher "Cumulus"
   ```

4. **Contacter le support** avec :
   - Capture d'écran des logs
   - Heure exacte de l'incident
   - État des input_boolean au moment de l'incident

---

**Date** : 29 Octobre 2025
**Version** : v2025-10-29-fix-auto-complete
**Auteur** : Laurent Feroux
**Assistance** : Claude Code
**GitHub** : https://github.com/LaurentFrx/Home_Assistant
