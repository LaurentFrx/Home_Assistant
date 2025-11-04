# Analyse des fichiers cumulus.yaml - Home Assistant

**Date d'analyse :** 2025-10-25
**Objectif :** Identifier les fichiers inutilisés et déterminer la cause du message "besoin urgent"

---

## 📊 Fichiers trouvés

### 1. `C:\Users\wakaw\Downloads\cumulus (1).yaml`
- **Lignes :** 655
- **Date modification :** 2024-10-24 20:30:48
- **Version :** Non identifiée (pas d'en-tête de version)
- **Première ligne :** `# 1) Démarrage PV automatique avec DOUBLE VÉRIFICATION appareils`
- **Contient `cumulus_besoin_chauffe_urgente` :** Non (seulement 1 référence, probablement dans un commentaire)
- **Type :** Fragment de code (commence par une automation, pas un package complet)
- **Statut :** ⚠️ **FICHIER INCOMPLET - À SUPPRIMER**

---

### 2. `C:\Users\wakaw\Downloads\cumulus.yaml`
- **Lignes :** 906
- **Date modification :** 2024-10-24 20:28:19
- **Version :** v2025-10-16a (PRODUCTION READY)
- **Première ligne :** `# CUMULUS — ROUTEUR SOLAIRE v2025-10-16a`
- **Contient `cumulus_besoin_chauffe_urgente` :** Oui (3 références + définition du sensor)
- **Type :** Package complet avec toutes les fonctionnalités avancées
- **Entités présentes :**
  - ✅ `sensor.cumulus_heures_depuis_derniere_chauffe`
  - ✅ `binary_sensor.cumulus_besoin_chauffe_urgente`
  - ✅ `input_datetime.cumulus_derniere_chauffe_complete`
  - ✅ Modèle thermique (Newton)
  - ✅ Prévisions Solcast
  - ✅ Gestion intelligente HC
- **Statut :** 📦 **VERSION PRODUCTION COMPLÈTE**

---

### 3. `C:\Users\wakaw\OneDrive\Documents\VSCode-HA-cumulus\homeassistant-cumulus\packages\cumulus.yaml`
- **Lignes :** 802
- **Date modification :** 2025-10-25 11:07:09 (AUJOURD'HUI - nos corrections)
- **Version :** v2025-11-08-fix-unavailable (CORRECTION CRITIQUE)
- **Première ligne :** `# CUMULUS - v2025-11-08-fix-unavailable`
- **Contient `cumulus_besoin_chauffe_urgente` :** Références uniquement (11 fois, mais pas de définition)
- **Type :** Version corrigée simplifiée (sans modèle thermique)
- **Entités présentes :**
  - ✅ `sensor.cumulus_consommation_reelle_w` (NOUVEAU - corrigé)
  - ✅ `binary_sensor.cumulus_chauffe_reelle` (CORRIGÉ)
  - ✅ `binary_sensor.cumulus_etat_coherent` (NOUVEAU)
  - ✅ `sensor.cumulus_debug_besoin_urgent` (DEBUG)
  - ✅ Automation fin chauffe universelle (NOUVEAU)
  - ❌ PAS de `sensor.cumulus_heures_depuis_derniere_chauffe`
  - ❌ PAS de `binary_sensor.cumulus_besoin_chauffe_urgente`
  - ❌ PAS de modèle thermique
- **Statut :** 🔧 **VERSION CORRIGÉE SIMPLIFIÉE**

---

## 🔍 Analyse du problème "besoin urgent"

### Scénario le plus probable :

**Votre Home Assistant utilise actuellement le fichier :**
`C:\Users\wakaw\Downloads\cumulus.yaml` (v2025-10-16a)

**Raison :** Ce fichier contient le sensor `binary_sensor.cumulus_besoin_chauffe_urgente` qui affiche "besoin urgent"

### Cause du message "besoin urgent" :

Le sensor `cumulus_besoin_chauffe_urgente` (ligne 830-835 du fichier Downloads) :

```yaml
- name: "cumulus_besoin_chauffe_urgente"
  unique_id: cumulus_besoin_chauffe_urgente
  state: >-
    {% set heures = states('sensor.cumulus_heures_depuis_derniere_chauffe') | float(0) %}
    {% set max_h = states('input_number.cumulus_espacement_max_h') | float(50) %}
    {{ heures >= max_h }}
```

**Logique :**
- Si `cumulus_heures_depuis_derniere_chauffe` >= `cumulus_espacement_max_h` (50h par défaut)
- Alors : **Besoin urgent = ON**

**Le sensor `cumulus_heures_depuis_derniere_chauffe` (ligne 505-515) :**

```yaml
- name: "cumulus_heures_depuis_derniere_chauffe"
  state: >-
    {% set last_ts = state_attr('input_datetime.cumulus_derniere_chauffe_complete', 'timestamp') %}
    {% if last_ts is none or last_ts == 0 %}
      999
    {% else %}
      {{ ((now().timestamp() - last_ts) / 3600) | round(1) }}
    {% endif %}
```

**Problème identifié :**
- Si `input_datetime.cumulus_derniere_chauffe_complete` n'a jamais été configuré → `last_ts = none`
- Le sensor retourne **999 heures**
- **999 >= 50 = TRUE** → **Besoin urgent affiché !**

---

## 🎯 Solutions proposées

### Option A : Utiliser la version production (Downloads) et corriger l'initialisation

**Avantages :**
- Toutes les fonctionnalités avancées (modèle thermique, Solcast, etc.)
- Gestion intelligente des heures creuses

**Actions requises :**
1. Initialiser `input_datetime.cumulus_derniere_chauffe_complete` :
   ```yaml
   service: input_datetime.set_datetime
   target:
     entity_id: input_datetime.cumulus_derniere_chauffe_complete
   data:
     datetime: "{{ now().strftime('%Y-%m-%d %H:%M:%S') }}"
   ```

2. Vérifier/configurer `input_number.cumulus_espacement_max_h` (défaut 50h)

3. Le message "besoin urgent" disparaîtra

**Fichiers à supprimer :**
- ❌ `C:\Users\wakaw\Downloads\cumulus (1).yaml` (fragment incomplet)
- ⚠️ `C:\Users\wakaw\OneDrive\Documents\VSCode-HA-cumulus\homeassistant-cumulus\packages\cumulus.yaml` (si non utilisé)

---

### Option B : Utiliser la version corrigée (OneDrive) sans besoin urgent

**Avantages :**
- `binary_sensor.cumulus_chauffe_reelle` corrigé (plus d'unavailable)
- Détection automatique fin de chauffe universelle
- Détection d'incohérences
- Pas de gestion "besoin urgent" (système simplifié)

**Actions requises :**
1. Remplacer le fichier dans votre config HA par :
   `C:\Users\wakaw\OneDrive\Documents\VSCode-HA-cumulus\homeassistant-cumulus\packages\cumulus.yaml`

2. Recharger la configuration HA

3. Le message "besoin urgent" disparaîtra (le sensor n'existe plus)

**Inconvénients :**
- ❌ Pas de modèle thermique de température
- ❌ Pas de gestion Solcast
- ❌ Pas de détection automatique besoin urgent

**Fichiers à supprimer :**
- ❌ `C:\Users\wakaw\Downloads\cumulus (1).yaml`
- ❌ `C:\Users\wakaw\Downloads\cumulus.yaml`

---

### Option C : Fusionner les deux versions (RECOMMANDÉ)

**Avantages :**
- Toutes les corrections de la version v2025-11-08
- Toutes les fonctionnalités de la version v2025-10-16a
- `binary_sensor.cumulus_chauffe_reelle` corrigé
- Modèle thermique fonctionnel
- Gestion intelligente besoin urgent

**Actions requises :**
1. Créer une nouvelle version fusionnée
2. Ajouter au fichier OneDrive :
   - `input_datetime.cumulus_derniere_chauffe_complete`
   - `input_number.cumulus_espacement_max_h`
   - `sensor.cumulus_heures_depuis_derniere_chauffe`
   - `binary_sensor.cumulus_besoin_chauffe_urgente`
   - Modèle thermique
   - Sensors Solcast

3. Initialiser les inputs

**Fichiers à supprimer après fusion :**
- ❌ `C:\Users\wakaw\Downloads\cumulus (1).yaml`
- ❌ `C:\Users\wakaw\Downloads\cumulus.yaml` (remplacé par la version fusionnée)

---

## 📋 Récapitulatif des fichiers

| Fichier | Lignes | Version | Statut | Action recommandée |
|---------|--------|---------|--------|-------------------|
| `Downloads/cumulus (1).yaml` | 655 | Inconnue | ❌ Incomplet | **SUPPRIMER** |
| `Downloads/cumulus.yaml` | 906 | v2025-10-16a | ⚠️ Probablement actif | Corriger OU remplacer |
| `OneDrive/.../cumulus.yaml` | 802 | v2025-11-08 | ✅ Corrigé | Activer OU fusionner |

---

## 🔧 Action immédiate pour résoudre "besoin urgent"

**Si vous utilisez `Downloads/cumulus.yaml` :**

Dans **Developer Tools → Services**, exécutez :

```yaml
service: input_datetime.set_datetime
target:
  entity_id: input_datetime.cumulus_derniere_chauffe_complete
data:
  datetime: "2024-10-25 03:30:00"
```

Cela indiquera que la dernière chauffe était cette nuit, donc le besoin urgent disparaîtra.

**Vérification :**
```yaml
# Dans Developer Tools → States
sensor.cumulus_heures_depuis_derniere_chauffe:
  # Devrait afficher un nombre < 50 (nombre d'heures depuis 03:30)

binary_sensor.cumulus_besoin_chauffe_urgente:
  state: off  # Devrait passer à OFF
```

---

## 📍 Localisation de votre config HA

**Question importante :** Où se trouve votre dossier de configuration Home Assistant ?

Les emplacements courants :
- `/config/` (Docker)
- `/home/homeassistant/.homeassistant/` (Home Assistant OS)
- `C:\Users\{user}\AppData\Roaming\homeassistant\` (Windows)
- `/usr/share/hassio/homeassistant/` (Supervised)

**Dans ce dossier, cherchez :**
- `packages/cumulus.yaml` ou
- `cumulus.yaml` directement

**Ce fichier est celui qui est RÉELLEMENT actif !**

---

## 🎯 Recommandation finale

1. **Immédiat** : Initialisez `input_datetime.cumulus_derniere_chauffe_complete` pour faire disparaître "besoin urgent"

2. **Court terme** : Identifiez quel fichier cumulus.yaml est chargé par HA

3. **Moyen terme** : Choisissez entre Option A, B ou C selon vos besoins

4. **Nettoyage** : Supprimez `cumulus (1).yaml` qui est un fragment inutile

---

**Besoin d'aide pour la fusion (Option C) ?** Je peux créer la version fusionnée complète pour vous !
