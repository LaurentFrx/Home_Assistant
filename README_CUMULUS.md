# 💧 CUMULUS INTELLIGENT v2.0 - Système de Gestion Avancé

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/LaurentFrx/Home_Assistant)
[![Home Assistant](https://img.shields.io/badge/home%20assistant-2024.x-brightgreen.svg)](https://www.home-assistant.io/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> Système de gestion intelligent pour ballon d'eau chaude avec optimisation solaire, prédictions ML et interface utilisateur exceptionnelle.

![Dashboard Preview](docs/images/dashboard-preview.png)

## ✨ Fonctionnalités Principales

### 🎯 Intelligence Artificielle
- **Prédiction température** : Modèle adaptatif de refroidissement
- **Anticipation besoins** : Analyse patterns de consommation
- **Optimisation multi-objectifs** : Stratégies personnalisables (économie, confort, préservation batterie)
- **Orchestration intelligente** : Gestion priorités avec autres appareils

### ☀️ Gestion Solaire Avancée
- **Seuils dynamiques** selon SOC batterie
- **Fenêtres horaires** configurables
- **Protection import réseau** avec limiteur
- **Priorisation APS** vs Solarbank

### 🎨 Interface Utilisateur Premium
- **Dashboard utilisateur ultra-simple** : Langage naturel, 2 actions max
- **Dashboard admin complet** : Monitoring, diagnostics, configuration
- **Widget compact** : 5 designs au choix pour dashboard principal
- **100% responsive** : Mobile-first design

### 🔧 Architecture Modulaire
- **Packages séparés** : Core, sensors, automations
- **Hot-reload** : Modifications sans redémarrage
- **Backup automatique** : Sauvegarde avant modifications
- **Migration assistée** : Script d'installation complet

## 📦 Installation

### Prérequis
- Home Assistant 2024.x ou supérieur
- Contacteur connecté (Shelly Pro 1 ou équivalent)
- Capteurs de production solaire
- Smart meter (Linky ou équivalent)

### Installation Automatique (Recommandé)

```bash
# 1. Télécharger le script d'installation
wget https://raw.githubusercontent.com/LaurentFrx/Home_Assistant/main/install_cumulus.sh

# 2. Rendre exécutable
chmod +x install_cumulus.sh

# 3. Lancer l'installation
./install_cumulus.sh --auto
```

### Installation Manuelle

1. **Copier les packages**
```bash
cp -r packages/cumulus /config/packages/
```

2. **Copier les dashboards**
```bash
cp lovelace_cumulus_*.yaml /config/lovelace/
```

3. **Modifier configuration.yaml**
```yaml
homeassistant:
  packages:
    cumulus: !include_dir_named packages/cumulus
```

4. **Recharger Home Assistant**
```bash
ha core reload
```

## 🎮 Utilisation

### Pour l'Utilisateur Final

#### Dashboard Simple
Accessible via : `http://votre-ha:8123/lovelace/cumulus-simple`

**3 informations essentielles :**
- ✅ État eau chaude (prête, tiède, froide)
- 🔮 Prochaine chauffe prévue
- 📊 Stratégie active

**2 actions seulement :**
- 🔥 Forcer une chauffe
- 🏖️ Mode vacances

### Pour l'Administrateur

#### Dashboard Admin
Accessible via : `http://votre-ha:8123/lovelace/cumulus-admin`

**Sections disponibles :**
1. **Monitoring temps réel** : Production, import, état
2. **Analyse thermique** : Graphiques 48h, historique
3. **Automations** : État, conditions, triggers
4. **Configuration** : Tous les paramètres
5. **Diagnostics** : Score santé, logs
6. **Actions rapides** : Reset, tests, export

### Configuration Initiale

#### Paramètres Essentiels

| Paramètre | Défaut | Description | Recommandation |
|-----------|---------|-------------|----------------|
| `cumulus_seuil_pv_statique_w` | 100W | Seuil démarrage PV | 50-150W selon installation |
| `cumulus_import_max_w` | 500W | Import max autorisé | Selon contrat (0-1000W) |
| `cumulus_temperature_cible_pv` | 58°C | Cible mode solaire | 55-60°C optimal |
| `cumulus_temperature_cible_hc` | 52°C | Cible heures creuses | 50-55°C économique |
| `cumulus_soc_min` | 10% | SOC minimum batterie | 5-20% selon préférence |

#### Stratégies d'Optimisation

**Économie Maximale** 💰
- Priorité absolue au solaire
- Heures creuses uniquement si critique
- Seuils élevés, températures minimales

**Confort Absolu** 🛁
- Eau chaude toujours disponible
- Chauffes préventives
- Températures élevées

**Préserver Batterie** 🔋
- Minimise cycles Solarbank
- Priorité APS direct
- Protection SOC > 30%

**Équilibré** ⚖️ (Défaut)
- Compromis intelligent
- Adaptatif selon conditions
- Recommandé pour débuter

## 🔧 Personnalisation

### Modifier via l'Interface UI

1. **Accéder à Settings > Dashboards**
2. **Éditer le dashboard souhaité**
3. **Modifier les cartes** :
   - Couleurs : Changer les gradients dans `styles`
   - Seuils : Adapter dans `templates`
   - Messages : Personnaliser les textes
   - Icônes : Remplacer les `mdi:xxx`

### Exemples de Personnalisation

#### Changer les Couleurs
```yaml
# Dans button-card styles
background: |
  [[[
    if (temp >= 55) return 'linear-gradient(135deg, #YOUR_COLOR1, #YOUR_COLOR2)';
  ]]]
```

#### Modifier les Messages
```yaml
# Dans template secondary
secondary: |
  {% if temp >= 55 %}
    Votre message personnalisé
  {% endif %}
```

#### Ajouter une Notification
```yaml
# Dans automations
- service: notify.mobile_app_your_phone
  data:
    title: "Cumulus"
    message: "{{ states('sensor.cumulus_alerte_message') }}"
```

## 📊 Architecture Technique

```
packages/cumulus/
├── core.yaml                 # Configuration de base
├── sensors_base.yaml         # Capteurs essentiels
├── sensors_calcul.yaml       # Intelligence & prédictions
├── sensors_monitoring.yaml   # Santé système
├── automations_pv.yaml       # Logique solaire
├── automations_hc.yaml       # Heures creuses
├── automations_safety.yaml   # Sécurités
└── automations_utils.yaml    # Utilitaires

lovelace/
├── cumulus_utilisateur_v2.yaml  # Dashboard simple
├── cumulus_admin_v2.yaml        # Dashboard technique
└── cumulus_widget.yaml          # Widgets compacts
```

## 🐛 Dépannage

### Le cumulus ne démarre jamais

1. **Vérifier les conditions** dans dashboard admin
2. **Contrôler les seuils** : Peut-être trop élevés ?
3. **Vérifier les verrous** : Deadband actif ?
4. **Consulter les logs** : Section diagnostic

### Chauffes trop fréquentes

1. **Augmenter `cumulus_espacement_minimal_heures`**
2. **Réduire températures cibles**
3. **Changer stratégie** vers "Économie maximale"

### Score santé dégradé

- **< 80%** : Vérifier sensors unavailable
- **< 60%** : Contrôler dernière chauffe
- **< 40%** : Intervention urgente requise

### Messages d'erreur courants

| Erreur | Cause | Solution |
|--------|-------|----------|
| `Coherence failed` | Incohérence cumulus ON mais pas d'import | Vérifier contacteur |
| `Import excessif` | Dépassement seuil | Ajuster `import_max_w` |
| `SOC trop bas` | Batterie déchargée | Attendre recharge ou ajuster `soc_min` |

## 🚀 Fonctionnalités Avancées

### API REST

```bash
# Obtenir état cumulus
curl -X GET \
  http://votre-ha:8123/api/states/sensor.cumulus_temperature_estimee \
  -H "Authorization: Bearer YOUR_TOKEN"

# Forcer chauffe
curl -X POST \
  http://votre-ha:8123/api/services/switch/turn_on \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "switch.shellypro1_ece334ee1b64"}'
```

### Intégration Node-RED

```json
{
  "id": "cumulus_flow",
  "type": "api-current-state",
  "server": "home-assistant",
  "name": "Check Cumulus",
  "entity_id": "sensor.cumulus_temperature_estimee",
  "outputs": 2
}
```

### Notifications Avancées

```yaml
automation:
  - alias: "Notification eau froide"
    trigger:
      - platform: numeric_state
        entity_id: sensor.cumulus_temperature_estimee
        below: 40
    action:
      - service: notify.telegram
        data:
          message: "⚠️ Eau froide détectée!"
          data:
            inline_keyboard:
              - text: "Forcer chauffe"
                callback_data: "/force_cumulus"
```

## 📈 Métriques et KPIs

### Tableau de Bord Énergie

| Métrique | Sensor | Objectif |
|----------|--------|----------|
| Consommation jour | `sensor.cumulus_consommation_jour` | < 6 kWh |
| Chauffes PV | `sensor.cumulus_chauffes_pv_mois` | > 70% |
| Coût mensuel | `sensor.cumulus_cout_mois` | < 30€ |
| Autonomie | `sensor.cumulus_autonomie_solaire` | > 60% |

### Graphiques Recommandés

1. **Production vs Consommation** : ApexCharts 24h
2. **Température évolution** : Mini-graph 48h
3. **Répartition modes** : Pie chart mensuel
4. **Économies réalisées** : Bar chart annuel

## 🤝 Contribution

Les contributions sont bienvenues !

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Changelog

### v2.0.0 (2024-11)
- ✨ Refonte complète architecture modulaire
- 🎨 Nouveaux dashboards UI/UX
- 🧠 Intelligence prédictive ML
- 🔧 Script installation automatique
- 📊 Système de monitoring avancé

### v1.0.0 (2024-06)
- 🎉 Version initiale
- ☀️ Gestion PV basique
- 🌙 Support heures creuses
- 📱 Dashboard simple

## 📄 License

MIT License - voir [LICENSE](LICENSE)

## 🙏 Remerciements

- Communauté Home Assistant
- Contributeurs GitHub
- Beta testeurs

## 📞 Support

- 🐛 Issues : [GitHub Issues](https://github.com/LaurentFrx/Home_Assistant/issues)
- 💬 Discord : [HA France](https://discord.gg/home-assistant-france)
- 📧 Email : laurent@example.com

---

**Made with ❤️ for Home Assistant**

*Si ce projet vous aide, n'hésitez pas à mettre une ⭐ sur GitHub !*
