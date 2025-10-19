# ✅ TEST CHECKLIST — Cumulus v2025-10-12a

**Utilisez cette checklist pour valider le déploiement de la version v2025-10-12a.**

---

## 📋 TESTS PRÉ-DÉPLOIEMENT

### **1. Validation syntaxe YAML**
- [ ] **Configuration** → **YAML** → **Check Configuration** → ✅ VALID

### **2. Vérification backup**
- [ ] Fichier `cumulus_backup_20251012_100120.yaml` existe dans `packages/`
- [ ] Taille du backup ≈ taille du fichier original

---

## 🔍 TESTS POST-DÉPLOIEMENT

### **PHASE 1 : Vérification des entités (Developer Tools → States)**

#### **Helper créé**
- [ ] `input_number.cumulus_alpha_aps` existe
- [ ] Valeur affichée = **0.88**
- [ ] Min/Max/Step : 0.5 / 1.0 / 0.01 ✅

#### **Nouveaux sensors**
- [ ] `sensor.cumulus_sb_dispo_w` existe et affiche une valeur ≥ 0
- [ ] `sensor.cumulus_capacity_factor` existe et affiche une valeur entre 0.0 et 1.0
- [ ] `sensor.cumulus_pv_effectif_w` existe et affiche une valeur ≥ 0
- [ ] `sensor.cumulus_pv_effectif_w` ≤ `sensor.cumulus_pv_power_w` (toujours)

#### **Sensor modifié**
- [ ] `sensor.cumulus_seuil_pv_dynamique_w` existe
- [ ] Attributs `pv_effectif_actuel_w` et `pv_brut_actuel_w` visibles

