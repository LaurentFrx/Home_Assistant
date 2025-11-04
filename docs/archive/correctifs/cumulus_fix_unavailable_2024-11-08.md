# Correction CUMULUS - Fix binary_sensor unavailable
**Date :** 2024-11-08
**Version :** v2025-11-08-fix-unavailable
**Dernière mise à jour :** 2024-11-08b (fix incohérence besoin_urgent)
**Repository :** LaurentFrx/Home_Assistant

---

## 🎯 Problèmes identifiés

### 1. **CRITIQUE** - binary_sensor.cumulus_chauffe_reelle en état unavailable
- **Symptôme :** Le sensor `binary_sensor.cumulus_chauffe_reelle` retourne `unavailable` au lieu de `on` ou `off`
- **Cause :** Le sensor utilisait uniquement `sensor.cumulus_import_reseau_w` sans calculer la consommation réelle du cumulus
- **Impact :**
  - La chauffe en heures creuses n'est pas détectée
  - L'automation "Fin chauffe universelle" ne se déclenche pas
  - Le verrou jour ne s'active pas après une chauffe complète

### 2. **INCOHÉRENCES** - États contradictoires
- **Symptôme :** Verrou jour actif ET besoin urgent simultanément
- **Cause :** Absence de mécanisme de détection d'incohérences
- **Impact :** Confusion dans les états du système, comportements imprévisibles

### 3. **ROBUSTESSE** - Chauffe HC non enregistrée
- **Symptôme :** La chauffe pendant les heures creuses n'est pas détectée ni enregistrée
- **Cause :** L'automation de fin de chauffe ne se déclenche pas si le sensor est unavailable
- **Impact :** Le système ne sait pas si la température a été atteinte

---

## ✅ Corrections apportées

### FIX #1 - Réparation de binary_sensor.cumulus_chauffe_reelle

#### Ajout de input_number.cumulus_puissance_w
```yaml
input_number:
  cumulus_puissance_w:
    name: Puissance nominale cumulus (W)
    min: 0
    max: 5000
    step: 100
    unit_of_measurement: W
    icon: mdi:water-boiler
    initial: 3000
```

#### Ajout de sensor.cumulus_consommation_reelle_w
**Localisation :** Lignes 263-296

**Formule universelle :**
```
Conso_cumulus = (Import_réseau + PV_total) - Talon_maison
```

**Caractéristiques :**
- Fonctionne avec toute répartition SB/APS
- Gère automatiquement l'export (import négatif)
- Borné entre 0 et puissance max
- Retourne 0 si contacteur OFF ou unavailable

**Attributs :**
- `import_w` : Import réseau actuel
- `pv_total_w` : Production PV totale
- `talon_w` : Talon maison configuré
- `formule` : "Conso = (Import + PV_total) - Talon"
- `explication` : Description du fonctionnement

#### Refonte de binary_sensor.cumulus_chauffe_reelle
**Localisation :** Lignes 334-376

**Nouvelle logique :**
```yaml
state: >-
  {% set sw_id = states('input_text.cumulus_entity_contacteur') | string %}
  {% if sw_id in ['unknown', 'unavailable', ''] %}
    false
  {% else %}
    {% set sw = is_state(sw_id, 'on') %}
    {% set conso = states('sensor.cumulus_consommation_reelle_w') | float(0) %}
    {% set puissance_nominale = states('input_number.cumulus_puissance_w') | float(3000) %}
    {% set seuil_chauffe = puissance_nominale * 0.85 %}
    {{ sw and (conso > seuil_chauffe) }}
  {% endif %}
```

**Seuil de détection :** 85% de la puissance nominale (2550W pour 3000W)

**Nouveaux attributs de diagnostic :**
- `consommation_w` : Consommation réelle mesurée
- `seuil_detection_w` : Seuil de détection calculé (85%)
- `contacteur_state` : État du contacteur
- `last_change_reason` : Raison du dernier changement d'état
- `check_time` : Timestamp du dernier calcul
- `all_sources_available` : Toutes les entités sources sont disponibles (true/false)

