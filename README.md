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
├── packages/              # Configuration modulaire
│   └── cumulus/          # Module cumulus (architecture modulaire - 7 fichiers)
├── automations/          # Automatisations via UI
│   └── archive/          # Anciennes versions archivées
├── scripts/             # Scripts réutilisables
├── custom_components/   # Composants personnalisés (Anker Solix, Solcast)
├── lovelace/            # Dashboards et cartes
│   └── cards/           # Cartes Lovelace (2 cartes actives)
├── docs/                # Documentation complète
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
- **[docs/ETAT_ACTUEL.md](docs/ETAT_ACTUEL.md)** - ✨ État actuel complet du système (NOUVEAU 2025-11-22)
- **[docs/STYLE_GUIDE.md](docs/STYLE_GUIDE.md)** - ✨ Guide de style et conventions (NOUVEAU 2025-11-22)
- **[docs/README_CUMULUS.md](docs/README_CUMULUS.md)** - Documentation complète du système Cumulus
- **[docs/ARCHITECTURE_TECHNIQUE.md](docs/ARCHITECTURE_TECHNIQUE.md)** - Architecture technique détaillée
- **[docs/GUIDE_DEPANNAGE.md](docs/GUIDE_DEPANNAGE.md)** - Guide de dépannage
- **[docs/CLAUDE_PREFERENCES.md](docs/CLAUDE_PREFERENCES.md)** - Règles critiques Home Assistant
- **[docs/GIT_SYNC_GUIDE.md](docs/GIT_SYNC_GUIDE.md)** - Guide synchronisation Git

### Audits et Revues
- **[AUDIT_COMPLET_CUMULUS_2025-11-15.md](AUDIT_COMPLET_CUMULUS_2025-11-15.md)** - Audit complet du système (2025-11-15)
- **[CODE_STYLE_REVIEW.md](CODE_STYLE_REVIEW.md)** - Revue de style de code (2025-11-16)

### Archive & Historique
- **[docs/archive/](docs/archive/)** - 32 documents archivés
  - 📋 **changelog/** - Changelogs détaillés (8 fichiers)
  - 🔴 **bugs/** - Bugs critiques et analyses de risques (2 fichiers)
  - 🔧 **correctifs/** - Correctifs appliqués (7 fichiers)
  - 📝 **procedures/** - Guides et checklists (7 fichiers)
  - 📊 **analyses/** - Analyses techniques (7 fichiers)
  - 📚 **old_syntheses/** - Anciennes synthèses (1 fichier)

---

**Dernière mise à jour:** 2025-11-22
**Architecture:** Modulaire v2.0
