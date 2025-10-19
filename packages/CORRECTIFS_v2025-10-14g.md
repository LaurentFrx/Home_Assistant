# CORRECTIFS v2025-10-14g — Bug Critique TemplateRuntimeError

**Date** : 2025-10-14
**Statut** : ✅ PRODUCTION READY - CRITIQUE
**Origine** : Analyse de Claude sur v2025-10-14f

---

## ⚠️ BUG CRITIQUE CORRIGÉ

### 🔧 FIX #1 : TemplateRuntimeError dans automation variation brutale

**Problème identifié par Claude :**
> "Bug critique – packages/cumulus.yaml:1345 : la vérification post‑délai calcule variation_confirmee = import_actuel - import_avant, mais la variable d'action import_avant (déclarée ligne packages/cumulus.yaml:1338) est une chaîne. Lors de l'évaluation du template, Home Assistant tente de soustraire un float et une str → TemplateRuntimeError, donc l'automatisation "variation brutale" se met en erreur et n'ouvre plus le contacteur."

**Explication technique :**

Dans Home Assistant, les variables déclarées dans le bloc `variables:` d'une action sont **toujours stockées comme des strings**, même si le template contient un filtre `| float()`.

Exemple :
```yaml
variables:
  import_avant: "{{ trigger.from_state.state | float(0) }}"  # Résultat : "3000.0" (STRING)
```

Même si `trigger.from_state.state | float(0)` évalue à `3000.0` (nombre), Home Assistant stocke la **représentation textuelle** du résultat du template, donc `"3000.0"` (chaîne).

Plus tard, quand on fait :
```yaml
{% set variation_confirmee = import_actuel - import_avant %}
# import_actuel est un float (via states() | float(0))
# import_avant est une string "3000.0"
# → TypeError: unsupported operand type(s) for -: 'float' and 'str'
```

**Correction appliquée :**

**Fichier** : `cumulus.yaml` ligne 1347

**AVANT** (v2025-10-14f) :
```yaml
# Ligne 1338 : Déclaration de la variable (stockée comme string)
- variables:
    sw_id: "{{ states('input_text.cumulus_entity_contacteur') }}"
    import_declenchement: "{{ trigger.to_state.state | float(0) }}"
    import_avant: "{{ trigger.from_state.state | float(0) }}"  # ← STRING !
    variation_initiale: "{{ (trigger.to_state.state | float(0)) - (trigger.from_state.state | float(0)) }}"

# Ligne 1347 : Utilisation sans cast
- condition: template
  value_template: >-
    {% set import_actuel = states('sensor.cumulus_import_reseau_w') | float(0) %}
    {% set variation_confirmee = import_actuel - import_avant %}  # ← CRASH : float - str
    {% set seuil = states('input_number.cumulus_seuil_variation_brutale_w') | float(300) %}
    {{ variation_confirmee > (seuil * 0.8) }}
```

**APRÈS** (v2025-10-14g) :
```yaml
# Ligne 1347 : Cast explicite de la variable string en float
- condition: template
  value_template: >-
    {% set import_actuel = states('sensor.cumulus_import_reseau_w') | float(0) %}
    {% set variation_confirmee = import_actuel - (import_avant | float(0)) %}  # ✅ CORRIGÉ
    {% set seuil = states('input_number.cumulus_seuil_variation_brutale_w') | float(300) %}
    {{ variation_confirmee > (seuil * 0.8) }}
```

**Impact du bug :**

Avant correction, dès que l'automation #6b ("Arrêt variation brutale import") se déclenchait :

1. ✅ Trigger détecte variation >300W
2. ✅ Conditions initiales passent (switch ON depuis 30s, variation détectée)
3. ✅ Variables déclarées (import_avant stocké comme `"3000.0"`)
4. ✅ Délai de 2 secondes (amortissement)
5. ❌ **CRASH** à la ligne 1347 : `TemplateRuntimeError: unsupported operand type(s) for -: 'float' and 'str'`
6. ❌ L'automation s'arrête en erreur
7. ❌ **Le cumulus NE S'ARRÊTE PAS** malgré la détection de variation brutale

**Conséquence :** La protection contre les appareils non déclarés (four, bouilloire, etc.) ne fonctionnait **jamais**.

---

## ✅ Vérifications additionnelles (déjà corrigées en v2025-10-14f)

### Point #2 : Message log conso domestique

**Feedback de Claude :**
> "Point de cohérence – packages/cumulus.yaml:1294-1300 : le log de l'automatisation "conso domestique élevée" annonce encore "talon+200 W" alors que le seuil est désormais paramétrable via input_number.cumulus_seuil_conso_domestique_w."

**Statut** : ✅ **DÉJÀ CORRIGÉ** en v2025-10-14f (ligne 1287)

Le message utilise bien `{{ states('input_number.cumulus_seuil_conso_domestique_w') }}W`.

### Point #3 : Refactoring automation démarrage PV

**Feedback de Claude :**
> "Refactoring incomplet – packages/cumulus.yaml:988-1003 : cumulus_on_pv_automatique embarque toujours la logique progressive inline, pendant que binary_sensor.cumulus_conditions_pv_ok la centralise déjà pour les redémarrages (ligne packages/cumulus.yaml:1421)."

