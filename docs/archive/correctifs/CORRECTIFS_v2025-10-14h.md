# CORRECTIFS v2025-10-14h — Corrections Critiques Logique Redémarrage

**Date** : 2025-10-14
**Statut** : ✅ PRODUCTION READY - CRITIQUE
**Origine** : Analyse approfondie de la logique de redémarrage

---

## 📋 Résumé des corrections

Version **v2025-10-14h** corrige 2 problèmes critiques identifiés dans la logique de redémarrage automatique :

1. **Trou logique** : Pas de redémarrage automatique après deadband pour les arrêts temporaires
2. **Fragilité technique** : Variables stockées comme strings pouvant causer des erreurs de conversion

---

## 🔧 CORRECTION #1 CRITIQUE : Redémarrage universel après deadband

### Problème identifié

**Trou dans la logique de redémarrage :**

Le cumulus peut être arrêté par **5 automatisations différentes** :

1. ✅ **Appareil prioritaire** → Redémarrage géré par `cumulus_redemarrage_si_appareil_arrete`
2. ❌ **Limiteur import** → **AUCUN redémarrage automatique**
3. ❌ **Conso domestique élevée** → **AUCUN redémarrage automatique**
4. ❌ **Variation brutale** → **AUCUN redémarrage automatique**
5. ❌ **Sécurité SOC bas** → **AUCUN redémarrage automatique**

**Pourquoi c'est un problème critique :**

L'automatisation `cumulus_on_pv_automatique` a un trigger qui ne se réévalue que quand la production APS passe **sous puis au-dessus** du seuil statique (100W). Si la production reste stable au-dessus, le trigger ne se déclenche jamais.

**Scénario problématique réel :**
```
11h30 : Cumulus chauffe (APS = 300W, import = 100W)
11h35 : Import monte à 450W → Limiteur coupe + deadband 5min
11h40 : Deadband terminé, import redescendu à 80W, APS toujours à 300W
11h40 : cumulus_on_pv_automatique NE SE DÉCLENCHE PAS (APS stable > 100W)
12h00 : Cumulus toujours arrêté → 20 minutes de solaire perdues
15h00 : Toujours arrêté → 3h30 de solaire perdues
17h50 : Fin fenêtre PV → Chauffe complètement manquée
```

**Impact** : Perte de **plusieurs heures** de production solaire disponible après chaque arrêt temporaire.

### Solution implémentée

**AJOUT** d'une nouvelle automatisation `cumulus_redemarrage_apres_deadband` qui surveille la fin du timer deadband et tente un redémarrage automatique si toutes les conditions sont réunies.

**Fichier** : `cumulus.yaml` lignes 1437-1492

**Code ajouté** :
```yaml
  # 7b) Redémarrage après deadband - CORRECTION TROU LOGIQUE
  - id: cumulus_redemarrage_apres_deadband
    alias: "Cumulus — Redémarrage après deadband"
    description: "Redémarrage universel quand deadband se termine et conditions OK"
    mode: single
    trigger:
      - platform: event
        event_type: timer.finished
        event_data:
          entity_id: timer.cumulus_deadband_ui
    condition:
      - condition: state
        entity_id: input_boolean.cumulus_temp_atteinte_aujourdhui
        state: "off"
      - condition: state
        entity_id: input_boolean.cumulus_interdit_depart
        state: "off"
      - condition: state
        entity_id: input_boolean.cumulus_mode_vacances
        state: "off"
      - condition: state
        entity_id: input_boolean.cumulus_verrou_jour
        state: "off"
      - condition: state
        entity_id: binary_sensor.cumulus_fenetre_pv
        state: "on"
      - condition: state
        entity_id: binary_sensor.cumulus_appareil_prioritaire_actif
        state: "off"
      # Utiliser le binary sensor dédié (logique progressive centralisée)
      - condition: state
        entity_id: binary_sensor.cumulus_conditions_pv_ok
        state: "on"
      # Vérifier SOC suffisant
      - condition: template
        value_template: >-
          {{ states('sensor.cumulus_soc_solarbank_pct')|float(0)
             >= states('input_number.cumulus_soc_min_pct')|float(10) }}
    action:
      - variables:
          sw_id: "{{ states('input_text.cumulus_entity_contacteur') }}"
      # Vérifier que le cumulus est effectivement arrêté
      - condition: template
        value_template: "{{ sw_id != '' and sw_id not in ['unknown', 'unavailable'] and is_state(sw_id, 'off') }}"
      - service: switch.turn_on
        target:
          entity_id: "{{ sw_id }}"
      - service: logbook.log
        data:
          name: "Cumulus Redémarrage Deadband"
          message: >
            Redémarrage automatique après fin deadband.
            Disponible={{ states('sensor.cumulus_puissance_disponible_w') }}W,
            Seuil={{ states('sensor.cumulus_seuil_pv_dynamique_w') }}W,
            SOC={{ states('sensor.cumulus_soc_solarbank_pct') }}%
          entity_id: "{{ sw_id }}"
```