---

### FIX #2 - Automation "Fin chauffe universelle"

**Localisation :** Lignes 527-569
**ID :** `cumulus_fin_chauffe_universelle`

**Fonctionnement :**
- **Trigger :** `binary_sensor.cumulus_chauffe_reelle` passe à `off` pendant 120 secondes
- **Détecte :** Fin de chauffe quelle que soit la source (PV, HC, ou manuelle)
- **Condition :** Vérifie que le contacteur était bien ON récemment

**Actions :**
1. Coupe le contacteur si encore ON
2. Active `input_boolean.cumulus_verrou_jour`
3. Active `input_boolean.temp_atteinte_aujourdhui`

**Durée minimale :** 120 secondes pour éviter les faux positifs

---

### FIX #3 - Détection d'incohérences

#### binary_sensor.cumulus_etat_coherent
**Localisation :** Lignes 388-441

**Détecte 3 types d'incohérences :**

1. **Verrou jour + besoin urgent** : Le verrou jour est actif mais le système indique un besoin urgent de chauffe
2. **Chauffe réelle ON mais contacteur OFF** : La chauffe est détectée alors que le contacteur est éteint
3. **Consommation élevée sans détection** : Consommation > 50% de la puissance nominale mais chauffe non détectée

**Attributs détaillés :**
- `incoherence_verrou_et_urgent` : true/false
- `incoherence_chauffe_sans_contacteur` : true/false
- `incoherence_conso_sans_detection` : true/false
- `details` : Description textuelle des incohérences détectées

#### Automation de notification
**Localisation :** Lignes 717-745
**ID :** `cumulus_notification_incoherence`

**Fonctionnement :**
- **Trigger :** `binary_sensor.cumulus_etat_coherent` passe à `on` pendant 30 secondes
- **Action :** Crée une notification persistante avec détails

**Contenu de la notification :**
- Titre : "⚠️ Cumulus - Incohérence détectée"
- Description des incohérences
- États actuels de tous les sensors concernés
- ID de notification : `cumulus_incoherence`

---

### FIX #4 - Fallback fin de chauffe en fin HC

**Localisation :** Lignes 668-702
**ID :** `cumulus_fallback_fin_hc`

**Problème résolu :** Si une chauffe a eu lieu pendant les HC mais que la fin n'a pas été détectée, le système ne sait pas si la température a été atteinte.

**Fonctionnement :**
- **Trigger :** Fin de la période heures creuses (`binary_sensor.cumulus_en_hc` → `off`)
- **Condition :** La chauffe réelle était ON il y a moins de 10 minutes
- **Action :**
  - Si chauffe terminée → Active le verrou jour et flag température atteinte
  - Si chauffe encore active → Ne met PAS le verrou (température non atteinte)

**Avantage :** Détection de fin de chauffe même si l'automation principale a raté le changement d'état.

---

## 🔧 CORRECTION 2024-11-08b - Fix incohérence "besoin urgent"

### Problème identifié
Après redémarrage de HA, l'affichage affiche "besoin urgent" car :
1. Le sensor `binary_sensor.cumulus_besoin_chauffe_urgente` n'existe PAS dans ce package
2. Ce sensor est référencé par `binary_sensor.cumulus_etat_coherent`
3. Quand le sensor est `unavailable`, le check `verrou_jour AND besoin_urgent` était évalué à `false AND false` = `false`
4. Mais après quelques secondes, les templates se stabilisent et le sensor `unavailable` provoquait une incohérence détectée

### Solution appliquée
Le `binary_sensor.cumulus_etat_coherent` vérifie maintenant si le sensor `cumulus_besoin_chauffe_urgente` existe avant de l'utiliser :

```yaml
{% set sensor_existe = states('binary_sensor.cumulus_besoin_chauffe_urgente') not in ['unavailable', 'unknown'] %}
{% set besoin_urgent = is_state('binary_sensor.cumulus_besoin_chauffe_urgente', 'on') if sensor_existe else false %}
{% set incoherence_1 = verrou_jour and besoin_urgent and sensor_existe %}
```

