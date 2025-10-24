# Améliorations Package Cumulus - 24 octobre 2025

## Vue d'ensemble

Ce document décrit les 6 catégories d'améliorations prioritaires appliquées au package cumulus Home Assistant pour renforcer sa sécurité, robustesse et facilité de diagnostic.

---

## 1️⃣ SÉCURITÉ & ROBUSTESSE

### Objectifs
Réduire les fausses détections et améliorer la fiabilité du système.

### Améliorations implémentées

#### 1.1 Seuil de détection thermostat : 70% → 85%
- **Fichier** : `packages/cumulus.yaml:820`
- **Impact** : Réduit les fausses détections de fin de chauffe
- **Avant** : `seuil_chauffe = puissance_nominale * 0.70`
- **Après** : `seuil_chauffe = puissance_nominale * 0.85`

#### 1.2 Délai minimum de chauffe : 60s → 120s
- **Fichier** : `automations/cumulus.yaml:170`
- **Impact** : Évite l'enregistrement de chauffes trop courtes
- **Avant** : `>= 60 secondes`
- **Après** : `>= 120 secondes`

#### 1.3 Détection anomalie cohérence
- **Fichier** : `automations/cumulus.yaml:647-697`
- **Automation** : `cumulus_detection_anomalie_coherence`
- **Déclenchement** : Switch ON mais consommation < 100W pendant 30s
- **Action** : Notification avec diagnostic détaillé (contacteur, mesures, causes possibles)

---

## 2️⃣ GESTION ERREURS ENTITÉS

### Objectifs
Empêcher les démarrages si une entité critique est invalide et alerter en cas de problème.

### Améliorations implémentées

#### 2.1 Binary sensor de validation
- **Fichier** : `packages/cumulus.yaml:882-959`
- **Entité** : `binary_sensor.cumulus_entites_ok`
- **Vérification** :
  - Entités critiques (4) : Import, Contacteur, SOC, PV total
  - Entités optionnelles (4) : Solcast×2, Lave-linge, Lave-vaisselle
- **Attributs** :
  - `entites_critiques_valides` : Liste détaillée avec statut ✅/❌
  - `entites_optionnelles_valides` : Liste détaillée avec statut ✅/⚠️
  - `dernier_evenement` : Résumé de l'état

#### 2.2 Dépendances automations
- **Fichiers** :
  - `automations/cumulus.yaml:24` (Démarrage PV)
  - `automations/cumulus.yaml:394` (Démarrage HC)
- **Condition ajoutée** :
  ```yaml
  - condition: state
    entity_id: binary_sensor.cumulus_entites_ok
    state: "on"
  ```

#### 2.3 Alerte entité unavailable pendant chauffe
- **Fichier** : `automations/cumulus.yaml:708-744`
- **Automation** : `cumulus_alerte_entite_unavailable_chauffe`
- **Déclenchement** : `binary_sensor.cumulus_entites_ok` passe à OFF pendant chauffe active
- **Action** : Notification avec détails des entités en erreur

---

## 3️⃣ CONSOLIDATION DEADBAND

### Objectifs
Améliorer la traçabilité et le diagnostic du mécanisme anti-flapping.

### Améliorations implémentées

#### 3.1 Traçabilité des raisons
- **Fichier** : `packages/cumulus.yaml:332-336`
- **Entité** : `input_text.cumulus_raison_deadband`
- **Raisons enregistrées** :
  - "Démarrage PV (anti-flapping)"
  - "Import réseau > XXXXw"
  - "SOC XX% < seuil XX%"
  - "Consommation domestique élevée (Import XXXXw)"

#### 3.2 Sensor état deadband
- **Fichier** : `packages/cumulus.yaml:744-769`
- **Entité** : `sensor.cumulus_etat_deadband`
- **Attributs** :
  - `raison` : Dernière raison d'activation
  - `timer_state` : État du timer
  - `temps_restant` : Durée restante
  - `fin_prevue` : Timestamp de fin
  - `dernier_evenement` : Explication état actuel

#### 3.3 Mise à jour automations
- **Fichiers** : `automations/cumulus.yaml`
- **Automations modifiées** (4) :
  - Démarrage PV automatique (ligne 67-71)
  - Limiteur import (ligne 111-115)
  - Sécurité SOC bas (ligne 153-157)
  - Arrêt conso domestique élevée (ligne 327-331)