**Bénéfices** :
- ✅ **Redémarrage universel** : Fonctionne pour TOUS les types d'arrêts (limiteur, conso, variation, SOC)
- ✅ **Maximisation solaire** : Ne perd plus de temps de production disponible
- ✅ **Logique centralisée** : Utilise `binary_sensor.cumulus_conditions_pv_ok` (progressive logic)
- ✅ **Sécurité** : Vérifie toutes les conditions avant redémarrage

---

## 🔧 CORRECTION #2 : import_avant robuste (calcul direct)

### Problème identifié

Dans l'automatisation `cumulus_arret_si_variation_brutale_import`, les variables étaient stockées dans le bloc `variables:` de l'action :

```yaml
# AVANT (v2025-10-14g)
action:
  - variables:
      sw_id: "{{ states('input_text.cumulus_entity_contacteur') }}"
      import_declenchement: "{{ trigger.to_state.state | float(0) }}"  # STRING "2500.0"
      import_avant: "{{ trigger.from_state.state | float(0) }}"  # STRING "2200.0"
      variation_initiale: "{{ (trigger.to_state.state | float(0)) - (trigger.from_state.state | float(0)) }}"  # STRING "300.0"
```

**Le problème** : Dans Home Assistant, les variables déclarées avec `variables:` stockent la **représentation textuelle** du résultat du template, pas le résultat numérique. Même si le template contient `| float(0)`, le résultat est ensuite stocké comme string.

**Conséquence** : Besoin de caster à chaque utilisation, code fragile et risque d'erreurs.

### Solution implémentée

**Approche robuste** : Ne plus stocker `import_avant`, `import_declenchement`, `variation_initiale` dans des variables, mais calculer directement dans chaque template au besoin.

**Fichier** : `cumulus.yaml` lignes 1337-1384

**AVANT** (v2025-10-14g) :
```yaml
action:
  - variables:
      sw_id: "{{ states('input_text.cumulus_entity_contacteur') }}"
      import_declenchement: "{{ trigger.to_state.state | float(0) }}"
      import_avant: "{{ trigger.from_state.state | float(0) }}"
      variation_initiale: "{{ (trigger.to_state.state | float(0)) - (trigger.from_state.state | float(0)) }}"
  # ...
  - condition: template
    value_template: >-
      {% set import_actuel = states('sensor.cumulus_import_reseau_w') | float(0) %}
      {% set variation_confirmee = import_actuel - (import_avant | float(0)) %}  # Cast nécessaire
      # ...
```

**APRÈS** (v2025-10-14h) :
```yaml
action:
  - variables:
      sw_id: "{{ states('input_text.cumulus_entity_contacteur') }}"
  # AMÉLIORATION : Ne pas stocker import_avant/maintenant comme strings
  # Calculer directement dans les templates pour éviter les conversions
  # ...
  - condition: template
    value_template: >-
      {% set import_avant = trigger.from_state.state | float(0) %}  # Calcul direct
      {% set import_actuel = states('sensor.cumulus_import_reseau_w') | float(0) %}
      {% set variation_confirmee = import_actuel - import_avant %}  # Pas de cast
      # ...
```

**Changements clés** :
- ✅ Suppression des variables `import_declenchement`, `import_avant`, `variation_initiale`
- ✅ Calcul direct de `import_avant` dans chaque template via `trigger.from_state.state | float(0)`
- ✅ Calcul direct de `variation` dans les messages via `(trigger.to_state.state | float(0)) - (trigger.from_state.state | float(0))`
- ✅ Plus de conversion string → float fragile

**Bénéfices** :
- ✅ **Robustesse** : Pas de risque d'erreur de conversion
- ✅ **Clarté** : Le type est toujours évident (float calculé sur place)
- ✅ **Maintenabilité** : Pas de cast à ne pas oublier

---

## 📊 Tests de validation

### Test 1 : Vérifier redémarrage après deadband (Correction #1)

**Scénario de test** :
1. Démarrer le cumulus en mode PV (vérifier switch ON)
2. Déclencher un arrêt limiteur en augmentant manuellement le talon ou en démarrant un gros appareil
3. Observer l'arrêt du cumulus et l'activation du deadband (5 min par défaut)
4. Attendre la fin du deadband (5 minutes)
5. Vérifier que le cumulus redémarre automatiquement

**Résultat attendu AVANT fix (v2025-10-14g)** :
```
11h35 : Cumulus arrêté (limiteur), deadband 5min activé
11h40 : Deadband terminé
11h40 : ❌ Cumulus reste arrêté
12h00 : ❌ Toujours arrêté
15h00 : ❌ Toujours arrêté (3h30 de solaire perdues)
```

**Résultat attendu APRÈS fix (v2025-10-14h)** :
```
11h35 : Cumulus arrêté (limiteur), deadband 5min activé
11h40 : Deadband terminé
11h40 : ✅ Redémarrage automatique (si conditions PV OK)
[logbook] Cumulus Redémarrage Deadband
Redémarrage automatique après fin deadband.
Disponible=1500W, Seuil=1200W, SOC=45%
```