**Résultat :** Si le sensor n'existe pas (cas normal pour cette version simplifiée), aucune incohérence n'est détectée.

### Nouvel attribut ajouté
- `besoin_urgent_sensor_existe` : Indique si le sensor de besoin urgent existe (true/false)

---

## 📋 Liste des entités ajoutées/modifiées

### Nouvelles entités ajoutées :

| Entité | Type | Description |
|--------|------|-------------|
| `input_number.cumulus_puissance_w` | Input Number | Puissance nominale du cumulus (3000W par défaut) |
| `sensor.cumulus_consommation_reelle_w` | Sensor | Consommation réelle calculée du cumulus |
| `binary_sensor.cumulus_etat_coherent` | Binary Sensor | Détection d'incohérences dans le système |

### Entités modifiées :

| Entité | Changement |
|--------|-----------|
| `binary_sensor.cumulus_chauffe_reelle` | Logique refaite : basée sur consommation réelle + attributs diagnostic |

### Nouvelles automations :

| Automation | ID | Description |
|------------|----|-----------|
| Cumulus — Fin chauffe universelle | `cumulus_fin_chauffe_universelle` | Détection universelle de fin de chauffe |
| Cumulus — Fallback fin chauffe en fin HC | `cumulus_fallback_fin_hc` | Fallback si fin de chauffe ratée pendant HC |
| Cumulus — Notification incohérence détectée | `cumulus_notification_incoherence` | Alerte en cas d'incohérence |

---

## 🧪 Tests recommandés

### Test 1 - Détection de chauffe réelle
1. Activer manuellement le contacteur via Shelly
2. Vérifier que `binary_sensor.cumulus_chauffe_reelle` passe à `on`
3. Consulter l'attribut `consommation_w` pour voir la consommation réelle
4. Vérifier que `all_sources_available` = `true`

### Test 2 - Fin de chauffe en heures creuses
1. Attendre le début des heures creuses (03:30)
2. Vérifier que le cumulus se met en chauffe
3. Attendre que la température max soit atteinte (thermostat coupe)
4. Vérifier que l'automation "Fin chauffe universelle" se déclenche après 120s
5. Vérifier que `input_boolean.cumulus_verrou_jour` passe à `on`

### Test 3 - Détection d'incohérence
1. Forcer manuellement `input_boolean.cumulus_verrou_jour` à `on`
2. Si `binary_sensor.cumulus_besoin_chauffe_urgente` existe et est `on`, vérifier que :
   - `binary_sensor.cumulus_etat_coherent` passe à `on`
   - Une notification persistante est créée
   - L'attribut `details` contient "Verrou jour actif ET besoin urgent"

### Test 4 - Fallback fin HC
1. Démarrer une chauffe manuelle pendant les HC
2. Laisser les HC se terminer (08:05)
3. Vérifier que le fallback vérifie si la température a été atteinte
4. Vérifier l'activation du verrou si température atteinte

---

## 📊 Diagnostic en cas de problème

### binary_sensor.cumulus_chauffe_reelle toujours unavailable
**Vérifications :**
1. Vérifier que `sensor.cumulus_consommation_reelle_w` existe et a une valeur numérique
2. Vérifier que `input_number.cumulus_puissance_w` existe (valeur par défaut 3000)
3. Vérifier que `input_text.cumulus_entity_contacteur` pointe vers le bon switch
4. Consulter l'attribut `all_sources_available` du binary_sensor

### Consommation réelle à 0 alors que cumulus chauffe
**Causes possibles :**
1. `sensor.cumulus_import_reseau_w` = unavailable
2. `sensor.cumulus_pv_power_w` = unavailable
3. Contacteur en état unknown/unavailable
4. La formule `(Import + PV) - Talon` donne un résultat négatif

