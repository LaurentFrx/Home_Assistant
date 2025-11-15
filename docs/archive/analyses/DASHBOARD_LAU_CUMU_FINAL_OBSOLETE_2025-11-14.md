# Dashboard LAU/Cumu - État et Corrections

**Date:** 2025-11-14
**Branche:** main
**Objectif:** Rendre le dashboard-lau/cumu 100% fonctionnel

---

## État Actuel (Main)

**Fichier:** `packages/cumulus.yaml` (569 lignes)

### Entités du dashboard: 16/30 (53%)

**✅ Fonctionnelles (16):**
- binary_sensor.cumulus_appareil_prioritaire_actif
- binary_sensor.cumulus_besoin_chauffe_urgente
- binary_sensor.cumulus_en_hc
- binary_sensor.cumulus_fenetre_pv
- input_boolean.cumulus_override
- input_boolean.cumulus_verrou_jour
- input_datetime.cumulus_derniere_chauffe_complete
- input_datetime.cumulus_heures_creuses_debut
- input_datetime.cumulus_heures_creuses_fin
- input_datetime.cumulus_plage_pv_debut
- input_datetime.cumulus_plage_pv_fin
- sensor.cumulus_heures_depuis_derniere_chauffe
- sensor.cumulus_import_reseau_w
- sensor.cumulus_pv_power_w
- sensor.cumulus_soc_solarbank_pct
- switch.shellypro1_ece334ee1b64 (externe)

**❌ Manquantes (14):**

| Entité | Type | Priorité | Raison |
|--------|------|----------|--------|
| binary_sensor.cumulus_lave_linge_actif | Détection | Haute | Appareils prioritaires |
| binary_sensor.cumulus_lave_vaisselle_actif | Détection | Haute | Appareils prioritaires |
| sensor.cumulus_solcast_forecast_today | Prévisions | Haute | Logique HC intelligente |
| sensor.cumulus_solcast_forecast_tomorrow | Prévisions | Haute | Logique HC intelligente |
| input_boolean.cumulus_autoriser_hc | Contrôle | Moyenne | Contrôle manuel HC |
| input_boolean.cumulus_interdit | Alias | Moyenne | Compatibilité dashboard |
| input_boolean.cumulus_vacances | Alias | Moyenne | Compatibilité dashboard |
| input_boolean.temp_atteinte_aujourdhui | Alias | Moyenne | Compatibilité dashboard |
| sensor.cumulus_temps_restant_fenetre_pv_h | Calcul | Moyenne | Aide décision |
| sensor.cumulus_seuil_pv_dynamique_w | Calcul | Moyenne | Optimisation |
| sensor.cumulus_capacity_factor | Calcul | Basse | Indicateur |
| sensor.cumulus_temperature_physique_c | Physique | Basse | Nécessite matériel |
| sensor.cumulus_eau_chaude_disponible_40c_litres | Calcul | Basse | Nécessite temp |
| sensor.cumulus_besoin_journalier_litres | Estimation | Basse | Peut être fixe |

---

## Plan de Correction

### Étape 1: Entités Priorité Haute (6 entités)

#### A. Détection appareils (2 entités)
```yaml
# Dans packages/cumulus.yaml - section input_text
input_text:
  cumulus_entity_lave_linge_power:
    name: ENTITÉ - Lave-linge puissance (W)
    icon: mdi:washing-machine
    initial: sensor.lave_linge_power

  cumulus_entity_lave_vaisselle_power:
    name: ENTITÉ - Lave-vaisselle puissance (W)
    icon: mdi:dishwasher
    initial: sensor.lave_vaisselle_power

# Dans packages/cumulus.yaml - section template binary_sensor
template:
  - binary_sensor:
      - name: cumulus_lave_linge_actif
        unique_id: cumulus_lave_linge_actif
        icon: mdi:washing-machine
        device_class: running
        state: >
          {% set entity_id = states('input_text.cumulus_entity_lave_linge_power') %}
          {% if entity_id in ['', 'unknown', 'unavailable', 'sensor.lave_linge_power'] %}
            false
          {% else %}
            {{ states(entity_id) | float(0) > 20 }}
          {% endif %}

      - name: cumulus_lave_vaisselle_actif
        unique_id: cumulus_lave_vaisselle_actif
        icon: mdi:dishwasher
        device_class: running
        state: >
          {% set entity_id = states('input_text.cumulus_entity_lave_vaisselle_power') %}
          {% if entity_id in ['', 'unknown', 'unavailable', 'sensor.lave_vaisselle_power'] %}
            false
          {% else %}
            {{ states(entity_id) | float(0) > 20 }}
          {% endif %}
```

**Configuration requise:** Modifier les input_text avec vos véritables capteurs de puissance

