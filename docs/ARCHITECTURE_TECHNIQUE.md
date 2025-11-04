# 🏗️ Architecture Technique - Cumulus Intelligent

**Version :** 1.0
**Pour :** Comprendre le fonctionnement interne
**Niveau :** Technique

---

## 📐 VUE D'ENSEMBLE
```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTÈME CUMULUS INTELLIGENT               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   CAPTEURS   │  │  DÉCISIONS   │  │   ACTIONS    │     │
│  │              │  │              │  │              │     │
│  │ • Import     │→ │ • Conditions │→ │ • Contacteur │     │
│  │ • PV         │  │   PV OK      │  │ • Verrous    │     │
│  │ • SOC        │  │ • Autoriser  │  │ • Timers     │     │
│  │ • Météo      │  │   HC         │  │              │     │
│  │ • Temps      │  │ • Besoins    │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              AUTOMATIONS (14+)                        │  │
│  │  Démarrage PV • Arrêts protections • Détection fin  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧩 COMPOSANTS PRINCIPAUX

### 1. Sensors (40+)

#### Sensors de mesure bruts
```yaml
sensor.cumulus_import_reseau_w:
  # Source : Compteur Linky ou Shelly EM
  # Valeur : -3000 à +6000W
  # Usage : Calculer consommation réelle

sensor.cumulus_pv_power_w:
  # Source : Onduleur (APS ou SolarBank selon mode)
  # Valeur : 0 à 4000W
  # Usage : Calculer puissance disponible
```

#### Sensors calculés critiques
```yaml
sensor.cumulus_consommation_reelle_w:
  # Formule : (Import + PV) - Talon
  # Bornes : 0 à 3000W
  # Usage : Détecter si cumulus chauffe
  # Template :
  value_template: >
    {% set import_w = states('sensor.cumulus_import_reseau_w') | float(0) %}
    {% set pv_w = states('sensor.cumulus_pv_power_w') | float(0) %}
    {% set talon = states('input_number.cumulus_talon_maison_w') | float(300) %}
    {% set conso = (import_w + pv_w) - talon %}
    {% set puissance_max = states('input_number.cumulus_puissance_w') | float(3000) %}
    {{ [0, [conso, puissance_max] | min] | max }}

sensor.cumulus_pv_disponible_w:
  # Formule : (PV × marge_secu) - talon
  # Usage : Décider démarrage PV
  # Marge sécurité : 1.2 (défaut)

sensor.cumulus_seuil_dynamique_w:
  # Formule : Progressif selon heure
  # >5h restantes : 50% du seuil
  # 3-5h : 70%
  # 2-3h : 85%
  # <2h : 100%
  # Usage : Optimiser fenêtre PV
```

#### Sensors de monitoring
```yaml
sensor.cumulus_temperature_estimee:
  # Modèle thermique Newton
  # Départ : 58°C après chauffe
  # Déperdition : -0.3°C/h
  # Min : 20°C
  # Attributs : heures_depuis_chauffe, deperdition

sensor.cumulus_heures_depuis_derniere_chauffe:
  # Calcul : now() - derniere_chauffe
  # Format : X.X heures
  # Usage : Détecter besoin urgent

sensor.cumulus_sante_systeme:
  # Score : 0-100%
  # 4 composantes × 25 pts :
  #   - Entités valides
  #   - Cohérence mesures
  #   - Espacement OK
  #   - Fonctionnement OK
```

---

### 2. Binary Sensors (15+)

#### Binary sensors de décision
```yaml
binary_sensor.cumulus_conditions_pv_ok:
  # Centralise TOUTE la logique démarrage PV
  # Conditions :
  # 1. Fenêtre PV active
  # 2. PV disponible > seuil dynamique
  # 3. SOC > seuil minimum
  # 4. Pas en deadband
  # 5. Pas de mode bloquant
  # 6. Pas de verrou jour
  # Usage : Déclencheur principal automation démarrage

