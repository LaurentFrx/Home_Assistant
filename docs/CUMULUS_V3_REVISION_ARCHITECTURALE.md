# 🏗️ CUMULUS INTELLIGENT V3 - RÉVISION ARCHITECTURALE COMPLÈTE

> **Document de référence** pour la refonte du système de gestion intelligente du chauffe-eau électrique  
> **Auteur** : Laurent / Claude  
> **Date** : Novembre 2025  
> **Statut** : Proposition de révision

---

## 📋 TABLE DES MATIÈRES

1. [Résumé Exécutif](#1-résumé-exécutif)
2. [Analyse Critique V2](#2-analyse-critique-v2)
3. [Architecture V3 Proposée](#3-architecture-v3-proposée)
4. [Spécifications Techniques](#4-spécifications-techniques)
5. [Dashboards](#5-dashboards)
6. [Plan de Migration](#6-plan-de-migration)
7. [Scripts Bash de Déploiement](#7-scripts-bash-de-déploiement)

---

## 1. RÉSUMÉ EXÉCUTIF

### 1.1 Contexte

Le système Cumulus Intelligent gère un chauffe-eau électrique Atlantic 3000W/300L vertical avec optimisation multi-sources :
- **Production PV** : Panneaux solaires via SolarBank + APS micro-inverters
- **Stockage batterie** : SolarBank avec monitoring SOC
- **Heures creuses** : Fallback tarification Linky
- **Contraintes confort** : Couple avec douches matinales

### 1.2 Leçons Apprises V2

| Aspect | Problème V2 | Solution V3 |
|--------|-------------|-------------|
| **Templates triggers** | Jinja2 interdit dans `for:` | Valeurs statiques + sensors calculés |
| **Stratification thermique** | Ignorée (15-30°C écart) | Modélisation multi-zones |
| **Complexité** | 40+ sensors, maintenance difficile | Architecture en couches stricte |
| **Tokens Claude** | 65k+ par session | Scripts bash auto-documentés |
| **UI famille** | Trop complexe | Dashboard ultra-simplifié dédié |

### 1.3 Objectifs V3

1. **Robustesse** : Zéro erreur YAML, gestion exhaustive des états unavailable/unknown
2. **Maintenabilité** : Découpage modulaire strict, documentation inline
3. **Économie tokens** : Scripts bash réutilisables, workflow 3 phases
4. **UX famille** : Dashboard 2 boutons, langage naturel
5. **Intelligence** : Modèle thermique réaliste, prédictions Solcast

---

## 2. ANALYSE CRITIQUE V2

### 2.1 Points Forts à Conserver

#### ✅ Architecture 4 couches
```
Couche 1 : Paramètres (input_number, input_boolean, input_select)
Couche 2 : Sensors (calculs, états dérivés, KPIs)
Couche 3 : Détecteurs d'état (binary_sensors conditions)
Couche 4 : Logique de contrôle (automations)
```

#### ✅ Stratégies d'optimisation multi-objectifs
- Économie maximale
- Confort prioritaire
- Préservation batterie
- Mode équilibré

#### ✅ Gestion priorités appareils
- Détection lave-linge/lave-vaisselle
- Arrêt cumulus si appareil prioritaire
- Redémarrage après fin appareil

### 2.2 Points Faibles à Corriger

#### ❌ Templates dans triggers `for:`
**Problème** : Home Assistant n'accepte pas Jinja2 dans la section `for:` des triggers numeric_state/state.

**V2 (incorrect)** :
```yaml
trigger:
  - platform: numeric_state
    entity_id: sensor.pv_surplus
    above: 100
    for: "{{ states('input_number.delai_stabilite') | int }}"  # ERREUR !
```

**V3 (corrigé)** :
```yaml
trigger:
  - platform: numeric_state
    entity_id: sensor.pv_surplus
    above: 100
    for: "00:03:00"  # Valeur statique

condition:
  - condition: template
    value_template: >
      {{ (now() - states.sensor.pv_surplus.last_changed).total_seconds() 
         >= (states('input_number.delai_stabilite') | int * 60) }}
```

#### ❌ Modèle thermique simpliste
**Problème** : Un seul sensor température ignore la stratification verticale (15-30°C d'écart bas/haut).

**V3** : Modèle multi-zones avec coefficients de mélange :
```yaml
sensor:
  - platform: template
    sensors:
      cumulus_temp_zone_basse:
        # Sonde physique (SNZB-02LD dans doigt de gant)
        value_template: "{{ states('sensor.snzb_02ld_cumulus_temperature') | float(15) }}"
        
      cumulus_temp_zone_haute_estimee:
        # Estimation basée sur stratification
        value_template: >
          {% set t_basse = states('sensor.cumulus_temp_zone_basse') | float(15) %}
          {% set en_chauffe = is_state('binary_sensor.cumulus_en_chauffe', 'on') %}
          {% set coef_strat = 1.25 if en_chauffe else 1.15 %}
          {{ (t_basse * coef_strat) | round(1) }}
```

#### ❌ Gestion états unavailable/unknown
**Problème** : Sensors en erreur provoquent comportements imprévisibles.

**V3** : Vérification systématique avec `availability_template` :
```yaml
sensor:
  - platform: template
    sensors:
      cumulus_puissance_safe:
        value_template: >
          {% set p = states('sensor.shelly_power') %}
          {% if p in ['unavailable', 'unknown', 'none'] %}
            0
          {% else %}
            {{ p | float(0) }}
          {% endif %}
        availability_template: >
          {{ states('sensor.shelly_power') not in ['unavailable', 'unknown'] }}
```

#### ❌ Complexité dashboard admin
**Problème** : Interface identique pour admin et famille.

**V3** : Deux dashboards strictement séparés :
- `lovelace_cumulus_famille.yaml` : 2 boutons max, langage naturel
- `lovelace_cumulus_admin.yaml` : Monitoring complet, debug, configuration

---

## 3. ARCHITECTURE V3 PROPOSÉE

### 3.1 Structure Fichiers

```
/config/packages/cumulus_v3/
├── 00_core.yaml           # Inputs, constantes, entités référencées
├── 10_sensors_physiques.yaml    # Sensors matériels (Shelly, SNZB, Linky)
├── 20_sensors_calcules.yaml     # Calculs dérivés, KPIs
├── 30_sensors_thermiques.yaml   # Modèle thermique multi-zones
├── 40_sensors_predictions.yaml  # Prédictions Solcast, ML
├── 50_binary_sensors.yaml       # Détecteurs d'état (conditions)
├── 60_automations_pv.yaml       # Logique solaire
├── 70_automations_hc.yaml       # Logique heures creuses
├── 80_automations_securite.yaml # Sécurités et fallbacks
├── 90_scripts.yaml              # Scripts HA réutilisables
└── 99_debug.yaml                # Sensors debug (désactivables)
```

### 3.2 Conventions de Nommage V3

#### Entités
```
# Pattern : cumulus_v3_{type}_{fonction}_{detail}

# Inputs
input_number.cumulus_v3_seuil_pv_min_w
input_boolean.cumulus_v3_mode_vacances
input_select.cumulus_v3_strategie

# Sensors
sensor.cumulus_v3_puissance_instantanee_w
sensor.cumulus_v3_temp_zone_basse_c
sensor.cumulus_v3_energie_jour_kwh

# Binary sensors
binary_sensor.cumulus_v3_surplus_pv_suffisant
binary_sensor.cumulus_v3_fenetre_hc_active

# Automations
automation.cumulus_v3_demarrage_pv_surplus
automation.cumulus_v3_arret_import_eleve
```

#### Commentaires YAML
```yaml
###############################################################################
# SECTION : [Nom de la section]
# Description : [Explication courte]
# Dépendances : [Entités requises]
# MAJ : [Date dernière modification]
###############################################################################
```

### 3.3 Diagramme Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           COUCHE 1 : PARAMÈTRES                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │input_number  │ │input_boolean │ │input_select  │ │input_datetime│    │
│  │seuils, délais│ │modes on/off  │ │stratégie     │ │fenêtres HC   │    │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        COUCHE 2 : SENSORS CALCULÉS                       │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐               │
│  │Physiques       │ │Thermiques      │ │Prédictifs      │               │
│  │- Puissance W   │ │- Temp zones    │ │- Solcast       │               │
│  │- Import/Export │ │- Stratification│ │- Estimation T° │               │
│  │- SOC batterie  │ │- Énergie stock │ │- Besoins J+1   │               │
│  └────────────────┘ └────────────────┘ └────────────────┘               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    COUCHE 3 : DÉTECTEURS D'ÉTAT                          │
│  ┌────────────────────┐ ┌────────────────────┐ ┌───────────────────┐    │
│  │Conditions PV       │ │Conditions HC       │ │Conditions Sécurité│    │
│  │- Surplus suffisant │ │- Fenêtre active    │ │- SOC minimum      │    │
│  │- Fenêtre horaire   │ │- Besoin chauffe HC │ │- Import max       │    │
│  │- Stabilité 3min    │ │- T° insuffisante   │ │- Appareil prio    │    │
│  └────────────────────┘ └────────────────────┘ └───────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     COUCHE 4 : LOGIQUE DE CONTRÔLE                       │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                        AUTOMATIONS                                  │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │ │
│  │  │PV            │ │Heures Creuses│ │Sécurité      │                │ │
│  │  │- Démarrage   │ │- Fallback HC │ │- Arrêt SOC   │                │ │
│  │  │- Arrêt import│ │- Fin HC      │ │- Arrêt import│                │ │
│  │  │- Arrêt app.  │ │- Espacement  │ │- Température │                │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌──────────────────┐
                        │ switch.shelly_   │
                        │ pro1_contacteur  │
                        └──────────────────┘
```

---

## 4. SPÉCIFICATIONS TECHNIQUES

### 4.1 Fichier 00_core.yaml

```yaml
###############################################################################
# CUMULUS V3 - CORE CONFIGURATION
# Description : Paramètres configurables via UI, constantes système
# Dépendances : Aucune (fichier racine)
# MAJ : 2025-11-24
###############################################################################

###############################################################################
# CONSTANTES SYSTÈME (ne pas modifier via UI)
###############################################################################
input_number:
  cumulus_v3_puissance_nominale_w:
    name: "Cumulus V3 - Puissance nominale (W)"
    min: 1000
    max: 4000
    step: 100
    initial: 3000
    unit_of_measurement: "W"
    icon: mdi:flash
    mode: box

  cumulus_v3_volume_litres:
    name: "Cumulus V3 - Volume (L)"
    min: 100
    max: 500
    step: 10
    initial: 300
    unit_of_measurement: "L"
    icon: mdi:water
    mode: box

###############################################################################
# SEUILS PV CONFIGURABLES
###############################################################################
  cumulus_v3_seuil_pv_min_w:
    name: "Cumulus V3 - Seuil PV minimum (W)"
    min: 0
    max: 500
    step: 10
    initial: 100
    unit_of_measurement: "W"
    icon: mdi:solar-power

  cumulus_v3_seuil_pv_progressif_w:
    name: "Cumulus V3 - Seuil PV progressif (W)"
    min: 0
    max: 300
    step: 10
    initial: 50
    unit_of_measurement: "W"
    icon: mdi:solar-power-variant

  cumulus_v3_import_max_autorise_w:
    name: "Cumulus V3 - Import max autorisé (W)"
    min: 0
    max: 1000
    step: 50
    initial: 500
    unit_of_measurement: "W"
    icon: mdi:transmission-tower-import

###############################################################################
# SEUILS THERMIQUES
###############################################################################
  cumulus_v3_temp_cible_pv_c:
    name: "Cumulus V3 - Température cible PV (°C)"
    min: 45
    max: 65
    step: 1
    initial: 60
    unit_of_measurement: "°C"
    icon: mdi:thermometer-high

  cumulus_v3_temp_cible_hc_c:
    name: "Cumulus V3 - Température cible HC (°C)"
    min: 45
    max: 65
    step: 1
    initial: 55
    unit_of_measurement: "°C"
    icon: mdi:thermometer

  cumulus_v3_temp_minimum_confort_c:
    name: "Cumulus V3 - Température minimum confort (°C)"
    min: 35
    max: 50
    step: 1
    initial: 45
    unit_of_measurement: "°C"
    icon: mdi:thermometer-low

  cumulus_v3_temp_critique_c:
    name: "Cumulus V3 - Température critique (°C)"
    min: 30
    max: 45
    step: 1
    initial: 38
    unit_of_measurement: "°C"
    icon: mdi:thermometer-alert

###############################################################################
# SEUILS BATTERIE
###############################################################################
  cumulus_v3_soc_minimum_pct:
    name: "Cumulus V3 - SOC minimum (%)"
    min: 0
    max: 50
    step: 5
    initial: 10
    unit_of_measurement: "%"
    icon: mdi:battery-low

  cumulus_v3_soc_confort_pct:
    name: "Cumulus V3 - SOC confort (%)"
    min: 20
    max: 80
    step: 5
    initial: 30
    unit_of_measurement: "%"
    icon: mdi:battery-medium

###############################################################################
# DÉLAIS (valeurs statiques pour triggers)
###############################################################################
  cumulus_v3_delai_stabilite_min:
    name: "Cumulus V3 - Délai stabilité PV (min)"
    min: 1
    max: 10
    step: 1
    initial: 3
    unit_of_measurement: "min"
    icon: mdi:timer-sand

  cumulus_v3_delai_avant_arret_min:
    name: "Cumulus V3 - Délai avant arrêt (min)"
    min: 1
    max: 5
    step: 1
    initial: 2
    unit_of_measurement: "min"
    icon: mdi:timer-off

  cumulus_v3_espacement_chauffes_h:
    name: "Cumulus V3 - Espacement minimum chauffes (h)"
    min: 12
    max: 72
    step: 4
    initial: 36
    unit_of_measurement: "h"
    icon: mdi:calendar-clock

###############################################################################
# FENÊTRES HORAIRES
###############################################################################
input_datetime:
  cumulus_v3_fenetre_pv_debut:
    name: "Cumulus V3 - Fenêtre PV début"
    has_date: false
    has_time: true
    initial: "09:00:00"
    icon: mdi:weather-sunny

  cumulus_v3_fenetre_pv_fin:
    name: "Cumulus V3 - Fenêtre PV fin"
    has_date: false
    has_time: true
    initial: "17:00:00"
    icon: mdi:weather-sunset

  cumulus_v3_fenetre_hc_debut:
    name: "Cumulus V3 - Fenêtre HC début"
    has_date: false
    has_time: true
    initial: "02:30:00"
    icon: mdi:moon-waning-crescent

  cumulus_v3_fenetre_hc_fin:
    name: "Cumulus V3 - Fenêtre HC fin"
    has_date: false
    has_time: true
    initial: "06:30:00"
    icon: mdi:moon-first-quarter

###############################################################################
# MODES ET OPTIONS
###############################################################################
input_boolean:
  cumulus_v3_mode_vacances:
    name: "Cumulus V3 - Mode vacances"
    icon: mdi:beach

  cumulus_v3_autoriser_hc:
    name: "Cumulus V3 - Autoriser heures creuses"
    initial: true
    icon: mdi:clock-check

  cumulus_v3_mode_force:
    name: "Cumulus V3 - Mode forcé"
    icon: mdi:fire

  cumulus_v3_debug_actif:
    name: "Cumulus V3 - Mode debug"
    initial: false
    icon: mdi:bug

###############################################################################
# STRATÉGIE D'OPTIMISATION
###############################################################################
input_select:
  cumulus_v3_strategie:
    name: "Cumulus V3 - Stratégie"
    options:
      - "Économie maximale"
      - "Confort prioritaire"
      - "Préserver batterie"
      - "Mode équilibré"
    initial: "Mode équilibré"
    icon: mdi:strategy

###############################################################################
# COMPTEURS ET STATISTIQUES
###############################################################################
counter:
  cumulus_v3_nb_chauffes_pv:
    name: "Cumulus V3 - Nombre chauffes PV"
    initial: 0
    step: 1
    icon: mdi:counter

  cumulus_v3_nb_chauffes_hc:
    name: "Cumulus V3 - Nombre chauffes HC"
    initial: 0
    step: 1
    icon: mdi:counter

###############################################################################
# TIMERS
###############################################################################
timer:
  cumulus_v3_deadband:
    name: "Cumulus V3 - Deadband après arrêt"
    duration: "00:05:00"
    icon: mdi:timer-pause

  cumulus_v3_duree_chauffe_max:
    name: "Cumulus V3 - Durée chauffe maximale"
    duration: "02:30:00"
    icon: mdi:timer-alert
```

### 4.2 Fichier 30_sensors_thermiques.yaml

```yaml
###############################################################################
# CUMULUS V3 - MODÈLE THERMIQUE MULTI-ZONES
# Description : Gestion stratification, estimation température, énergie stockée
# Dépendances : 00_core.yaml, 10_sensors_physiques.yaml
# MAJ : 2025-11-24
###############################################################################

###############################################################################
# TEMPÉRATURES MULTI-ZONES
###############################################################################
template:
  - sensor:
      ###########################################################################
      # Zone basse - Sonde physique SNZB-02LD
      ###########################################################################
      - name: "Cumulus V3 - Température zone basse"
        unique_id: cumulus_v3_temp_zone_basse
        device_class: temperature
        state_class: measurement
        unit_of_measurement: "°C"
        icon: mdi:thermometer-low
        availability: >
          {{ states('sensor.snzb_02ld_cumulus_temperature') 
             not in ['unavailable', 'unknown', 'none'] }}
        state: >
          {% set temp_raw = states('sensor.snzb_02ld_cumulus_temperature') | float(none) %}
          {% if temp_raw is none %}
            {{ state_attr('sensor.cumulus_v3_temp_zone_basse', 'state') | float(20) }}
          {% else %}
            {# Calibration sonde : ajuster selon écart mesuré #}
            {% set calibration = 0 %}
            {{ (temp_raw + calibration) | round(1) }}
          {% endif %}

      ###########################################################################
      # Zone haute - Estimation par stratification
      ###########################################################################
      - name: "Cumulus V3 - Température zone haute (estimée)"
        unique_id: cumulus_v3_temp_zone_haute
        device_class: temperature
        state_class: measurement
        unit_of_measurement: "°C"
        icon: mdi:thermometer-high
        state: >
          {% set t_basse = states('sensor.cumulus_v3_temp_zone_basse') | float(20) %}
          {% set en_chauffe = is_state('binary_sensor.cumulus_v3_en_chauffe', 'on') %}
          {% set duree_chauffe_min = states('sensor.cumulus_v3_duree_chauffe_min') | float(0) %}
          
          {# Coefficient de stratification dynamique #}
          {# Plus élevé pendant chauffe (eau chaude monte) #}
          {% if en_chauffe %}
            {# Stratification progressive avec durée chauffe #}
            {% set coef_base = 1.15 %}
            {% set coef_max = 1.35 %}
            {% set progression = min(duree_chauffe_min / 60, 1) %}
            {% set coef = coef_base + (coef_max - coef_base) * progression %}
          {% else %}
            {# Homogénéisation progressive après arrêt #}
            {% set derniere_chauffe = as_timestamp(states.binary_sensor.cumulus_v3_en_chauffe.last_changed) | default(0) %}
            {% set depuis_arret_h = (as_timestamp(now()) - derniere_chauffe) / 3600 %}
            {% set coef = max(1.05, 1.20 - (depuis_arret_h * 0.03)) %}
          {% endif %}
          
          {{ (t_basse * coef) | round(1) }}

      ###########################################################################
      # Température moyenne pondérée (pour décisions)
      ###########################################################################
      - name: "Cumulus V3 - Température moyenne"
        unique_id: cumulus_v3_temp_moyenne
        device_class: temperature
        state_class: measurement
        unit_of_measurement: "°C"
        icon: mdi:thermometer
        state: >
          {% set t_basse = states('sensor.cumulus_v3_temp_zone_basse') | float(20) %}
          {% set t_haute = states('sensor.cumulus_v3_temp_zone_haute') | float(25) %}
          {# Pondération : zone haute représente ~40% du volume utilisable #}
          {{ ((t_basse * 0.6) + (t_haute * 0.4)) | round(1) }}

      ###########################################################################
      # Température de soutirage (eau disponible en sortie)
      ###########################################################################
      - name: "Cumulus V3 - Température soutirage"
        unique_id: cumulus_v3_temp_soutirage
        device_class: temperature
        state_class: measurement
        unit_of_measurement: "°C"
        icon: mdi:water-thermometer
        state: >
          {# L'eau sort par le haut, donc température zone haute #}
          {{ states('sensor.cumulus_v3_temp_zone_haute') | float(20) }}

###############################################################################
# ÉNERGIE THERMIQUE STOCKÉE
###############################################################################
  - sensor:
      - name: "Cumulus V3 - Énergie stockée"
        unique_id: cumulus_v3_energie_stockee_kwh
        device_class: energy
        state_class: measurement
        unit_of_measurement: "kWh"
        icon: mdi:lightning-bolt
        state: >
          {# E = m × Cp × ΔT #}
          {# Cp eau = 4186 J/(kg·K) = 1.163 Wh/(kg·K) #}
          {% set volume = states('input_number.cumulus_v3_volume_litres') | float(300) %}
          {% set t_moy = states('sensor.cumulus_v3_temp_moyenne') | float(20) %}
          {% set t_ref = 15 %}  {# Température eau froide entrée #}
          {% set cp_wh = 1.163 / 1000 %}  {# kWh/(L·K) #}
          {{ (volume * cp_wh * (t_moy - t_ref)) | round(2) }}

      - name: "Cumulus V3 - Énergie disponible"
        unique_id: cumulus_v3_energie_disponible_kwh
        device_class: energy
        state_class: measurement
        unit_of_measurement: "kWh"
        icon: mdi:lightning-bolt-outline
        state: >
          {# Énergie utilisable au-dessus de la température minimum confort #}
          {% set volume = states('input_number.cumulus_v3_volume_litres') | float(300) %}
          {% set t_moy = states('sensor.cumulus_v3_temp_moyenne') | float(20) %}
          {% set t_min = states('input_number.cumulus_v3_temp_minimum_confort_c') | float(45) %}
          {% set cp_wh = 1.163 / 1000 %}
          {% set delta_t = max(0, t_moy - t_min) %}
          {{ (volume * cp_wh * delta_t) | round(2) }}

###############################################################################
# AUTONOMIE ET PRÉDICTIONS
###############################################################################
  - sensor:
      - name: "Cumulus V3 - Douches disponibles"
        unique_id: cumulus_v3_douches_disponibles
        state_class: measurement
        unit_of_measurement: "douches"
        icon: mdi:shower-head
        state: >
          {# Hypothèse : 1 douche = 40L à 38°C, eau froide 15°C #}
          {# Volume eau chaude par douche ≈ 25L à 55°C #}
          {% set energie_dispo = states('sensor.cumulus_v3_energie_disponible_kwh') | float(0) %}
          {% set energie_douche = 1.0 %}  {# kWh par douche environ #}
          {{ (energie_dispo / energie_douche) | int }}

      - name: "Cumulus V3 - Autonomie heures"
        unique_id: cumulus_v3_autonomie_heures
        state_class: measurement
        unit_of_measurement: "h"
        icon: mdi:clock-outline
        state: >
          {# Estimation basée sur refroidissement naturel #}
          {% set t_moy = states('sensor.cumulus_v3_temp_moyenne') | float(20) %}
          {% set t_min = states('input_number.cumulus_v3_temp_minimum_confort_c') | float(45) %}
          {% set t_amb = 20 %}  {# Température ambiante #}
          {% set tau = 72 %}  {# Constante de temps refroidissement (heures) #}
          {% if t_moy <= t_min %}
            0
          {% else %}
            {# t(h) = t_amb + (t0 - t_amb) × e^(-h/tau) #}
            {# Résoudre pour h quand t(h) = t_min #}
            {% set ratio = (t_min - t_amb) / (t_moy - t_amb) %}
            {% if ratio > 0 and ratio < 1 %}
              {{ (-tau * log(ratio)) | round(0) }}
            {% else %}
              72
            {% endif %}
          {% endif %}

###############################################################################
# REFROIDISSEMENT - MODÈLE PRÉDICTIF
###############################################################################
  - sensor:
      - name: "Cumulus V3 - Température dans 6h"
        unique_id: cumulus_v3_temp_prediction_6h
        device_class: temperature
        state_class: measurement
        unit_of_measurement: "°C"
        icon: mdi:thermometer-chevron-down
        state: >
          {% set t_moy = states('sensor.cumulus_v3_temp_moyenne') | float(20) %}
          {% set t_amb = 20 %}
          {% set tau = 72 %}  {# Constante de temps en heures #}
          {% set h = 6 %}
          {{ (t_amb + (t_moy - t_amb) * (2.718281828 ** (-h/tau))) | round(1) }}

      - name: "Cumulus V3 - Température demain matin"
        unique_id: cumulus_v3_temp_prediction_demain
        device_class: temperature
        state_class: measurement
        unit_of_measurement: "°C"
        icon: mdi:thermometer-chevron-down
        state: >
          {# Prédiction pour 7h demain #}
          {% set t_moy = states('sensor.cumulus_v3_temp_moyenne') | float(20) %}
          {% set t_amb = 20 %}
          {% set tau = 72 %}
          {% set maintenant = now().hour + now().minute/60 %}
          {% set h_jusque_demain_7h = (24 - maintenant) + 7 %}
          {{ (t_amb + (t_moy - t_amb) * (2.718281828 ** (-h_jusque_demain_7h/tau))) | round(1) }}
```

### 4.3 Fichier 50_binary_sensors.yaml

```yaml
###############################################################################
# CUMULUS V3 - DÉTECTEURS D'ÉTAT (CONDITIONS)
# Description : Binary sensors pour conditions des automations
# Dépendances : 00_core.yaml, 10-40_sensors
# MAJ : 2025-11-24
###############################################################################

template:
  - binary_sensor:
      ###########################################################################
      # ÉTAT PHYSIQUE CUMULUS
      ###########################################################################
      - name: "Cumulus V3 - En chauffe"
        unique_id: cumulus_v3_en_chauffe
        device_class: heat
        icon: mdi:fire
        state: >
          {% set puissance = states('sensor.shelly_pro1_power') | float(0) %}
          {% set switch_on = is_state('switch.shellypro1_ece334ee1b64', 'on') %}
          {{ switch_on and puissance > 100 }}
        availability: >
          {{ states('sensor.shelly_pro1_power') not in ['unavailable', 'unknown'] }}

      ###########################################################################
      # CONDITIONS PV
      ###########################################################################
      - name: "Cumulus V3 - Fenêtre PV active"
        unique_id: cumulus_v3_fenetre_pv_active
        icon: mdi:weather-sunny
        state: >
          {% set debut = states('input_datetime.cumulus_v3_fenetre_pv_debut') %}
          {% set fin = states('input_datetime.cumulus_v3_fenetre_pv_fin') %}
          {% set maintenant = now().strftime('%H:%M:%S') %}
          {{ debut <= maintenant <= fin }}

      - name: "Cumulus V3 - Surplus PV suffisant"
        unique_id: cumulus_v3_surplus_pv_suffisant
        icon: mdi:solar-power
        state: >
          {% set surplus = states('sensor.cumulus_v3_surplus_pv_w') | float(0) %}
          {% set seuil = states('input_number.cumulus_v3_seuil_pv_min_w') | float(100) %}
          {% set soc = states('sensor.solarbank_soc') | float(0) %}
          {% set soc_min = states('input_number.cumulus_v3_soc_minimum_pct') | float(10) %}
          {{ surplus >= seuil and soc >= soc_min }}

      - name: "Cumulus V3 - Surplus PV stable"
        unique_id: cumulus_v3_surplus_pv_stable
        icon: mdi:sine-wave
        delay_on: "00:03:00"  # Stabilité 3 minutes
        state: >
          {{ is_state('binary_sensor.cumulus_v3_surplus_pv_suffisant', 'on') }}

      - name: "Cumulus V3 - Conditions PV réunies"
        unique_id: cumulus_v3_conditions_pv_reunies
        icon: mdi:check-all
        state: >
          {% set fenetre = is_state('binary_sensor.cumulus_v3_fenetre_pv_active', 'on') %}
          {% set surplus = is_state('binary_sensor.cumulus_v3_surplus_pv_stable', 'on') %}
          {% set pas_vacances = is_state('input_boolean.cumulus_v3_mode_vacances', 'off') %}
          {% set temp_ok = states('sensor.cumulus_v3_temp_moyenne') | float(60) 
                          < states('input_number.cumulus_v3_temp_cible_pv_c') | float(60) %}
          {{ fenetre and surplus and pas_vacances and temp_ok }}

      ###########################################################################
      # CONDITIONS HEURES CREUSES
      ###########################################################################
      - name: "Cumulus V3 - Fenêtre HC active"
        unique_id: cumulus_v3_fenetre_hc_active
        icon: mdi:moon-waning-crescent
        state: >
          {% set debut = states('input_datetime.cumulus_v3_fenetre_hc_debut') %}
          {% set fin = states('input_datetime.cumulus_v3_fenetre_hc_fin') %}
          {% set maintenant = now().strftime('%H:%M:%S') %}
          {# Gestion fenêtre à cheval sur minuit #}
          {% if debut > fin %}
            {{ maintenant >= debut or maintenant <= fin }}
          {% else %}
            {{ debut <= maintenant <= fin }}
          {% endif %}

      - name: "Cumulus V3 - Besoin chauffe HC"
        unique_id: cumulus_v3_besoin_chauffe_hc
        icon: mdi:water-thermometer-outline
        state: >
          {% set temp_pred = states('sensor.cumulus_v3_temp_prediction_demain') | float(50) %}
          {% set temp_min = states('input_number.cumulus_v3_temp_minimum_confort_c') | float(45) %}
          {% set solcast_demain = states('sensor.solcast_pv_forecast_previsions_pour_demain') | float(0) %}
          {% set seuil_solcast = 8 %}  {# kWh prévu demain #}
          {# Chauffe HC si : température prédite insuffisante ET peu de soleil prévu #}
          {{ temp_pred < temp_min and solcast_demain < seuil_solcast }}

      - name: "Cumulus V3 - Conditions HC réunies"
        unique_id: cumulus_v3_conditions_hc_reunies
        icon: mdi:check-all
        state: >
          {% set fenetre = is_state('binary_sensor.cumulus_v3_fenetre_hc_active', 'on') %}
          {% set besoin = is_state('binary_sensor.cumulus_v3_besoin_chauffe_hc', 'on') %}
          {% set autorise = is_state('input_boolean.cumulus_v3_autoriser_hc', 'on') %}
          {% set pas_vacances = is_state('input_boolean.cumulus_v3_mode_vacances', 'off') %}
          {{ fenetre and besoin and autorise and pas_vacances }}

      ###########################################################################
      # CONDITIONS SÉCURITÉ
      ###########################################################################
      - name: "Cumulus V3 - Import trop élevé"
        unique_id: cumulus_v3_import_trop_eleve
        device_class: problem
        icon: mdi:transmission-tower-import
        delay_on: "00:00:30"  # Anti-rebond 30s
        state: >
          {% set import_w = states('sensor.smart_meter_grid_import') | float(0) %}
          {% set seuil = states('input_number.cumulus_v3_import_max_autorise_w') | float(500) %}
          {% set en_chauffe = is_state('binary_sensor.cumulus_v3_en_chauffe', 'on') %}
          {{ en_chauffe and import_w > seuil }}

      - name: "Cumulus V3 - SOC critique"
        unique_id: cumulus_v3_soc_critique
        device_class: problem
        icon: mdi:battery-alert
        state: >
          {% set soc = states('sensor.solarbank_soc') | float(100) %}
          {% set seuil = states('input_number.cumulus_v3_soc_minimum_pct') | float(10) %}
          {{ soc < seuil }}

      - name: "Cumulus V3 - Température critique"
        unique_id: cumulus_v3_temp_critique
        device_class: cold
        icon: mdi:snowflake-alert
        state: >
          {% set temp = states('sensor.cumulus_v3_temp_moyenne') | float(50) %}
          {% set seuil = states('input_number.cumulus_v3_temp_critique_c') | float(38) %}
          {{ temp < seuil }}

      - name: "Cumulus V3 - Appareil prioritaire actif"
        unique_id: cumulus_v3_appareil_prioritaire_actif
        icon: mdi:washing-machine
        state: >
          {% set lave_linge = states('sensor.lave_linge_power') | float(0) > 50 %}
          {% set lave_vaisselle = states('sensor.lave_vaisselle_power') | float(0) > 50 %}
          {{ lave_linge or lave_vaisselle }}

      ###########################################################################
      # ÉTAT GLOBAL SYSTÈME
      ###########################################################################
      - name: "Cumulus V3 - Système OK"
        unique_id: cumulus_v3_systeme_ok
        device_class: running
        icon: mdi:check-circle
        state: >
          {% set shelly_ok = states('switch.shellypro1_ece334ee1b64') not in ['unavailable', 'unknown'] %}
          {% set sonde_ok = states('sensor.snzb_02ld_cumulus_temperature') not in ['unavailable', 'unknown'] %}
          {% set linky_ok = states('sensor.smart_meter_grid_import') not in ['unavailable', 'unknown'] %}
          {{ shelly_ok and sonde_ok and linky_ok }}
```

---

## 5. DASHBOARDS

### 5.1 Dashboard Famille (Ultra-Simple)

```yaml
###############################################################################
# CUMULUS V3 - DASHBOARD FAMILLE
# Description : Interface 2 boutons, langage naturel, mobile-first
# Usage : /config/lovelace/cumulus_v3_famille.yaml
###############################################################################

title: "💧 Eau Chaude"
path: cumulus-famille

type: custom:vertical-stack-in-card
cards:
  # ═══════════════════════════════════════════════════════════════════════════
  # CARTE PRINCIPALE - ÉTAT EN LANGAGE NATUREL
  # ═══════════════════════════════════════════════════════════════════════════
  - type: markdown
    content: >
      {% set douches = states('sensor.cumulus_v3_douches_disponibles') | int(0) %}
      {% set temp = states('sensor.cumulus_v3_temp_soutirage') | float(20) %}
      {% set en_chauffe = is_state('binary_sensor.cumulus_v3_en_chauffe', 'on') %}
      {% set vacances = is_state('input_boolean.cumulus_v3_mode_vacances', 'on') %}
      
      {% if vacances %}
      ## 🏖️ Mode vacances activé
      L'eau n'est pas chauffée.
      {% elif en_chauffe %}
      ## 🔥 Chauffe en cours...
      Encore quelques minutes !
      {% elif douches >= 3 %}
      ## ✅ Parfait pour toute la famille
      {{ douches }} douches disponibles · {{ temp | round(0) }}°C
      {% elif douches >= 2 %}
      ## ✅ OK pour 2 douches
      {{ temp | round(0) }}°C · Prochaine chauffe bientôt
      {% elif douches >= 1 %}
      ## ⚠️ Juste une douche
      Évitez les bains · {{ temp | round(0) }}°C
      {% else %}
      ## ❌ C'est froid !
      Lancer une chauffe forcée ?
      {% endif %}
    card_mod:
      style: |
        ha-card {
          background: {% if is_state('binary_sensor.cumulus_v3_temp_critique', 'on') %}
                        linear-gradient(135deg, #ff6b6b 0%, #ee5a5a 100%)
                      {% elif states('sensor.cumulus_v3_douches_disponibles') | int < 2 %}
                        linear-gradient(135deg, #ffa726 0%, #fb8c00 100%)
                      {% else %}
                        linear-gradient(135deg, #66bb6a 0%, #43a047 100%)
                      {% endif %};
          color: white;
          padding: 20px;
          border-radius: 16px;
        }

  # ═══════════════════════════════════════════════════════════════════════════
  # PROCHAINE CHAUFFE PRÉVUE
  # ═══════════════════════════════════════════════════════════════════════════
  - type: markdown
    content: >
      {% set solcast = states('sensor.solcast_pv_forecast_previsions_pour_demain') | float(0) %}
      {% set temp_pred = states('sensor.cumulus_v3_temp_prediction_demain') | float(50) %}
      {% set heure_pv_debut = states('input_datetime.cumulus_v3_fenetre_pv_debut')[:5] %}
      
      {% if solcast > 10 %}
      🔮 **Demain ~{{ heure_pv_debut }}** avec le soleil ☀️
      {% elif solcast > 5 %}
      🔮 **Demain** si le soleil le permet
      {% else %}
      🔮 **Cette nuit** en heures creuses 🌙
      {% endif %}

  # ═══════════════════════════════════════════════════════════════════════════
  # 2 BOUTONS SEULEMENT
  # ═══════════════════════════════════════════════════════════════════════════
  - type: horizontal-stack
    cards:
      - type: button
        name: "🔥 Forcer chauffe"
        icon: mdi:fire
        tap_action:
          action: call-service
          service: input_boolean.turn_on
          target:
            entity_id: input_boolean.cumulus_v3_mode_force
        hold_action:
          action: more-info
          entity: input_boolean.cumulus_v3_mode_force
        card_mod:
          style: |
            ha-card {
              background: linear-gradient(135deg, #ff7043 0%, #f4511e 100%);
              color: white;
              min-height: 80px;
              border-radius: 12px;
            }

      - type: button
        name: "🏖️ Vacances"
        icon: mdi:beach
        tap_action:
          action: toggle
        entity: input_boolean.cumulus_v3_mode_vacances
        card_mod:
          style: |
            ha-card {
              background: {% if is_state('input_boolean.cumulus_v3_mode_vacances', 'on') %}
                            linear-gradient(135deg, #42a5f5 0%, #1e88e5 100%)
                          {% else %}
                            linear-gradient(135deg, #78909c 0%, #546e7a 100%)
                          {% endif %};
              color: white;
              min-height: 80px;
              border-radius: 12px;
            }
```

### 5.2 Dashboard Admin (Complet)

Structure recommandée en onglets :
1. **Monitoring** : Graphiques temps réel, KPIs
2. **Thermique** : Températures zones, énergie stockée, prédictions
3. **Automations** : États, historique déclenchements
4. **Configuration** : Tous les input_* modifiables
5. **Debug** : Sensors bruts, logs, diagnostics

---

## 6. PLAN DE MIGRATION V2 → V3

### 6.1 Pré-requis

- [ ] Backup complet `/config`
- [ ] Identifier entités V2 utilisées ailleurs (dashboards, automations externes)
- [ ] Vérifier compatibilité sonde SNZB-02LD

### 6.2 Phases Migration

| Phase | Action | Durée | Risque |
|-------|--------|-------|--------|
| 1 | Créer structure `/config/packages/cumulus_v3/` | 10 min | Nul |
| 2 | Déployer 00_core.yaml (nouveaux inputs) | 5 min | Nul |
| 3 | Déployer sensors (coexistence V2/V3) | 15 min | Faible |
| 4 | Déployer binary_sensors | 10 min | Faible |
| 5 | **Basculer automations** (désactiver V2, activer V3) | 20 min | Moyen |
| 6 | Tester pendant 24-48h | 48h | - |
| 7 | Supprimer V2 si OK | 10 min | Faible |

### 6.3 Rollback

```bash
# En cas de problème, réactiver V2 :
ha core reload
# Puis désactiver manuellement les automations V3 dans l'UI
```

---

## 7. SCRIPTS BASH DE DÉPLOIEMENT

### 7.1 Script Principal : deploy_cumulus_v3.sh

```bash
#!/bin/bash
#==============================================================================
# CUMULUS V3 - SCRIPT DE DÉPLOIEMENT
# Description : Déploie l'architecture V3 complète
# Usage : ./deploy_cumulus_v3.sh [--dry-run] [--backup] [--force]
# Auteur : Laurent
# Date : 2025-11-24
#==============================================================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONFIG_DIR="/config"
PACKAGES_DIR="${CONFIG_DIR}/packages"
V3_DIR="${PACKAGES_DIR}/cumulus_v3"
BACKUP_DIR="${CONFIG_DIR}/backups/cumulus_v3_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${CONFIG_DIR}/logs/deploy_cumulus_v3_$(date +%Y%m%d_%H%M%S).log"
REPO_URL="https://raw.githubusercontent.com/LaurentFrx/Home_Assistant/main"

# Options
DRY_RUN=false
DO_BACKUP=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --backup) DO_BACKUP=true ;;
        --force) FORCE=true ;;
        *) echo "Option inconnue: $1"; exit 1 ;;
    esac
    shift
done

# Fonctions
log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

# Créer dossier logs si nécessaire
mkdir -p "$(dirname "$LOG_FILE")"

log "═══════════════════════════════════════════════════════════════"
log "       CUMULUS V3 - DÉPLOIEMENT"
log "═══════════════════════════════════════════════════════════════"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'PRODUCTION')"

#==============================================================================
# PHASE 1 : VÉRIFICATIONS
#==============================================================================
log ""
log "📋 PHASE 1 : Vérifications préalables"

# Vérifier qu'on est bien sur le serveur HA
if [ ! -d "$CONFIG_DIR" ]; then
    error "Répertoire $CONFIG_DIR introuvable. Êtes-vous sur le serveur HA ?"
fi

# Vérifier que la V2 existe (pour migration)
if [ -f "${PACKAGES_DIR}/cumulus.yaml" ]; then
    success "Package V2 détecté : ${PACKAGES_DIR}/cumulus.yaml"
    V2_EXISTS=true
else
    warn "Package V2 non trouvé - installation fraîche"
    V2_EXISTS=false
fi

# Vérifier si V3 existe déjà
if [ -d "$V3_DIR" ] && [ "$FORCE" = false ]; then
    error "Dossier V3 existe déjà. Utilisez --force pour écraser."
fi

success "Vérifications OK"

#==============================================================================
# PHASE 2 : BACKUP
#==============================================================================
if [ "$DO_BACKUP" = true ]; then
    log ""
    log "💾 PHASE 2 : Backup"
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR"
        
        # Backup V2 si existe
        if [ "$V2_EXISTS" = true ]; then
            cp "${PACKAGES_DIR}/cumulus.yaml" "${BACKUP_DIR}/" 2>/dev/null || true
        fi
        
        # Backup V3 si existe
        if [ -d "$V3_DIR" ]; then
            cp -r "$V3_DIR" "${BACKUP_DIR}/cumulus_v3_old/" 2>/dev/null || true
        fi
        
        success "Backup créé : $BACKUP_DIR"
    else
        log "  [DRY RUN] Backup serait créé dans : $BACKUP_DIR"
    fi
fi

#==============================================================================
# PHASE 3 : CRÉATION STRUCTURE
#==============================================================================
log ""
log "📁 PHASE 3 : Création structure V3"

FILES=(
    "00_core.yaml"
    "10_sensors_physiques.yaml"
    "20_sensors_calcules.yaml"
    "30_sensors_thermiques.yaml"
    "40_sensors_predictions.yaml"
    "50_binary_sensors.yaml"
    "60_automations_pv.yaml"
    "70_automations_hc.yaml"
    "80_automations_securite.yaml"
    "90_scripts.yaml"
    "99_debug.yaml"
)

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$V3_DIR"
    
    for file in "${FILES[@]}"; do
        log "  Création : $file"
        # Ici, vous pouvez soit télécharger depuis GitHub soit créer les fichiers
        # Pour l'instant, on crée des placeholders
        touch "${V3_DIR}/${file}"
    done
    
    success "Structure V3 créée"
else
    log "  [DRY RUN] Fichiers qui seraient créés :"
    for file in "${FILES[@]}"; do
        log "    - ${V3_DIR}/${file}"
    done
fi

#==============================================================================
# PHASE 4 : VALIDATION YAML
#==============================================================================
log ""
log "🔍 PHASE 4 : Validation YAML"

if [ "$DRY_RUN" = false ]; then
    # Vérification syntaxe via ha core check
    log "  Exécution : ha core check"
    if ha core check 2>&1 | tee -a "$LOG_FILE"; then
        success "Configuration YAML valide"
    else
        error "Erreurs YAML détectées - vérifiez les logs"
    fi
else
    log "  [DRY RUN] ha core check serait exécuté"
fi

#==============================================================================
# PHASE 5 : RECHARGEMENT
#==============================================================================
log ""
log "🔄 PHASE 5 : Rechargement Home Assistant"

if [ "$DRY_RUN" = false ]; then
    log "  Exécution : ha core reload"
    if ha core reload 2>&1 | tee -a "$LOG_FILE"; then
        success "Configuration rechargée"
    else
        warn "Rechargement partiel - vérifiez l'UI"
    fi
else
    log "  [DRY RUN] ha core reload serait exécuté"
fi

#==============================================================================
# RÉSUMÉ
#==============================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "       RÉSUMÉ DÉPLOIEMENT"
log "═══════════════════════════════════════════════════════════════"
log ""
log "📂 Dossier V3     : $V3_DIR"
log "📄 Fichiers créés : ${#FILES[@]}"
[ "$DO_BACKUP" = true ] && log "💾 Backup         : $BACKUP_DIR"
log "📝 Log            : $LOG_FILE"
log ""

if [ "$DRY_RUN" = true ]; then
    warn "MODE DRY RUN - Aucune modification effectuée"
    log "Relancez sans --dry-run pour appliquer"
else
    success "DÉPLOIEMENT TERMINÉ"
    log ""
    log "Prochaines étapes :"
    log "  1. Vérifier les entités dans Developer Tools > States"
    log "  2. Configurer les paramètres dans l'UI"
    log "  3. Tester une chauffe forcée"
    log "  4. Surveiller pendant 24-48h"
fi

log ""
log "═══════════════════════════════════════════════════════════════"
```

### 7.2 Script Validation : validate_cumulus_v3.sh

```bash
#!/bin/bash
#==============================================================================
# CUMULUS V3 - SCRIPT DE VALIDATION
# Description : Vérifie que toutes les entités V3 sont opérationnelles
# Usage : ./validate_cumulus_v3.sh
#==============================================================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo "═══════════════════════════════════════════════════════════════"
echo "       CUMULUS V3 - VALIDATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

ERRORS=0
WARNINGS=0

#==============================================================================
# VÉRIFICATION ENTITÉS
#==============================================================================
echo "📋 Vérification des entités..."

# Fonction pour vérifier une entité
check_entity() {
    local entity=$1
    local expected=$2  # "exists" ou une valeur attendue
    
    # Utiliser l'API REST de HA
    local state=$(curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        "http://supervisor/core/api/states/${entity}" 2>/dev/null | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('state','NOT_FOUND'))" 2>/dev/null || echo "ERROR")
    
    if [ "$state" = "ERROR" ] || [ "$state" = "NOT_FOUND" ]; then
        error "$entity : NON TROUVÉ"
        ((ERRORS++))
        return 1
    elif [ "$state" = "unavailable" ] || [ "$state" = "unknown" ]; then
        warn "$entity : $state"
        ((WARNINGS++))
        return 0
    else
        success "$entity : $state"
        return 0
    fi
}

# Inputs
echo ""
echo "📌 Input Numbers :"
check_entity "input_number.cumulus_v3_seuil_pv_min_w" "exists"
check_entity "input_number.cumulus_v3_temp_cible_pv_c" "exists"
check_entity "input_number.cumulus_v3_soc_minimum_pct" "exists"

# Binary Sensors
echo ""
echo "📌 Binary Sensors :"
check_entity "binary_sensor.cumulus_v3_en_chauffe" "exists"
check_entity "binary_sensor.cumulus_v3_conditions_pv_reunies" "exists"
check_entity "binary_sensor.cumulus_v3_systeme_ok" "exists"

# Sensors
echo ""
echo "📌 Sensors :"
check_entity "sensor.cumulus_v3_temp_zone_basse" "exists"
check_entity "sensor.cumulus_v3_douches_disponibles" "exists"
check_entity "sensor.cumulus_v3_energie_stockee_kwh" "exists"

#==============================================================================
# RÉSUMÉ
#==============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "       RÉSUMÉ VALIDATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Erreurs   : $ERRORS"
echo "Warnings  : $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        success "VALIDATION RÉUSSIE - Système opérationnel"
    else
        warn "VALIDATION OK avec avertissements"
    fi
    exit 0
else
    error "VALIDATION ÉCHOUÉE - $ERRORS erreur(s) détectée(s)"
    exit 1
fi
```

---

## 📊 ANNEXES

### A. Mapping Entités V2 → V3

| Entité V2 | Entité V3 | Notes |
|-----------|-----------|-------|
| `input_number.cumulus_seuil_pv_w` | `input_number.cumulus_v3_seuil_pv_min_w` | Renommé pour clarté |
| `sensor.cumulus_temperature_estimee` | `sensor.cumulus_v3_temp_moyenne` | Multi-zones maintenant |
| `binary_sensor.cumulus_pv_suffisant` | `binary_sensor.cumulus_v3_surplus_pv_stable` | Avec délai intégré |

### B. Dépendances Matérielles

| Composant | Entity ID | Rôle |
|-----------|-----------|------|
| Shelly Pro 1 | `switch.shellypro1_ece334ee1b64` | Contacteur cumulus |
| SNZB-02LD | `sensor.snzb_02ld_cumulus_temperature` | Sonde température |
| Linky | `sensor.smart_meter_grid_import` | Import réseau |
| SolarBank | `sensor.solarbank_soc` | SOC batterie |

### C. Checklist Pré-Déploiement

- [ ] Backup `/config` complet
- [ ] Vérifier version HA ≥ 2024.x
- [ ] Tester accès SSH
- [ ] Identifier entités à adapter (entity_id locaux)
- [ ] Prévoir créneau de 2h sans besoin eau chaude

---

**Document généré le** : 2025-11-24  
**Version** : 3.0.0-draft  
**Statut** : Proposition de révision

---

*Ce document est conçu pour être utilisé avec Claude Code CLI ou VS Code pour un déploiement progressif et sécurisé.*
