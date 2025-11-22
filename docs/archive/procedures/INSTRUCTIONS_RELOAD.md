# 🔄 INSTRUCTIONS DE RECHARGEMENT - CUMULUS V2

## ✅ STATUT : Fichiers installés avec succès !

Tous les fichiers du système Cumulus Intelligent v2 sont en place dans votre configuration Home Assistant.

---

## 🎯 ÉTAPE FINALE : Recharger Home Assistant

### MÉTHODE 1 : Rechargement rapide (Recommandé)

1. **Ouvrir Home Assistant** : http://192.168.1.29:8123
2. **Aller dans Developer Tools** (Outils de développement)
3. **Onglet YAML**
4. **Cliquer sur les boutons suivants dans cet ordre** :
   - ✅ **"Check Configuration"** (Vérifier la configuration)
   - ⏳ Attendre le résultat (devrait dire "Configuration valid!")
   - ✅ **"Reload Template Entities"** (Recharger les entités template)
   - ✅ **"Reload Automations"** (Recharger les automations)
   - ✅ **"Reload All"** (Recharger tout) - **C'est le plus important !**

**⏱️ Temps d'attente** : 30-60 secondes pour que tout se charge

---

### MÉTHODE 2 : Redémarrage complet (Si la méthode 1 ne suffit pas)

1. **Settings** > **System** > **Restart**
2. Cliquer sur **"Restart Home Assistant"**
3. Confirmer
4. ⏳ Attendre 2-3 minutes

---

## 🎨 ACCÉDER AUX NOUVEAUX DASHBOARDS

Une fois HA rechargé, créer les dashboards :

### Dashboard Utilisateur Simple

1. **Settings** > **Dashboards**
2. **+ Add Dashboard**
3. Remplir :
   - **Title** : `Cumulus - Utilisateur`
   - **Icon** : `mdi:water-boiler`
   - **URL** : `cumulus-simple`
   - Cocher : ☑️ **Show in sidebar**
   - Cocher : ☑️ **Admin only** (si vous voulez)
4. Cliquer **Create**
5. Dans le nouveau dashboard, cliquer sur **⋮** (menu) > **Edit Dashboard**
6. Cliquer sur **Raw configuration editor** (éditeur de configuration brute)
7. **Supprimer tout** le contenu
8. **Copier le contenu** du fichier : `/config/lovelace/lovelace_cumulus_utilisateur_v2.yaml`
9. **Coller** dans l'éditeur
10. Cliquer **Save**

### Dashboard Admin Complet

Répéter les mêmes étapes avec :
- **Title** : `Cumulus - Admin`
- **URL** : `cumulus-admin`
- **Fichier source** : `/config/lovelace/lovelace_cumulus_admin_v2.yaml`

### Dashboard Premium (Optionnel)

- **Title** : `Cumulus - Premium`
- **URL** : `cumulus-premium`
- **Fichier source** : `/config/lovelace/lovelace_cumulus_premium.yaml`

---

## 🔍 VÉRIFIER LES ENTITÉS

Après rechargement, vérifier que les nouvelles entités existent :

1. **Developer Tools** > **States**
2. Chercher `cumulus` dans la barre de recherche
3. Vous devriez voir apparaître :

**Capteurs principaux :**
- `sensor.cumulus_temperature_estimee`
- `sensor.cumulus_litres_disponibles`
- `sensor.cumulus_prochaine_chauffe_prevue`
- `sensor.cumulus_pv_power_w`
- `sensor.cumulus_import_reseau_w`

**Input helpers :**
- `input_number.cumulus_seuil_pv_statique_w`
- `input_number.cumulus_import_max_w`
- `input_number.cumulus_temperature_cible_pv`
- `input_select.cumulus_strategie_optimisation`
- `input_boolean.cumulus_mode_vacances`

**Automations :**
- `automation.cumulus_demarrage_pv_intelligent`
- `automation.cumulus_arret_pv_intelligent`
- `automation.cumulus_protection_import`

**Si vous voyez ces entités** : ✅ **Installation réussie !**

---

## ⚙️ CONFIGURATION INITIALE

### 1. Paramètres essentiels à configurer

Une fois les dashboards créés, ouvrir le **Dashboard Admin** et configurer :

