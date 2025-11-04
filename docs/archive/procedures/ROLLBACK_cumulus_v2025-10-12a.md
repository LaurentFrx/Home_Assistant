# 🔙 PROCÉDURE DE ROLLBACK — Cumulus v2025-10-12a

**En cas de problème avec la version v2025-10-12a, suivez cette procédure.**

---

## ⚠️ QUAND FAIRE UN ROLLBACK ?

### **Cas critiques (rollback IMMÉDIAT) :**
- ❌ Le cumulus ne démarre plus du tout en mode PV
- ❌ Erreurs YAML dans les logs Home Assistant
- ❌ Sensors qui affichent `unavailable` ou `unknown`
- ❌ Automations qui ne se déclenchent plus

### **Cas non-critiques (investigation avant rollback) :**
- ⚠️ Le cumulus démarre moins souvent qu'avant (comportement attendu avec PV effectif)
- ⚠️ Notifications de refus démarrage fréquentes (c'est l'objectif de l'automation)

---

## 🛠️ PROCÉDURE DE ROLLBACK

### **OPTION 1 : Rollback via fichier backup (RECOMMANDÉ)**

#### **Étape 1 : Restaurer le backup**
```bash
cp \\192.168.1.29\config\packages\cumulus_backup_20251012_100120.yaml \\192.168.1.29\config\packages\cumulus.yaml
```

#### **Étape 2 : Vérifier la syntaxe**
Dans Home Assistant :
1. Aller dans **Configuration** → **YAML** → **Check Configuration**
2. Vérifier qu'il n'y a pas d'erreurs

#### **Étape 3 : Recharger les entités**
Dans Home Assistant :
1. **Developer Tools** → **YAML** → Recharger :
   - ✅ **Template entities** (pour les sensors)
   - ✅ **Automations**
   - ✅ **Helpers** (pour input_number)

#### **Étape 4 : Vérifier le retour à la normale**
Dans **Developer Tools** → **States**, vérifier :
- `sensor.cumulus_pv_power_w` est disponible
- `binary_sensor.cumulus_chauffe_reelle` fonctionne
- Automation `ce_on_pv_simple` est active

---

### **OPTION 2 : Rollback manuel (si le backup est corrompu)**

#### **1. Supprimer les nouvelles entités**

Éditer `packages/cumulus.yaml` et supprimer les lignes suivantes :

**a) Dans la section `input_number` (après ligne ~310) :**
```yaml
  # ========== NOUVEAU - Coefficient alpha APS ========== #
  cumulus_alpha_aps:
    name: Coefficient efficacité APS (α)
    min: 0.5
    max: 1.0
    step: 0.01
    initial: 0.88
    icon: mdi:alpha
```

**b) Dans la section `template: - sensor:` (après ligne ~628) :**
```yaml
      # ========== NOUVEAUX SENSORS - Calculs PV avancés ==========
      - name: "cumulus_sb_dispo_w"
        [... tout le bloc jusqu'à "cumulus_pv_effectif_w" inclus ...]
```

**c) Dans `sensor.cumulus_seuil_pv_dynamique_w` (lignes ~711-714) :**
Supprimer les attributs :
```yaml
          pv_effectif_actuel_w: >-
            {{ states('sensor.cumulus_pv_effectif_w') }}
          pv_brut_actuel_w: >-
            {{ states('sensor.cumulus_pv_power_w') }}
```

**d) Automation `cumulus_log_refus_demarrage` (après ligne ~1365) :**
Supprimer TOUTE l'automation (ID `cumulus_log_refus_demarrage`)

#### **2. Restaurer l'automation `ce_on_pv_simple`**

Remplacer toutes les occurrences de `sensor.cumulus_pv_effectif_w` par `sensor.cumulus_pv_power_w` dans :
- Le trigger `value_template` (ligne ~887)
- La condition `value_template` (ligne ~903)
- Les conditions avant action (lignes ~944 et ~954)

#### **3. Restaurer l'en-tête**
Remplacer `v2025-10-12a` par `v2025-10-10c` dans l'en-tête du fichier.

#### **4. Recharger (même procédure que Option 1, étapes 2-4)**

---

## 🧹 NETTOYAGE POST-ROLLBACK

### **Entités fantômes à supprimer**

Après le rollback, les nouvelles entités peuvent rester dans HA. Pour les supprimer :

1. **Configuration** → **Entities**
2. Rechercher et supprimer :
   - `input_number.cumulus_alpha_aps`
   - `sensor.cumulus_sb_dispo_w`
   - `sensor.cumulus_capacity_factor`
   - `sensor.cumulus_pv_effectif_w`
3. **Developer Tools** → **Services** → Appeler `homeassistant.reload_config_entry`

### **Notifications persistantes**

Supprimer la notification de refus démarrage si présente :
1. **Notifications** (cloche en haut à droite)
2. Cliquer sur la notification "Cumulus - Refus démarrage"
3. Cliquer sur "Dismiss"

---

## 📊 VÉRIFICATION POST-ROLLBACK

### **Checklist de validation :**

- [ ] Home Assistant démarre sans erreurs
- [ ] Configuration YAML valide (Check Configuration OK)
- [ ] Sensor `sensor.cumulus_pv_power_w` fonctionne
- [ ] Automation `ce_on_pv_simple` active
- [ ] Cumulus démarre en mode PV (test réel ou simulation)
- [ ] Aucun log d'erreur dans **Settings** → **System** → **Logs**

---

## 🆘 EN CAS DE PROBLÈME

### **Si le rollback échoue :**

1. **Redémarrer Home Assistant** :
   - **Settings** → **System** → **Restart**

2. **Vérifier les logs** :
   - **Settings** → **System** → **Logs**
   - Rechercher les erreurs liées à `cumulus` ou `template`

3. **Demander de l'aide** :
   - Forum Home Assistant : https://community.home-assistant.io/
   - Fournir les fichiers :
     - `packages/cumulus.yaml`
     - `packages/cumulus_backup_20251012_100120.yaml`
     - Logs d'erreur

---

## 📝 NOTES IMPORTANTES

- ⚠️ **NE PAS** supprimer le fichier backup (`cumulus_backup_20251012_100120.yaml`)
- ⚠️ **Toujours** vérifier la syntaxe YAML avant de recharger
- ℹ️ Le rollback ne supprime PAS les données historiques des sensors (c'est normal)

---

**🤖 Généré automatiquement par Claude Code**