binary_sensor.cumulus_chauffe_reelle:
  # Détecte si cumulus chauffe réellement
  # Méthode : Consommation > 85% puissance nominale
  # Seuil : 2550W (pour 3000W nominal)
  # Attributs : consommation_w, seuil_detection_w, all_sources_available
  # Template :
  state: >
    {% set conso = states('sensor.cumulus_consommation_reelle_w') | float(0) %}
    {% set puissance = states('input_number.cumulus_puissance_w') | float(3000) %}
    {% set seuil = puissance * 0.85 %}
    {{ conso > seuil }}

binary_sensor.cumulus_autoriser_chauffe_hc_intelligente:
  # Logique évitement HC
  # Autorise HC si :
  #   - Besoin urgent (>50h) OU
  #   - Météo défavorable demain
  # Bloque si déjà chauffé aujourd'hui
```

#### Binary sensors de surveillance
```yaml
binary_sensor.cumulus_etat_coherent:
  # Détecte incohérences logiques
  # Exemples :
  #   - Verrou + Besoin urgent simultanés
  #   - Override + Interdit simultanés
  #   - Switch ON mais consommation nulle
  # Attributs : coherent, details, anomalies

binary_sensor.cumulus_entites_ok:
  # Valide disponibilité entités critiques
  # Liste : contacteur, import, PV, SOC
  # Attributs : all_ok, entites_manquantes
```

---

### 3. Input Helpers (25+)

#### Input booleans (contrôles)
```yaml
input_boolean.cumulus_override:
  # Force chauffe immédiate ignorant toute logique

input_boolean.cumulus_interdit:
  # Bloque toute chauffe (maintenance)

input_boolean.cumulus_vacances:
  # Désactive alertes + autorisations HC

input_boolean.cumulus_verrou_jour:
  # Empêche 2e chauffe même jour
  # S'active après fin chauffe détectée
  # Se réinitialise à minuit
```

#### Input numbers (paramètres)
```yaml
input_number.cumulus_seuil_pv_on_w:
  # Seuil démarrage mode PV
  # Défaut : 100W
  # Range : 0-500W

input_number.cumulus_espacement_max_h:
  # Délai max sans chauffe
  # Défaut : 50h
  # Range : 24-120h

input_number.cumulus_seuil_variation_brutale_w:
  # Détection appareil démarré
  # Défaut : 300W
  # Configurable UI (v2025-10-14e)
```

#### Input datetimes (traçabilité)
```yaml
input_datetime.cumulus_derniere_chauffe_complete:
  # Horodatage précis dernière chauffe
  # Usage : Calcul température, espacement

input_datetime.cumulus_debut_chauffe_actuelle:
  # Timestamp début chauffe en cours
  # Usage : Calcul durée, historique
```

---

### 4. Automations (14+)

#### Groupe A : Démarrage
```yaml
automation.cumulus_on_pv_automatique:
  # Trigger : binary_sensor.cumulus_conditions_pv_ok passe à ON
  # Action :
  #   1. Vérifier contacteur OFF
  #   2. switch.turn_on
  #   3. Enregistrer début chauffe

automation.cumulus_on_hc_intelligent:
  # Trigger : Début HC (03:30) + conditions
  # Conditions :
  #   - binary_sensor.cumulus_autoriser_chauffe_hc_intelligente = ON
  #   - Pas de verrou jour
  # Action : switch.turn_on + log
```

#### Groupe B : Arrêts de protection
```yaml
automation.cumulus_limiteur_import:
  # Trigger : Import > 1500W pendant 5 min
  # Action : Arrêt + log "limiteur"

automation.cumulus_securite_soc_bas:
  # Trigger : SOC < 5%
  # Action : Arrêt + log "SOC critique"

automation.cumulus_arret_si_appareil_demarre:
  # Trigger : Appareil prioritaire > 100W
  # Appareils : lave-linge, lave-vaisselle
  # Action : Arrêt + deadband 5 min

automation.cumulus_arret_si_variation_brutale_import:
  # Trigger : Import augmente > seuil en 2s
  # Protection : Tampon 30s après démarrage cumulus
  # Action : Arrêt + deadband + log raison
