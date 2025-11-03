# 📘 SYNTHÈSE COMPLÈTE - Système Cumulus Intelligent

**Date de synthèse :** 2025-11-03
**Branche :** claude/cumulus-markdown-synthesis-011CUkmnAo6nGWQePJ8M6kJ5
**Repository :** LaurentFrx/Home_Assistant

---

## 📚 TABLE DES MATIÈRES

1. [Vue d'ensemble du système](#vue-densemble-du-système)
2. [Évolution chronologique des versions](#évolution-chronologique-des-versions)
3. [Fonctionnalités principales](#fonctionnalités-principales)
4. [Bugs critiques corrigés](#bugs-critiques-corrigés)
5. [Configuration et paramétrage](#configuration-et-paramétrage)
6. [Architecture technique](#architecture-technique)
7. [Interface Lovelace](#interface-lovelace)
8. [Problèmes connus et limitations](#problèmes-connus-et-limitations)
9. [Tests et validation](#tests-et-validation)
10. [Guide de dépannage](#guide-de-dépannage)

---

## 📖 VUE D'ENSEMBLE DU SYSTÈME

Le **Cumulus Intelligent** est un système de gestion automatisée de chauffe-eau électrique optimisé pour maximiser l'autoconsommation photovoltaïque (PV) tout en garantissant la disponibilité d'eau chaude.

### Objectifs principaux

1. **Optimisation solaire** : Chauffer l'eau prioritairement avec production PV
2. **Sécurité approvisionnement** : Garantir eau chaude disponible (chauffe HC si nécessaire)
3. **Évitement heures creuses** : Ne chauffer en HC que si vraiment nécessaire
4. **Économies** : Réduire la consommation en heures pleines réseau

### Composants du système

- **Package cumulus.yaml** : Logique complète du système
- **Automations** : 14+ automations pour gestion automatique
- **Sensors** : 40+ capteurs pour monitoring et décisions
- **Dashboard Lovelace** : Interface utilisateur complète
- **Notifications** : Alertes intelligentes

---

## ⏱️ ÉVOLUTION CHRONOLOGIQUE DES VERSIONS

### Version v2025-10-12a (12 octobre 2025)
**Objectif** : Améliorer la précision du déclenchement PV

**Nouveautés** :
- ✅ Coefficient α_APS configurable (efficacité onduleur)
- ✅ Sensor capacity factor (ratio production actuelle/max)
- ✅ Sensor PV effectif (calcul réel de puissance disponible)
- ✅ Sensor SolarBank disponible
- ✅ Diagnostic automatique refus démarrage

**Impact** : Déclenchement plus conservateur et précis

---

### Version v2025-10-14a (14 octobre 2025)
**Objectif** : Améliorations majeures post-feedback

**Nouveautés** :
- ✅ Démarrage PV progressif (50% seuil si >5h restantes)
- ✅ Détection variation brutale import (+300W)
- ✅ Détection fin chauffe par chute import (-2100W+)

---

### Version v2025-10-14b
**Corrections critiques** :
- 🔴 **BUG CRITIQUE** : Boucle ON/OFF détection variation (CORRIGÉ)
  - Ajout tampon 30s après démarrage
- 🔴 **BUG CRITIQUE** : Redémarrage ineffectif après appareil prioritaire (CORRIGÉ)
  - Ajout switch.turn_on explicite

---

### Version v2025-10-14c
**Harmonisation et protections** :
- ✅ Protection faux positif fin chauffe (3 min minimum)
- ✅ Harmonisation redémarrage avec logique progressive
- ✅ Vérification switch ON pendant chauffe

---

### Version v2025-10-14d
**Corrections bugs critiques identifiés par ChatGPT** :
- 🔴 **BUG CRITIQUE #1** : Condition impossible sur binary_sensor (CORRIGÉ)
  - Utilisation de `last_changed` du switch physique au lieu du binary_sensor
- 🔴 **BUG CRITIQUE #2** : Deadband jamais déclenché (CORRIGÉ)
  - Ajout `timer.start` lors arrêt appareil prioritaire

---

### Version v2025-10-14e
**Améliorations identifiées par Claude** :
- ✅ Protection boot HA (states.get)
- ✅ Seuils configurables UI (conso domestique, variation brutale)
- ✅ Variation brutale robuste (switch direct + amortissement 2s)
- ✅ Logique progressive centralisée (binary_sensor dédié)

**5 points corrigés** :
1. Fragilité calcul consommation indirecte (DOCUMENTÉ)
2. TemplateRuntimeError au boot (CORRIGÉ)
3. Variation brutale trop sensible (CORRIGÉ)
4. Seuils câblés en dur (CORRIGÉ)
5. Duplication logique progressive (REFACTORISÉ)

---

### Version v2025-10-14f
**Finalisation refactoring** :
- ✅ Utilisation complète binary_sensor dans toutes automations
- ✅ Message log avec seuil dynamique
- ✅ Élimination duplication code

---

### Version v2025-10-14g
**Fix critique TemplateRuntimeError** :
- 🔴 **BUG CRITIQUE** : Cast import_avant en float (CORRIGÉ)
  - Variables stockées comme strings nécessitaient cast explicite

---

### Version v2025-10-14h
**Corrections logique redémarrage** :
- 🔴 **TROU LOGIQUE** : Redémarrage universel après deadband (AJOUTÉ)
- ✅ import_avant robuste (calcul direct)

**Nouvelle automation** : `cumulus_redemarrage_apres_deadband`

---

### Version v2025-10-24 (24 octobre 2025)
**6 catégories d'améliorations** :

1. **Sécurité & robustesse**
   - Seuil détection thermostat : 70% → 85%
   - Délai minimum chauffe : 60s → 120s
   - Détection anomalie cohérence

2. **Gestion erreurs entités**
   - Binary sensor validation entités critiques
   - Dépendances automations
   - Alerte entités unavailable

3. **Consolidation deadband**
   - Traçabilité raisons
   - Sensor état deadband
   - Mise à jour automations

4. **Optimisation détection fin chauffe**
   - Durée chauffe temps réel
   - Historique chauffes (10 dernières)
   - Affichage formaté

5. **Monitoring proactif**
   - Sensor santé système (score 0-100%)
   - Alertes automatiques si < 70%

6. **Documentation**
   - Attribut `dernier_evenement` sur 12 sensors

---

### Version v2025-11-08 (8 novembre 2024)
**Fix binary_sensor unavailable** :
- 🔴 **CRITIQUE** : binary_sensor.cumulus_chauffe_reelle unavailable (CORRIGÉ)
- ✅ Ajout sensor.cumulus_consommation_reelle_w
- ✅ Refonte binary_sensor.cumulus_chauffe_reelle
- ✅ Automation "Fin chauffe universelle"
- ✅ Détection incohérences système
- ✅ Fallback fin chauffe en fin HC

---

## 🎯 FONCTIONNALITÉS PRINCIPALES

### 1. Gestion Intelligente Espacement (jusqu'à 50h)

**Entités** :
- `sensor.cumulus_heures_depuis_derniere_chauffe` : Temps écoulé
- `input_number.cumulus_espacement_max_h` : Intervalle max (défaut 50h)
- `binary_sensor.cumulus_besoin_chauffe_urgente` : Alerte dépassement

**Logique** :
- Si délai > 50h → Chauffe urgente même en HC
- Évite manque d'eau chaude

---

### 2. Intégration Solcast (Prévisions Météo)

**Entités** :
- `input_text.cumulus_entity_solcast_today/tomorrow` : Config capteurs
- `sensor.cumulus_solcast_forecast_today/tomorrow` : Prévisions
- `input_number.cumulus_seuil_solcast_bon_kwh` : Seuil bonne journée (8 kWh)
- `binary_sensor.cumulus_meteo_favorable_aujourdhui/demain` : Décision

**Logique** :
- Prévision demain < 8 kWh → Chauffe HC ce soir (sécurité)
- Prévision demain > 8 kWh → Pas de chauffe HC (attente soleil)

---

### 3. Évitement Intelligent Heures Creuses

**Entités** :
- `input_boolean.cumulus_autoriser_hc` : Toggle activation HC
- `binary_sensor.cumulus_autoriser_chauffe_hc_intelligente` : Décision

**Conditions chauffe HC** :
- Besoin urgent (> 50h depuis dernière chauffe) **OU**
- Météo défavorable demain (< 8 kWh prévu)

**Anti-gaspillage** :
- Ne chauffe PAS en HC si déjà chauffé dans la journée

**Scénarios** :

**A - Beau temps** :
```
Lundi 14h : Chauffe PV terminée
Lundi 03h30 : PAS de chauffe HC (13h écoulées + beau temps prévu)
Mardi 12h : Chauffe PV
Économie : 1 chauffe HC évitée
```

**B - Temps couvert** :
```
Lundi 14h : Chauffe PV terminée
Solcast : 3 kWh mardi (mauvais)
Mardi 03h30 : Chauffe HC activée (sécurité)
Résultat : Eau chaude garantie
```

**C - Dépassement 50h** :
```
Lundi 10h : Dernière chauffe
Mardi : Nuageux, pas de chauffe
Mercredi 12h : Dépassement 50h → Chauffe HC garantie
```

---

### 4. Démarrage PV Progressif

**Logique** :
- **>5h restantes** : Démarre à 50% du seuil (optimiste)
- **3-5h restantes** : Démarre à 70% du seuil
- **2-3h restantes** : Démarre à 85% du seuil
- **<2h restantes** : Démarre à 100% du seuil (strict)

**Entité centralisée** : `binary_sensor.cumulus_conditions_pv_ok`

**Avantages** :
- Maximise le temps de chauffe disponible
- Évite d'attendre trop longtemps avec production suffisante
- Devient strict en fin de fenêtre pour garantir fin de chauffe

---

### 5. Détection Variation Brutale Import

**Objectif** : Arrêter temporairement si appareil non déclaré démarre

**Seuil** : +300W (configurable via `input_number.cumulus_seuil_variation_brutale_w`)

**Protections** :
- Tampon 30s après démarrage cumulus (évite boucle ON/OFF)
- Amortissement 2s (filtre pics transitoires)
- Vérification switch direct (pas de dépendance binary_sensor)

**Exemple** :
```
11h30 : Cumulus chauffe (import = 100W)
11h35 : Four démarre (+1500W) → import = 1600W
11h35 : Détection variation +1500W > 300W
11h35 : Amortissement 2s
11h35.2s : Variation confirmée > 240W (80% de 300W)
11h35.2s : Cumulus arrêté, deadband 5min
```

---

### 6. Détection Fin Chauffe Thermostat

**Méthode** : Détection chute import > 2100W

**Protections** :
- Chauffe continue ≥ 3 min (via `last_changed` du switch)
- Switch toujours ON (pas coupé par autre automation)
- Délai confirmation 15s

**Résultat** : Activation `input_boolean.cumulus_verrou_jour`

---

### 7. Estimation Température et Volume

**Modèle thermique** :
- Température départ : 58°C
- Déperdition : 0,3°C/h
- Température min : 20°C

**Entités** :
- `sensor.cumulus_temperature_estimee` : Calcul déperdition
- `sensor.cumulus_litres_disponibles_estimes` : Proportionnel température
- `input_datetime.cumulus_derniere_chauffe_complete` : Horodatage précis

**Mise à jour** : Automatique lors fin chauffe détectée

---

### 8. Système Notifications Intelligent

**Alertes** :
1. **48h sans chauffe** : Si pas de chauffe depuis 48h (hors vacances)
2. **Besoin urgent** : Si espacement max dépassé (hors vacances)
3. **Import anormal** : Si import > 1500W pendant 5 min en chauffe PV
4. **Chauffe terminée** : Confirmation succès avec température et capacité
5. **Incohérence détectée** : Si états contradictoires
6. **Entité unavailable** : Si entité critique passe unavailable pendant chauffe
7. **Santé système dégradée** : Si score < 70%

---

### 9. Monitoring Santé Système

**Entité** : `sensor.cumulus_sante_systeme`

**Score 0-100%** calculé sur :
- **Entités valides** (25 pts) : Toutes entités critiques disponibles
- **Cohérence mesures** (25 pts) : Switch/conso cohérents
- **Espacement chauffes** (25 pts) : Pas de besoin urgent
- **État fonctionnel** (25 pts) : Système opérationnel

**Niveaux** :
- ≥ 90% : Excellent ✅
- 75-89% : Bon ✅
- 50-74% : Moyen ⚠️
- 25-49% : Dégradé ⚠️
- < 25% : Critique 🔴

**Alerte automatique** : Notification si < 70% pendant 5 min

---

### 10. Historique des Chauffes

**Entités** :
- `input_text.cumulus_historique_chauffes` : Stockage (10 dernières)
- `sensor.cumulus_historique_chauffes_display` : Affichage formaté

**Format entrée** : `DD/MM HH:MM - XXmin - XX% PV - Statut`

**Statuts** : "Complète" ou "Interrompue"

**Enregistrement automatique** :
- Début chauffe : Timestamp
- Fin chauffe : Durée, % PV, statut

---

## 🔴 BUGS CRITIQUES CORRIGÉS

### BUG #1 : Boucle ON/OFF détection variation (v2025-10-14b)

**Problème** : L'automation détectait le démarrage du cumulus lui-même (+3000W) et l'arrêtait immédiatement

**Solution** : Tampon 30s sur `binary_sensor.cumulus_chauffe_reelle` avant détection

**Ligne** : 1206-1207

---

### BUG #2 : Redémarrage ineffectif (v2025-10-14b)

**Problème** : L'automation retirait le verrou mais ne redémarrait pas physiquement le cumulus

**Solution** : Ajout `switch.turn_on` explicite avec vérification contacteur OFF

**Ligne** : 1293-1295

---

### BUG #3 : Condition impossible binary_sensor (v2025-10-14d)

**Problème** : `binary_sensor.cumulus_chauffe_reelle` recalcule en temps réel, donc passe à OFF dès que thermostat coupe → condition `for: 3 minutes` jamais vraie

**Solution** : Utilisation `last_changed` du switch physique au lieu du binary_sensor

**Ligne** : 1051-1065

**Impact** : Verrou jour ne s'activait JAMAIS → cumulus pouvait chauffer plusieurs fois par jour

---

### BUG #4 : Deadband jamais déclenché (v2025-10-14d)

**Problème** : Vérification timer deadband ajoutée mais timer jamais démarré lors arrêt

**Solution** : Ajout `timer.start` dans automation arrêt appareil prioritaire

**Ligne** : 1168-1172

**Impact** : Cycles rapides ON/OFF possibles

---

### BUG #5 : TemplateRuntimeError (v2025-10-14g)

**Problème** : Variables déclarées avec `variables:` stockées comme strings → crash lors soustraction `float - str`

**Solution** : Cast explicite `import_avant | float(0)` lors utilisation

**Ligne** : 1347

**Impact** : Automation variation brutale crashait à chaque déclenchement → protection inefficace

---

### BUG #6 : Trou logique redémarrage (v2025-10-14h)

**Problème** : Pas de redémarrage automatique après deadband pour arrêts limiteur/conso/variation/SOC

**Solution** : Nouvelle automation `cumulus_redemarrage_apres_deadband`

**Ligne** : 1437-1492

**Impact** : Perte de plusieurs heures de production solaire après chaque arrêt temporaire

---

### BUG #7 : binary_sensor unavailable (v2025-11-08)

**Problème** : `binary_sensor.cumulus_chauffe_reelle` retournait unavailable au lieu de on/off

**Cause** : Utilisait uniquement sensor import sans calculer consommation réelle cumulus

**Solution** :
- Ajout `sensor.cumulus_consommation_reelle_w` (formule universelle)
- Refonte `binary_sensor.cumulus_chauffe_reelle` (seuil 85%, attributs diagnostic)
- Automation "Fin chauffe universelle"
- Détection incohérences

**Ligne** : 263-376

**Impact** : Chauffe HC non détectée, verrou jour non activé, température pas enregistrée

---

## ⚙️ CONFIGURATION ET PARAMÉTRAGE

### Paramètres principaux

```yaml
# Foyer
cumulus_nb_personnes: 2
cumulus_capacite_litres: 300

# Espacement
cumulus_espacement_max_h: 50  # Chauffe urgente après 50h

# Solcast
cumulus_seuil_solcast_bon_kwh: 8  # Seuil bonne journée

# Heures creuses
cumulus_autoriser_hc: true  # Laisser activé pour sécurité

# Seuils PV
cumulus_seuil_pv_on_w: 100  # Seuil démarrage
cumulus_marge_secu_pv: 1.2  # Marge 20%

# Puissance
cumulus_puissance_w: 3000  # Puissance nominale

# Talon
cumulus_talon_maison_w: 300  # Consommation base

# Deadband
cumulus_deadband_min: 5  # Délai anti-flapping

# Seuils configurables UI (v2025-10-14e)
cumulus_seuil_conso_domestique_w: 200  # Arrêt si conso > talon+200W
cumulus_seuil_variation_brutale_w: 300  # Détection variation >300W

# Coefficient alpha APS (v2025-10-12a)
cumulus_alpha_aps: 0.88  # Efficacité onduleur 88%
```

### Ajustements selon usage

**Consommation élevée** :
- `cumulus_espacement_max_h: 36-40`

**Consommation faible** :
- `cumulus_espacement_max_h: 60-72`

**Région ensoleillée** :
- `cumulus_seuil_solcast_bon_kwh: 10-12`

**Région nuageuse** :
- `cumulus_seuil_solcast_bon_kwh: 5-6`

**Peu d'appareils domestiques** :
- `cumulus_seuil_conso_domestique_w: 150`

**Beaucoup charges variables** :
- `cumulus_seuil_conso_domestique_w: 300`

**Détecter petits appareils** :
- `cumulus_seuil_variation_brutale_w: 200`

**Ignorer appareils < 500W** :
- `cumulus_seuil_variation_brutale_w: 500`

---

### Entités à configurer

```yaml
# Entités critiques (input_text)
cumulus_entity_import_w: sensor.smart_meter_grid_import
cumulus_entity_contacteur: switch.shellypro1_ece334ee1b64
cumulus_entity_soc_solarbank: sensor.system_sanguinet_etat_de_charge_du_sb
cumulus_entity_pv_total: sensor.pv_total_entree_sb_aps_w

# Entités optionnelles (Solcast)
cumulus_entity_solcast_today: sensor.solcast_pv_forecast_previsions_pour_aujourd_hui
cumulus_entity_solcast_tomorrow: sensor.solcast_pv_forecast_previsions_pour_demain

# Appareils prioritaires
cumulus_entity_lave_linge: sensor.lave_linge_power
cumulus_entity_lave_vaisselle: sensor.lave_vaisselle_power
```

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Structure des fichiers

```
/config/
├── packages/
│   └── cumulus.yaml (fichier principal)
├── lovelace/
│   └── dashboard LAU/cumu (vue Lovelace)
├── docs/
│   ├── cumulus_fix_unavailable_2024-11-08.md
│   ├── analyse_fichiers_cumulus.md
│   └── cumulus_improvements_2025-10-24.md
└── packages/ (documentation)
    ├── AMELIORATIONS_v2025-10-14e.md
    ├── BUGS_CRITIQUES_v2025-10-14d.md
    ├── CHANGELOG_cumulus_v2025-10-12a.md
    ├── CORRECTIFS_v2025-10-14c.md
    ├── CORRECTIFS_v2025-10-14f.md
    ├── CORRECTIFS_v2025-10-14g.md
    ├── CORRECTIFS_v2025-10-14h.md
    ├── RISQUES_cumulus_v2025-10-14b.md
    ├── ROLLBACK_cumulus_v2025-10-12a.md
    └── TEST_CHECKLIST_cumulus_v2025-10-12a.md
```

---

### Architecture package cumulus.yaml

**14+ automations** :
1. `cumulus_on_pv_automatique` : Démarrage PV progressif
2. `cumulus_limiteur_import` : Arrêt si import trop élevé
3. `cumulus_securite_soc_bas` : Arrêt si SOC < 5%
4. `cumulus_fin_detectee_temperature_max` : Détection fin chauffe thermostat
5. `cumulus_arret_si_appareil_demarre` : Arrêt si appareil prioritaire
6a. `cumulus_arret_si_conso_domestique_elevee` : Arrêt si conso > talon+seuil
6b. `cumulus_arret_si_variation_brutale_import` : Arrêt si variation > seuil
7a. `cumulus_redemarrage_si_appareil_arrete` : Redémarrage après appareil
7b. `cumulus_redemarrage_apres_deadband` : Redémarrage après timer (v2025-10-14h)
8. `cumulus_fin_chauffe_universelle` : Fin chauffe quelle que soit source (v2025-11-08)
9. `cumulus_fallback_fin_hc` : Fallback si fin chauffe HC ratée (v2025-11-08)
10. `cumulus_notification_incoherence` : Alerte incohérences (v2025-11-08)
11. `cumulus_detection_anomalie_coherence` : Alerte anomalie switch/conso
12. `cumulus_alerte_entite_unavailable_chauffe` : Alerte entité unavailable
13. `cumulus_enregistrement_debut_chauffe` : Enregistrement historique
14. `cumulus_alerte_sante_systeme_degradee` : Alerte santé < 70%

**40+ sensors** :
- Import/Export réseau
- Consommation réelle cumulus
- PV total, APS, SolarBank
- Puissance disponible, seuil dynamique
- Fenêtre PV (début, fin, durée)
- Température estimée, litres disponibles
- Heures depuis dernière chauffe
- Solcast prévisions aujourd'hui/demain
- Capacity factor, PV effectif
- État deadband, durée chauffe actuelle
- Historique chauffes, santé système

**15+ binary_sensors** :
- Fenêtre PV active
- En heures creuses
- Appareil prioritaire actif
- Chauffe réelle détectée
- Conditions PV OK (logique progressive)
- Méteo favorable aujourd'hui/demain
- Autoriser chauffe HC intelligente
- Besoin chauffe urgente
- Entités OK (validation)
- État cohérent (détection incohérences)

**25+ input helpers** :
- Booleans : interdit, override, vacances, verrous
- Numbers : seuils, puissances, SOC, espacement, seuils UI
- Datetimes : heures creuses, dernière chauffe, début chauffe actuelle
- Texts : entités configurables, raison deadband, historique
- Select : mode chauffe (solarbank/aps)

**1 timer** :
- `cumulus_deadband_ui` : Anti-flapping configurable

---

### Formule calcul consommation réelle

**Formule universelle** :
```
Conso_cumulus = (Import_réseau + PV_total) - Talon_maison
```

**Bornes** : Entre 0 et puissance_max (3000W)

**Exemples** :

| Cas | Import | PV | Talon | Conso cumulus |
|-----|--------|-----|-------|---------------|
| 100% réseau | 3300W | 0W | 300W | 3000W ✅ |
| 100% PV | -2700W | 3000W | 300W | 3000W ✅ |
| Mixte | 1500W | 1800W | 300W | 3000W ✅ |
| Cumulus OFF | 300W | 0W | 300W | 0W ✅ |
| Export | -500W | 800W | 300W | 0W ✅ |

**Limitation connue** : Sensible aux variations du talon domestique (voir section Problèmes connus)

---

## 🎨 INTERFACE LOVELACE

### Carte cumulus complète (lovelace_carte_cumulus.yaml)

**Sections** :

1. **En-tête dynamique**
   - Titre avec capacité et nombre de personnes

2. **Statut temps réel (chips)**
   - État chauffe (🔥/💤) avec couleur dynamique
   - Température estimée (rouge/orange/bleu)
   - Litres disponibles (vert/orange/rouge)
   - Heures depuis dernière chauffe avec alerte

3. **Jauge température**
   - Gauge visuelle 20-60°C avec zones couleur

4. **Graphique historique 48h**
   - Température eau (rouge)
   - Production PV (jaune, axe secondaire)
   - Import réseau (bleu, axe secondaire)
   - Ligne animée, 2 points/heure

5. **Météo & prévisions**
   - Prévision Solcast aujourd'hui/demain
   - Couleur dynamique selon seuil

6. **Contrôles rapides**
   - Override, Interdit, Vacances
   - Autoriser HC, Besoin urgent, Temp atteinte
   - Boutons tactiles avec icônes dynamiques

7. **Données techniques**
   - Import, Production PV, SOC batterie
   - Puissance cumulus
   - Seuils calculés
   - Dernière chauffe

8. **Configuration complète**
   - Tous inputs modifiables
   - Organisés par catégorie

9. **Fenêtres horaires**
   - Plages PV et HC
   - Indicateurs actifs

10. **Logique intelligente**
    - Tous binary sensors
    - Statuts temps réel

**Dépendances HACS** :
- `custom:mushroom-title-card`
- `custom:mushroom-chips-card`
- `custom:mushroom-entity-card`
- `custom:mini-graph-card`

---

### Changelog Vue LAU/cumu

**2025-10-29** :
- ✅ Ajout section Prévisions Solaires
- ✅ Cartes Solcast aujourd'hui/demain
- ✅ Modification manuelle dernière chauffe

**2025-10-29b** :
- ✅ Ajout input_datetime.cumulus_derniere_chauffe_complete
- ✅ Affichage éditable dans dashboard

---

## ⚠️ PROBLÈMES CONNUS ET LIMITATIONS

### 1. Calcul consommation indirect (STRUCTUREL)

**Gravité** : 🟠 MAJEUR

**Problème** :
- Formule `(Import + PV) - Talon` suppose talon constant (300W)
- Charges variables (pompe, VMC, frigo) font varier le talon réel de ±200W

**Impact** :
- Consommation cumulus mal évaluée
- Faux positifs/négatifs détection chauffe

**Solutions alternatives** :
1. **Compteur dédié** : Shelly EM sur circuit cumulus (~60€) - IDÉAL
2. **Talon adaptatif** : Calculer talon moyen 5 min hors chauffe
3. **Fenêtre glissante** : Filtrer variations < 10s

**Action** : Surveiller logs `binary_sensor.cumulus_chauffe_reelle` pendant 1 semaine

**Statut** : DOCUMENTÉ, non résolu

---

### 2. Modèle thermique simplifié

**Gravité** : 🟡 MINEUR

**Problème** :
- Déperdition fixe 0,3°C/h (moyenne)
- Réel dépend de l'isolation du ballon

**Impact** :
- Température estimée peut être incohérente (±5°C)

**Ajustement** :
- Cumulus bien isolé : 0,2°C/h
- Cumulus ancien : 0,4°C/h
- Modifier ligne 593-606 du package

**Solution idéale** : Sonde température physique

---

### 3. Sensor besoin urgent absent (v2025-11-08)

**Gravité** : ℹ️ INFO

**Contexte** :
- Version v2025-11-08 simplifie le package
- `binary_sensor.cumulus_besoin_chauffe_urgente` n'existe PAS

**Impact** :
- `binary_sensor.cumulus_etat_coherent` vérifie si sensor existe avant utilisation
- Pas d'incohérence détectée si sensor absent

**Correction** : Ligne 183 (vérification existence sensor)

---

### 4. Limitation redémarrage (CORRIGÉ v2025-10-14h)

**Gravité** : 🔴 CRITIQUE (CORRIGÉ)

**Problème** : Pas de redémarrage automatique après deadband pour arrêts limiteur/conso/variation/SOC

**Solution** : Nouvelle automation `cumulus_redemarrage_apres_deadband`

**Statut** : ✅ CORRIGÉ

---

### 5. Template for: compatibilité HA

**Gravité** : 🟡 MINEUR

**Prérequis** : Home Assistant 2024.6+

**Ligne** : 875 (trigger avec `for:` template)

**Action** : Vérifier version HA avec `ha core info`

**Si version < 2024.6** : Remplacer par valeur fixe

---

## ✅ TESTS ET VALIDATION

### Tests critiques recommandés

#### Test 1 : Détection chauffe réelle
1. Activer contacteur manuellement
2. Vérifier `binary_sensor.cumulus_chauffe_reelle` → ON
3. Consulter attribut `consommation_w`
4. Vérifier `all_sources_available` = true

#### Test 2 : Fin chauffe HC
1. Attendre début HC (03:30)
2. Vérifier cumulus se met en chauffe
3. Attendre température max (thermostat coupe)
4. Vérifier automation "Fin chauffe universelle" se déclenche après 120s
5. Vérifier `input_boolean.cumulus_verrou_jour` → ON

#### Test 3 : Détection incohérence
1. Forcer `input_boolean.cumulus_verrou_jour` → ON
2. Si besoin urgent existe et ON : vérifier alerte
3. Vérifier `binary_sensor.cumulus_etat_coherent` → ON
4. Vérifier notification persistante
5. Consulter attribut `details`

#### Test 4 : Fallback fin HC
1. Démarrer chauffe manuelle pendant HC
2. Laisser HC se terminer (08:05)
3. Vérifier fallback vérifie température atteinte
4. Vérifier activation verrou si OK

#### Test 5 : Redémarrage après deadband (v2025-10-14h)
1. Démarrer cumulus mode PV
2. Déclencher arrêt limiteur
3. Observer deadband 5 min
4. Vérifier redémarrage automatique après timer

#### Test 6 : Variation brutale robuste
1. Démarrer cumulus mode PV
2. Attendre 30s (sortie tampon)
3. Allumer four/bouilloire (>300W)
4. Vérifier détection après 2s
5. Vérifier arrêt si variation confirmée

---

### Checklist validation déploiement (v2025-10-12a)

**Tests pré-déploiement** :
- [ ] Configuration YAML valide
- [ ] Backup créé et vérifié

**Tests post-déploiement** :
- [ ] Entités créées (alpha_aps, capacity_factor, pv_effectif, sb_dispo)
- [ ] Automations actives (on_pv_simple, log_refus_demarrage)
- [ ] Sensors affichent valeurs cohérentes

**Tests fonctionnels** :
- [ ] Capacity factor cohérent
- [ ] PV effectif ≤ PV brut
- [ ] SolarBank disponible logique
- [ ] Démarrage PV (simulation)
- [ ] Log refus démarrage

**Tests robustesse** :
- [ ] Comportement entité manquante
- [ ] Modification alpha_aps réactive

**Tests régression** :
- [ ] Automations héritées fonctionnent
- [ ] Sensors thermiques OK
- [ ] Notifications OK

**Tests conditions réelles** :
- [ ] Journée complète PV
- [ ] Journée nuageuse

---

## 🔧 GUIDE DE DÉPANNAGE

### Cumulus ne chauffe plus en HC

**Cause** : Logique d'évitement active

**Vérifier** :
- `binary_sensor.cumulus_autoriser_chauffe_hc_intelligente` = OFF ?
- Si oui : heures depuis dernière < 50h ET météo favorable demain

**Solution** :
- Activer `input_boolean.cumulus_override`
- OU attendre besoin urgent (>50h)
- OU modifier `cumulus_espacement_max_h` (réduire à 36h)

---

### binary_sensor.cumulus_chauffe_reelle toujours unavailable

**Vérifications** :
1. `sensor.cumulus_consommation_reelle_w` existe et a valeur ?
2. `input_number.cumulus_puissance_w` existe (défaut 3000) ?
3. `input_text.cumulus_entity_contacteur` pointe vers bon switch ?
4. Consulter attribut `all_sources_available`

**Causes possibles** :
- `sensor.cumulus_import_reseau_w` = unavailable
- `sensor.cumulus_pv_power_w` = unavailable
- Contacteur en unknown/unavailable

**Solution** : Vérifier attributs `import_w`, `pv_total_w`, `talon_w`

---

### Température estimée incohérente

**Cause** : Modèle simplifié de déperdition

**Ajustement** :
- Cumulus bien isolé : 0,2°C/h (modifier ligne 593)
- Cumulus ancien : 0,4°C/h

**Solution idéale** : Sonde température physique

---

### Pas de notifications

**Vérifier** :
- Service `persistent_notification` activé
- Pas en mode vacances (bloque alertes)
- Notifications visibles panneau latéral HA

---

### Consommation réelle à 0 alors que cumulus chauffe

**Causes** :
1. `sensor.cumulus_import_reseau_w` = unavailable
2. `sensor.cumulus_pv_power_w` = unavailable
3. Contacteur unknown/unavailable
4. Formule `(Import + PV) - Talon` négative

**Solution** : Vérifier attributs du sensor consommation_reelle_w

---

### Fin chauffe non détectée

**Vérifications** :
1. `binary_sensor.cumulus_chauffe_reelle` était ON pendant chauffe ?
2. Timestamp `last_changed` du binary_sensor ?
3. Logs automation `cumulus_fin_chauffe_universelle` ?
4. Si échec : fallback `cumulus_fallback_fin_hc` devrait fonctionner

---

### Redémarrage ne fonctionne pas après deadband

**Vérifier** :
- Version ≥ v2025-10-14h (automation ajoutée)
- Timer deadband terminé (`idle`)
- `binary_sensor.cumulus_conditions_pv_ok` = ON
- SOC ≥ seuil minimum
- Pas de mode interdit/vacances/verrou

---

### Santé système < 70%

**Consulter** :
- `sensor.cumulus_sante_systeme`
- Attributs `evaluation_*` pour détails

**Causes fréquentes** :
- Entités unavailable
- Incohérence switch/conso
- Besoin urgent actif
- Système non fonctionnel

---

## 📚 RÉFÉRENCES DOCUMENTATION

### Fichiers principaux

**Configuration** :
- `packages/cumulus.yaml` : Configuration complète
- `lovelace_carte_cumulus.yaml` : Interface utilisateur

**Documentation versions** :
- `CHANGELOG_cumulus_v2025-10-12a.md` : Changelog v2025-10-12a
- `AMELIORATIONS_v2025-10-14e.md` : Améliorations v2025-10-14e
- `CORRECTIFS_v2025-10-14c.md` : Correctifs critiques v2025-10-14c
- `CORRECTIFS_v2025-10-14f.md` : Finalisation refactoring
- `CORRECTIFS_v2025-10-14g.md` : Fix TemplateRuntimeError
- `CORRECTIFS_v2025-10-14h.md` : Corrections redémarrage
- `BUGS_CRITIQUES_v2025-10-14d.md` : Bugs critiques ChatGPT
- `cumulus_fix_unavailable_2024-11-08.md` : Fix binary_sensor
- `cumulus_improvements_2025-10-24.md` : 6 améliorations

**Analyse** :
- `RISQUES_cumulus_v2025-10-14b.md` : Analyse des risques
- `analyse_fichiers_cumulus.md` : Analyse versions multiples

**Procédures** :
- `TEST_CHECKLIST_cumulus_v2025-10-12a.md` : Tests validation
- `ROLLBACK_cumulus_v2025-10-12a.md` : Procédure rollback

**Interface** :
- `CHANGELOG_LAU_CUMU.md` : Changelog Lovelace

**Modifications spécifiques** :
- `MODIFICATION_DERNIERE_CHAUFFE.md` : Modification manuelle date

---

## 🎯 RÉSUMÉ EXÉCUTIF

Le **Système Cumulus Intelligent** est un package Home Assistant mature et robuste qui optimise la chauffe d'eau chaude sanitaire en maximisant l'autoconsommation solaire tout en garantissant la disponibilité d'eau chaude.

**Points forts** :
- ✅ 7 versions correctives (v2025-10-14a à h) avec corrections bugs critiques
- ✅ Logique progressive centralisée (binary_sensor dédié)
- ✅ Détection intelligente fin chauffe (protection faux positifs)
- ✅ Redémarrage universel après deadband
- ✅ 40+ sensors, 14+ automations, monitoring complet
- ✅ Interface Lovelace complète
- ✅ Système notifications intelligent
- ✅ Score santé 0-100%
- ✅ Historique 10 dernières chauffes

**Limitations connues** :
- ⚠️ Calcul consommation indirect (solution : compteur dédié)
- ⚠️ Modèle thermique simplifié (solution : sonde température)

**Version actuelle recommandée** : v2025-10-14h ou v2025-11-08 (selon besoin modèle thermique)

**Prochaines évolutions** :
- Compteur dédié cumulus (éliminer calcul indirect)
- Sonde température physique (éliminer modèle Newton)
- Machine learning durée chauffe
- Intégration météo secondaire
- Statistiques énergétiques

---

**Document créé le 2025-11-03**
**Basé sur l'analyse de 16 fichiers markdown**
**Repository :** github.com/LaurentFrx/Home_Assistant
