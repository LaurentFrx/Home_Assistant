# 🚀 Améliorations Cumulus Intelligent - Octobre 2025

## 📋 Résumé des améliorations

### ✅ Fonctionnalités ajoutées

#### 1. **Gestion intelligente de l'espacement (jusqu'à 50h)**
- Nouveau sensor `cumulus_heures_depuis_derniere_chauffe` qui calcule le temps écoulé depuis la dernière chauffe
- Input `cumulus_espacement_max_h` (défaut: 50h) pour définir l'intervalle maximum entre deux chauffes
- Binary sensor `cumulus_besoin_chauffe_urgente` qui s'active quand le délai est dépassé

#### 2. **Intégration Solcast pour prévisions météo**
- Nouveaux inputs pour configurer les capteurs Solcast (aujourd'hui et demain)
- Sensors `cumulus_solcast_forecast_today` et `cumulus_solcast_forecast_tomorrow`
- Input `cumulus_seuil_solcast_bon_kwh` (défaut: 8 kWh) pour définir une "bonne journée"
- Binary sensors `cumulus_meteo_favorable_aujourdhui` et `cumulus_meteo_favorable_demain`

#### 3. **Évitement intelligent des heures creuses**
- Nouveau toggle `cumulus_autoriser_hc` pour activer/désactiver les HC
- Binary sensor `cumulus_autoriser_chauffe_hc_intelligente` qui décide si HC nécessaire selon :
  - Besoin urgent (> 50h depuis dernière chauffe) OU
  - Météo défavorable demain (< 8 kWh prévu)
- **Anti-gaspillage** : N'allume plus en HC si déjà chauffé dans la journée

#### 4. **Constante de consommation**
- Input `cumulus_puissance_w` (défaut: 2950W) pour avoir la valeur de référence
- Utilisable pour calculs futurs (économies, durée de chauffe, etc.)

#### 5. **Planificateur de besoins**
- Input `cumulus_nb_personnes` (défaut: 2) pour le nombre de personnes au foyer
- Input `cumulus_capacite_litres` (défaut: 300L) pour la capacité du ballon
- Préparation pour logique adaptative future

#### 6. **Estimation température et volume disponible**
- Sensor `cumulus_temperature_estimee` : Modèle de déperdition thermique (58°C → perd 0,3°C/h → min 20°C)
- Sensor `cumulus_litres_disponibles_estimes` : Calcul proportionnel selon température
- Input datetime `cumulus_derniere_chauffe_complete` : Horodatage précis
- Mise à jour automatique lors de la fin de chauffe détectée

#### 7. **Système de notifications intelligent**
- **Alerte 48h** : Notification si pas de chauffe depuis 48h (hors mode vacances)
- **Alerte besoin urgent** : Notification si espacement max dépassé (hors vacances)
- **Alerte import anormal** : Si import > 1500W pendant 5 min en chauffe PV
- **Confirmation chauffe terminée** : Notification de succès avec température et capacité

#### 8. **Carte Lovelace magnifique**
Fichier `lovelace_carte_cumulus.yaml` avec :

**En-tête dynamique :**
- Titre avec capacité et nombre de personnes

**Statut en temps réel (chips) :**
- État chauffe (🔥/💤) avec couleur dynamique
- Température estimée avec code couleur (rouge/orange/bleu)
- Litres disponibles avec indicateur (vert/orange/rouge)
- Heures depuis dernière chauffe avec alerte

**Jauge température :**
- Gauge visuelle 20-60°C avec zones de couleur

**Graphique historique 48h :**
- Température eau (rouge)
- Production PV (jaune, axe secondaire)
- Import réseau (bleu, axe secondaire)
- Ligne animée, 2 points/heure

**Météo & prévisions :**
- Prévision Solcast aujourd'hui/demain
- Couleur dynamique selon seuil

**Contrôles rapides :**
- Override, Interdit, Vacances
- Autoriser HC, Besoin urgent, Temp atteinte
- Boutons tactiles avec icônes dynamiques

**Données techniques :**
- Import, Production PV, SOC batterie
- Puissance cumulus
- Seuils calculés
- Dernière chauffe

**Configuration complète :**
- Tous les inputs modifiables
- Organisés par catégorie

**Fenêtres horaires :**
- Plages PV et HC
- Indicateurs actifs

**Logique intelligente :**
- Tous les binary sensors
- Statuts en temps réel

---

## 🎯 Logique d'évitement HC (détail)

### Ancien comportement
✗ Chauffe systématique tous les soirs en HC (03h30)

### Nouveau comportement
✓ Chauffe en HC **uniquement si** :
1. `cumulus_autoriser_hc` est activé (toggle manuel)
2. **ET** l'une de ces conditions :
   - Heures depuis dernière chauffe ≥ 50h (besoin urgent)
   - OU prévision Solcast demain < 8 kWh (pas assez de soleil prévu)

### Exemple de scénarios

**Scénario A : Beau temps**
- Lundi 14h : chauffe PV terminée
- Lundi 03h30 (nuit) : Pas de chauffe HC (seulement 13h écoulées + beau temps prévu mardi)
- Mardi 12h : chauffe PV si production suffisante
- Économie : 1 chauffe HC évitée

**Scénario B : Temps couvert**
- Lundi 14h : chauffe PV terminée
- Solcast prévoit 3 kWh pour mardi (mauvais)
- Mardi 03h30 : Chauffe HC activée (sécurité car mauvais temps prévu)
- Mardi journée : Pas de chauffe PV (nuageux)
- Résultat : Eau chaude garantie

**Scénario C : Dépassement 50h**
- Lundi 10h : dernière chauffe
- Mardi : nuageux, pas de chauffe
- Mercredi 03h30 : 41h écoulées, pas de chauffe HC
- Mercredi 12h : Dépassement 50h → Chauffe HC prochaine nuit garantie

---

## 📦 Installation

### 1. Package cumulus.yaml
Le fichier `packages/cumulus.yaml` a été modifié avec toutes les améliorations.

**⚠️ Action requise :**
- Vérifier les capteurs Solcast dans les inputs :
  - `cumulus_entity_solcast_today`
  - `cumulus_entity_solcast_tomorrow`
- Remplacer par vos capteurs réels si différents

### 2. Carte Lovelace
Le fichier `lovelace_carte_cumulus.yaml` est prêt à l'emploi.

**Dépendances requises (HACS) :**
- `custom:mushroom-title-card`
- `custom:mushroom-chips-card`
- `custom:mushroom-entity-card`
- `custom:mini-graph-card`

**Pour intégrer dans votre dashboard :**
```yaml
# Dans votre fichier Lovelace principal
- type: custom:mod-card
  card: !include lovelace_carte_cumulus.yaml
```

Ou copiez-collez directement le contenu dans l'éditeur visuel.

### 3. Premier démarrage

**Initialisation manuelle nécessaire :**
1. Aller dans Développeur → États
2. Trouver `input_datetime.cumulus_derniere_chauffe_complete`
3. Définir la date/heure de votre dernière chauffe connue
4. Ou attendre la prochaine chauffe (sera enregistrée automatiquement)

---

## 🔧 Configuration recommandée

### Réglages suggérés (2 personnes, 300L)
```yaml
cumulus_nb_personnes: 2
cumulus_capacite_litres: 300
cumulus_espacement_max_h: 50
cumulus_seuil_solcast_bon_kwh: 8
cumulus_autoriser_hc: true  # Laisser activé pour sécurité
```

### Ajustements selon usage
- **Consommation élevée (douches fréquentes)** : Réduire espacement à 36-40h
- **Consommation faible** : Augmenter espacement à 60-72h
- **Région ensoleillée** : Augmenter seuil Solcast à 10-12 kWh
- **Région nuageuse** : Réduire seuil Solcast à 5-6 kWh

---

## 📊 Monitoring

### Capteurs clés à surveiller
- `sensor.cumulus_heures_depuis_derniere_chauffe` : Ne devrait jamais dépasser 50h
- `sensor.cumulus_temperature_estimee` : Devrait rester > 45°C
- `binary_sensor.cumulus_besoin_chauffe_urgente` : Devrait rester OFF

### Notifications attendues
- **Chauffe terminée** : À chaque fin de cycle complet
- **Alerte 48h** : Si aucune chauffe pendant 2 jours
- **Besoin urgent** : Si espacement max dépassé depuis 1h
- **Import anormal** : Si problème pendant chauffe PV

---

## 🚦 Prochaines évolutions possibles

### À court terme
- [ ] Historique des chauffes (sensor compteur)
- [ ] Calcul économies réalisées vs. HC uniquement
- [ ] Graphique taux autoconsommation cumulus

### À moyen terme
- [ ] Intégration machine à laver / lave-vaisselle (délestage)
- [ ] Détection automatique absence (sensors présence)
- [ ] Calendrier intégré (vacances scolaires)

### À long terme
- [ ] Machine Learning prédictif consommation eau
- [ ] Optimisation multi-équipements
- [ ] Statistiques détaillées (kWh/€ économisés)

---

## 🆘 Dépannage

### Le cumulus ne chauffe plus en HC
**Cause probable :** Logique d'évitement active
**Vérifier :**
- `binary_sensor.cumulus_autoriser_chauffe_hc_intelligente` = OFF ?
- Si oui : heures depuis dernière chauffe < 50h ET météo favorable demain
- **Solution** : Activer `cumulus_override` ou attendre besoin urgent

### Température estimée incohérente
**Cause :** Modèle simplifié de déperdition
**Ajustement :** Le coefficient de 0,3°C/h est une moyenne
- Si cumulus bien isolé : réduire à 0,2°C/h (modifier template)
- Si cumulus ancien : augmenter à 0,4°C/h

### Pas de notifications
**Vérifier :**
- Service `persistent_notification` activé
- Pas en mode vacances (bloque certaines alertes)
- Notifications visibles dans le panneau latéral HA

---

## 📝 Notes de version

**v2025-10-07 - "Intelligence Météo"**
- Ajout gestion espacement jusqu'à 50h
- Intégration Solcast complète
- Évitement intelligent HC avec anti-gaspillage
- Estimation température/volume disponible
- Système notifications complet
- Carte Lovelace premium
- Planificateur besoins (nb personnes, capacité)

**v2025-10-03a - "Baseline"**
- Version initiale avec seuil PV 100W
- Limiteur d'import
- Sécurité SOC
- Gestion HC basique

---

## 📞 Support

Pour toute question ou amélioration, consulter :
- Documentation package : En-tête de `cumulus.yaml`
- Logs Home Assistant : Développeur → Logs
- États en temps réel : Développeur → États

---

**🎉 Profitez de votre cumulus intelligent !**
