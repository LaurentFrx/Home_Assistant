# 🔧 Guide de Dépannage - Cumulus Intelligent

**Version :** 1.0
**Dernière mise à jour :** 03 novembre 2025

---

## 🎯 MÉTHODOLOGIE DE DIAGNOSTIC

### Approche systématique

1. **Observer** le symptôme précis
2. **Vérifier** les sensors/binary_sensors concernés
3. **Consulter** les attributs pour détails
4. **Consulter** les logs Home Assistant
5. **Appliquer** la solution
6. **Valider** le correctif

---

## 🔴 PROBLÈMES CRITIQUES

### 1. Cumulus ne démarre JAMAIS (ni PV ni HC)

#### Symptômes
- Contacteur reste OFF en permanence
- Aucune chauffe depuis plusieurs jours
- `binary_sensor.cumulus_conditions_pv_ok` toujours OFF

#### Diagnostic étape par étape

**Étape 1 - Vérifier modes bloquants**
```yaml
Vérifier :
- input_boolean.cumulus_interdit = OFF
- input_boolean.cumulus_vacances = OFF
- input_boolean.cumulus_verrou_jour = OFF (se réinitialise minuit)
```

**Étape 2 - Vérifier entités critiques**
```yaml
Consulter sensor.cumulus_sante_systeme :
- Score < 25% → Entités manquantes
- Vérifier attribut "entites_valides"
- Vérifier chaque entité listée unavailable
```

**Étape 3 - Vérifier contacteur**
```yaml
Tester manuellement :
- Aller dans switch.shellypro1_xxx
- Activer manuellement → Cumulus chauffe ?
- Si NON → Problème électrique/contacteur
- Si OUI → Problème logique HA
```

**Étape 4 - Vérifier automations**
```yaml
Dans Paramètres > Automations :
- cumulus_on_pv_automatique = activée ?
- cumulus_on_hc_intelligent = activée ?
```

#### Solutions

| Cause | Solution |
|-------|----------|
| Mode interdit actif | Désactiver `input_boolean.cumulus_interdit` |
| Verrou jour bloqué | Attendre minuit OU réinitialiser manuellement |
| Entité unavailable | Vérifier intégration (Shelly, capteurs) |
| Automation désactivée | Réactiver dans interface |
| Contacteur HS | Vérifier câblage/remplacer contacteur |

---

### 2. Cumulus chauffe EN CONTINU (ne s'arrête pas)

#### Symptômes
- Contacteur reste ON pendant heures
- Import réseau très élevé
- `binary_sensor.cumulus_chauffe_reelle` = ON en permanence

#### Diagnostic

**Étape 1 - Vérifier override**
```yaml
input_boolean.cumulus_override = ON ?
→ Si OUI : Désactiver pour reprendre logique auto
```

**Étape 2 - Vérifier détection fin chauffe**
```yaml
Consulter binary_sensor.cumulus_chauffe_reelle :
- Attribut "consommation_w" = combien ?
- Si < 500W → Thermostat a coupé mais pas détecté
```

**Étape 3 - Vérifier automations fin chauffe**
```yaml
Chercher dans logs HA :
- "Fin chauffe universelle" déclenché ?
- "Fallback fin HC" déclenché ?
- Si rien → Automations peut-être désactivées
```

#### Solutions

| Cause | Solution |
|-------|----------|
| Override oublié | Désactiver `input_boolean.cumulus_override` |
| Thermostat défectueux | Vérifier température réelle > 65°C, remplacer thermostat |
| Automation désactivée | Réactiver `cumulus_fin_chauffe_universelle` |
| Seuil détection trop bas | Vérifier `input_number.cumulus_puissance_w` = 3000W |

**Action d'urgence :**
```yaml
# Couper manuellement
switch.shellypro1_xxx: OFF
# Puis diagnostiquer à froid
```

---

### 3. binary_sensor.cumulus_chauffe_reelle = unavailable

#### Symptômes
- Sensor toujours grisé
- Pas de détection chauffe
- Attributs vides ou incomplets

#### Diagnostic

**Vérifier sources de données**
```yaml
Consulter attributs du sensor :
- import_w = valeur ou unavailable ?
- pv_total_w = valeur ou unavailable ?
- talon_w = valeur ou unavailable ?
- switch_state = on/off ou unknown ?
- all_sources_available = true/false ?
```

#### Solutions

| Source manquante | Action |
|------------------|--------|
| `sensor.cumulus_import_reseau_w` | Vérifier intégration compteur Linky/Shelly EM |
| `sensor.cumulus_pv_power_w` | Vérifier intégration onduleur/APS |
| Switch contacteur | Vérifier connexion Shelly |
| `input_number.cumulus_talon_maison_w` | Créer si absent (défaut 300) |

**Si toutes sources OK mais sensor unavailable :**
```yaml
# Forcer recalcul
1. Ouvrir Configuration > Outils > YAML > Recharger sensors
2. Ou redémarrer Home Assistant
```

---

## 🟠 PROBLÈMES FRÉQUENTS

### 4. Cumulus ne chauffe PLUS en heures creuses

