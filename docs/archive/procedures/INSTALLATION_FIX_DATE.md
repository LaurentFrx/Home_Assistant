# Installation du correctif automatique de date - Cumulus

**Date :** 2025-10-25
**Version :** v2025-10-25-fix-date-auto
**Problème résolu :** Message "besoin urgent" permanent dû à une date invalide

---

## 🎯 Problème résolu

### Symptôme
Le message "besoin urgent" s'affichait en permanence même après avoir initialisé `input_datetime.cumulus_derniere_chauffe_complete`.

### Cause racine
Lors de l'initialisation manuelle, l'année était incorrecte :
- Année mise : **2024**
- Année actuelle : **2025**
- Résultat : 365 jours d'écart = 8768 heures
- 8768h >= 50h (seuil) → **Besoin urgent permanent** ❌

### Solution
5 automations + 1 script pour gérer automatiquement la date sans intervention manuelle.

---

## 📦 Contenu du correctif

Le fichier [cumulus_fix_date_auto.yaml](../cumulus_fix_date_auto.yaml) contient :

### 5 Automations

| ID | Nom | Description | Trigger |
|----|-----|-------------|---------|
| 1 | Init au démarrage | Initialise la date au démarrage de HA si jamais configurée | HA start |
| 2 | MAJ après fin chauffe | Met à jour la date après chaque chauffe complète | Chauffe OFF + verrou ON |
| 3 | Protection date invalide | Détecte et corrige les dates > 30 jours | Toutes les heures |
| 4 | Maintenance hebdo | Vérifie la cohérence et notifie si pas de chauffe depuis 7j | Dimanche 12h |
| 5 | Correction besoin urgent | Corrige automatiquement si besoin urgent anormal > 2h | Besoin urgent ON 2h |

### 1 Script

| Nom | Description | Usage |
|-----|-------------|-------|
| cumulus_reset_derniere_chauffe | Réinitialise manuellement la date | Appel manuel si besoin |

---

## 🚀 Installation

### Prérequis

Vérifiez que votre configuration contient :
- ✅ `input_datetime.cumulus_derniere_chauffe_complete`
- ✅ `sensor.cumulus_heures_depuis_derniere_chauffe`
- ✅ `binary_sensor.cumulus_besoin_chauffe_urgente`
- ✅ `binary_sensor.cumulus_chauffe_reelle`
- ✅ `input_boolean.cumulus_verrou_jour`

---

### Méthode A : Package séparé (RECOMMANDÉ)

**Avantages :**
- Séparation des préoccupations
- Facile à activer/désactiver
- Pas de modification des fichiers existants

**Installation :**