### Test 2 : Vérifier robustesse variation brutale (Correction #2)

**Scénario de test** :
1. Démarrer le cumulus en mode PV
2. Attendre 30 secondes (sortie du tampon anti-flap)
3. Allumer un appareil puissant (four, bouilloire) pour créer variation >300W
4. Observer les logs Home Assistant

**Résultat attendu** :
```
✅ Aucun TemplateRuntimeError
✅ Variation détectée correctement
✅ Délai 2s d'amortissement respecté
✅ Cumulus arrêté si variation confirmée
✅ Message correct dans logbook avec valeur de variation
```

### Test 3 : Test de non-régression complet

**Vérifier que toutes les automations fonctionnent** :
- ✅ Démarrage PV automatique (trigger APS >100W)
- ✅ Limiteur import (arrêt si import >seuil)
- ✅ Sécurité SOC bas (arrêt si SOC <5%)
- ✅ Détection fin chauffe (chute import -2100W+)
- ✅ Arrêt appareil prioritaire (lave-linge/vaisselle)
- ✅ Arrêt conso domestique élevée (import >talon+200W)
- ✅ Arrêt variation brutale (import +300W+)
- ✅ **NOUVEAU** : Redémarrage après deadband
- ✅ Redémarrage après appareil prioritaire

---

## 📁 Fichiers modifiés

| Fichier | Lignes modifiées | Type de modification |
|---------|------------------|---------------------|
| `packages/cumulus.yaml` | 1-12 | Version header → v2025-10-14h |
| `packages/cumulus.yaml` | 1437-1492 | **AJOUT** nouvelle automation #7b |
| `packages/cumulus.yaml` | 1337-1384 | **MODIFICATION** section action automation #6b |
| `packages/CORRECTIFS_v2025-10-14h.md` | NEW | Documentation complète |

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

### v2025-10-14g (Bug critique TemplateRuntimeError)
1. ✅ Cast import_avant en float pour éviter TemplateRuntimeError

### v2025-10-14h (Corrections logique redémarrage) — **CETTE VERSION**
1. ✅ **Redémarrage automatique après deadband (comble trou logique)**
2. ✅ import_avant robuste (calcul direct, pas de stockage string)

---

## 🚨 Criticité de ces corrections

**Niveau** : 🔴 **CRITIQUE**

**Raison correction #1** :
- Trou logique empêchant le redémarrage après arrêts temporaires
- Perte de plusieurs heures de production solaire par jour
- Impact direct sur le taux d'autoconsommation PV

**Raison correction #2** :
- Amélioration de la robustesse (évite futurs bugs de conversion)
- Code plus maintenable et compréhensible
- Élimine source potentielle d'erreurs

**Recommandation** :
- Déployer **IMMÉDIATEMENT** en production
- Monitorer les logs pendant 48h pour confirmer les redémarrages automatiques
- Vérifier le taux d'autoconsommation PV (devrait augmenter significativement)

---

## 🚀 Déploiement

```bash
# 1. Vérifier la configuration
cd /config
ha core check

# 2. Recharger le package
ha core restart

# 3. Tester le redémarrage après deadband
# - Déclencher un arrêt (limiteur, conso, variation)
# - Attendre la fin du deadband (5 min)
# - Vérifier le redémarrage automatique dans le logbook

# 4. Vérifier les logs
tail -f /config/home-assistant.log | grep -i "deadband\|variation brutale"
```

---

## 📝 Notes importantes

### Architecture de redémarrage complète

Après v2025-10-14h, le système dispose de **2 mécanismes de redémarrage** complémentaires :

1. **Redémarrage spécifique appareil prioritaire** (`cumulus_redemarrage_si_appareil_arrete`)
   - Trigger : Appareil prioritaire passe à OFF
   - Délai : 30 secondes après arrêt appareil
   - Bonus : Désactive le verrou jour (permet reprise même si température atteinte)

2. **Redémarrage universel deadband** (`cumulus_redemarrage_apres_deadband`) — **NOUVEAU**
   - Trigger : Fin du timer deadband
   - S'applique à : Limiteur, conso domestique, variation brutale, SOC bas
   - Respecte toutes les conditions PV (logique progressive, SOC, fenêtre, etc.)

**Couverture complète** : Tous les scénarios d'arrêt temporaire ont maintenant un mécanisme de redémarrage automatique.

### Leçon apprise : Triggers passifs vs actifs

**Le problème** :
- Trigger `platform: template` avec `value_template: APS >= 100W` ne se réévalue que sur **changement d'état**
- Si APS reste stable à 300W, le trigger ne se déclenche jamais même si cumulus est arrêté

**La solution** :
- Ajouter un trigger **événementiel** (`timer.finished`) qui garantit une réévaluation à un moment précis
- Complète le trigger passif par un trigger actif

**Général isation** : Pour toute automatisation critique, prévoir un mécanisme de "réveil" périodique ou événementiel.

---

**Version finale : v2025-10-14h — PRODUCTION READY** ✅

**IMPORTANT : Corrections critiques, déploiement immédiat fortement recommandé**