#### Symptômes
- Chauffe PV fonctionne
- Mais jamais de chauffe HC même après plusieurs jours
- `binary_sensor.cumulus_autoriser_chauffe_hc_intelligente` = OFF

#### Diagnostic
```yaml
Vérifier :
1. sensor.cumulus_heures_depuis_derniere_chauffe < 50h ?
2. binary_sensor.cumulus_meteo_favorable_demain = ON ?

→ Si les 2 = OUI : Normal, système évite HC (logique intelligente)
```

**Comprendre la logique :**
- Chauffe HC **activée** si :
  - Besoin urgent (>50h) **OU**
  - Météo mauvaise demain (<8 kWh prévu)
- Sinon HC **évitée** (économie)

#### Solutions

| Situation | Action |
|-----------|--------|
| Vous voulez forcer HC ce soir | Activer `input_boolean.cumulus_override` |
| Espacement 50h trop long | Réduire `cumulus_espacement_max_h` à 36-40h |
| Pas confiance Solcast | Désactiver temporairement intégration Solcast |
| Toujours forcer HC | `input_boolean.cumulus_autoriser_hc` = OFF (déconseillé) |

---

### 5. Température estimée incohérente

#### Symptômes
- Dashboard affiche 45°C mais eau semble froide
- Ou affiche 30°C mais eau très chaude
- Écart > 10°C avec réalité

#### Cause
Modèle thermique simplifié (déperdition fixe 0,3°C/h)

#### Solutions

**Solution temporaire - Ajuster déperdition**
```yaml
# Dans packages/cumulus.yaml, ligne ~600
# Modifier selon isolation cumulus :

# Cumulus récent (< 5 ans), bien isolé
deperdition_par_heure: 0.2

# Cumulus moyen (5-10 ans)
deperdition_par_heure: 0.3  # ← Valeur actuelle

# Cumulus ancien (> 10 ans), peu isolé
deperdition_par_heure: 0.4
```

**Solution définitive**
- Installer sonde température physique (DS18B20 + ESP32)
- Remplacer estimation par mesure réelle

**Workaround**
- Modifier manuellement après chaque chauffe :
```yaml
  input_datetime.cumulus_derniere_chauffe_complete: [date/heure réelle]
```

---

### 6. Démarrages PV trop fréquents (ON/OFF rapides)

#### Symptômes
- Cumulus démarre puis s'arrête toutes les 5-10 min
- Import oscille sans cesse
- Usure prématurée contacteur

#### Diagnostic
```yaml
Vérifier :
1. sensor.cumulus_pv_disponible_w oscille ?
2. timer.cumulus_deadband_ui = active en permanence ?
3. Logs : "Variation brutale détectée" fréquents ?
```

#### Solutions

| Cause | Solution |
|-------|----------|
| Nuages intermittents | Augmenter `cumulus_seuil_pv_on_w` à 200-300W |
| Appareils domestiques variables | Augmenter `cumulus_seuil_variation_brutale_w` à 500W |
| Deadband trop court | Augmenter `cumulus_deadband_min` à 10-15 min |
| Marge sécurité trop faible | Augmenter `cumulus_marge_secu_pv` à 1.3-1.5 |

---

### 7. Import réseau élevé pendant chauffe PV

#### Symptômes
- Cumulus chauffe en "mode PV"
- Mais import réseau > 1000W
- `binary_sensor.cumulus_conditions_pv_ok` = ON

#### Diagnostic

**Comprendre le calcul**
```
Puissance dispo = (PV_total × marge_secu) - talon_maison
Seuil démarrage = cumulus_seuil_pv_on_w (défaut 100W)

Exemple :
PV = 3500W, talon = 300W, marge = 1.2
Dispo = (3500 × 1.2) - 300 = 3900W
→ Démarre car 3900W > 100W (seuil)
→ Mais cumulus consomme 3000W
→ Import = 3000W - 3500W = -500W (export théorique)
→ Mais si talon réel = 800W (±500W variation)
→ Import réel = 3000W - 3500W + 500W = 0W (OK)
```

#### Solutions

| Cause | Solution |
|-------|----------|
| Talon mal estimé | Recalculer talon moyen sur 1 semaine |
| Marge trop optimiste | Réduire `cumulus_marge_secu_pv` à 1.0-1.1 |
| Seuil démarrage trop bas | Augmenter `cumulus_seuil_pv_on_w` à 200-300W |
| Charges variables nombreuses | Augmenter `cumulus_seuil_conso_domestique_w` |

**Solution idéale :**
- Installer compteur dédié circuit cumulus (Shelly EM)
- Éliminer calcul indirect

---

### 8. Notifications trop fréquentes

#### Symptômes
- Alertes "incohérence" multiples par jour
- Notifications "entité unavailable" récurrentes
- Spam de notifications

#### Diagnostic
```yaml
Identifier le type d'alerte :
1. "Incohérence détectée" → binary_sensor.cumulus_etat_coherent
2. "Entité unavailable" → automation alerte_entite_unavailable
3. "Santé dégradée" → sensor.cumulus_sante_systeme < 70%
```

#### Solutions

