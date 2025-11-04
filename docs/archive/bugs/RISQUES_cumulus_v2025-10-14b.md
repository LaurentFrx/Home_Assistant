# ANALYSE DES RISQUES - Package Cumulus v2025-10-14b

**Date** : 2025-10-14
**Version** : v2025-10-14b
**Fichier** : `packages/cumulus.yaml`

---

## ✅ BUGS CRITIQUES CORRIGÉS

### 1. Boucle ON/OFF détection variation brutale (CORRIGÉ)
**Ligne** : 1195-1238
**Gravité** : 🔴 CRITIQUE

**Problème initial** :
L'automatisation `cumulus_arret_si_variation_brutale_import` détectait le démarrage du cumulus lui-même (+3000W) et l'arrêtait immédiatement, créant une boucle infinie ON/OFF.

**Solution appliquée** :
Ajout d'une condition `for: seconds: 30` sur `binary_sensor.cumulus_chauffe_reelle` (ligne 1206-1207). L'automatisation attend maintenant 30 secondes après le démarrage avant de détecter les variations.

**Comportement attendu** :
- Cumulus démarre → 30s de stabilisation
- Après 30s : détection des variations > 300W (appareils tiers)

---

### 2. Redémarrage ineffectif après appareil prioritaire (CORRIGÉ)
**Ligne** : 1257-1300
**Gravité** : 🔴 CRITIQUE

**Problème initial** :
L'automatisation `cumulus_redemarrage_si_appareil_arrete` retirait uniquement le verrou sans redémarrer physiquement le cumulus. L'automatisation PV ne se déclenchait pas (pas de transition false→true du trigger).

**Solution appliquée** :
Ajout de `switch.turn_on` explicite (lignes 1293-1295) avec vérification que le contacteur est bien OFF avant de le rallumer.

**Comportement attendu** :
- Appareil prioritaire s'arrête + PV OK → Cumulus redémarre automatiquement

---

## ⚠️ RISQUES DE CONCEPTION (NON CORRIGÉS)

### 3. Calcul de production APS potentiellement incorrect
**Lignes** : 603-634
**Gravité** : 🟠 MAJEUR
**Impact** : Surévaluation de la puissance disponible

**Problème** :
```yaml
cumulus_production_aps_w:
  state: >-
    {% set pv_total = states('sensor.cumulus_pv_power_w') | float(0) %}
    {% set sb_max = states('input_number.cumulus_solarbank_max_w') | float(1200) %}
    {% if pv_total > sb_max %}
      {{ (pv_total - sb_max) | round(0) }}
    {% else %}
      {{ pv_total | round(0) }}
    {% endif %}

cumulus_production_solaire_totale_w:
  state: >-
    {% set aps = states('sensor.cumulus_production_aps_w') | float(0) %}
    {{ (aps * 2) | round(0) }}
```

**Hypothèse actuelle** :
- `sensor.cumulus_pv_power_w` (entité `sensor.pv_total_entree_sb_aps_w`) = PV total SB+APS
- Le capteur déduit 1200W pour isoler l'APS
- Puis multiplie par 2 pour obtenir la production totale

**Risque** :
Si `sensor.pv_total_entree_sb_aps_w` est déjà la production totale des deux groupes, on surestime la puissance.

**Vérification nécessaire** :
1. Consulter la définition de `sensor.pv_total_entree_sb_aps_w` dans la config
2. Vérifier les valeurs réelles en journée :
   - `sensor.cumulus_pv_power_w` : ?W
   - `sensor.cumulus_production_aps_w` : ?W
   - `sensor.cumulus_production_solaire_totale_w` : ?W
3. Comparer avec la puissance crête installée

**Action recommandée** :
- Test en conditions réelles avec log des valeurs
- Ajuster la formule si nécessaire

---

### 4. Calcul consommation cumulus indirect et fragile
**Ligne** : 387-416
**Gravité** : 🟠 MAJEUR
**Impact** : Détections erronées de fin de chauffe

**Problème** :
```yaml
cumulus_consommation_reelle_w:
  state: >-
    {% set import_w = states('sensor.cumulus_import_reseau_w') | float(0) %}
    {% set pv_total_w = states('sensor.cumulus_pv_power_w') | float(0) %}
    {% set talon = states('input_number.cumulus_talon_maison_w') | float(300) %}
    {% set conso_cumulus = (import_w + pv_total_w) - talon %}
    {{ [[0, conso_cumulus] | max, puissance_max] | min | round(0) }}
```

**Formule** : `Conso_cumulus = (Import + PV_total) - Talon`

**Hypothèse** : Le talon domestique (300W) est constant.

**Risque** :
Des charges variables (pompe, VMC modulante, réfrigérateur) peuvent faire varier le talon réel de ±200W, faussant le calcul :
- Pompe démarre (+100W) → Conso cumulus surévaluée de 100W
- VMC réduit (-50W) → Conso cumulus sous-évaluée de 50W

**Impact sur `binary_sensor.cumulus_chauffe_reelle`** :
- Seuil de détection : 2100W (70% de 3000W)
- Si talon varie de +200W → consommation calculée passe à 3200W → OK
- Si talon varie de -200W → consommation calculée passe à 2800W → OK
- **Mais** si plusieurs appareils variables s'accumulent, le capteur peut osciller

**Solutions alternatives** :
1. **Compteur dédié** : Installer un compteur intelligent sur le circuit cumulus (idéal mais matériel requis)
2. **Talon adaptatif** : Calculer le talon moyen sur 5 min hors chauffe cumulus
3. **Fenêtre glissante** : Filtrer les variations courtes (< 10s) avant de détecter la chauffe