**Solution :** Vérifier les attributs `import_w`, `pv_total_w`, `talon_w` du sensor

### Fin de chauffe non détectée
**Vérifications :**
1. Vérifier que `binary_sensor.cumulus_chauffe_reelle` était bien à `on` pendant la chauffe
2. Vérifier le timestamp `last_changed` du binary_sensor
3. Vérifier les logs de l'automation `cumulus_fin_chauffe_universelle`
4. Si échec de l'automation principale, le fallback `cumulus_fallback_fin_hc` devrait fonctionner

---

## 🔧 Configuration initiale

### Paramètres à vérifier après installation :

```yaml
# Dans input_text :
cumulus_entity_import_w: sensor.smart_meter_grid_import  # À adapter
cumulus_entity_contacteur: switch.shellypro1_ece334ee1b64  # À adapter
cumulus_entity_soc_solarbank: sensor.system_sanguinet_etat_de_charge_du_sb  # À adapter

# Dans input_number :
cumulus_puissance_w: 3000  # Puissance nominale de votre cumulus
cumulus_talon_maison_w: 300  # Consommation de base de la maison
cumulus_seuil_pv_on_w: 100  # Seuil PV pour démarrage

# Dans input_datetime :
cumulus_heures_creuses_debut: "03:30:00"  # Début HC
cumulus_heures_creuses_fin: "08:05:00"  # Fin HC
```

---

## 📝 Notes techniques

### Formule de consommation réelle
La formule `Conso = (Import + PV_total) - Talon` fonctionne dans tous les cas :

| Cas | Import | PV | Talon | Conso cumulus |
|-----|--------|-----|-------|---------------|
| Chauffe 100% réseau | 3300W | 0W | 300W | 3000W ✓ |
| Chauffe 100% PV | -2700W | 3000W | 300W | 3000W ✓ |
| Chauffe mixte | 1500W | 1800W | 300W | 3000W ✓ |
| Cumulus OFF | 300W | 0W | 300W | 0W ✓ |
| Export sans cumulus | -500W | 800W | 300W | 0W ✓ (borné) |

### Seuil de détection 85%
Le seuil de 85% (2550W pour 3000W) permet :
- D'éviter les faux négatifs dus aux variations de tension
- De détecter la chauffe même si la puissance est légèrement inférieure
- D'éviter les faux positifs quand le cumulus s'arrête

### Durée minimale 120s
La durée de 120 secondes pour détecter la fin de chauffe évite :
- Les coupures momentanées du thermostat
- Les variations de consommation dues à d'autres appareils
- Les faux positifs lors des démarrages/arrêts rapides

---

## 🔄 Migration depuis la version précédente

1. **Sauvegarde :** Sauvegarder l'ancien fichier `packages/cumulus.yaml`
2. **Remplacement :** Copier le nouveau fichier v2025-11-08-fix-unavailable
3. **Configuration :** Vérifier les paramètres dans la section "Configuration initiale"
4. **Rechargement :** Recharger la configuration Home Assistant
   - Developer Tools → YAML → Reload Template Entities
   - Developer Tools → YAML → Reload Automations
5. **Vérification :**
   - Vérifier que `binary_sensor.cumulus_chauffe_reelle` a un état `on` ou `off`
   - Vérifier que `sensor.cumulus_consommation_reelle_w` affiche une valeur
   - Tester l'activation manuelle du contacteur

---

## 📞 Support

En cas de problème, vérifier :
1. Les logs Home Assistant (`Developer Tools → Logs`)
2. Les états des sensors dans `Developer Tools → States`
3. Les attributs de `binary_sensor.cumulus_chauffe_reelle`
4. L'attribut `details` de `binary_sensor.cumulus_etat_coherent`

Pour signaler un bug : [GitHub Issues](https://github.com/LaurentFrx/homeassistant-cumulus/issues)

---

**Auteur de la correction :** Claude (Anthropic)
**Date de création :** 2024-11-08
**Licence :** Même licence que le projet original
