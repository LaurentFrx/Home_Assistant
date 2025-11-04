# Home Assistant - Configuration personnelle

Configuration complète de mon installation Home Assistant pour la gestion intelligente de mon domicile.

## 📦 Packages principaux

- **Cumulus** : Automatisation du chauffe-eau électrique basée sur la production photovoltaïque et l'optimisation tarifaire (heures creuses)
- **Solaire & économies** : Suivi en temps réel de la production solaire, calcul des économies et optimisation de la consommation
- **Salle de bain (Isa collège)** : Gestion automatique du chauffage avec programmation intelligente pour les douches matinales
- **Carte batterie** : Monitoring et visualisation de la batterie Solarbank Anker

## 🏠 Intégrations principales

- **Solcast Solar** : Prévisions de production photovoltaïque
- **Anker Solix** : Gestion de la batterie domestique
- **Daikin Onecta** : Contrôle de la climatisation et du chauffage
- **Zigbee2MQTT** : Réseau domotique Zigbee

## 📁 Structure du dépôt

```
.
├── packages/              # Configuration modulaire (cumulus, solaire, etc.)
├── automations/          # Automatisations simples
├── scripts/             # Scripts réutilisables
├── custom_components/   # Composants personnalisés
├── themes/             # Thèmes d'interface
├── templates/          # Templates Jinja2
└── configuration.yaml  # Configuration principale
```

## 🚀 Fonctionnalités clés

- ⚡ Optimisation énergétique basée sur les prévisions solaires
- 🔋 Gestion intelligente du stockage sur batterie
- 🌡️ Automatisation du chauffage selon les plannings
- 📊 Tableaux de bord personnalisés pour le suivi énergétique

## 📚 Documentation

### Documentation principale
- **[docs/README_CUMULUS.md](docs/README_CUMULUS.md)** - Documentation complète du système Cumulus (À CRÉER)
- **[docs/GUIDE_INSTALLATION.md](docs/GUIDE_INSTALLATION.md)** - Guide d'installation et configuration (À CRÉER)
- **[docs/GUIDE_UTILISATION.md](docs/GUIDE_UTILISATION.md)** - Guide d'utilisation quotidienne (À CRÉER)

### Archive & Historique
- **[docs/archive/HISTORIQUE_VERSIONS.md](docs/archive/HISTORIQUE_VERSIONS.md)** - Timeline complète des versions (v2025-10-12a à v2025-11-08)
- **[docs/archive/README.md](docs/archive/README.md)** - Guide de navigation dans l'archive
- **[docs/archive/bugs/BUGS_CRITIQUES_v2025-10-14d.md](docs/archive/bugs/BUGS_CRITIQUES_v2025-10-14d.md)** - Bugs critiques corrigés (LECTURE ESSENTIELLE)

L'archive contient 21 documents organisés par catégorie :
- 📋 **changelog/** - Changelogs détaillés
- 🔴 **bugs/** - Bugs critiques et analyses de risques
- 🔧 **correctifs/** - Correctifs appliqués (7 documents)
- 📝 **procedures/** - Guides et checklists (5 documents)
- 📊 **analyses/** - Analyses techniques (6 documents)
