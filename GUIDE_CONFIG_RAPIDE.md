# 🚀 GUIDE DE CONFIGURATION RAPIDE - CUMULUS INTELLIGENT V2

## 📋 Check-list d'installation (10 minutes)

### Étape 1 : Installation automatique
```bash
# Sur votre serveur HA (SSH)
cd /config
chmod +x /home/claude/install_cumulus.sh
./install_cumulus.sh --auto
```

### Étape 2 : Configuration initiale via l'UI

#### 2.1 Accéder au dashboard Admin
```
http://192.168.1.29:8123/lovelace/cumulus-admin
```

#### 2.2 Régler les paramètres essentiels

| ⚙️ Paramètre | 🎯 Valeur recommandée | 📝 Notes |
|--------------|------------------------|----------|
| **Seuil PV** | `100W` | Baisser à 50W si beaucoup de soleil |
| **Import max** | `500W` | 0W pour zéro import réseau |
| **Température PV** | `58°C` | 55-60°C optimal |
| **Température HC** | `52°C` | 50-55°C économique |
| **SOC minimum** | `10%` | 5-20% selon préférence |
| **Fenêtre PV** | `09:00 - 17:00` | Adapter selon saison |
| **Espacement chauffes** | `24h` | 48h si peu d'utilisation |

#### 2.3 Choisir une stratégie
- 🍃 **Économie maximale** : Pour minimiser la facture
- 🛁 **Confort absolu** : Eau chaude garantie
- 🔋 **Préserver batterie** : Limiter l'usure Solarbank
- ⚖️ **Équilibré** (recommandé pour débuter)

### Étape 3 : Personnalisation des dashboards

#### 3.1 Dashboard utilisateur (pour votre femme)
```yaml
# Éditer via UI : Settings > Dashboards > Cumulus Simple > Edit

# Pour changer les messages :
secondary: |
  {% if temp >= 55 %}
    ✅ Parfait pour toute la famille  # <- Modifier ici
  {% endif %}

# Pour changer les couleurs :
background: |
  [[[
    if (temp >= 55) return 'linear-gradient(135deg, #51cf66, #69db7c)';
    # Remplacer les codes couleur hex selon préférence
  ]]]
```

#### 3.2 Ajouter le widget au dashboard principal
```yaml
# Dans votre dashboard principal, ajouter :
- !include lovelace_cumulus_widget.yaml

# Ou copier directement une des 5 versions du widget
```

### Étape 4 : Tests de validation

#### ✅ Test 1 : Forcer une chauffe
1. Ouvrir dashboard utilisateur
2. Cliquer "🔥 Forcer maintenant"
3. Vérifier que le contacteur s'active
4. Observer la montée en température

#### ✅ Test 2 : Vérifier les conditions PV
1. Attendre une journée ensoleillée
2. Observer dans dashboard admin :
   - Production APS > 100W ✓
   - SOC batterie > 10% ✓
   - Dans fenêtre PV ✓
3. Le cumulus doit démarrer automatiquement

#### ✅ Test 3 : Mode vacances
1. Activer "🏖️ Mode vacances"
2. Vérifier que les chauffes sont suspendues
3. Désactiver au retour = chauffe forcée

## 🎨 Personnalisations populaires

### Couleurs personnalisées
```yaml
# Palette pastel douce
Vert: #a8e6cf → #c3f0ca
Orange: #ffd3b6 → #ffaaa5
Bleu: #8fcaca → #a8dadc
Rouge: #ff8b94 → #ffaaa5

# Palette sombre élégante
Vert: #2d6a4f → #40916c
Orange: #e76f51 → #f4a261
Bleu: #264653 → #2a9d8f
Rouge: #e63946 → #f1faee

# Palette moderne vibrante
Vert: #06ffa5 → #00e676
Orange: #ffb700 → #ff6b35
Bleu: #0336ff → #0091ea
Rouge: #ff0266 → #d50000
```

### Messages personnalisés
```yaml
# Remplacer dans sensors_calcul.yaml
"✅ Parfait pour toute la famille" → "✅ C'est tout bon !"
"⚠️ OK pour 1 douche" → "⚠️ Juste une douche"
"❌ Eau froide" → "❌ C'est froid !"
"🔮 Demain avec le soleil" → "🔮 Demain si beau temps"
```

### Icônes alternatives
```yaml
mdi:water-boiler → mdi:water-pump
mdi:fire → mdi:radiator
mdi:solar-power → mdi:white-balance-sunny
mdi:moon-waning-crescent → mdi:weather-night
mdi:beach → mdi:airplane
```

## 🔧 Dépannage rapide