**Statut** : ✅ **DÉJÀ CORRIGÉ** en v2025-10-14f (lignes 992-994)

L'automation utilise bien `binary_sensor.cumulus_conditions_pv_ok`.

---

## 📊 Tests de validation

### Test 1 : Vérifier le fix TemplateRuntimeError

**Procédure :**
1. Démarrer le cumulus en mode PV
2. Attendre 30 secondes (sortie du tampon anti-flap)
3. Allumer un appareil électrique puissant (four, bouilloire) pour créer variation >300W
4. Observer les logs Home Assistant

**Résultat attendu AVANT fix :**
```
Error executing script. Unexpected error for call_service at pos 4:
unsupported operand type(s) for -: 'float' and 'str'
Traceback (most recent call last):
  ...
  File "homeassistant/helpers/template.py", line XXX
    variation_confirmee = import_actuel - import_avant
TypeError: unsupported operand type(s) for -: 'float' and 'str'
```

**Résultat attendu APRÈS fix (v2025-10-14g) :**
```
[logbook] Cumulus Variation Brutale
Arrêt temporaire - augmentation brutale import +450W (confirmée après 2s).
PAS de verrou (température non atteinte).
Deadband 5min activé.
```

### Test 2 : Vérifier que l'automation fonctionne correctement

**Procédure :**
1. Simuler variation brutale en allumant un appareil
2. Vérifier que le cumulus s'arrête bien après 2 secondes
3. Vérifier que le deadband est activé
4. Vérifier la notification persistante

**Résultat attendu :**
- ✅ Cumulus s'arrête 2 secondes après détection
- ✅ Timer deadband activé (5 minutes par défaut)
- ✅ Notification affichée avec variation détectée
- ✅ Log dans le logbook

---

## 📁 Fichiers modifiés

| Fichier | Lignes modifiées | Type de modification |
|---------|------------------|---------------------|
| `packages/cumulus.yaml` | 1-8 | Version header → v2025-10-14g |
| `packages/cumulus.yaml` | 1347 | Fix TemplateRuntimeError (cast float) |
| `packages/CORRECTIFS_v2025-10-14g.md` | NEW | Documentation complète |

---

## 🎯 Récapitulatif de TOUTES les corrections depuis v2025-10-13f

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

### v2025-10-14f (Finalisation Claude)
1. ✅ Utilisation complète binary_sensor dans toutes automations
2. ✅ Message log avec seuil dynamique

### v2025-10-14g (Bug critique TemplateRuntimeError) — **CETTE VERSION**
1. ✅ Cast import_avant en float pour éviter TemplateRuntimeError

---

## 🚨 Criticité de ce fix

**Niveau** : 🔴 **CRITIQUE**

**Raison** :
- L'automation #6b ("Arrêt variation brutale") ne fonctionnait **JAMAIS** depuis sa création
- Le cumulus continue de chauffer même quand un appareil non déclaré démarre
- Risque de dépassement de la puissance souscrite
- Risque de disjonction générale

**Recommandation** :
- Déployer **IMMÉDIATEMENT** en production
- Tester la détection de variation brutale dès le déploiement
- Monitorer les logs pendant 48h pour confirmer le bon fonctionnement

---

## 🚀 Déploiement

```bash
# 1. Vérifier la configuration
cd /config
ha core check

# 2. Recharger le package
ha core restart

# 3. Tester l'automation variation brutale
# Allumer un appareil puissant (four, bouilloire) pendant que le cumulus chauffe

# 4. Vérifier les logs
tail -f /config/home-assistant.log | grep -i "variation brutale\|TemplateRuntimeError"
```

---

## 📝 Notes importantes

### Leçon apprise : Variables dans automations Home Assistant

Dans les automations Home Assistant, les variables déclarées avec `variables:` sont **toujours des strings**, même si le template contient des filtres de conversion.

**Règle d'or** : Toujours caster explicitement les variables quand elles sont utilisées dans des opérations arithmétiques.

**Exemple de pattern sûr :**
```yaml
variables:
  ma_valeur: "{{ states('sensor.foo') | float(0) }}"  # Stocké comme string "42.0"

# Plus tard...
value_template: >-
  {% set calcul = 100 - (ma_valeur | float(0)) %}  # ✅ SAFE : cast explicite
```

**Anti-pattern (source de bugs) :**
```yaml
variables:
  ma_valeur: "{{ states('sensor.foo') | float(0) }}"

# Plus tard...
value_template: >-
  {% set calcul = 100 - ma_valeur %}  # ❌ CRASH : float - str
```

### Impact sur les autres automations

J'ai vérifié toutes les autres automations du package : **aucune autre occurrence** de ce pattern dangereux n'a été trouvée.

Les autres variables sont soit :
- Utilisées comme strings (`sw_id` dans les conditions)
- Calculées directement dans le template sans stockage intermédiaire
- Castées explicitement avant utilisation

---

**Version finale : v2025-10-14g — PRODUCTION READY** ✅

**IMPORTANT : Fix critique, déploiement immédiat recommandé**