```

#### Groupe C : Redémarrages
```yaml
automation.cumulus_redemarrage_si_appareil_arrete:
  # Trigger : Appareil prioritaire < 100W
  # Conditions : Conditions PV toujours OK
  # Action :
  #   1. Retirer verrou deadband
  #   2. switch.turn_on (explicite)

automation.cumulus_redemarrage_apres_deadband:
  # Trigger : Timer deadband → idle
  # Conditions : Conditions PV OK + autorisation
  # Action : Redémarrage universel
  # Raisons : limiteur, conso, variation, SOC
  # Ajout : v2025-10-14h (corrige trou logique)
```

#### Groupe D : Détection fin chauffe
```yaml
automation.cumulus_fin_chauffe_universelle:
  # Trigger : binary_sensor.cumulus_chauffe_reelle passe OFF
  # Conditions :
  #   - Était ON pendant ≥ 120s (filtre faux positifs)
  #   - Switch contacteur toujours ON (pas arrêt automation)
  # Délai : 15s confirmation
  # Action :
  #   1. Activer verrou_jour
  #   2. Enregistrer derniere_chauffe_complete
  #   3. Mettre à jour historique
  #   4. Notification succès

automation.cumulus_fallback_fin_hc:
  # Trigger : Fin HC (08:05)
  # Conditions : Cumulus était en chauffe HC
  # Action : Vérifier température, activer verrou si OK
  # Usage : Sécurité si détection universelle rate
```

#### Groupe E : Monitoring
```yaml
automation.cumulus_notification_incoherence:
  # Trigger : binary_sensor.cumulus_etat_coherent = OFF
  # Délai : 2 min (filtre transitoires)
  # Action : Notification persistante + détails

automation.cumulus_alerte_sante_systeme_degradee:
  # Trigger : sensor.cumulus_sante_systeme < 70%
  # Délai : 5 min
  # Action : Notification + détails composantes
```

---

## 🔄 FLUX DE DÉCISION DÉTAILLÉ

### Scénario A : Démarrage PV classique
```
11h00 : Production solaire augmente
  ↓
11h15 : PV dispo = 3500W > seuil (progressif 150W car >5h restantes)
  ↓
binary_sensor.cumulus_conditions_pv_ok passe ON
  ↓
automation.cumulus_on_pv_automatique se déclenche
  ↓
Vérifications :
  ✓ SOC = 60% (>5%)
  ✓ Pas de deadband actif
  ✓ Pas de verrou jour
  ✓ Contacteur actuellement OFF
  ↓
Action : switch.turn_on
  ↓
Enregistrement : debut_chauffe_actuelle = 11h15
  ↓
11h16 : binary_sensor.cumulus_chauffe_reelle = ON (conso 2950W)
```

### Scénario B : Arrêt variation brutale
```
11h30 : Cumulus chauffe depuis 15 min
  ↓
11h31 : Utilisateur allume four (1800W)
  ↓
Import passe de -200W à +1600W en 2s
  ↓
Variation = +1800W > seuil (300W)
  ↓
Protection tampon : Chauffe depuis 15 min > 30s ✓
  ↓
Amortissement 2s : Variation confirmée après 2s
  ↓
automation.cumulus_arret_si_variation_brutale se déclenche
  ↓
Actions :
  1. switch.turn_off
  2. timer.cumulus_deadband_ui.start (5 min)
  3. input_text.cumulus_raison_deadband = "variation_brutale"
  4. Log détails
  ↓
11h31 : Cumulus arrêté, attente 5 min
```

### Scénario C : Redémarrage après deadband
```
11h36 : Timer deadband arrive à idle (5 min écoulés)
  ↓
automation.cumulus_redemarrage_apres_deadband se déclenche
  ↓
Vérifications :
  ✓ binary_sensor.cumulus_conditions_pv_ok = ON
  ✓ SOC toujours > 5%
  ✓ Pas de mode interdit/vacances
  ✓ Contacteur actuellement OFF
  ↓
Actions :
  1. Retirer verrou deadband (si existait)
  2. switch.turn_on (explicite)
  3. Log "Redémarrage après deadband (variation_brutale)"
  ↓
11h36 : Cumulus redémarre
  ↓