---

## 4️⃣ OPTIMISATION DÉTECTION FIN CHAUFFE

### Objectifs
Permettre suivi temps réel et analyse historique des performances.

### Améliorations implémentées

#### 4.1 Durée chauffe actuelle temps réel
- **Fichier** : `packages/cumulus.yaml:771-801`
- **Entité** : `sensor.cumulus_duree_chauffe_actuelle`
- **Unité** : Minutes
- **Mise à jour** : Automatique en temps réel
- **Attributs** :
  - `debut_chauffe` : Timestamp de début
  - `consommation_w` : Consommation actuelle
  - `autonomie_pv_pct` : Pourcentage PV
  - `dernier_evenement` : État descriptif

#### 4.2 Historique des chauffes
- **Fichier** : `packages/cumulus.yaml:343-347`
- **Entité** : `input_text.cumulus_historique_chauffes`
- **Format** : Entrées séparées par `|`, limité aux 10 dernières
- **Structure entrée** : `DD/MM HH:MM - XXmin - XX% PV - Statut`
- **Statuts** : "Complète" ou "Interrompue"

#### 4.3 Affichage historique
- **Fichier** : `packages/cumulus.yaml:921-960`
- **Entité** : `sensor.cumulus_historique_chauffes_display`
- **Attributs** :
  - `historique_complet` : 10 dernières entrées formatées
  - `derniere_chauffe` : Dernière entrée
  - `dernier_evenement` : Résumé

#### 4.4 Automation enregistrement
- **Fichiers** :
  - `automations/cumulus.yaml:766-785` (Début chauffe)
  - `automations/cumulus.yaml:227-243` (Fin chauffe complète)
  - `automations/cumulus.yaml:267-283` (Fin chauffe interrompue)

---

## 5️⃣ MONITORING PROACTIF

### Objectifs
Détecter proactivement les problèmes avant qu'ils n'impactent le fonctionnement.

### Améliorations implémentées

#### 5.1 Sensor santé système
- **Fichier** : `packages/cumulus.yaml:803-919`
- **Entité** : `sensor.cumulus_sante_systeme`
- **Score** : 0-100%
- **Calcul** :
  - **Entités valides** (25 pts) : Toutes entités critiques disponibles
  - **Cohérence mesures** (25 pts) : Switch/conso cohérents
  - **Espacement chauffes** (25 pts) : Pas de besoin urgent
  - **État fonctionnel** (25 pts) : Système opérationnel

#### 5.2 Niveaux de santé
- **Excellent** : ≥ 90%
- **Bon** : 75-89%
- **Moyen** : 50-74%
- **Dégradé** : 25-49%
- **Critique** : < 25%

#### 5.3 Attributs détaillés
- `evaluation_entites` : Détail validation entités
- `evaluation_coherence` : Détail cohérence mesures
- `evaluation_espacement` : Détail espacement chauffes
- `evaluation_fonctionnel` : Détail état système
- `niveau_sante` : Niveau textuel
- `dernier_evenement` : Résumé état

#### 5.4 Alerte automatique
- **Fichier** : `automations/cumulus.yaml:820-867`
- **Automation** : `cumulus_alerte_sante_systeme_degradee`
- **Déclenchement** : Score < 70% pendant 5 minutes
- **Notification** : Diagnostic complet avec toutes évaluations

---

## 6️⃣ DOCUMENTATION

### Objectifs
Faciliter le diagnostic en ajoutant des explications contextuelles sur chaque sensor.

### Améliorations implémentées

#### 6.1 Sensors avec attribut dernier_evenement

| Sensor | Fichier | Ligne | Informations affichées |
|--------|---------|-------|------------------------|
| `cumulus_import_reseau_w` | packages/cumulus.yaml | 371-380 | Import/Export actuel |
| `cumulus_consommation_reelle_w` | packages/cumulus.yaml | 463-475 | État chauffe + diagnostic |
| `cumulus_repartition_sources` | packages/cumulus.yaml | 528-535 | Chauffe + autonomie PV |
| `cumulus_seuil_import_limiteur_w` | packages/cumulus.yaml | 553-560 | Comparaison import vs seuil |
| `cumulus_puissance_disponible_w` | packages/cumulus.yaml | 754-762 | Dispo vs requis + SOC |
| `cumulus_temperature_physique_c` | packages/cumulus.yaml | 593-606 | État température + diagnostic |
| `cumulus_chauffe_reelle` | packages/cumulus.yaml | 829-834 | État chauffe actuel |
| `cumulus_entites_ok` | packages/cumulus.yaml | 954-959 | Validation entités |
| `cumulus_etat_deadband` | packages/cumulus.yaml | 764-769 | État deadband + raison |
| `cumulus_duree_chauffe_actuelle` | packages/cumulus.yaml | 796-801 | Durée temps réel |
| `cumulus_sante_systeme` | packages/cumulus.yaml | 911-919 | État santé global |
| `cumulus_historique_chauffes_display` | packages/cumulus.yaml | 840-846 | Dernière chauffe |

