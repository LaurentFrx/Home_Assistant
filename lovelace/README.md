# Workspace Lovelace Claude

Ce dossier contient le workspace dédié pour les cartes Lovelace créées avec l'aide de Claude.

## Structure

```
lovelace/
├── work.yaml              # Dashboard principal de travail
├── cards/                 # Dossier contenant toutes les cartes
│   └── [vos cartes].yaml
└── README.md              # Ce fichier
```

## Fichier work.yaml

Le fichier `work.yaml` est le dashboard principal en mode YAML. Il est accessible dans la sidebar de Home Assistant sous le nom "Workspace Claude" avec l'icône robot.

Configuration dans `configuration.yaml`:
```yaml
lovelace:
  dashboards:
    lovelace-work:
      mode: yaml
      title: Workspace Claude
      icon: mdi:robot
      show_in_sidebar: true
      filename: lovelace/work.yaml
```

## Dossier cards/

Toutes les cartes créées par Claude seront stockées dans le dossier `cards/` sous forme de fichiers YAML individuels.

### Utilisation des cartes

Quand vous demandez à Claude de créer ou modifier une carte :
1. Claude crée/modifie le fichier dans `lovelace/cards/`
2. Claude ajoute automatiquement la carte dans `work.yaml`
3. Rechargez la configuration Lovelace dans Home Assistant pour voir les changements

### Intégration d'une carte manuellement

Si vous souhaitez intégrer une carte manuellement dans `work.yaml` :

```yaml
title: Workspace Claude
views:
  - title: Cartes de test
    path: test-cards
    icon: mdi:view-dashboard
    cards:
      - !include cards/ma_carte.yaml
```

## Règles importantes

- **NE JAMAIS renommer une entité** sans demande explicite
- Les cartes sont en YAML, pas en mode UI
- Après toute modification, recharger la configuration Lovelace dans Home Assistant

## Recharger la configuration

Pour appliquer les modifications :
1. Paramètres → Tableaux de bord
2. Menu ⋮ → Ressources
3. Recharger les ressources Lovelace

Ou via Developer Tools → YAML → Tableau de bord Lovelace