1. **Copiez le fichier dans packages/**
   ```bash
   # Dans votre dossier config Home Assistant
   cp cumulus_fix_date_auto.yaml packages/
   ```

2. **Vérifiez que packages est activé dans configuration.yaml**
   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```

3. **Redémarrez Home Assistant**
   - Paramètres → Système → Redémarrer

4. **Vérifiez l'installation**
   - Paramètres → Automations et Scènes
   - Cherchez "Cumulus" dans la barre de recherche
   - Vous devriez voir 5 nouvelles automations

---

### Méthode B : Intégration dans automations.yaml

**Avantages :**
- Tout centralisé dans automations.yaml
- Pas besoin de packages

**Installation :**

1. **Ouvrez votre automations.yaml**

2. **Ajoutez à la fin du fichier**
   ```yaml
   # Copiez toute la section automation: de cumulus_fix_date_auto.yaml
   # SANS le "automation:" du début (il existe déjà dans votre fichier)
   ```

3. **Rechargez les automations**
   - Developer Tools → YAML → Reload Automations
   - OU : Paramètres → Automations → ⋮ → Recharger les automations

4. **Vérifiez**
   - Les 5 automations apparaissent dans la liste

---

### Méthode C : Fusion avec cumulus.yaml

**Avantages :**
- Tout dans un seul fichier
- Cohérence du package

**Installation :**

1. **Ouvrez votre fichier cumulus.yaml actif**
   - Probablement : `C:\Users\wakaw\Downloads\cumulus.yaml`

2. **Ajoutez à la fin du fichier**
   ```yaml
   # Copiez TOUTE la section automation: + script: de cumulus_fix_date_auto.yaml
   ```

3. **Rechargez le package**
   - Developer Tools → YAML → Reload All YAML Configuration
   - OU redémarrez HA

---

## ✅ Vérification de l'installation

### Test 1 : Automations présentes

1. Allez dans **Paramètres → Automations et Scènes**
2. Cherchez "Cumulus" dans la barre de recherche
3. Vous devriez voir :
   - ✅ Cumulus — Init dernière chauffe au démarrage
   - ✅ Cumulus — MAJ dernière chauffe après fin
   - ✅ Cumulus — Protection date invalide
   - ✅ Cumulus — Maintenance hebdo date
   - ✅ Cumulus — Correction besoin urgent anormal

### Test 2 : Script disponible

1. Allez dans **Developer Tools → Services**
2. Cherchez : `script.cumulus_reset_derniere_chauffe`
3. Le script devrait apparaître

### Test 3 : Initialisation automatique

1. **Developer Tools → States**
2. Cherchez `input_datetime.cumulus_derniere_chauffe_complete`
3. Vérifiez que la date est récente (< 24h)
4. Vérifiez l'année : **2025** ✅

### Test 4 : Besoin urgent OFF

1. **Developer Tools → States**
2. Cherchez `binary_sensor.cumulus_besoin_chauffe_urgente`
3. État devrait être : **off** ✅
4. Cherchez `sensor.cumulus_heures_depuis_derniere_chauffe`
5. Valeur devrait être : **< 50 heures** ✅

---

## 🧪 Tests manuels

### Test du script de reset

```yaml
# Dans Developer Tools → Services
service: script.cumulus_reset_derniere_chauffe
data: {}
```

**Résultat attendu :**
- Date mise à jour à maintenant
- Notification affichée
- Besoin urgent passe à OFF

---

### Test de l'automation de fin de chauffe

**Scénario :**
1. Activez manuellement le contacteur cumulus
2. Attendez 2 minutes (chauffe détectée)
3. Le thermostat coupe (température max)
4. `binary_sensor.cumulus_chauffe_reelle` passe à OFF
5. `input_boolean.cumulus_verrou_jour` passe à ON

**Résultat attendu :**
- `input_datetime.cumulus_derniere_chauffe_complete` se met à jour automatiquement
- Message dans les logs : "Chauffe complète détectée"

---

### Test de protection date invalide

**Scénario de test :**
1. Mettez manuellement une date invalide :
   ```yaml
   service: input_datetime.set_datetime
   target:
     entity_id: input_datetime.cumulus_derniere_chauffe_complete
   data:
     datetime: "2024-01-01 00:00:00"
   ```

2. Attendez 1 heure (ou forcez le trigger)

**Résultat attendu :**
- Automation détecte la date > 30 jours
- Corrige automatiquement à hier
- Notification affichée

---

## 📊 Monitoring

### Logs à surveiller

**Dans Developer Tools → Logs**, cherchez :

```
Cumulus : Initialisation automatique de derniere_chauffe_complete
Cumulus : Chauffe complète détectée, mise à jour
Cumulus : Correction automatique de besoin urgent anormal
Cumulus : Maintenance hebdomadaire
```

### Notifications

Les notifications apparaissent dans le panneau de notifications (🔔) :

| Notification | Cause | Action |
|--------------|-------|--------|
| ⚠️ Date corrigée | Date > 30 jours détectée | Vérifier pourquoi la date était invalide |
| ℹ️ Maintenance | Pas de chauffe depuis 7j | Vérifier le fonctionnement du cumulus |
| 🔧 Correction automatique | Besoin urgent anormal | Date corrigée automatiquement |
| ✅ Date réinitialisée | Script manuel exécuté | Confirmation du reset |

---

## 🔧 Configuration avancée

### Modifier le seuil de détection

Par défaut, "besoin urgent" s'active après **50 heures** sans chauffe.

Pour modifier :

```yaml
# Dans Developer Tools → Services
service: input_number.set_value
target:
  entity_id: input_number.cumulus_espacement_max_h
data:
  value: 72  # 3 jours au lieu de 50h
```

### Désactiver temporairement

Pour désactiver les automations sans les supprimer :

1. **Paramètres → Automations et Scènes**
2. Cliquez sur l'automation
3. Basculez le toggle à **OFF**

### Modifier la fréquence de vérification

L'automation de protection vérifie **toutes les heures**.

Pour modifier, éditez `cumulus_protection_date_invalide` :

```yaml
trigger:
  - platform: time_pattern
    hours: "/6"  # Toutes les 6 heures au lieu de 1
```

---

## ❗ Dépannage

### "Les automations n'apparaissent pas"

**Solutions :**
1. Vérifiez les erreurs YAML :
   - Developer Tools → YAML → CHECK CONFIGURATION
2. Vérifiez les logs :
   - Developer Tools → Logs
3. Redémarrez complètement HA

### "Besoin urgent reste actif"

**Diagnostic :**
1. Vérifiez la date actuelle :
   ```yaml
   # Developer Tools → Template
   {{ states('input_datetime.cumulus_derniere_chauffe_complete') }}
   {{ state_attr('input_datetime.cumulus_derniere_chauffe_complete', 'timestamp') }}
   ```

2. Vérifiez les heures calculées :
   ```yaml
   {{ states('sensor.cumulus_heures_depuis_derniere_chauffe') }}
   ```

3. Forcez le reset manuel :
   ```yaml
   service: script.cumulus_reset_derniere_chauffe
   ```

### "L'automation de fin de chauffe ne se déclenche pas"

**Vérifications :**
1. `binary_sensor.cumulus_chauffe_reelle` existe et fonctionne ?
2. `input_boolean.cumulus_verrou_jour` s'active après chauffe ?
3. La durée de chauffe est > 120 secondes ?

**Logs :**
```yaml
# Developer Tools → States
binary_sensor.cumulus_chauffe_reelle
  last_changed: ...  # Vérifier l'historique
```

---

## 🎯 Résumé des bénéfices

Après installation de ce correctif :

| Avant | Après |
|-------|-------|
| ❌ Date manuelle à chaque install | ✅ Initialisation automatique |
| ❌ Risque d'erreur d'année | ✅ Validation automatique |
| ❌ Besoin urgent permanent si erreur | ✅ Correction automatique |
| ❌ Pas de mise à jour après chauffe | ✅ MAJ automatique à chaque cycle |
| ❌ Pas de monitoring | ✅ Logs + notifications |

---

## 📞 Support

### En cas de problème

1. Vérifiez les logs : Developer Tools → Logs
2. Vérifiez les états : Developer Tools → States
3. Testez le script de reset : `script.cumulus_reset_derniere_chauffe`
4. Consultez la documentation : [cumulus_fix_unavailable_2024-11-08.md](cumulus_fix_unavailable_2024-11-08.md)

### Fichiers de référence

- **Correctif :** [cumulus_fix_date_auto.yaml](../cumulus_fix_date_auto.yaml)
- **Diagnostic :** [diagnostic_besoin_urgent.yaml](../diagnostic_besoin_urgent.yaml)
- **Solutions :** [solutions_besoin_urgent.yaml](../solutions_besoin_urgent.yaml)

---

**Auteur :** Claude (Anthropic)
**Date :** 2025-10-25
**Version :** v2025-10-25-fix-date-auto