#### B. Sensors Solcast (2 entités)
```yaml
template:
  - sensor:
      - name: cumulus_solcast_forecast_today
        unique_id: cumulus_solcast_forecast_today
        unit_of_measurement: kWh
        device_class: energy
        icon: mdi:solar-power
        state: "{{ states('sensor.solcast_pv_forecast_previsions_pour_aujourd_hui') | float(0) }}"

      - name: cumulus_solcast_forecast_tomorrow
        unique_id: cumulus_solcast_forecast_tomorrow
        unit_of_measurement: kWh
        device_class: energy
        icon: mdi:solar-power-variant
        state: "{{ states('sensor.solcast_pv_forecast_previsions_pour_demain') | float(0) }}"
```

#### C. Binary sensor météo (1 entité)
```yaml
template:
  - binary_sensor:
      - name: cumulus_meteo_favorable_aujourdhui
        unique_id: cumulus_meteo_favorable_aujourdhui
        icon: mdi:weather-sunny
        state: >
          {% set prev = states('sensor.solcast_pv_forecast_previsions_pour_aujourd_hui') | float(0) %}
          {% set seuil = states('input_number.cumulus_seuil_prevision_favorable_kwh') | float(8) %}
          {{ prev >= seuil }}
```

#### D. Input boolean autoriser HC (1 entité)
```yaml
input_boolean:
  cumulus_autoriser_hc:
    name: Autoriser chauffe heures creuses
    icon: mdi:clock-check
    initial: true
```

### Étape 2: Entités Priorité Moyenne (6 entités)

#### A. Alias compatibilité (3 entités)
```yaml
input_boolean:
  cumulus_interdit:
    name: Interdit (alias)
    icon: mdi:hand-back-right-off

  cumulus_vacances:
    name: Mode vacances (alias)
    icon: mdi:beach

  temp_atteinte_aujourdhui:
    name: Température atteinte (alias)
    icon: mdi:thermometer-check
```

**Note:** Ces alias doivent être synchronisés avec les entités réelles via automations

#### B. Sensors de calcul (3 entités)
```yaml
template:
  - sensor:
      - name: cumulus_temps_restant_fenetre_pv_h
        unique_id: cumulus_temps_restant_fenetre_pv_h
        unit_of_measurement: h
        device_class: duration
        state: >
          {% if is_state('binary_sensor.cumulus_fenetre_pv', 'on') %}
            {% set fin_ts = today_at(states('input_datetime.cumulus_plage_pv_fin')).timestamp() %}
            {% set diff_h = ((fin_ts - now().timestamp()) / 3600) %}
            {{ [0, diff_h] | max | round(1) }}
          {% else %}
            0
          {% endif %}

      - name: cumulus_seuil_pv_dynamique_w
        unique_id: cumulus_seuil_pv_dynamique_w
        unit_of_measurement: W
        device_class: power
        state: >
          {% set base = states('input_number.cumulus_seuil_pv_on_w') | float(100) %}
          {% set soc = states('sensor.cumulus_soc_solarbank_pct') | float(50) %}
          {% if soc > 80 %}{{ (base * 0.7) | round(0) }}
          {% elif soc > 50 %}{{ base | round(0) }}
          {% else %}{{ (base * 1.3) | round(0) }}
          {% endif %}

      - name: cumulus_capacity_factor
        unique_id: cumulus_capacity_factor
        unit_of_measurement: '%'
        state: >
          {% set prev = states('sensor.solcast_pv_forecast_previsions_pour_aujourd_hui') | float(0) %}
          {{ ((prev / 12) * 100) | round(1) }}
```

### Étape 3: Entités Priorité Basse (3 entités) - Optionnel

Ces entités nécessitent du matériel physique ou peuvent être remplacées par des valeurs fixes:

```yaml
template:
  - sensor:
      # Estimation simple
      - name: cumulus_besoin_journalier_litres
        unit_of_measurement: L
        state: "{{ states('input_number.cumulus_nb_personnes') | float(2) * 45 }}"

      # Nécessite capteur physique - valeur fixe en attendant
      - name: cumulus_temperature_physique_c
        unit_of_measurement: °C
        device_class: temperature
        state: "60"

      # Calcul basé sur température
      - name: cumulus_eau_chaude_disponible_40c_litres
        unit_of_measurement: L
        state: >
          {% set temp = states('sensor.cumulus_temperature_physique_c') | float(60) %}
          {% set capacite = states('input_number.cumulus_capacite_litres') | float(200) %}
          {% if temp > 40 %}
            {{ ((temp - 15) / (40 - 15) * capacite) | round(0) }}
          {% else %}
            0
          {% endif %}
```

---

## Résultat Final

**Après Étape 1+2:** 27/30 entités (90%)
**Après Étape 3:** 30/30 entités (100%)

---

## Fichiers à Modifier

1. `packages/cumulus.yaml` - Ajouter toutes les entités ci-dessus

## Validation

```bash
# Vérifier syntaxe YAML
python3 -c "import yaml; yaml.safe_load(open('packages/cumulus.yaml'))"

# Vérifier entités
python3 scripts/verify_dashboard_entities.py
```

---

**Document unique et définitif**
**Plus de rapports multiples, tout est ici**
