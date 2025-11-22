# ÉTAT ACTUEL DU SYSTÈME - Home Assistant

**Date de mise à jour:** 2025-11-22
**Branche:** claude/list-apply-markdown-01L8pT1nxS6Y6XDPKiyADRas
**Version système:** 2.0 (architecture modulaire)

---

## 📊 SYNTHÈSE RAPIDE

### Statut Global: ✅ OPÉRATIONNEL - Architecture Modulaire

**Changements majeurs au 2025-11-22:**
- ✅ Architecture modulaire complète dans `packages/cumulus/`
- ✅ Ancien fichier monolithique archivé
- ✅ Cartes Lovelace nettoyées (2 cartes actives au lieu de 7)
- ✅ Documentation obsolète archivée
- ✅ Guide de style créé

### Métriques
- **Modules cumulus:** 7 fichiers (2536 lignes)
- **Automatisations:** 12 automations modulaires
- **Sensors:** 50+ sensors
- **Binary sensors:** 18+ binary sensors
- **Dashboards:** 2 cartes Lovelace actives
- **Documentation:** 10 fichiers markdown principaux + 32 fichiers archivés

---

## 🏗️ ARCHITECTURE DU PROJET

### Structure des Dossiers

```
/home/user/Home_Assistant/
├── automations/              # Automations via UI
│   └── archive/              # Archive des anciennes automations
│       └── cumulus.yaml.OLD_20241122
├── configuration.yaml        # Configuration principale
├── custom_components/        # Composants personnalisés
│   ├── anker_solix/
│   └── solcast_solar/
├── docs/                     # Documentation
│   ├── ARCHITECTURE_TECHNIQUE.md
│   ├── CLAUDE_PREFERENCES.md
│   ├── ETAT_ACTUEL.md       # Ce fichier
│   ├── GIT_SYNC_GUIDE.md
│   ├── GUIDE_DEPANNAGE.md
│   ├── HEADER_TEMPLATE.md
│   ├── README_CUMULUS.md
│   ├── STYLE_GUIDE.md       # ✨ NOUVEAU (2025-11-22)
│   └── archive/             # Archives
│       ├── HISTORIQUE_VERSIONS.md
│       ├── analyses/        # 7 fichiers d'analyse
│       ├── bugs/            # 2 fichiers de bugs
│       ├── changelog/       # 8 fichiers changelog
│       ├── correctifs/      # 7 fichiers de correctifs
│       ├── old_syntheses/   # ✨ NOUVEAU
│       │   └── SYNTHESE_CUMULUS_COMPLETE.md
│       ├── procedures/      # 7 fichiers de procédures
│       │   ├── GUIDE_CONFIG_RAPIDE.md
│       │   └── INSTRUCTIONS_RELOAD.md
│       └── README.md
├── lovelace/                # Dashboards Lovelace
│   ├── cards/
│   │   ├── archive/         # ✨ NOUVEAU - 5 anciennes cartes archivées
│   │   ├── lovelace_carte_cumulus_styled.yaml       # Carte admin
│   │   ├── lovelace_carte_cumulus_utilisateur.yaml  # Carte simple
│   │   ├── lovelace_carte_pv_solcast.yaml
│   │   ├── lovelace_carte_volets_interpolee.yaml
│   │   └── README.md        # ✨ NOUVEAU - Guide des cartes
│   ├── CHANGELOG_LAU_CUMU.md
│   └── dashboard_cumulus_avance.yaml
├── packages/                # Packages thématiques
│   ├── carte_batterie.yaml
│   ├── cumulus/             # ✨ MODULE CUMULUS (architecture modulaire)
│   │   ├── automations_hc_safety.yaml   # 536 lignes - HC & sécurités
│   │   ├── automations_pv.yaml          # 434 lignes - Gestion PV
│   │   ├── core.yaml                    # 301 lignes - Config de base
│   │   ├── core.yaml.BACKUP
│   │   ├── sensors_base.yaml            # 339 lignes - Sensors essentiels
│   │   ├── sensors_calcul.yaml          # 481 lignes - Calculs & intelligence
│   │   └── sensors_monitoring.yaml      # 445 lignes - Santé & monitoring
│   ├── cumulus_input_select.yaml        # 593 octets - Input select cumulus
│   ├── cumulus.yaml.OLD_BACKUP          # Ancienne version monolithique
│   ├── git_sync.yaml
│   ├── salle_de_bain_douche_isa_college.yaml
│   └── solaire_economies.yaml
├── scripts/                 # Scripts bash
│   ├── git_sync.sh
│   ├── ouverture_volets.yaml
│   └── ...
├── themes/                  # Thèmes UI
├── templates/               # Templates Jinja2
├── AUDIT_COMPLET_CUMULUS_2025-11-15.md
├── CODE_STYLE_REVIEW.md
├── cumulus_fix_date_auto.yaml
├── README.md
└── README_CUMULUS.md
```

