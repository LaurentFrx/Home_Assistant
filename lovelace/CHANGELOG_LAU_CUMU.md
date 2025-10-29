# CHANGELOG Vue LAU/cumu

## 2025-10-29 - Ajout Prévisions Solaires

### Modifications apportées
- Ajout section "Prévisions Solaires" dans la vue dashboard-lau/cumu
- Position : Après le header, carte position 3-4

### Cartes ajoutées

#### 1. Titre


#### 2. Cartes prévisions (horizontal-stack)
- **Aujourd'hui** : sensor.solcast_pv_forecast_previsions_pour_aujourd_hui
- **Demain** : sensor.solcast_pv_forecast_previsions_pour_demain

### Fichiers modifiés
-  (mode storage, non versionné)
- Backup créé : 

### Validation
- ✓ Sensors Solcast vérifiés et actifs
- ✓ 2 cartes Mushroom ajoutées avec icônes solar-power
- ✓ Total cartes vue cumu : 14 → 16

### Accès
Dashboard LAU → Vue Cumulus (path: cumu)
Position : En haut, après besoin urgent

## [2025-10-29] - Ajout modification manuelle derniere chauffe

### Ajoute
- input_datetime.cumulus_derniere_chauffe_complete pour modification manuelle
- Documentation MODIFICATION_DERNIERE_CHAUFFE.md

### Modifie
- packages/cumulus.yaml : ajout entite input_datetime

### Impact
- Permet correction manuelle date derniere chauffe complete
- Prise en charge immediate par automatisations et sensors
- Affichage dashboard LAU/cumu devient editable

### Fichiers modifies
- /config/packages/cumulus.yaml (backup: cumulus.yaml.backup_20251029_100520)

