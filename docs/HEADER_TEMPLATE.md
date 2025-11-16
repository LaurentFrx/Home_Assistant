# Template de Header pour Fichiers YAML

## Pour Packages (packages/*.yaml)

```yaml
###############################################################################
# NOM DU MODULE - Description courte
# Version: vYYYY-MM-DD
# Auteur: [Nom]
#
# DESCRIPTION:
#   Description détaillée de ce que fait ce module.
#   Peut être sur plusieurs lignes.
#
# PRÉREQUIS (Helpers / UI):
#   - input_number.exemple_parametre
#   - input_boolean.exemple_switch
#   - schedule.exemple_planning (si applicable)
#
# CAPTEURS SOURCES (Intégrations):
#   - sensor.exemple_source_1 (Description, unité)
#   - sensor.exemple_source_2 (Description, unité)
#
# ENTITÉS CRÉÉES:
#   - sensor.module_sensor_1 - Description
#   - binary_sensor.module_etat - Description
#   - switch.module_action - Description
#
# NOTES:
#   - Notes importantes sur l'utilisation
#   - Limitations connues
#   - Références vers documentation externe
###############################################################################
```

## Pour Automations (automations/*.yaml)

```yaml
###############################################################################
# AUTOMATIONS - NOM DU MODULE
# Version: vYYYY-MM-DD
#
# DESCRIPTION:
#   Description du système d'automatisation.
#   Comportement général attendu.
#
# DÉPENDANCES:
#   - Entités requises du package associé
#   - Autres automations liées
#
# AUTOMATIONS INCLUSES:
#   1. Nom automation 1 - Description courte
#   2. Nom automation 2 - Description courte
#   ...
#
# NOTES:
#   - Ordre d'exécution si important
#   - Modes de fonctionnement
###############################################################################
```

## Pour Scripts (scripts/*.yaml)

```yaml
###############################################################################
# SCRIPT: Nom du script
# Description: Ce que fait le script
# Usage: Quand/comment l'utiliser
# Dépendances: Entités requises
###############################################################################
```

## Pour Scripts Simples (< 20 lignes)

```yaml
# Script: Nom court - Description
# Usage: Contexte d'utilisation
```

## Exemple Complet (Package)

```yaml
###############################################################################
# GESTION CUMULUS - Chauffe-eau solaire intelligent
# Version: v2025-11-16
# Auteur: Laurent
#
# DESCRIPTION:
#   Automatisation complète du chauffe-eau électrique basée sur:
#   - Production photovoltaïque (APS + SolarBank)
#   - Optimisation tarifaire (heures creuses)
#   - Détection d'appareils prioritaires (lave-linge, lave-vaisselle)
#   - Gestion intelligente selon prévisions météo
#
# PRÉREQUIS (Helpers / UI):
#   - input_number.cumulus_seuil_pv_on_w (seuil démarrage)
#   - input_datetime.cumulus_heures_creuses_debut
#   - input_datetime.cumulus_heures_creuses_fin
#   - schedule.hc_hours (ON = heures creuses)
#
# CAPTEURS SOURCES (Intégrations):
#   - sensor.smart_meter_grid_import (import réseau, W)
#   - sensor.solcast_pv_forecast_* (prévisions Solcast, kWh)
#   - sensor.solarbank_3_e2700_pro_etat_de_charge (SOC batterie, %)
#   - switch.shellypro1_ece334ee1b64 (contacteur cumulus)
#
# ENTITÉS CRÉÉES:
#   - sensor.cumulus_puissance_disponible_w - Puissance dispo pour chauffe
#   - binary_sensor.cumulus_fenetre_pv - Fenêtre PV active
#   - sensor.cumulus_heures_depuis_derniere_chauffe - Monitoring
#
# NOTES:
#   - Mode override disponible pour forcer la chauffe
#   - Verrou journalier automatique selon météo
#   - Voir docs/README_CUMULUS.md pour documentation complète
###############################################################################

input_text:
  cumulus_entity_import_w:
    name: ENTITÉ - Import réseau (W)
    ...
```

## Règles Générales

1. **Largeur maximale:** 79 caractères (respecter les bornes `###`)
2. **Séparateur:** Utiliser `###` (79 caractères) pour les sections importantes
3. **Indentation dans header:** 2 espaces après `#` pour les listes
4. **Version:** Format `vYYYY-MM-DD` pour suivi chronologique
5. **Sections obligatoires:** NOM, VERSION, DESCRIPTION
6. **Sections optionnelles:** PRÉREQUIS, CAPTEURS SOURCES, ENTITÉS CRÉÉES, NOTES
7. **Ordre:** Toujours mettre le header en première ligne du fichier

## Anti-patterns à Éviter

❌ **Mauvais:**
```yaml
# TEST WORKFLOW - Wed 12 Nov 15:57
input_text:
  ...
```

❌ **Mauvais:**
```yaml
# packages/cumulus.yaml
# Gestion du cumulus
```

❌ **Pas de header du tout**

✅ **Bon:**
```yaml
###############################################################################
# MODULE CUMULUS - Gestion chauffe-eau solaire
# Version: v2025-11-16
#
# DESCRIPTION:
#   Automatisation du chauffe-eau basée sur production PV
###############################################################################
```