#### 6.2 Format des explications
- ✅ Émojis pour lecture rapide
- ⚠️ Alertes pour situations anormales
- ❌ Erreurs pour problèmes critiques
- Valeurs numériques formatées et arrondies
- Explications en français

---

## Résumé des nouvelles entités créées

### Input helpers
- `input_text.cumulus_raison_deadband` : Raison dernier deadband
- `input_text.cumulus_historique_chauffes` : Historique 10 chauffes
- `input_datetime.cumulus_debut_chauffe_actuelle` : Début chauffe actuelle

### Sensors
- `sensor.cumulus_etat_deadband` : État deadband avec détails
- `sensor.cumulus_duree_chauffe_actuelle` : Durée chauffe temps réel
- `sensor.cumulus_historique_chauffes_display` : Affichage historique
- `sensor.cumulus_sante_systeme` : Score santé 0-100%

### Binary sensors
- `binary_sensor.cumulus_entites_ok` : Validation entités configurables

### Automations
- `cumulus_detection_anomalie_coherence` : Alerte anomalie switch/conso
- `cumulus_alerte_entite_unavailable_chauffe` : Alerte entité unavailable
- `cumulus_enregistrement_debut_chauffe` : Enregistrement début chauffe
- `cumulus_alerte_sante_systeme_degradee` : Alerte santé < 70%

---

## Référence des fichiers modifiés

1. **packages/cumulus.yaml**
   - En-tête mis à jour (lignes 1-47)
   - Nouveaux input_text et input_datetime (lignes 332-347)
   - Attributs dernier_evenement sur 12 sensors
   - 4 nouveaux sensors (deadband, durée, historique, santé)
   - 1 nouveau binary_sensor (entités_ok)

2. **automations/cumulus.yaml**
   - 4 automations modifiées (enregistrement raison deadband)
   - 2 conditions ajoutées (validation entités)
   - 4 nouvelles automations (anomalie, unavailable, début chauffe, santé)
   - Enregistrement historique dans fin chauffe universelle

---

## Utilisation

### Surveillance santé système
1. Ajouter `sensor.cumulus_sante_systeme` dans une carte Lovelace
2. Utiliser des cartes conditionnelles pour afficher alertes si < 70%
3. Afficher attributs `evaluation_*` pour diagnostic détaillé

### Consultation historique
1. Afficher `sensor.cumulus_historique_chauffes_display`
2. Attribut `historique_complet` montre les 10 dernières chauffes
3. Format lisible : Date, Durée, % PV, Statut

### Diagnostic problèmes
1. Vérifier `binary_sensor.cumulus_entites_ok`
2. Consulter `dernier_evenement` des sensors concernés
3. Vérifier `sensor.cumulus_sante_systeme` pour vue d'ensemble

### Traçabilité deadband
1. Consulter `sensor.cumulus_etat_deadband`
2. Attribut `raison` explique pourquoi le deadband est actif
3. Attribut `temps_restant` indique quand redémarrage possible

---

## Notes importantes

### Compatibilité
- ✅ Toutes les fonctionnalités existantes préservées
- ✅ Aucun breaking change
- ✅ Configuration existante compatible

### Performance
- Impact négligeable sur performance Home Assistant
- Sensors template optimisés pour calculs légers
- Historique limité à 10 entrées (pas de croissance infinie)

### Maintenance
- Pas de maintenance requise
- Historique auto-limité à 10 entrées
- Notifications auto-gérées (mêmes notification_id)

---

## Auteur

Améliorations implémentées le 24 octobre 2025 via Claude Code.

## Licence

Ces améliorations suivent la même licence que le package cumulus d'origine.
