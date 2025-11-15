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

### 🎯 Documents de Référence (À JOUR)

**⭐ COMMENCEZ ICI:**
- **[AUDIT_COMPLET_CUMULUS_2025-11-15.md](AUDIT_COMPLET_CUMULUS_2025-11-15.md)** - 🔴 Audit complet + problèmes résolus
- **[docs/ETAT_ACTUEL.md](docs/ETAT_ACTUEL.md)** - ✅ État réel du système (89 entités, 18 automatisations)

**Documentation Principale:**
- **[docs/README_CUMULUS.md](docs/README_CUMULUS.md)** - Documentation complète Cumulus
- **[docs/GUIDE_DEPANNAGE.md](docs/GUIDE_DEPANNAGE.md)** - Guide de dépannage
- **[docs/ARCHITECTURE_TECHNIQUE.md](docs/ARCHITECTURE_TECHNIQUE.md)** - Architecture technique détaillée

### 📊 Métriques Système

**Version actuelle:** v2025-11-15 (100% opérationnel)
- ✅ Package cumulus.yaml: 857 lignes
- ✅ Automatisations: 18 actives
- ✅ Entités: 89 (input_number: 21, sensors: 29, binary_sensors: 18)
- ✅ Dashboards: 2 (Cumulus Avancé YAML + LAU/cumu UI)

**Correctifs appliqués le 2025-11-15:**
- ✅ 14 entités manquantes critiques ajoutées
- ✅ Toutes automatisations fonctionnelles
- ✅ Documentation réorganisée et mise à jour

### 📦 Archive & Historique

**Versions importantes:**
- **[docs/archive/HISTORIQUE_VERSIONS.md](docs/archive/HISTORIQUE_VERSIONS.md)** - Timeline v2025-10-12a à v2025-11-15
- **[docs/archive/bugs/BUGS_CRITIQUES_v2025-10-14d.md](docs/archive/bugs/BUGS_CRITIQUES_v2025-10-14d.md)** - Bugs critiques résolus

**Structure archive (22 documents):**
- 📋 **changelog/** - 8 changelogs détaillés
- 🔴 **bugs/** - Analyses bugs critiques
- 🔧 **correctifs/** - 3 correctifs majeurs
- 📝 **procedures/** - 3 guides et checklists
- 📊 **analyses/** - 8 analyses techniques (dont 1 obsolète archivée)