**Pour incohérences répétées :**
```yaml
Consulter attribut "details" du binary_sensor.cumulus_etat_coherent
→ Identifie la vraie cause (ex: verrou + besoin urgent)
→ Corriger la cause racine
```

**Pour entités unavailable :**
```yaml
Identifier quelle entité :
- Vérifier intégration concernée
- Stabiliser connexion
- Ou retirer sensor si non critique
```

**Pour santé dégradée :**
```yaml
Consulter attributs evaluation_* :
- Identifier composante < 100%
- Corriger selon diagnostic
```

**Désactiver temporairement :**
```yaml
# En mode vacances
input_boolean.cumulus_vacances = ON

# Ou désactiver automation spécifique
```

---

## 🟡 PROBLÈMES MINEURS

### 9. Historique chauffes vide

#### Symptômes
- `sensor.cumulus_historique_chauffes_display` vide
- Pas de traçabilité

#### Solutions
```yaml
1. Vérifier automation "enregistrement_debut_chauffe" active
2. Si input_text.cumulus_historique_chauffes vide :
   → Normal si jamais chauffé depuis installation
3. Attendre 1 chauffe complète pour initialiser
```

---

### 10. Dashboard Lovelace affichage incorrect

#### Symptômes
- Cartes vides ou erreurs
- Graphique ne s'affiche pas
- Chips manquants

#### Solutions

**Vérifier dépendances HACS :**
```yaml
Requis :
- mushroom-title-card
- mushroom-chips-card
- mushroom-entity-card
- mini-graph-card
```

**Forcer reload :**
```yaml
CTRL + F5 (ou CMD + SHIFT + R sur Mac)
→ Vide cache navigateur
```

**Vérifier entités :**
```yaml
Si carte vide :
→ Clic droit > Inspecter élément
→ Console : erreur "entity not found" ?
→ Vérifier nom entité correct
```

---

## 🔍 OUTILS DE DIAGNOSTIC AVANCÉS

### Activer logs détaillés
```yaml
# Dans configuration.yaml
logger:
  default: warning
  logs:
    homeassistant.components.template: debug
    homeassistant.components.automation: debug
```

### Vérifier état complet système
```yaml
# Services > Developer Tools > États
Filtrer : "cumulus"
→ Voir toutes entités + attributs
```

### Consulter historique détaillé
```yaml
# Historique > Sélectionner entité
sensor.cumulus_temperature_estimee
→ Graphique évolution 7 derniers jours
```

### Tester automation manuellement
```yaml
# Services > Developer Tools > Services
Service : automation.trigger
Entité : automation.cumulus_on_pv_automatique
→ Force déclenchement manuel (ignore conditions)
```

---

## 📋 CHECKLIST DIAGNOSTIC COMPLET

### Avant de demander de l'aide

- [ ] README principal consulté
- [ ] Section problème correspondant vérifiée
- [ ] Sensors critiques vérifiés (cumulus_sante_systeme)
- [ ] Logs Home Assistant consultés (1h historique)
- [ ] Attributs sensors examinés
- [ ] Version système identifiée (v2025-10-14h ou v2025-11-08)
- [ ] Tests manuels effectués (contacteur, override)

### Informations à collecter
```yaml
# Copier ces infos si besoin support
Version HA :
Version cumulus.yaml :
Symptôme précis :
Depuis quand :
Actions tentées :
Logs pertinents :
États sensors critiques :
  - sensor.cumulus_sante_systeme :
  - binary_sensor.cumulus_etat_coherent :
  - binary_sensor.cumulus_chauffe_reelle :
```

---

## 🚨 ACTIONS D'URGENCE

### Eau froide imminente (invités ce soir)
```yaml
1. Activer input_boolean.cumulus_override = ON
2. Vérifier contacteur passe ON
3. Attendre 2h (chauffe complète)
4. Désactiver override après
```

### Facture EDF anormale (cumulus chauffe trop)
```yaml
1. Consulter historique chauffes (10 dernières)
2. Si > 1 chauffe/jour : Activer input_boolean.cumulus_interdit
3. Diagnostiquer pourquoi verrou_jour ne fonctionne pas
4. Corriger puis réactiver
```

### Système instable (redémarrages fréquents)
```yaml
1. Passer en mode dégradé :
   - cumulus_interdit = ON (arrêt auto)
   - cumulus_autoriser_hc = OFF (chauffe manuelle HC)
2. Diagnostiquer à froid
3. Corriger
4. Réactiver progressivement
```

---

## 📞 ESCALADE

### Si aucune solution ne fonctionne

1. **Sauvegarder état actuel**
```yaml
   # Exporter configuration
   Configuration > System > Backup
```

2. **Mode dégradé**
```yaml
   # Désactiver automations cumulus
   # Gestion manuelle temporaire
```

3. **Collecter diagnostics**
```yaml
   - Logs complets (24h)
   - États tous sensors
   - Configuration cumulus.yaml
   - Version HA
```

4. **Documenter chronologie**
```
   - Quand problème apparu
   - Modifications récentes
   - Comportement avant/après
```

---

**🎯 90% des problèmes résolus avec ce guide - Bonne chance !**