### ❌ Problème : "Entity not found"
```yaml
# Vérifier dans Developer Tools > States
sensor.smart_meter_grid_import  # Doit exister
sensor.aps_power_w               # Doit exister
switch.shellypro1_ece334ee1b64  # Doit exister

# Si différent, adapter dans sensors_base.yaml
```

### ❌ Problème : Dashboard ne s'affiche pas
```bash
# Vérifier les packages
ls -la /config/packages/cumulus/
# Doit contenir : core.yaml, sensors_*.yaml, automations_*.yaml

# Recharger
ha core check
ha core reload
```

### ❌ Problème : Cumulus ne démarre jamais
```yaml
# Baisser les seuils dans dashboard admin :
Seuil PV: 50W (au lieu de 100W)
SOC minimum: 5% (au lieu de 10%)
Import max: 1000W (au lieu de 500W)

# Vérifier fenêtre PV active :
09:00 - 17:00 (élargir si besoin)
```

## 📊 Métriques à surveiller

### Dashboard Admin - KPIs importants
- **Score santé** > 80% = Bon
- **Autonomie solaire** > 60% = Excellent
- **Température moyenne** > 50°C = Confort
- **Coût mensuel** < 15€ = Économique

### Alertes à configurer
```yaml
# Dans automations (ajouter si souhaité)
- alias: "Alerte eau froide"
  trigger:
    platform: numeric_state
    entity_id: sensor.cumulus_temperature_estimee
    below: 40
    for: "01:00:00"
  action:
    service: notify.mobile_app_votre_telephone
    data:
      title: "⚠️ Cumulus"
      message: "Eau froide depuis 1h !"
```

## 🎯 Optimisations avancées

### Pour maximiser l'autonomie solaire
1. **Stratégie** : "Économie maximale"
2. **Fenêtre PV** : 10:00 - 16:00 (heures de production max)
3. **Température cible PV** : 60°C (stocker plus de chaleur)
4. **Seuil PV** : 150W (attendre plus de soleil)

### Pour minimiser les coûts
1. **Désactiver** chauffes HC si soleil prévu lendemain
2. **Température HC** : 50°C (minimum confort)
3. **Espacement** : 48h minimum
4. **Import max** : 0W (aucun import)

### Pour préserver la batterie
1. **Stratégie** : "Préserver batterie"
2. **SOC minimum** : 30%
3. **Privilégier** production APS directe
4. **Éviter** décharges profondes

## 📱 Accès rapide mobile

### Ajouter à l'écran d'accueil (iOS)
1. Ouvrir Safari
2. Aller sur : `http://192.168.1.29:8123/lovelace/cumulus-simple`
3. Partager > Sur l'écran d'accueil
4. Nommer : "Eau Chaude"

### Ajouter à l'écran d'accueil (Android)
1. Ouvrir Chrome
2. Aller sur : `http://192.168.1.29:8123/lovelace/cumulus-simple`
3. Menu ⋮ > Ajouter à l'écran d'accueil
4. Nommer : "Eau Chaude"

## 💡 Tips & Astuces

### Astuce 1 : Prédire les besoins
- Weekend = +20% consommation eau
- Hiver = +30% besoins
- Invités = Forcer chauffe la veille

### Astuce 2 : Synchroniser avec routine
- Douches matin → Chauffe nuit précédente
- Douches soir → Chauffe midi solaire
- Variable → Mode équilibré

### Astuce 3 : Maintenance préventive
- Vérifier **score santé** chaque semaine
- Tester **contacteur** mensuellement
- Nettoyer **historique** annuellement

## 🆘 Support

### Documentation complète
- README : `/home/claude/README_CUMULUS.md`
- Architecture : `/config/packages/cumulus/`

### Logs et debug
```bash
# Voir logs cumulus
grep -i cumulus /config/home-assistant.log

# Mode debug
# Activer dans dashboard admin > Configuration > Mode debug
```

### Contact
- GitHub Issues : [github.com/LaurentFrx/Home_Assistant/issues](https://github.com/LaurentFrx/Home_Assistant/issues)
- Forum HA : [community.home-assistant.io](https://community.home-assistant.io)

## ✅ Checklist finale

- [ ] Installation des packages complétée
- [ ] Dashboards accessibles
- [ ] Paramètres initiaux configurés
- [ ] Test de chauffe forcée réussi
- [ ] Widget ajouté au dashboard principal
- [ ] Accès mobile configuré
- [ ] Notifications activées
- [ ] Stratégie choisie
- [ ] Documentation sauvegardée

---

**🎉 Félicitations ! Votre système Cumulus Intelligent v2 est opérationnel !**

*Version 2.0.0 - Novembre 2024*