Nouveau cycle commence
```

### Scénario D : Fin chauffe thermostat
```
13h45 : Thermostat cumulus atteint 60°C → coupe résistance
  ↓
13h45.5s : Consommation chute 2950W → 0W
  ↓
13h45.5s : binary_sensor.cumulus_chauffe_reelle passe OFF
  ↓
automation.cumulus_fin_chauffe_universelle évalue conditions :
  ✓ binary_sensor était ON pendant ≥ 120s (2h30 > 2 min)
  ✓ switch.contacteur toujours ON (pas arrêt automation)
  ↓
Délai 15s : Confirmation fin chauffe pas transitoire
  ↓
13h46 : Actions
  1. input_boolean.cumulus_verrou_jour = ON
  2. input_datetime.cumulus_derniere_chauffe_complete = 13h46
  3. Mise à jour historique (durée 2h31, 95% PV)
  4. Notification "Chauffe terminée : 55°C, 275L"
  ↓
13h46 : Système en veille jusqu'à minuit (verrou actif)
```

### Scénario E : Évitement HC intelligent
```
Mardi 21h00 : Dernière chauffe = Mardi 13h (8h écoulées)
  ↓
Vérifications :
  - Heures depuis chauffe = 8h < 50h (pas urgent)
  - Solcast demain = 11 kWh > 8 kWh (bon)
  ↓
binary_sensor.cumulus_autoriser_chauffe_hc_intelligente = OFF
  ↓
Mercredi 03h30 : Début HC
  ↓
automation.cumulus_on_hc_intelligent évalue :
  ✗ Autorisation HC = OFF
  ↓
Pas de démarrage HC → Économie 1 chauffe
  ↓
Mercredi 11h : Chauffe PV comme prévu
  ↓
Résultat : 0€ HC évité, eau chaude garantie
```

---

## 🔧 FORMULES ET CALCULS CLÉS

### Consommation réelle cumulus
```python
conso = max(0, min((import + pv_total) - talon, puissance_max))

# Exemples :
# 100% réseau : (3300 + 0) - 300 = 3000W ✓
# 100% PV : (-2700 + 3000) - 300 = 0W → Mais talon réel variable !
# Mixte : (1500 + 1800) - 300 = 3000W ✓
```

**Limitation** : Formule indirecte sensible aux variations du talon

### Puissance PV disponible
```python
pv_dispo = (pv_total × marge_secu) - talon

# Exemple :
# PV = 3500W, marge = 1.2, talon = 300W
# Dispo = (3500 × 1.2) - 300 = 3900W
```

### Seuil dynamique progressif
```python
heures_restantes = (fin_fenetre_pv - now()).hours

if heures_restantes > 5:
    coef = 0.5  # Optimiste
elif heures_restantes > 3:
    coef = 0.7
elif heures_restantes > 2:
    coef = 0.85
else:
    coef = 1.0  # Strict

seuil_dynamique = seuil_base × coef
```

### Température estimée (Newton)
```python
t_elapsed = (now - derniere_chauffe).hours
t_actuelle = max(20, 58 - (deperdition × t_elapsed))

# Exemple :
# Dernière chauffe = il y a 24h
# T = max(20, 58 - (0.3 × 24)) = 50.8°C
```

### Score santé système
```python
score = 0

# Entités valides (25 pts)
if all_critical_entities_available:
    score += 25

# Cohérence mesures (25 pts)
if switch == ON and consommation > 2000W:
    score += 25
elif switch == OFF and consommation < 100W:
    score += 25

# Espacement OK (25 pts)
if heures_depuis_chauffe < 50:
    score += 25

# Fonctionnement OK (25 pts)
if not (interdit or deadband_actif or besoin_urgent):
    score += 25

