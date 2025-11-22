# Guide de Style - Home Assistant Configuration

**Date:** 2025-11-22
**Version:** 1.0
**Projet:** LaurentFrx/Home_Assistant

---

## 📋 Table des Matières

1. [Formatage YAML](#formatage-yaml)
2. [Conventions de Nommage](#conventions-de-nommage)
3. [Headers de Fichiers](#headers-de-fichiers)
4. [Templates Jinja2](#templates-jinja2)
5. [Structure des Automations](#structure-des-automations)
6. [Documentation Inline](#documentation-inline)

---

## 📝 Formatage YAML

### Indentation

- **2 espaces UNIQUEMENT** (jamais de tabs)
- Indentation cohérente dans toute la hiérarchie

```yaml
# ✅ BON
automation:
  - id: mon_automation
    alias: "Mon Automation"
    trigger:
      - platform: state
        entity_id: sensor.example

# ❌ MAUVAIS (4 espaces)
automation:
    - id: mon_automation
```

### Strings

```yaml
# ✅ BON - Guillemets simples pour éviter échappements
name: 'Mon capteur'
state: '{{ states("sensor.example") }}'

# ❌ MAUVAIS - Double quotes nécessitent échappements
state: "{{ states(\"sensor.example\") }}"
```

### Templates Multi-lignes

```yaml
# ✅ BON - Utiliser '>' pour multi-lignes
value_template: >
  {% set aps = states('sensor.cumulus_production_aps_w') | float(0) %}
  {% set seuil = states('input_number.cumulus_seuil_pv_statique_w') | float(100) %}
  {{ aps >= seuil }}

# ❌ MAUVAIS - Espaces blancs excessifs
value_template: '


  {% set aps = states(''sensor.cumulus_production_aps_w'') | float(0) %}


  {{ aps >= seuil }}'
```

---

## 🏷️ Conventions de Nommage

### Entity IDs

**Format:** `module_description_unite`

```yaml
# Sensors de données brutes
sensor.cumulus_import_w
sensor.cumulus_soc_solarbank_pct
sensor.cumulus_temperature_estimee

# Binary sensors
binary_sensor.cumulus_fenetre_pv
binary_sensor.cumulus_chauffe_reelle

# Input helpers
input_number.cumulus_seuil_pv_on_w
input_boolean.cumulus_override
input_datetime.cumulus_plage_pv_debut
```

### Friendly Names

**Format:** Descriptif en français avec majuscules appropriées

```yaml
# ✅ BON
name: "Cumulus - Seuil PV statique"
name: "Cumulus - Température estimée"

# ❌ MAUVAIS
name: "seuil pv"  # Pas de majuscules
name: "CUMULUS_SEUIL_PV"  # Tout en majuscules
```

### Alias Automations

**Format:** `Module — Action descriptive`

```yaml
# ✅ BON
alias: "Cumulus — ON PV automatique"
alias: "Cumulus — Démarrage HC intelligent"

# ❌ MAUVAIS
alias: "cumulus on"
alias: "CUMULUS_ON_PV"
```

### IDs Automations

**Format:** `module_action_contexte`

```yaml
# ✅ BON
id: cumulus_demarrage_pv_intelligent
id: cumulus_limiteur_import_reseau
id: cumulus_alerte_besoin_urgent

# ❌ MAUVAIS
id: cumulus1
id: pv_start
```

---

## 📄 Headers de Fichiers

### Template Standard

```yaml
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ NOM DU MODULE                                                              ║
# ║ Description courte du module                                               ║
# ╚══════════════════════════════════════════════════════════════════════════╝
#
# Description détaillée du module et de ses fonctionnalités.
# Architecture et logique générale.
#
# Version: X.Y.Z
# Auteur: Nom
# Dernière mise à jour: YYYY-MM
#
# Dépendances:
#   - integration.xyz
#   - sensor.abc
#
# Configuration requise:
#   - input_number.exemple (via UI)
```

### Exemple Réel (core.yaml)

```yaml
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ CUMULUS INTELLIGENT - MODULE CORE                                          ║
# ║ Input helpers et configuration de base                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
#
# Ce module contient tous les paramètres configurables du système cumulus.
# Architecture 4 couches : Config → Sensors → Détecteurs → Contrôle
#
# Version: 2.0.0
# Auteur: Laurent
# Dernière mise à jour: 2024-11
```

### Sections dans le Fichier

```yaml
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ NOM DE LA SECTION                                                        │
# └─────────────────────────────────────────────────────────────────────────┘

# Ou pour des sous-sections:
# ════════════════════════════════════════════════════════════════════════════
# SECTION MAJEURE
# ════════════════════════════════════════════════════════════════════════════
```

---

## 🔧 Templates Jinja2

### Best Practices

```yaml
# ✅ BON - Variables nommées, defaults, logique claire
state: >
  {% set aps = states('sensor.cumulus_production_aps_w') | float(0) %}
  {% set seuil = states('input_number.cumulus_seuil_pv_statique_w') | float(100) %}
  {% set soc = states('sensor.cumulus_soc_solarbank_pct') | float(50) %}

  {% if soc > 80 %}
    {{ (seuil * 0.7) | round(0) }}
  {% elif soc > 50 %}
    {{ seuil | round(0) }}
  {% else %}
    {{ (seuil * 1.3) | round(0) }}
  {% endif %}

# ❌ MAUVAIS - Tout sur une ligne, pas de defaults
state: "{{ states('sensor.example') * 1.2 if states('sensor.other') > 50 else 0 }}"
```

### Gestion des Valeurs Manquantes

```yaml
# ✅ Toujours utiliser des defaults
{{ states('sensor.example') | float(0) }}
{{ states('sensor.example') | int(100) }}
{{ states('sensor.example') | default('unknown') }}

# Vérifier availability
{% if states('sensor.example') not in ['unknown', 'unavailable', 'none'] %}
  {{ states('sensor.example') }}
{% else %}
  0
{% endif %}
```

---

## 🤖 Structure des Automations

### Format Standard

```yaml
automation:
  - id: module_action_contexte
    alias: "Module — Action descriptive"
    description: "Courte description de ce que fait l'automation"
    mode: single  # ou restart, queued, parallel

    trigger:
      - platform: state
        entity_id: sensor.example
        id: trigger_name  # ID pour différencier dans les actions

    condition:
      - condition: state
        entity_id: input_boolean.enable
        state: 'on'

    action:
      - service: switch.turn_on
        target:
          entity_id: switch.example
```

### Commentaires Sections

```yaml
automation:
  # ┌─────────────────────────────────────────────────────────────────────────┐
  # │ DÉMARRAGE PV INTELLIGENT                                                │
  # └─────────────────────────────────────────────────────────────────────────┘
  - id: cumulus_demarrage_pv_intelligent
    alias: "Cumulus - Démarrage PV intelligent"

    trigger:
      # Trigger principal : puissance APS suffisante
      - platform: numeric_state
        entity_id: sensor.cumulus_production_aps_w
        above: input_number.cumulus_seuil_pv_statique_w
```

---

## 📝 Documentation Inline

### Commentaires Utiles

```yaml
# ✅ BON - Explique le "pourquoi"
# Démarrage progressif : 50% du seuil si >5h restantes
# pour maximiser le temps de chauffe disponible
cumulus_seuil_pv_dynamique_w:
  name: "Cumulus - Seuil PV dynamique"

# ❌ MAUVAIS - Répète le code
# Seuil PV dynamique
cumulus_seuil_pv_dynamique_w:
  name: "Cumulus - Seuil PV dynamique"
```

### Valeurs Magiques

```yaml
# ✅ BON - Explique les seuils/constantes
# Seuil de 85% pour détection chauffe (évite faux positifs)
# 3000W = puissance nominale cumulus
{% set seuil_detection = 0.85 %}
{% set puissance_max = 3000 %}

# ❌ MAUVAIS
{% set x = 0.85 %}
{% set y = 3000 %}
```

---

## 🚫 Anti-Patterns à Éviter

### 1. Renommage d'Entités Sans Prévenir

❌ **NE JAMAIS** renommer une entité sans demande explicite
❌ Les noms sont des identifiers techniques utilisés partout

### 2. Templates Trop Complexes

❌ Templates > 10 lignes → extraire en sensor helper
❌ Logique dupliquée → centraliser dans un sensor

### 3. Hardcoded Values

❌ Valeurs en dur dans automations → utiliser input_number
❌ Entity IDs en dur → utiliser input_text pour réutilisabilité

### 4. Automations Sans Protection

❌ Pas de condition anti-boucle
❌ Pas de mode défini (risque de boucles infinies)
❌ Pas de gestion des états unavailable

---

## ✅ Checklist Avant Commit

- [ ] Indentation 2 espaces partout
- [ ] Headers présents et complets
- [ ] Entity IDs respectent conventions
- [ ] Templates utilisent `>` pour multi-lignes
- [ ] Defaults sur tous les `| float()`, `| int()`
- [ ] Commentaires expliquent le "pourquoi"
- [ ] Pas de valeurs magiques non documentées
- [ ] Automations ont `mode:` défini
- [ ] YAML valide (`ha core check`)

---

## 📚 Références

- **CODE_STYLE_REVIEW.md** : Revue de style complète
- **CLAUDE_PREFERENCES.md** : Règles critiques Home Assistant
- **Home Assistant YAML Style Guide** : https://www.home-assistant.io/docs/configuration/yaml/

---

**Document créé le 2025-11-22**
**Basé sur l'audit complet du système cumulus**