**Action recommandée** :
- Surveiller les logs de `binary_sensor.cumulus_chauffe_reelle` pendant 1 semaine
- Si oscillations fréquentes → implémenter talon adaptatif

---

### 5. Template for: dans trigger (compatibilité HA)
**Ligne** : 875
**Gravité** : 🟡 MINEUR
**Impact** : Échec validation YAML sur anciennes versions HA

**Code** :
```yaml
trigger:
  - platform: template
    value_template: >-
      {% set aps = states('sensor.cumulus_production_aps_w') | float(0) %}
      {% set seuil = states('input_number.cumulus_seuil_pv_statique_w') | float(100) %}
      {{ aps >= seuil }}
    for:
      seconds: "{{ states('input_number.cumulus_on_delay_s')|int(10) }}"
```

**Prérequis** : Home Assistant 2024.6+

**Action** :
Vérifier la version HA actuelle :
```bash
ha core info
```

Si version < 2024.6, remplacer par :
```yaml
for:
  seconds: 10  # Valeur fixe
```

---

## 📊 RÉCAPITULATIF

| Risque | Gravité | Statut | Action |
|--------|---------|--------|--------|
| Boucle ON/OFF variation | 🔴 CRITIQUE | ✅ CORRIGÉ | Tampon 30s ajouté |
| Redémarrage ineffectif | 🔴 CRITIQUE | ✅ CORRIGÉ | switch.turn_on ajouté |
| Calcul production APS | 🟠 MAJEUR | ⚠️ À VÉRIFIER | Test conditions réelles requis |
| Consommation indirecte | 🟠 MAJEUR | ⚠️ À SURVEILLER | Monitorer logs 1 semaine |
| Template for: | 🟡 MINEUR | ✅ OK si HA 2024.6+ | Vérifier version HA |

---

## 🔍 TESTS RECOMMANDÉS

### Test 1 : Démarrage PV progressif
**Objectif** : Vérifier que le cumulus démarre avec 50% du seuil quand >5h restantes

**Procédure** :
1. Attendre début fenêtre PV (10:20)
2. Vérifier valeurs :
   - `sensor.cumulus_fenetre_pv_restante_corrigee_h` > 5h ?
   - `sensor.cumulus_puissance_disponible_w` ≥ 50% de `sensor.cumulus_seuil_pv_dynamique_w` ?
3. Observer démarrage automatique

**Résultat attendu** : Cumulus démarre vers 10:30 avec ~1500W disponibles au lieu d'attendre 3000W

---

### Test 2 : Détection variation brutale (post-stabilisation)
**Objectif** : Vérifier que le cumulus s'arrête si appareil non déclaré démarre (mais pas à son propre démarrage)

**Procédure** :
1. Cumulus en chauffe depuis >1 min
2. Démarrer cafetière (1200W) ou bouilloire
3. Observer arrêt automatique après détection variation

**Résultat attendu** :
- Pas d'arrêt dans les 30 premières secondes de chauffe cumulus
- Arrêt quasi-immédiat si appareil démarre après 30s de chauffe

---

### Test 3 : Redémarrage après appareil prioritaire
**Objectif** : Vérifier que le cumulus redémarre après arrêt du lave-linge

**Procédure** :
1. Cumulus en chauffe PV
2. Démarrer lave-linge → cumulus s'arrête
3. Attendre fin cycle lave-linge (30s après détection OFF)
4. Observer redémarrage automatique si PV OK

**Résultat attendu** : Cumulus redémarre automatiquement sans intervention

---

### Test 4 : Détection fin de chauffe thermostat
**Objectif** : Vérifier détection correcte de la coupure thermostat

**Procédure** :
1. Lancer chauffe complète
2. Attendre coupure thermostat (6h environ)
3. Observer dans les logs : chute d'import détectée (~2100W+)
4. Vérifier activation verrou jour

**Résultat attendu** :
- Log : "Thermostat interne coupé détecté (chute import -2100W)"
- `input_boolean.cumulus_verrou_jour` = ON
- Notification envoyée avec bilan

---

## 📝 LOGS À SURVEILLER

### Activation debug (configuration.yaml)
```yaml
logger:
  default: info
  logs:
    homeassistant.components.automation.cumulus_on_pv_automatique: debug
    homeassistant.components.automation.cumulus_arret_si_variation_brutale_import: debug
    homeassistant.components.automation.cumulus_fin_detectee_temperature_max: debug
    homeassistant.components.automation.cumulus_redemarrage_si_appareil_arrete: debug
```

### Signaux d'alerte
- **Boucle ON/OFF** : Contacteur switch change d'état toutes les 30s
- **Faux positifs variation** : Arrêts intempestifs sans appareil tiers
- **Non-détection fin chauffe** : Cumulus continue de tourner après 7h de chauffe
- **Surestimation PV** : Démarrage alors que production réelle < 1500W

---

## 🔧 MAINTENANCE FUTURE

### Améliorations possibles (v2025-11)
1. **Compteur dédié cumulus** : Éliminer le calcul indirect de consommation
2. **Apprentissage machine** : Prédire durée chauffe selon température départ
3. **API météo secondaire** : Combiner Solcast + OpenWeatherMap pour prévisions
4. **Historique énergétique** : Statistiques mensuelles autoconsommation PV

### Évolutions matérielles
- Sonde température ballon DHW (précision ±1°C vs modèle Newton ±5°C)
- Compteur triphasé avec mesure directe cumulus
- Extension SolarBank pour augmenter capacité batterie

---

**Document généré automatiquement le 2025-10-14**
**Auteur** : Claude Code (Anthropic)
**Révision** : 1.0