#### **Automations**
- [ ] Automation `ce_on_pv_simple` active (pas d'erreurs)
- [ ] Automation `cumulus_log_refus_demarrage` active

---

### **PHASE 2 : Tests fonctionnels des sensors**

#### **Test 1 : Capacity Factor**
**Contexte :** Vérifier que le capacity factor est cohérent.

1. Noter la valeur de `sensor.cumulus_pv_power_w` : _______ W
2. Noter SB_max (`input_number.cumulus_solarbank_max_w`) : _______ W
3. Noter APS_max (`input_number.cumulus_aps_max_w`) : _______ W
4. Calculer manuellement : `PV / (SB_max + APS_max)` = _______
5. Comparer avec `sensor.cumulus_capacity_factor` : _______

- [ ] Les valeurs correspondent (±0.01)

#### **Test 2 : PV Effectif**
**Contexte :** Vérifier le calcul PV effectif.

1. Noter `sensor.cumulus_pv_power_w` : _______ W
2. Noter `input_number.cumulus_alpha_aps` : _______
3. Noter `sensor.cumulus_capacity_factor` : _______
4. Calculer manuellement : `PV × α × CF` = _______
5. Comparer avec `sensor.cumulus_pv_effectif_w` : _______

- [ ] Les valeurs correspondent (±5W)

#### **Test 3 : SolarBank Disponible**
**Contexte :** Vérifier que SB_dispo retourne une valeur logique.

1. Noter `sensor.cumulus_import_reseau_w` : _______ W
2. Noter `sensor.cumulus_pv_power_w` : _______ W
3. Noter `input_number.cumulus_solarbank_max_w` : _______ W
4. Si import > 0 : SB_dispo devrait être **faible**
5. Si import < 0 (injection) : SB_dispo devrait être **élevé**

- [ ] `sensor.cumulus_sb_dispo_w` affiche une valeur logique (≥ 0)

---

### **PHASE 3 : Tests de l'automation ON PV**

#### **Test 4 : Déclenchement PV (simulation)**
**Contexte :** Vérifier que le cumulus démarre avec PV effectif suffisant.

**Conditions préalables :**
- [ ] `input_boolean.cumulus_interdit` = OFF
- [ ] `input_boolean.cumulus_vacances` = OFF
- [ ] `input_boolean.cumulus_verrou_jour` = OFF
- [ ] `input_boolean.temp_atteinte_aujourdhui` = OFF
- [ ] `binary_sensor.cumulus_fenetre_pv` = ON
- [ ] `sensor.cumulus_soc_solarbank_pct` ≥ seuil démarrage
- [ ] `binary_sensor.cumulus_appareil_en_cours` = OFF

**Procédure :**
1. Noter le seuil : `sensor.cumulus_seuil_pv_dynamique_w` = _______ W
2. Attendre que `sensor.cumulus_pv_effectif_w` dépasse le seuil
3. Attendre le délai de confirmation (`input_number.cumulus_on_delay_s`)
4. Observer l'état du contacteur

- [ ] Contacteur passe à ON après le délai
- [ ] `binary_sensor.cumulus_chauffe_reelle` passe à ON

**Si le test échoue :** Vérifier les logs et la notification de refus démarrage.

---

### **PHASE 4 : Test de l'automation de diagnostic**

#### **Test 5 : Log refus démarrage**
**Contexte :** Provoquer un refus de démarrage volontaire.

**Procédure :**
1. Activer `input_boolean.cumulus_interdit` = ON
2. Attendre que `sensor.cumulus_pv_effectif_w` > seuil pendant 30s
3. Observer les notifications

- [ ] Notification "⚠️ Cumulus - Refus démarrage" apparaît
- [ ] Raison affichée : "🔒 Mode INTERDIT actif"
- [ ] Log dans `home-assistant.log` (niveau WARNING)

**Nettoyage :**
4. Désactiver `input_boolean.cumulus_interdit` = OFF
5. Supprimer la notification

---

### **PHASE 5 : Tests de robustesse**

#### **Test 6 : Comportement avec entité manquante**
**Contexte :** Vérifier les fallbacks en cas d'entité indisponible.

**Procédure :**
1. Temporairement renommer `input_number.cumulus_alpha_aps` en `cumulus_alpha_aps_test`
2. Recharger **Template entities**
3. Observer `sensor.cumulus_pv_effectif_w`

- [ ] Sensor affiche une valeur (utilise fallback 0.88)
- [ ] Aucune erreur dans les logs

**Nettoyage :**
4. Renommer `cumulus_alpha_aps_test` → `cumulus_alpha_aps`
5. Recharger **Template entities**

#### **Test 7 : Modification α_APS en direct**
**Contexte :** Vérifier la réactivité du système.

1. Noter `sensor.cumulus_pv_effectif_w` : _______ W
2. Modifier `input_number.cumulus_alpha_aps` : 0.88 → **0.75**
3. Attendre 5 secondes
4. Noter `sensor.cumulus_pv_effectif_w` : _______ W

- [ ] La valeur a diminué (environ -13%)
- [ ] Le sensor réagit instantanément

**Nettoyage :**
5. Remettre `input_number.cumulus_alpha_aps` = **0.88**

---

### **PHASE 6 : Tests de régression**

#### **Test 8 : Fonctionnalités héritées**
**Contexte :** Vérifier que les anciennes fonctionnalités marchent toujours.

- [ ] Automation `cumulus_limiteur_import` fonctionne (test ou observation logs)
- [ ] Automation `cumulus_securite_soc_bas` fonctionne
- [ ] Automation `cumulus_fin_detectee_par_import` fonctionne
- [ ] Sensors thermiques (`cumulus_temperature_physique_c`, etc.) fonctionnent
- [ ] Notifications (48h sans chauffe, etc.) fonctionnent

---

## 🎯 TESTS EN CONDITIONS RÉELLES

### **Test 9 : Journée complète PV**
**Contexte :** Observer le comportement sur une journée ensoleillée.

**À surveiller :**
- [ ] Cumulus démarre quand PV effectif > seuil dynamique
- [ ] Cumulus s'arrête si PV effectif < seuil (limiteur import)
- [ ] Notification refus démarrage pertinente (si blocage)
- [ ] Aucune erreur dans les logs

**Métriques à noter :**
- Heure de démarrage : _______
- PV effectif au démarrage : _______ W
- Seuil dynamique : _______ W
- Durée de chauffe : _______ min
- Température finale : _______ °C

---

### **Test 10 : Journée nuageuse (capacity factor bas)**
**Contexte :** Vérifier que le système est plus conservateur.

**À observer :**
- [ ] `sensor.cumulus_capacity_factor` varie entre 0.3 et 0.8
- [ ] PV effectif nettement inférieur au PV brut
- [ ] Cumulus démarre seulement si PV effectif > seuil (plus strict)

---

## 📊 RAPPORT DE TESTS

### **Résumé :**
- Tests réussis : _____ / 10
- Tests échoués : _____ / 10
- Tests non applicables : _____ / 10

### **Problèmes rencontrés :**
1. _______________________________________________________
2. _______________________________________________________
3. _______________________________________________________

### **Actions correctives :**
1. _______________________________________________________
2. _______________________________________________________
3. _______________________________________________________

### **Décision finale :**
- [ ] ✅ Déploiement validé → Garder v2025-10-12a
- [ ] ⚠️ Problèmes mineurs → Continuer observation
- [ ] ❌ Problèmes critiques → ROLLBACK immédiat (voir ROLLBACK.md)

---

**Date des tests :** __________________
**Testeur :** __________________
**Conditions météo :** ☀️ / ⛅ / ☁️ / 🌧️

---

**🤖 Généré automatiquement par Claude Code**