| Paramètre | Valeur recommandée | Ajuster selon |
|-----------|-------------------|---------------|
| **Seuil PV** | 100W | Votre production solaire |
| **Import max** | 500W | Votre contrat électrique |
| **Température PV** | 58°C | Confort souhaité |
| **Température HC** | 52°C | Économies |
| **SOC minimum** | 10% | Préservation batterie |
| **Fenêtre PV** | 09:00 - 17:00 | Heures d'ensoleillement |

### 2. Choisir une stratégie

Dans `input_select.cumulus_strategie_optimisation`, choisir :
- 🍃 **Économie maximale** : Minimiser coûts
- ⚖️ **Équilibré** : Compromis (recommandé)
- 🛁 **Confort absolu** : Eau chaude garantie
- 🔋 **Préserver batterie** : Limiter usure Solarbank

---

## 🧪 TESTS DE VALIDATION

### Test 1 : Forcer une chauffe

1. Ouvrir **Dashboard Utilisateur**
2. Cliquer **"🔥 Forcer maintenant"**
3. Confirmer
4. Vérifier que `switch.shellypro1_ece334ee1b64` passe à `ON`

### Test 2 : Vérifier les conditions

Dans **Dashboard Admin** > Section **Conditions PV** :
- Production PV : devrait afficher la production actuelle
- SOC batterie : devrait afficher le niveau
- Import réseau : devrait afficher la consommation
- Fenêtre PV : devrait dire OUI ou NON selon l'heure

### Test 3 : Vérifier les automations

1. **Settings** > **Automations & Scenes**
2. Chercher `cumulus`
3. Toutes les automations doivent être **activées** (toggle bleu)

---

## 🐛 DÉPANNAGE

### Problème : "Entity not available" ou "Unknown"

**Cause** : Les noms d'entités dans votre installation sont différents

**Solution** : Identifier vos entités réelles

1. **Developer Tools** > **States**
2. Chercher vos entités :
   - Switch contacteur : chercher `switch` + `shelly` ou `cumulus`
   - Import réseau : chercher `sensor` + `grid` ou `import`
   - Production PV : chercher `sensor` + `solar` ou `pv` ou `power`

3. Adapter les fichiers dans `/config/packages/cumulus/`

**Exemple** : Si votre contacteur s'appelle `switch.contacteur_cumulus` au lieu de `switch.shellypro1_ece334ee1b64` :

```bash
# Via terminal SSH ou File Editor :
cd /config/packages/cumulus
# Remplacer dans tous les fichiers
sed -i 's/switch.shellypro1_ece334ee1b64/switch.contacteur_cumulus/g' *.yaml
# Puis recharger HA
```

### Problème : Dashboard vide ou erreur

**Causes possibles** :
1. Custom cards manquantes (button-card, mushroom, apexcharts)
2. Thème non compatible

**Solutions** :
1. Installer les custom cards via HACS :
   - **button-card**
   - **mushroom**
   - **apexcharts-card**
   - **mini-graph-card**
   - **bar-card**

2. Utiliser le dashboard widget (version simple) dans votre dashboard existant

---

## 📱 ACCÈS MOBILE

### iOS
1. Safari > http://192.168.1.29:8123/lovelace/cumulus-simple
2. Partager > Sur l'écran d'accueil
3. Nommer "Eau Chaude"

### Android
1. Chrome > http://192.168.1.29:8123/lovelace/cumulus-simple
2. Menu ⋮ > Ajouter à l'écran d'accueil
3. Nommer "Eau Chaude"

---

## ✅ CHECKLIST

- [ ] Home Assistant rechargé (YAML Reload All)
- [ ] Entités cumulus visibles dans Developer Tools
- [ ] Dashboard Utilisateur créé et fonctionnel
- [ ] Dashboard Admin créé et fonctionnel
- [ ] Paramètres configurés (seuils, températures)
- [ ] Stratégie choisie
- [ ] Test chauffe manuelle réussi
- [ ] Automations activées

---

## 📚 DOCUMENTATION

- **README complet** : `/config/README_CUMULUS.md`
- **Guide rapide** : `/config/GUIDE_CONFIG_RAPIDE.md`
- **Code source** : `/config/packages/cumulus/`

---

## 🆘 BESOIN D'AIDE ?

Si un problème persiste :
1. Vérifier les logs : **Settings** > **System** > **Logs**
2. Chercher "cumulus" ou "error" dans les logs
3. Partager l'erreur pour assistance

---

**🎉 Bon déploiement !**

*Version 2.0.0 - Système Cumulus Intelligent*