---

## 🔧 MODULE CUMULUS - ARCHITECTURE DÉTAILLÉE

### Structure Modulaire

Le système cumulus est organisé en 7 fichiers dans `packages/cumulus/` :

#### 1. **core.yaml** (301 lignes)
- **Input numbers** (21 entités) : Seuils, puissances, temporisations, config physique
- **Input booleans** (11 entités) : Contrôles manuels, états système, alias compatibilité
- **Input datetimes** (5 entités) : Fenêtres horaires, dernière chauffe
- **Input texts** (7 entités) : Entités configurables, historique, raison deadband
- **Timer** (1 entité) : Deadband anti-flapping

#### 2. **sensors_base.yaml** (339 lignes)
- Mesures de base : Import réseau, SOC, production PV
- Seuils calculés : Import limiteur, fin de chauffe, PV dynamique
- Puissance & énergie : Disponible, effectif, répartition sources

#### 3. **sensors_calcul.yaml** (481 lignes)
- Prévisions Solcast : Aujourd'hui, demain
- Calculs avancés : Temps restant, capacity factor
- Historique : Dernières chauffes, durée, dates
- Température & eau : Estimation déperdition, litres disponibles, besoin journalier

#### 4. **sensors_monitoring.yaml** (445 lignes)
- Score santé système (0-100%)
- Sensors de debug
- Monitoring continu

#### 5. **automations_pv.yaml** (434 lignes)
Automations liées à la gestion PV :
- Démarrage PV intelligent
- Arrêt PV intelligent
- Limiteur import réseau
- Protection surchauffe
- Gestion appareils prioritaires

#### 6. **automations_hc_safety.yaml** (536 lignes)
Automations heures creuses et sécurités :
- Démarrage HC intelligent
- Arrêt fin HC
- Mode vacances / retour vacances
- Sécurité anti-légionelle
- Reset quotidien
- Reset deadband

---

## 📋 INVENTAIRE COMPLET DES ENTITÉS

### Input Helpers (45 entités totales)

#### Input Numbers (21)
- Seuils PV (4) : `cumulus_seuil_pv_statique_w`, `cumulus_seuil_pv_dynamique_w`, etc.
- SOC & Sécurité (3) : `cumulus_soc_start_pct`, `cumulus_soc_stop_pct`, `cumulus_soc_min_pct`
- Import & Limiteurs (3) : `cumulus_talon_maison_w`, `cumulus_marge_import_w`, etc.
- Temporisations (4) : `cumulus_on_delay_s`, `cumulus_deadband_s`, etc.
- Config Physique (4) : `cumulus_puissance_w`, `cumulus_capacite_litres`, `cumulus_nb_personnes`, `cumulus_temperature_cible_c`
- Logique Intelligente (3) : `cumulus_espacement_max_h`, `cumulus_seuil_prevision_favorable_kwh`, etc.

#### Input Booleans (11)
- Contrôles manuels : `cumulus_override`, `cumulus_interdit_depart`, `cumulus_mode_vacances`
- États système : `cumulus_temp_atteinte_aujourdhui`, `cumulus_verrou_jour`, etc.
- Alias compatibilité : `cumulus_interdit`, `cumulus_vacances`, `temp_atteinte_aujourdhui`

#### Input Datetimes (5)
- Fenêtres : `cumulus_plage_pv_debut`, `cumulus_plage_pv_fin`, `cumulus_heures_creuses_debut`, `cumulus_heures_creuses_fin`
- Historique : `cumulus_derniere_chauffe_complete`, `cumulus_debut_chauffe_actuelle`

#### Input Texts (7)
- Entités configurables : `cumulus_entity_import_w`, `cumulus_entity_contacteur`, etc.
- Traçabilité : `cumulus_raison_deadband`, `cumulus_historique_chauffes`

#### Timer (1)
- `cumulus_deadband_ui` : Temporisation deadband (1:40)

