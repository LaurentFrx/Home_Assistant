# CORRECTIFS v2025-10-14f — Finalisation Refactoring

**Date** : 2025-10-14
**Statut** : ✅ PRODUCTION READY
**Origine** : Feedback final de Claude sur v2025-10-14e

---

## 📋 Résumé des corrections

Version **v2025-10-14f** finalise le refactoring de la logique progressive en corrigeant les derniers détails manqués dans v2025-10-14e.

### ♻️ REFACTORING #1 : Utilisation complète du binary sensor centralisé

**Problème identifié par Claude :**
> "Le boolean binary_sensor.cumulus_conditions_pv_ok a bien été créé... mais l'automatisation de démarrage PV (packages/cumulus.yaml:989-1003) continue d'embarquer la même logique en dur"

**Correction appliquée :**

**Fichier** : `cumulus.yaml` lignes 987-990

**AVANT** (v2025-10-14e) :
```yaml
# Automatisation #1 : Démarrage PV automatique
- condition: template
  value_template: >-
    {% set puissance_dispo = states('sensor.cumulus_puissance_disponible_w') | float(0) %}
    {% set seuil_dynamique = states('sensor.cumulus_seuil_pv_dynamique_w') | float(9999) %}
    {% set temps_restant = states('sensor.cumulus_fenetre_pv_restante_corrigee_h') | float(0) %}
    {% if temps_restant > 5 %}
      {{ puissance_dispo > (seuil_dynamique * 0.5) }}
    {% elif temps_restant > 3 %}
      {{ puissance_dispo > (seuil_dynamique * 0.7) }}
    {% elif temps_restant > 2 %}
      {{ puissance_dispo > (seuil_dynamique * 0.85) }}
    {% else %}
      {{ puissance_dispo > seuil_dynamique }}
    {% endif %}
```

**APRÈS** (v2025-10-14f) :
```yaml
# REFACTORING : Utiliser le binary sensor dédié (logique progressive centralisée)
- condition: state
  entity_id: binary_sensor.cumulus_conditions_pv_ok
  state: "on"
```

**Bénéfices :**
- ✅ **Single Source of Truth** : La logique progressive n'existe plus qu'à UN seul endroit
- ✅ **Maintenabilité** : Toute modification future de la logique progressive se fait dans le binary sensor uniquement
- ✅ **Cohérence garantie** : Les deux automations de démarrage (PV et redémarrage) utilisent exactement la même logique

---

### 🔧 FIX #2 : Message log avec valeur dynamique

**Problème identifié par Claude :**
> "Le message logbook après arrêt pour forte conso (packages/cumulus.yaml:1295-1299) affiche toujours 'talon+200 W', alors que le seuil réel est désormais input_number.cumulus_seuil_conso_domestique_w"

**Correction appliquée :**

**Fichier** : `cumulus.yaml` ligne 1283

**AVANT** (v2025-10-14e) :
```yaml
message: >
  Arrêt temporaire - import {{ states('sensor.cumulus_import_reseau_w') }}W > talon+200W.
  Maison consomme plus que prévu. PAS de verrou.
  Deadband {{ states('input_number.cumulus_deadband_min') }}min activé.
```

**APRÈS** (v2025-10-14f) :
```yaml
message: >
  Arrêt temporaire - import {{ states('sensor.cumulus_import_reseau_w') }}W > talon+{{ states('input_number.cumulus_seuil_conso_domestique_w') }}W.
  Maison consomme plus que prévu. PAS de verrou.
  Deadband {{ states('input_number.cumulus_deadband_min') }}min activé.
```

