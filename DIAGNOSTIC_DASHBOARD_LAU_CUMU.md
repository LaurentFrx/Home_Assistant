# 🔍 DIAGNOSTIC DASHBOARD-LAU/CUMU

**Date:** 2025-11-14
**Dashboard:** LAU → Vue "Cumulus" (path: cumu)
**Fichier de référence:** `lovelace/vue_cumu_reference.json`

---

## 📊 RÉSUMÉ EXÉCUTIF

| Métrique | Valeur | État |
|----------|--------|------|
| **Total entités** | 30 | - |
| **✅ Fonctionnelles** | 16 | 🟢 |
| **🔄 Renommées** | 3 | 🟡 |
| **❌ Manquantes** | 11 | 🔴 |
| **État global** | 53% | 🟠 MOYEN |

---

## ✅ ENTITÉS FONCTIONNELLES (16/30)

Ces entités sont correctement définies dans `packages/cumulus.yaml` ou sont des intégrations externes:

### Binary Sensors (4)
- ✅ `binary_sensor.cumulus_appareil_prioritaire_actif`
- ✅ `binary_sensor.cumulus_besoin_chauffe_urgente`
- ✅ `binary_sensor.cumulus_en_hc`
- ✅ `binary_sensor.cumulus_fenetre_pv`

### Input Booleans (2)
- ✅ `input_boolean.cumulus_override`
- ✅ `input_boolean.cumulus_verrou_jour`

### Input Datetimes (5)
- ✅ `input_datetime.cumulus_derniere_chauffe_complete`
- ✅ `input_datetime.cumulus_heures_creuses_debut`
- ✅ `input_datetime.cumulus_heures_creuses_fin`
- ✅ `input_datetime.cumulus_plage_pv_debut`
- ✅ `input_datetime.cumulus_plage_pv_fin`

### Sensors (4)
- ✅ `sensor.cumulus_heures_depuis_derniere_chauffe`
- ✅ `sensor.cumulus_import_reseau_w`
- ✅ `sensor.cumulus_pv_power_w`
- ✅ `sensor.cumulus_soc_solarbank_pct`

### Switches (1)
- ✅ `switch.shellypro1_ece334ee1b64` (Entité Shelly externe)

---

## 🔄 ENTITÉS RENOMMÉES (3/30)

Ces entités existent dans `packages/cumulus.yaml` mais sous un nom différent:

| Dashboard (ancien) | Configuration (nouveau) | Impact |
|--------------------|-------------------------|--------|
| `input_boolean.cumulus_interdit` | `input_boolean.cumulus_interdit_depart` | 🟡 Renommer |
| `input_boolean.cumulus_vacances` | `input_boolean.cumulus_mode_vacances` | 🟡 Renommer |
| `input_boolean.temp_atteinte_aujourdhui` | `input_boolean.cumulus_temp_atteinte_aujourdhui` | 🟡 Renommer |

### Actions recommandées

**Option 1: Mettre à jour le dashboard LAU**
- Modifier les noms dans la vue "Cumulus" du dashboard LAU
- Utiliser les nouveaux noms de `packages/cumulus.yaml`

**Option 2: Créer des alias dans Home Assistant**
- Créer des helpers avec les anciens noms
- Pointer vers les nouvelles entités

---

## ❌ ENTITÉS MANQUANTES (11/30)

Ces entités sont référencées dans le dashboard mais n'existent ni dans `packages/cumulus.yaml` ni dans les intégrations:

### Binary Sensors (2)
```yaml
- binary_sensor.cumulus_lave_linge_actif
- binary_sensor.cumulus_lave_vaisselle_actif
```

**Usage:** Détection d'appareils prioritaires
**Impact:** Fonction "Appareil prioritaire actif" ne peut pas fonctionner
**Solution:** Créer des template binary sensors basés sur la consommation électrique

### Input Booleans (1)
```yaml
- input_boolean.cumulus_autoriser_hc
```

**Usage:** Autorisation de chauffe en heures creuses
**Impact:** Impossible de contrôler la chauffe HC via le dashboard
**Solution:** Créer un input_boolean manuel ou utiliser une logique d'automation

### Sensors Thermiques (3)
```yaml
- sensor.cumulus_temperature_physique_c
- sensor.cumulus_eau_chaude_disponible_40c_litres
- sensor.cumulus_besoin_journalier_litres
```