### Sensors (50+ entités)
*Voir sections sensors_base, sensors_calcul, sensors_monitoring pour détails*

### Binary Sensors (18+ entités)
- État temps réel (4) : `cumulus_fenetre_pv`, `cumulus_en_hc`, `cumulus_deadband_actif`, `cumulus_chauffe_reelle`
- Détections appareils (3) : `cumulus_lave_linge_actif`, `cumulus_lave_vaisselle_actif`, `cumulus_appareil_prioritaire_actif`
- Conditions PV (1) : `cumulus_soleil_suffisant`
- Fin de chauffe (1) : `cumulus_fini_par_import`
- Météo (2) : `cumulus_meteo_favorable_aujourdhui`, `cumulus_meteo_favorable_demain`
- Logique HC (3) : `cumulus_besoin_chauffe_urgente`, `cumulus_autoriser_chauffe_hc_intelligente`, `cumulus_on_hc_prevu`
- Monitoring (3) : `cumulus_etat_coherent`, `cumulus_entites_ok`, `cumulus_capacite_suffisante`

### Automations (12 actives)

#### Mode PV (5 automations)
1. `cumulus_demarrage_pv_intelligent` : Démarre quand conditions PV optimales
2. `cumulus_arret_pv_intelligent` : Arrêt si conditions dégradées
3. `cumulus_limiteur_import_reseau` : Protection import excessif
4. `cumulus_protection_surchauffe` : Sécurité température
5. `cumulus_gestion_appareils_prioritaires` : Priorité lave-linge/vaisselle

#### Mode HC & Sécurités (7 automations)
6. `cumulus_demarrage_hc_intelligent` : HC si besoin urgent OU météo défavorable
7. `cumulus_arret_hc` : Arrêt fin heures creuses
8. `cumulus_mode_vacances` : Activation mode vacances
9. `cumulus_retour_vacances` : Désactivation mode vacances
10. `cumulus_securite_anti_legionelle` : Chauffe sécurité si >7j sans 60°C
11. `cumulus_reset_quotidien` : Reset journalier verrous
12. `cumulus_reset_deadband` : Reset deadband après timer

---

## 📊 DASHBOARDS & INTERFACES

### Cartes Lovelace Actives (2 cartes)

#### 1. **lovelace_carte_cumulus_styled.yaml**
- **Usage:** Dashboard admin complet
- **Version:** 2025-10-21
- **Type:** Design moderne professionnel optimisé
- **Sections:** Monitoring, configuration, diagnostic

#### 2. **lovelace_carte_cumulus_utilisateur.yaml**
- **Usage:** Interface utilisateur finale
- **Version:** 2025-10-09b
- **Type:** Interface simplifiée non-technique
- **Cible:** Utilisatrice finale (non-technique)

### Cartes Archivées (5 cartes)
*Archivées dans `lovelace/cards/archive/` le 2025-11-22*

---

## 🎯 LOGIQUE MÉTIER

### Démarrage PV

**Conditions cumulatives:**
1. Fenêtre PV active (10:20-17:50)
2. APS >= seuil statique (100W)
3. Puissance disponible > seuil dynamique (selon SOC)
4. SOC >= seuil minimum (25%)
5. Pas d'interdit/vacances/verrou
6. Aucun appareil prioritaire actif
7. Deadband expiré
8. Entités critiques OK

**Seuil dynamique selon SOC:**
- SOC > 80% : seuil × 0.7
- SOC 50-80% : seuil normal
- SOC < 50% : seuil × 1.3

### Heures Creuses Intelligentes

**Démarrage HC SI:**
1. Besoin urgent (>50h depuis dernière chauffe) **OU**
2. Météo défavorable demain (<8kWh prévu Solcast)

**Cas spécial verrou:**
- Si temp max atteinte + météo défavorable → verrou désactivé à 03:30 (permet HC préventive)
- Si temp max atteinte + météo favorable → verrou maintenu jusqu'à 08:10

### Espacement Chauffes

- **Maximum:** 50 heures (configurable 24-120h)
- **Alerte besoin urgent:** Notification à 51h
- **Besoin urgent ON:** Binary sensor activé après 50h

### Fin de Chauffe

**Détection universelle:**
- Chauffe OFF pendant 60s
- Durée minimum 2 minutes
- Si switch ON + consommation <150W → Temp max atteinte

**Actions:**
1. Enregistre dernière chauffe complète
2. Active `temp_atteinte_aujourdhui`
3. Active `verrou_jour`
4. Coupe contacteur
5. Ajoute entrée historique
6. Notification avec bilan

