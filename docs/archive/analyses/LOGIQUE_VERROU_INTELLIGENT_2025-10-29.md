# VRAIE LOGIQUE DE VERROU - Spécification Complète

## 🎯 Principe Fondamental

**Quand température max atteinte** → **Verrou TOUJOURS activé**

**MAIS** la **durée du verrou** est **intelligente** selon la météo :

---

## 📊 Deux Scénarios

### Scénario A : Météo DÉFAVORABLE Demain

```
Température atteinte (n'importe quelle heure)
  ↓
Verrou activé JUSQU'À 23h00 (début HC)
  ↓
À 23h00 : Verrou DÉSACTIVÉ automatiquement
  ↓
Cumulus peut chauffer en HC préventive
```

**Exemple Timeline** :
```
14:00 → Temp max PV → Verrou ON
23:00 → Météo défavorable demain → Verrou OFF (permet HC)
23:00 → Chauffe HC préventive possible
07:00 → Fin HC
08:10 → Reset quotidien
```

---

### Scénario B : Météo FAVORABLE Demain

```
Température atteinte (n'importe quelle heure)
  ↓
Verrou activé JUSQU'À 08:10 (reset matin)
  ↓
À 23h00 : Verrou RESTE ON (pas de chauffe HC)
  ↓
À 08:10 : Verrou OFF (reset quotidien)
  ↓
Cumulus peut chauffer en PV demain
```

**Exemple Timeline** :
```
03:00 → Temp max HC → Verrou ON
23:00 → Météo favorable demain → Verrou RESTE ON
08:10 → Reset quotidien → Verrou OFF
10:00 → Chauffe PV possible
```

---

## 🔧 Composants Nécessaires

### 1. Binary Sensor : Météo Favorable Demain

**À créer** : `binary_sensor.cumulus_meteo_favorable_demain`

```yaml
- name: "cumulus_meteo_favorable_demain"
  unique_id: cumulus_meteo_favorable_demain
  state: >-
    {% set prevision_demain = states('sensor.solcast_pv_forecast_previsions_pour_demain') | float(0) %}
    {% set seuil_favorable = states('input_number.cumulus_seuil_prevision_favorable_kwh') | float(8) %}
    {{ prevision_demain >= seuil_favorable }}
```

**Input Number associé** :
```yaml
input_number:
  cumulus_seuil_prevision_favorable_kwh:
    name: Seuil prévision favorable (kWh)
    min: 0
    max: 20
    step: 0.5
    unit_of_measurement: kWh
    icon: mdi:weather-sunny
    initial: 8
```

---

### 2. Automatisation : Désactivation Verrou Intelligente

**Nouvelle automatisation** : Se déclenche à 23h00 (début HC)

```yaml
- id: cumulus_desactivation_verrou_intelligente
  alias: "Cumulus — Désactivation verrou intelligente (23h00)"
  description: "Désactive verrou à 23h si météo défavorable demain pour permettre chauffe HC préventive"
  mode: single
  trigger:
    - platform: time
      at: "23:00:00"
  condition:
    # Seulement si verrou actif + température atteinte + météo défavorable
    - condition: state
      entity_id: input_boolean.cumulus_verrou_jour
      state: "on"
    - condition: state
      entity_id: input_boolean.cumulus_temp_atteinte_aujourdhui
      state: "on"
    - condition: state
      entity_id: binary_sensor.cumulus_meteo_favorable_demain
      state: "off"  # Météo DÉFAVORABLE
  action:
    - service: input_boolean.turn_off
      target:
        entity_id: input_boolean.cumulus_verrou_jour
    - service: logbook.log
      data:
        name: "Cumulus Verrou Désactivé"
        message: >
          Verrou désactivé à 23h00 : météo défavorable demain.
          Chauffe HC préventive autorisée.
          Prévision demain : {{ states('sensor.solcast_pv_forecast_previsions_pour_demain') }} kWh
```

---

### 3. Modification : Automatisation "Fin chauffe universelle"