return score  # 0-100%
```

---

## 🎨 DIAGRAMME ÉTATS
```
┌─────────────────────────────────────────────────────────────┐
│                      MACHINE À ÉTATS                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│         ┌──────────┐                                        │
│    ┌───│  VEILLE  │◄─────────┐                            │
│    │   └──────────┘           │                            │
│    │        │                  │                            │
│    │   Conditions PV OK       │ Verrou jour                │
│    │        │                  │ (minuit reset)            │
│    ▼        ▼                  │                            │
│ ┌──────────────┐               │                            │
│ │CHAUFFE EN    │               │                            │
│ │  COURS (PV)  │───Fin─────────┤                            │
│ └──────────────┘  détectée     │                            │
│    │        ▲                   │                            │
│    │Arrêt   │Redémarrage       │                            │
│    │protect.│après deadband    │                            │
│    ▼        │                   │                            │
│ ┌──────────────┐               │                            │
│ │  DEADBAND    │───────────────┘                            │
│ │   (5 min)    │                                            │
│ └──────────────┘                                            │
│                                                              │
│  Transitions spéciales :                                    │
│  • Override → Force CHAUFFE                                 │
│  • Interdit → Force VEILLE                                  │
│  • HC matin → CHAUFFE si conditions                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 DÉPENDANCES ENTRE ENTITÉS

### Hiérarchie de dépendance
```
Niveau 1 (Sources brutes) :
├─ switch.contacteur (Shelly)
├─ sensor.import_reseau (Linky/Shelly EM)
├─ sensor.pv_total (Onduleur)
└─ sensor.soc_solarbank (Anker)

Niveau 2 (Calculs primaires) :
├─ sensor.cumulus_consommation_reelle_w
│   └─ Dépend : import, pv_total, talon
├─ sensor.cumulus_pv_disponible_w
│   └─ Dépend : pv_total, talon, marge_secu
└─ binary_sensor.cumulus_chauffe_reelle
    └─ Dépend : consommation_reelle_w, puissance

Niveau 3 (Décisions) :
├─ binary_sensor.cumulus_conditions_pv_ok
│   └─ Dépend : pv_disponible, seuil, SOC, fenetre_pv
└─ binary_sensor.cumulus_autoriser_chauffe_hc
    └─ Dépend : espacement, meteo, verrou_jour

Niveau 4 (Actions) :
└─ automations
    └─ Dépendent : binary_sensors décisions
```

**Implication** : Si `sensor.import_reseau` unavailable → Cascade échecs jusqu'aux automations

---

## 🔍 POINTS D'ATTENTION ARCHITECTURE

### 1. Calcul indirect consommation

**Problème structurel** :
```python
conso = (import + pv) - talon
# Suppose talon constant (300W)
# Réel : talon oscille 100-500W
```

**Impact** :
- Faux positifs/négatifs détection chauffe
- Difficile à corriger sans compteur dédié

**Mitigations actuelles** :
- Seuil détection 85% (au lieu de 90%)
- Binary sensor avec attributs diagnostics
- Monitoring cohérence

### 2. Logique progressive centralisée

**Évolution v2025-10-14e** :
- Avant : Logique dupliquée dans chaque automation
- Après : `binary_sensor.cumulus_conditions_pv_ok` unique

**Avantages** :
- Maintenance simplifiée
- Cohérence garantie
- Traçabilité (attributs détaillés)

### 3. Gestion deadband

**Système anti-flapping** :
- Timer unique configurable (5 min défaut)
- Raison stockée (diagnostics)
- Redémarrage universel après timer

**Protège contre** :
- ON/OFF rapides (usure contacteur)
- Cycles infinis (bugs logique)

---

## 🚀 EXTENSIBILITÉ

### Points d'extension prévus

**1. Scoring opportunité** (Évolution future)
```yaml
sensor.cumulus_score_opportunite_pv:
  # Remplacera binary_sensor.cumulus_conditions_pv_ok
  # Score 0-100 au lieu de ON/OFF
  # Poids configurables par critère
```

**2. Machine learning durée**
```yaml
sensor.cumulus_duree_predite:
  # Analyse historique 10 chauffes
  # Adapte démarrage selon durée prévue
```

**3. Multi-sources météo**
```yaml
binary_sensor.cumulus_meteo_consensus:
  # Croise Solcast + Open-Meteo + historique
  # Décision si 2/3 d'accord
```

---

**🎯 Architecture mature, robuste, évolutive - Prête pour intelligence avancée**
