# FIX AUTOMATION CUMULUS - 29 Octobre 2025

## 🔧 Problème Résolu

**Symptôme** : L'automatisation "Cumulus — Fin détectée par import (OFF + verrou + tag du jour)"
éteignait le cumulus à mauvais escient lors d'allumages manuels.

**Cause** : L'ancienne automatisation #4 se déclenchait trop facilement :
- Délai trop court (5 secondes seulement)
- Pas de vérification de la durée de chauffe réelle
- Pas d'exclusion pour les allumages manuels (override)

## ✅ Corrections Appliquées

### 1. Automatisation #4 DÉSACTIVÉE
- Ajout de `initial_state: false` → automatisation désactivée par défaut
- Conditions renforcées si réactivée :
  * Délai augmenté : 5s → 30s
  * Vérification que le cumulus chauffe depuis >5 minutes
  * Exclusion si `input_boolean.cumulus_override` est actif
  * Log ajouté pour traçabilité

### 2. Automatisation #4b ACTIVE (Méthode Recommandée)
L'automatisation "Fin chauffe universelle" reste la seule active :
- Détecte la fin de chauffe quelle que soit la source (PV, HC, manuelle)
- Délai robuste de 120 secondes
- Fonctionne correctement sans faux positifs

### 3. Encodage UTF-8 Corrigé
Tous les caractères mal encodés ont été corrigés :
- â€" → —
- Ã© → é, Ã  → à, Ã¨ → è, etc.

## 📋 Utilisation

### Désactivation Permanente (Recommandé)
L'automatisation #4 est déjà désactivée. Rien à faire.

### Réactivation (Non Recommandé)
Si vous souhaitez réactiver l'ancienne méthode :
1. Aller dans Paramètres → Automatisations
2. Chercher "Cumulus — Fin détectée par import (DÉSACTIVÉE)"
3. Activer manuellement

**⚠️ ATTENTION** : La méthode universelle (#4b) est plus fiable.

## 🧪 Tests Recommandés

1. **Test allumage manuel** :
   - Activer `input_boolean.cumulus_override`
   - Allumer le cumulus manuellement
   - Vérifier qu'il ne s'éteint PAS automatiquement

2. **Test automatisation universelle** :
   - Laisser le cumulus chauffer complètement (thermostat coupe)
   - Vérifier que l'automatisation détecte la fin après 120s
   - Vérifier que le verrou jour s'active

## 📦 Fichiers Modifiés

- `packages/cumulus.yaml` : Automatisation + encodage
- Backup créé automatiquement avant modification

## 🔗 Commits

- Commit : 556cbff
- GitHub : https://github.com/LaurentFrx/Home_Assistant/commit/556cbff

---

**Date** : 29 Octobre 2025
**Version** : v2025-10-29-fix-automation
**Auteur** : Laurent Feroux
**Assistance** : Claude Code