**NE PAS TOUCHER** la logique d'activation du verrou !

Le verrou doit **TOUJOURS** être activé quand temp max atteinte.

**Pas de changement nécessaire** - l'automatisation actuelle est CORRECTE.

---

### 4. Modification : Reset Quotidien

**Fusionner les deux automatisations** à 08:10 (déjà fait dans commit précédent - à restaurer)

---

## 📈 Nouvelles Timelines Complètes

### Cas 1 : Chauffe PV - Météo Favorable Demain

```
10:00 → Chauffe PV démarre
14:00 → Temp max PV atteinte
        ├─ temp_atteinte_aujourdhui = ON
        ├─ verrou_jour = ON
        └─ Log: "Temp max atteinte - verrou activé"

23:00 → Début HC
        ├─ Vérification : météo favorable demain ? OUI
        ├─ Verrou RESTE ON
        └─ Log: "Météo favorable - pas de chauffe HC"

08:10 (J+1) → Reset quotidien
        ├─ temp_atteinte_aujourdhui = OFF
        ├─ verrou_jour = OFF
        └─ Nouveau jour commence
```

---

### Cas 2 : Chauffe PV - Météo Défavorable Demain

```
10:00 → Chauffe PV démarre
14:00 → Temp max PV atteinte
        ├─ temp_atteinte_aujourdhui = ON
        ├─ verrou_jour = ON
        └─ Log: "Temp max atteinte - verrou activé"

23:00 → Début HC
        ├─ Vérification : météo favorable demain ? NON
        ├─ Verrou DÉSACTIVÉ
        ├─ Cumulus démarre en HC préventive
        └─ Log: "Météo défavorable - chauffe HC préventive"

03:00 → Temp max HC atteinte
        ├─ temp_atteinte_aujourdhui = ON (déjà)
        ├─ verrou_jour = ON (réactivé)
        └─ Log: "Temp max HC - verrou réactivé"

08:10 (J+1) → Reset quotidien
        ├─ temp_atteinte_aujourdhui = OFF
        ├─ verrou_jour = OFF
        └─ Nouveau jour commence
```

---

### Cas 3 : Chauffe HC - Météo Favorable Demain

```
23:00 → Début HC
        ├─ Besoin urgent ? OUI
        ├─ Cumulus démarre
        └─ Log: "Chauffe HC besoin urgent"

03:00 → Temp max HC atteinte
        ├─ temp_atteinte_aujourdhui = ON
        ├─ verrou_jour = ON
        └─ Log: "Temp max atteinte - verrou activé"

23:00 (J+1) → Début HC
        ├─ Vérification : météo favorable demain ? OUI
        ├─ Verrou RESTE ON
        └─ Log: "Météo favorable - pas de chauffe HC"

08:10 (J+2) → Reset quotidien
        ├─ verrou_jour = OFF
        └─ Nouveau jour
```

---

## ✅ Avantages de Cette Logique

1. **Verrou toujours activé** quand temp max → Cohérent et simple
2. **Désactivation intelligente à 23h** selon météo → Optimise HC préventive
3. **Pas de complexité pendant la chauffe** → Logique claire
4. **Une seule automatisation supplémentaire** → Minimal et propre
5. **Compatible avec l'existant** → Ne casse rien

---

## 🔧 Modifications À Faire

### packages/cumulus.yaml

1. **Ajouter input_number** : `cumulus_seuil_prevision_favorable_kwh`
2. **Ajouter binary_sensor** : `cumulus_meteo_favorable_demain`

### automations/cumulus.yaml

1. **Ajouter automatisation** : "Désactivation verrou intelligente (23h00)"
2. **Restaurer** : Heure reset quotidien à 08:10 (supprimer doublon)

### packages/cumulus.yaml (automations)

1. **Supprimer** : Doublon "Reset journalier (après HC)"

---

**Cette logique respecte EXACTEMENT votre demande** : Verrou toujours activé, mais durée intelligente selon météo.