**Bénéfices :**
- ✅ Le message logbook affiche désormais la vraie valeur configurée (par défaut 200W, mais modifiable par l'utilisateur)
- ✅ Cohérence totale entre l'UI, la logique et les logs

---

## 📊 Automations utilisant binary_sensor.cumulus_conditions_pv_ok

Après v2025-10-14f, **TOUTES** les automations utilisant la logique progressive font maintenant référence au binary sensor centralisé :

1. ✅ **Automation #1** : `cumulus_on_pv_automatique` (ligne 988-990)
   - Démarrage PV avec logique progressive

2. ✅ **Automation #7** : `cumulus_redemarrage_si_appareil_arrete` (ligne 1406-1408)
   - Redémarrage après arrêt appareil prioritaire

**Code complet du binary sensor** (lignes 888-926) :
```yaml
- name: "cumulus_conditions_pv_ok"
  unique_id: cumulus_conditions_pv_ok
  icon: mdi:solar-power-variant
  state: >-
    {% set puissance_dispo = states('sensor.cumulus_puissance_disponible_w') | float(0) %}
    {% set seuil_dynamique = states('sensor.cumulus_seuil_pv_dynamique_w') | float(9999) %}
    {% set temps_restant = states('sensor.cumulus_fenetre_pv_restante_corrigee_h') | float(0) %}
    {% if temps_restant > 5 %}
      {# Plus de 5h : accepter 50% du seuil (démarrage optimiste) #}
      {{ puissance_dispo > (seuil_dynamique * 0.5) }}
    {% elif temps_restant > 3 %}
      {# 3-5h : accepter 70% du seuil #}
      {{ puissance_dispo > (seuil_dynamique * 0.7) }}
    {% elif temps_restant > 2 %}
      {# 2-3h : accepter 85% du seuil #}
      {{ puissance_dispo > (seuil_dynamique * 0.85) }}
    {% else %}
      {# Moins de 2h : exiger 100% du seuil (strict) #}
      {{ puissance_dispo > seuil_dynamique }}
    {% endif %}
  attributes:
    puissance_disponible_w: "{{ states('sensor.cumulus_puissance_disponible_w') }}"
    seuil_dynamique_w: "{{ states('sensor.cumulus_seuil_pv_dynamique_w') }}"
    temps_restant_h: "{{ states('sensor.cumulus_fenetre_pv_restante_corrigee_h') }}"
    seuil_applique_pct: >-
      {% set temps_restant = states('sensor.cumulus_fenetre_pv_restante_corrigee_h') | float(0) %}
      {% if temps_restant > 5 %}
        50
      {% elif temps_restant > 3 %}
        70
      {% elif temps_restant > 2 %}
        85
      {% else %}
        100
      {% endif %}
    explication: >-
      Logique progressive : plus il reste de temps dans la fenêtre PV,
      moins le seuil de puissance est strict (50% si >5h, 100% si <2h).
```

---

## ✅ Tests de validation

### Test 1 : Vérifier le binary sensor
```yaml
# Dans Developer Tools > Templates
{{ states('binary_sensor.cumulus_conditions_pv_ok') }}
{{ state_attr('binary_sensor.cumulus_conditions_pv_ok', 'seuil_applique_pct') }}
{{ state_attr('binary_sensor.cumulus_conditions_pv_ok', 'temps_restant_h') }}
```

**Résultat attendu :**
- State : `on` ou `off` selon conditions PV
- Attribut `seuil_applique_pct` : 50, 70, 85 ou 100 selon temps restant
- Attribut `temps_restant_h` : nombre d'heures restantes dans fenêtre PV

### Test 2 : Vérifier cohérence des automations
```bash
# Rechercher toutes les références à la logique progressive
grep -n "puissance_dispo.*seuil_dynamique.*temps_restant" packages/cumulus.yaml
```

**Résultat attendu :**
- Aucune occurrence en dehors du binary_sensor (lignes 888-926)
- Les automations #1 et #7 doivent utiliser `binary_sensor.cumulus_conditions_pv_ok`

### Test 3 : Vérifier message logbook dynamique
```yaml
# Simuler arrêt conso domestique et observer le logbook
# Le message doit afficher : "import XXW > talon+YYW" où YY = valeur configurée
```

**Résultat attendu :**
- Si `input_number.cumulus_seuil_conso_domestique_w` = 200W : message affiche "talon+200W"
- Si modifié à 250W : message affiche "talon+250W"

---

## 📁 Fichiers modifiés

| Fichier | Lignes modifiées | Type de modification |
|---------|------------------|---------------------|
| `packages/cumulus.yaml` | 1-15 | Version header → v2025-10-14f |
| `packages/cumulus.yaml` | 987-990 | Refactoring automation #1 (binary sensor) |
| `packages/cumulus.yaml` | 1283 | Fix message log dynamique |
| `packages/CORRECTIFS_v2025-10-14f.md` | NEW | Documentation complète |

---

## 🎯 Récapitulatif final de toutes les corrections depuis v2025-10-13f

### v2025-10-14a (Correctifs demandés initialement)
1. ✅ Démarrage PV progressif (50% seuil si >5h, 100% si <2h)
2. ✅ Détection variation brutale import (+300W)
3. ✅ Détection fin chauffe par chute import (-2100W+)

### v2025-10-14b (Corrections post-tests)
1. ✅ Boucle ON/OFF variation (tampon 30s après démarrage)
2. ✅ Redémarrage effectif après appareil prioritaire

### v2025-10-14c (Harmonisation)
1. ✅ Protection faux positif fin chauffe (3min minimum)
2. ✅ Harmonisation redémarrage (logique progressive)

### v2025-10-14d (Bugs critiques ChatGPT)
1. ✅ Détection fin chauffe avec last_changed du switch
2. ✅ Deadband effectif sur arrêt appareil prioritaire

### v2025-10-14e (Améliorations Claude)
1. ✅ Protection boot HA (states.get)
2. ✅ Seuils configurables UI
3. ✅ Variation brutale robuste (switch direct + amortissement)
4. ✅ Logique progressive centralisée (binary_sensor créé)

### v2025-10-14f (Finalisation Claude) — **CETTE VERSION**
1. ✅ Utilisation complète binary_sensor dans toutes automations
2. ✅ Message log avec seuil dynamique

---

## 🚀 Déploiement

```bash
# 1. Vérifier la configuration
cd /config
ha core check

# 2. Recharger le package
ha core restart

# 3. Vérifier que toutes les entités sont disponibles
ha state list | grep cumulus_conditions_pv_ok
```

---

## 📝 Notes importantes

### Point architectural résolu
La **duplication de code** identifiée dans v2025-10-14e est maintenant **complètement éliminée**. La logique progressive n'existe plus qu'à UN seul endroit : `binary_sensor.cumulus_conditions_pv_ok`.

### Point architectural documenté (non résolu)
Le **calcul indirect de consommation** (`(Import + PV_total) - Talon`) reste une fragilité connue, documentée dans `AMELIORATIONS_v2025-10-14e.md` point #1. Solution recommandée : installer un wattmètre dédié sur le cumulus si les tests en conditions réelles révèlent des problèmes de précision.

### Prochaines étapes recommandées
1. **Tests en conditions réelles** : Monitorer pendant 1 semaine
2. **Validation des seuils** : Ajuster `input_number.cumulus_seuil_conso_domestique_w` et `input_number.cumulus_seuil_variation_brutale_w` selon observations terrain
3. **Évaluation hardware** : Décider si un wattmètre dédié est nécessaire

---

**Version finale : v2025-10-14f — PRODUCTION READY** ✅