**Usage:** Affichage température et volume d'eau disponible
**Impact:** Pas d'information sur l'état thermique du cumulus
**Solutions possibles:**
1. Capteur de température physique (sonde DS18B20)
2. Template sensor basé sur estimation énergétique
3. Intégration avec thermostat Wifi si équipé

### Sensors Solcast (2)
```yaml
- sensor.cumulus_solcast_forecast_today
- sensor.cumulus_solcast_forecast_tomorrow
```

**Usage:** Prévisions de production solaire
**Impact:** Logique de décision intelligente HC désactivée
**Solution:** Créer des template sensors basés sur l'intégration Solcast:

```yaml
template:
  - sensor:
      - name: cumulus_solcast_forecast_today
        unique_id: cumulus_solcast_forecast_today
        unit_of_measurement: kWh
        state: "{{ states('sensor.solcast_pv_forecast_previsions_pour_aujourd_hui') | float(0) }}"

      - name: cumulus_solcast_forecast_tomorrow
        unique_id: cumulus_solcast_forecast_tomorrow
        unit_of_measurement: kWh
        state: "{{ states('sensor.solcast_pv_forecast_previsions_pour_demain') | float(0) }}"
```

### Sensors de Calcul (3)
```yaml
- sensor.cumulus_capacity_factor
- sensor.cumulus_seuil_pv_dynamique_w
- sensor.cumulus_temps_restant_fenetre_pv_h
```

**Usage:** Calculs avancés pour optimisation
**Impact:** Fonctionnalités avancées indisponibles
**Solution:** Implémenter les templates de calcul

---

## 🛠️ PLAN D'ACTION RECOMMANDÉ

### Phase 1: Corrections Immédiates (Haute priorité)

1. **Corriger les renommages** (5 min)
   - Mettre à jour les 3 entités renommées dans le dashboard LAU
   - Ou créer des helpers d'alias

2. **Ajouter les sensors Solcast** (2 min)
   - Ajouter les 2 template sensors dans `packages/cumulus.yaml`
   - Recharger la configuration

### Phase 2: Fonctionnalités Manquantes (Priorité moyenne)

3. **Créer les binary sensors d'appareils** (10 min)
   ```yaml
   # À ajouter dans packages/cumulus.yaml
   template:
     - binary_sensor:
         - name: cumulus_lave_linge_actif
           state: "{{ states('sensor.prise_lave_linge_power') | float(0) > 20 }}"

         - name: cumulus_lave_vaisselle_actif
           state: "{{ states('sensor.prise_lave_vaisselle_power') | float(0) > 20 }}"
   ```

4. **Ajouter input_boolean.cumulus_autoriser_hc** (1 min)
   ```yaml
   input_boolean:
     cumulus_autoriser_hc:
       name: Autoriser chauffe HC
       icon: mdi:clock-check
   ```

### Phase 3: Fonctionnalités Avancées (Basse priorité)

5. **Sensors thermiques** (Nécessite matériel/estimation)
   - Installer sonde température (si possible)
   - Ou créer templates d'estimation basés sur énergie consommée

6. **Sensors de calcul avancés** (30 min)
   - Implémenter capacity_factor
   - Implémenter seuil_pv_dynamique_w
   - Implémenter temps_restant_fenetre_pv_h

---

## 📝 SCRIPTS DE VÉRIFICATION

Deux scripts ont été créés pour faciliter les diagnostics futurs:

### 1. `scripts/check_dashboard_lau_cumu.sh`
Script Bash basique pour vérification rapide

```bash
./scripts/check_dashboard_lau_cumu.sh
```

### 2. `scripts/verify_dashboard_entities.py`
Script Python détaillé avec analyse complète

```bash
python3 scripts/verify_dashboard_entities.py
```

---

## 🎯 PROCHAINES ÉTAPES

1. ✅ Lire ce diagnostic
2. ⏳ Décider quelles fonctionnalités sont prioritaires
3. ⏳ Implémenter Phase 1 (corrections immédiates)
4. ⏳ Tester le dashboard après corrections
5. ⏳ Planifier Phases 2 et 3 selon besoins

---

## 📎 FICHIERS DE RÉFÉRENCE

- Configuration principale: `packages/cumulus.yaml`
- Liste entités: `lovelace/entities_lau_cumu.txt`
- Vue de référence: `lovelace/vue_cumu_reference.json`
- Changelog: `lovelace/CHANGELOG_LAU_CUMU.md`
- Vérification Solcast: `lovelace/verification_solcast.txt`

---

**Généré le:** 2025-11-14 22:15
**Outil:** Claude Code - Diagnostic automatisé
