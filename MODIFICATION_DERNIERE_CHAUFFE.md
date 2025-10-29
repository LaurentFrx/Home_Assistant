# Modification manuelle de l heure de la derniere chauffe complete

## Date de modification
2025-10-29

## Objectif
Permettre de modifier manuellement la date et l heure de la derniere chauffe complete du cumulus via le dashboard LAU/cumu.

## Modification apportee

### Fichier : packages/cumulus.yaml

Ajout de l input_datetime manquant dans la section input_datetime (apres cumulus_heures_creuses_fin) :

  cumulus_derniere_chauffe_complete:
    name: Derniere chauffe complete
    has_date: true
    has_time: true
    icon: mdi:calendar-clock

### Fichier de backup
Un backup automatique a ete cree : cumulus.yaml.backup_20251029_100520

## Utilisation

### Dans le dashboard LAU/cumu

1. Aller sur le dashboard LAU
2. Ouvrir l onglet Cumulus (cumu)
3. Trouver l entite Derniere chauffe complete
4. Cliquer dessus pour ouvrir le selecteur de date/heure
5. Modifier la date et l heure selon vos besoins
6. Valider

### Impact sur les automatisations

Cette date est utilisee par :

1. sensor.cumulus_heures_depuis_derniere_chauffe : Calcule les heures ecoulees depuis la derniere chauffe
2. Automatisations de fin de chauffe : Met a jour automatiquement cette date quand une chauffe se termine
3. Calcul du besoin urgent : Determine si une chauffe est necessaire en fonction du temps ecoule

### Cas d usage

- Correction manuelle : Si une chauffe n a pas ete detectee automatiquement
- Initialisation : Definir une valeur initiale lors de la premiere utilisation
- Test : Forcer une date ancienne pour tester le declenchement du besoin urgent

## Notes importantes

- L entite est deja affichee dans le dashboard LAU/cumu (pas besoin de modification du dashboard)
- Les automatisations utilisent deja cette entite
- La modification manuelle sera prise en compte immediatement par tous les sensors et automatisations
