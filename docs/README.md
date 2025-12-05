# 💧 CUMULUS V3 DASHBOARD - Application Eau Chaude

> Dashboard Home Assistant niveau application pour la gestion intelligente du chauffe-eau électrique

![Version](https://img.shields.io/badge/version-3.0.0-blue)
![HA Version](https://img.shields.io/badge/Home%20Assistant-2024.x+-brightgreen)
![Style](https://img.shields.io/badge/style-Glassmorphism-orange)

---

## ✨ Caractéristiques

### 🎨 Design Premium
- **Glassmorphisme** aux teintes chaudes (copper, amber, terracotta)
- **Inspiration Tesla** - Minimaliste et élégant
- **Mobile-first** - Optimisé pour iPhone (80%), iPad Pro (15%), PC (5%)
- **Animations fluides** - Feedback tactile et transitions CSS3

### 📱 Navigation App-Like
- **Bottom navigation bar** style iOS
- **Pop-ups** pour sous-vues (pas de changement de page)
- **Touch targets** 48px minimum
- **Safe areas** iOS supportées

### 🔥 Fonctionnalités
- **Carte héro** avec température temps réel et état
- **KPIs** : douches disponibles, énergie, batterie
- **Graphiques** température 24h/7j, consommation
- **Réglages** accessibles sans quitter le dashboard
- **Vue debug** pour le monitoring technique

---

## 📦 Contenu du Package

```
cumulus_v3_dashboard/
├── themes/
│   └── warm_glassmorphism.yaml      # Thème complet
├── packages/
│   └── cumulus_v3_dashboard_sensors.yaml  # Sensors calculés
├── lovelace/
│   └── dashboard_cumulus_v3.yaml    # Dashboard principal
├── button_card_templates.yaml       # Templates réutilisables
├── install_cumulus_v3_dashboard.sh  # Script d'installation
└── README.md                        # Ce fichier
```

---

## 🔧 Prérequis

### Cartes Custom (HACS)
Installez ces cartes depuis HACS **avant** l'installation :

| Carte | Obligatoire | Usage |
|-------|-------------|-------|
| [bubble-card](https://github.com/Clooos/Bubble-Card) | ✅ Oui | Navigation, pop-ups, bottom bar |
| [button-card](https://github.com/custom-cards/button-card) | ✅ Oui | Boutons personnalisés |
| [apexcharts-card](https://github.com/RomRider/apexcharts-card) | ✅ Oui | Graphiques |
| [card-mod](https://github.com/thomasloven/lovelace-card-mod) | ✅ Oui | Styling CSS |
| [mushroom](https://github.com/piitaya/lovelace-mushroom) | ⚠️ Recommandé | Cartes compactes |

### Entités Requises
Le dashboard est configuré pour ces entités :

| Fonction | Entity ID | Notes |
|----------|-----------|-------|
| Contacteur cumulus | `switch.shellypro1_ece334ee1b64` | Shelly Pro 1 |
| Température | `sensor.thermo_cumulus_temperature` | Sonde SNZB-02LD |
| Import réseau | `sensor.smart_meter_grid_import` | Linky |
| SOC Batterie | `sensor.system_sanguinet_etat_de_charge_du_sb` | SolarBank |
| Production PV | `sensor.pv_total_entree_sb_aps_w` | Total PV |
| Solcast aujourd'hui | `sensor.solcast_pv_forecast_previsions_pour_aujourd_hui` | Prévisions |
| Solcast demain | `sensor.solcast_pv_forecast_previsions_pour_demain` | Prévisions |
| Lave-linge | `sensor.lave_linge_power` | Optionnel |
| Lave-vaisselle | `sensor.lave_vaisselle_power` | Optionnel |

---

## 🚀 Installation

### Méthode 1 : Script Automatique (Recommandé)

```bash
# 1. Copier les fichiers sur le serveur HA
# (via SCP, Samba, ou File Editor)

# 2. Se connecter en SSH
ssh root@192.168.1.29

# 3. Naviguer vers le dossier
cd /config/cumulus_v3_dashboard

# 4. Rendre le script exécutable
chmod +x install_cumulus_v3_dashboard.sh

# 5. Lancer l'installation (simulation d'abord)
./install_cumulus_v3_dashboard.sh --dry-run

# 6. Si OK, lancer l'installation réelle
./install_cumulus_v3_dashboard.sh --backup
```

### Méthode 2 : Installation Manuelle

#### Étape 1 : Copier les fichiers

```bash
# Thème
cp themes/warm_glassmorphism.yaml /config/themes/

# Package sensors
cp packages/cumulus_v3_dashboard_sensors.yaml /config/packages/

# Templates button-card
cp button_card_templates.yaml /config/

# Dashboard (optionnel - peut être ajouté via UI)
cp lovelace/dashboard_cumulus_v3.yaml /config/lovelace/
```

#### Étape 2 : Configurer configuration.yaml

Ajoutez ou vérifiez ces lignes :

```yaml
homeassistant:
  packages: !include_dir_named packages

frontend:
  themes: !include_dir_merge_named themes

# Templates button-card
button_card_templates: !include button_card_templates.yaml
```

#### Étape 3 : Recharger

```bash
# Via SSH
ha core check
ha core reload

# Ou via UI
# Configuration → Contrôle du serveur → Recharger
```

#### Étape 4 : Ajouter le Dashboard

**Option A - Via fichier YAML :**
1. Paramètres → Tableaux de bord
2. Ajouter un tableau de bord
3. Choisir "Utiliser une vue existante d'un fichier YAML"
4. Entrer le chemin : `lovelace/dashboard_cumulus_v3.yaml`

**Option B - Via UI :**
1. Créer un nouveau dashboard
2. Passer en mode YAML (⋮ → Modifier en YAML)
3. Coller le contenu de `dashboard_cumulus_v3.yaml`

#### Étape 5 : Activer le Thème

1. Cliquer sur votre profil (en bas à gauche)
2. Thème → Sélectionner "Warm Glassmorphism"

---

## 🎛️ Personnalisation

### Modifier les Entity IDs

Si vos entités ont des noms différents, modifiez-les dans :

1. **`cumulus_v3_dashboard_sensors.yaml`** - Sensors calculés
2. **`dashboard_cumulus_v3.yaml`** - Dashboard (rechercher/remplacer)

Exemple de recherche/remplacement :
```
switch.shellypro1_ece334ee1b64 → switch.votre_switch
sensor.thermo_cumulus_temperature → sensor.votre_sonde
```

### Modifier les Couleurs

Dans `warm_glassmorphism.yaml`, ajustez les variables :

```yaml
# Couleurs principales
warm-copper: "#D4915D"      # Accent principal
warm-amber: "#CF9C6B"       # Accent secondaire
warm-bronze: "#E8B88A"      # Highlights

# Backgrounds
glass-bg-dark: "rgba(45, 38, 32, 0.55)"  # Opacité des cartes
```

### Ajouter des Vues

Pour ajouter une nouvelle vue pop-up :

```yaml
# Dans dashboard_cumulus_v3.yaml, ajouter :

- type: vertical-stack
  cards:
    - type: custom:bubble-card
      card_type: pop-up
      hash: "#ma-nouvelle-vue"
      name: Ma Nouvelle Vue
      icon: mdi:plus
      # ... configuration

    # Contenu de la vue
    - type: entities
      entities:
        - entity: sensor.mon_sensor
```

Puis ajouter un bouton de navigation :
```yaml
- type: custom:button-card
  name: Ma Vue
  tap_action:
    action: navigate
    navigation_path: "#ma-nouvelle-vue"
```

---

## 📐 Architecture du Dashboard

```
┌─────────────────────────────────────────────────────┐
│                   VUE PRINCIPALE                     │
│  ┌─────────────────────────────────────────────┐   │
│  │          CARTE HÉRO (Température)           │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │ Douches │ │ Énergie │ │Batterie │  ← KPIs      │
│  └─────────┘ └─────────┘ └─────────┘               │
│  ┌─────────────────────────────────────────────┐   │
│  │        Graphique Température 24h            │   │
│  └─────────────────────────────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐                 │
│  │🔥 Forcer     │ │🏖️ Vacances   │  ← Actions     │
│  └──────────────┘ └──────────────┘                 │
│  ┌─────────────────────────────────────────────┐   │
│  │           Statut Solaire                     │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   POP-UPS                            │
│  #cumulus-details   → Détails + Contrôle            │
│  #cumulus-historique → Graphiques 7 jours           │
│  #cumulus-energie   → Production solaire + Batterie │
│  #cumulus-reglages  → Paramètres                    │
│  #cumulus-debug     → Sensors techniques            │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│               BOTTOM NAVIGATION BAR                  │
│  [ Accueil ] [ Cumulus ] [ Énergie ] [ Réglages ]  │
└─────────────────────────────────────────────────────┘
```

---

## 🐛 Dépannage

### Le dashboard ne s'affiche pas

1. Vérifier que toutes les cartes HACS sont installées
2. Vider le cache du navigateur (Ctrl+Shift+R)
3. Vérifier les logs HA : Configuration → Logs

### Entité non trouvée

1. Vérifier le nom exact dans Developer Tools → States
2. Modifier l'entity_id dans les fichiers YAML
3. Recharger la configuration

### Thème non appliqué

1. Recharger les thèmes : Outils de développement → Services → `frontend.reload_themes`
2. Sélectionner le thème dans le profil utilisateur

### Pop-ups ne s'ouvrent pas

1. Vérifier que bubble-card est bien installé
2. Vérifier la syntaxe du `hash` (doit commencer par `#`)
3. Vérifier la `navigation_path` des boutons

### Graphiques vides

1. Vérifier que les sensors ont des données historiques
2. Attendre quelques heures pour l'accumulation de données
3. Vérifier que recorder est configuré pour ces entités

---

## 📊 Sensors Créés

Le package `cumulus_v3_dashboard_sensors.yaml` crée automatiquement :

| Sensor | Type | Description |
|--------|------|-------------|
| `sensor.cumulus_v3_puissance_w` | Power | Puissance (3000W ou 0W) |
| `sensor.cumulus_v3_temperature_c` | Temperature | Température formatée |
| `sensor.cumulus_v3_surplus_pv` | Power | Surplus PV disponible |
| `sensor.cumulus_v3_etat` | Text | État textuel |
| `sensor.cumulus_v3_douches_disponibles` | Count | Estimation douches |
| `sensor.cumulus_v3_message_famille` | Text | Message pour dashboard |
| `sensor.cumulus_v3_duree_chauffe` | Duration | Durée chauffe en cours |
| `sensor.cumulus_v3_prochaine_chauffe` | Text | Prédiction prochaine chauffe |
| `sensor.cumulus_v3_energie_journaliere` | Energy | Consommation du jour |
| `sensor.cumulus_v3_energie_hebdomadaire` | Energy | Consommation semaine |
| `sensor.cumulus_v3_energie_mensuelle` | Energy | Consommation mois |
| `binary_sensor.cumulus_v3_en_chauffe` | Binary | État chauffe |
| `binary_sensor.cumulus_v3_temperature_ok` | Binary | Température confort |
| `binary_sensor.cumulus_v3_surplus_pv_ok` | Binary | Surplus suffisant |

---

## 📱 Accès Mobile

### Ajouter à l'écran d'accueil (iPhone)

1. Ouvrir Safari → `http://votre-ha:8123/lovelace/eau-chaude`
2. Tap sur l'icône Partage (carré avec flèche)
3. "Sur l'écran d'accueil"
4. Nommer "Eau Chaude" → Ajouter

### Application Companion

1. Installer Home Assistant Companion depuis l'App Store
2. Configurer votre serveur
3. Aller dans l'app → Paramètres → Companion App → Navigation
4. Ajouter "/lovelace/eau-chaude" comme raccourci

---

## 🔄 Mises à jour

Pour mettre à jour le dashboard :

```bash
# 1. Sauvegarder l'existant
cp /config/lovelace/dashboard_cumulus_v3.yaml /config/lovelace/dashboard_cumulus_v3.yaml.bak

# 2. Copier la nouvelle version
cp nouvelle_version/dashboard_cumulus_v3.yaml /config/lovelace/

# 3. Recharger
ha core reload
```

---

## 📄 Licence

MIT License - Libre d'utilisation et de modification.

---

## 🙏 Crédits

- [Bubble Card](https://github.com/Clooos/Bubble-Card) par Clooos
- [Button Card](https://github.com/custom-cards/button-card)
- [ApexCharts Card](https://github.com/RomRider/apexcharts-card)
- Design inspiré par Tesla UI et Apple iOS

---

**Créé avec ❤️ pour Home Assistant**