---

## 🔍 MONITORING & SANTÉ

### Score Santé Système

**Critères (25 pts chacun):**
1. Entités critiques disponibles
2. Cohérence mesures (pas d'incohérence switch/conso)
3. Espacement chauffes OK (pas de besoin urgent)
4. État fonctionnel (pas vacances/interdit)

**Niveaux:**
- 90-100% : Excellent ✅
- 75-89% : Bon ✅
- 50-74% : Moyen ⚠️
- 25-49% : Dégradé ⚠️
- 0-24% : Critique 🔴

---

## ⚙️ CONFIGURATION

### Configuration Matérielle

```yaml
# Photovoltaïque
Anker Solix E1600 Solarbank 2 Pro: 1600 Wh, max 1200W
APS (Micro-onduleurs): max 960W
Prévisions: Solcast PV Forecast

# Cumulus
Capacité: 300 litres
Puissance nominale: 3000W
Contrôle: Shelly Pro 1 (switch.shellypro1_ece334ee1b64)
Température cible: 60°C

# Maison
Talon: 300W
Nombre de personnes: 2
```

### Configuration Logicielle

**Fichier:** `configuration.yaml`

```yaml
homeassistant:
  packages:
    cumulus_input_select: !include packages/cumulus_input_select.yaml
    cumulus_core: !include packages/cumulus/core.yaml
    cumulus_sensors_base: !include packages/cumulus/sensors_base.yaml
    cumulus_sensors_calcul: !include packages/cumulus/sensors_calcul.yaml
    cumulus_sensors_monitoring: !include packages/cumulus/sensors_monitoring.yaml
    cumulus_automations_pv: !include packages/cumulus/automations_pv.yaml
    cumulus_automations_hc_safety: !include packages/cumulus/automations_hc_safety.yaml
    # ... autres packages
```

---

## 📅 HISTORIQUE RÉCENT

### 2025-11-22 - NETTOYAGE COMPLET
- ✅ Archivage ancien fichier `automations/cumulus.yaml` (1068 lignes)
- ✅ Archivage 5 cartes Lovelace obsolètes
- ✅ Archivage documentation obsolète (DASHBOARD_LAU_CUMU_FINAL.md, etc.)
- ✅ Création `docs/STYLE_GUIDE.md`
- ✅ Création `lovelace/cards/README.md`
- ✅ Mise à jour `docs/ETAT_ACTUEL.md`

### 2025-11-15 - AUDIT COMPLET
- Audit complet du système (AUDIT_COMPLET_CUMULUS_2025-11-15.md)
- Identification entités manquantes et problèmes critiques

### 2024-11 - ARCHITECTURE MODULAIRE
- Migration vers architecture modulaire packages/cumulus/
- Séparation en 7 fichiers thématiques
- Headers standardisés

---

## 🚀 PROCHAINES ÉVOLUTIONS

### Court Terme
- [ ] Vérifier que toutes les automations fonctionnent après archivage
- [ ] Tester score santé système
- [ ] Valider dashboards Lovelace

### Moyen Terme
- [ ] Tests automatisés au démarrage
- [ ] Intégration calendrier vacances scolaires
- [ ] Graphiques long terme (économies, kWh PV vs HC)

### Long Terme
- [ ] Machine Learning prévision consommation
- [ ] Optimisation multi-équipements
- [ ] Intégration tarifs Tempo/EJP

---

## 📞 DOCUMENTATION & SUPPORT

### Documentation Principale

- **docs/STYLE_GUIDE.md** : Guide de style et conventions
- **docs/CLAUDE_PREFERENCES.md** : Règles critiques HA
- **docs/README_CUMULUS.md** : Documentation complète cumulus
- **docs/ARCHITECTURE_TECHNIQUE.md** : Architecture détaillée
- **docs/GUIDE_DEPANNAGE.md** : Guide de dépannage
- **docs/GIT_SYNC_GUIDE.md** : Guide synchronisation Git

### Archives

- **docs/archive/** : 32 fichiers archivés (analyses, bugs, correctifs, procédures)
- **automations/archive/** : Anciennes versions automations
- **lovelace/cards/archive/** : Anciennes cartes Lovelace

---

**Document de référence officiel**
**Toujours à jour avec l'état réel du système**
**Dernière mise à jour complète:** 2025-11-22
