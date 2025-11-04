# CORRECTIONS BUGS CRITIQUES - Package Cumulus v2025-10-14d

**Date** : 2025-10-14
**Version** : v2025-10-14d
**Source analyse** : ChatGPT
**Fichier** : `packages/cumulus.yaml`

---

## 🎯 REMERCIEMENTS

**Merci à ChatGPT** pour avoir identifié 2 bugs critiques dans la v2025-10-14c qui rendaient les corrections précédentes **totalement inefficaces**.

---

## 🔴 BUG CRITIQUE #1 : Condition impossible sur binary_sensor

### Analyse ChatGPT (100% correcte)

> "Claude a ajouté la condition `binary_sensor.cumulus_chauffe_reelle` doit être `on` depuis 3 minutes avant de valider la chute d'import. Mais ce binaire est justement basé sur la puissance instantanée ; dès que l'import chute (thermostat ou coupure), le template recalculé repasse ce capteur à `off`. Résultat : la condition n'est jamais vraie au moment du test et l'automatisation ne consigne plus la fin de chauffe ni n'active le verrou."

### Le problème (v2025-10-14c)

**Code bugué** (lignes 1049-1053) :
```yaml
- condition: state
  entity_id: binary_sensor.cumulus_chauffe_reelle
  state: "on"
  for:
    minutes: 3
```

**Définition du binary_sensor** (ligne 779-793) :
```yaml
binary_sensor.cumulus_chauffe_reelle:
  state: >-
    {% set conso = states('sensor.cumulus_consommation_reelle_w') | float(0) %}
    {% set seuil_chauffe = puissance_nominale * 0.70 %}
    {{ sw and (conso > seuil_chauffe) }}
```

**Séquence d'événements (bug)** :
```
T+0s  : Thermostat interne coupe
T+0s  : Import chute de 3000W → 300W
T+0s  : sensor.cumulus_consommation_reelle_w recalcule
        Avant : (3300 + 1200) - 300 = 4200W
        Après : (300 + 1200) - 300 = 1200W
T+0s  : binary_sensor.cumulus_chauffe_reelle recalcule
        Avant : 4200W > 2100W → ON
        Après : 1200W < 2100W → OFF ❌
T+0s  : Condition `for: minutes: 3` évalue l'état ACTUEL
        État actuel = OFF → Condition FAUSSE ❌
```

**Conséquence catastrophique** :
- ✅ Protection contre faux positifs : OUI (trop bien même !)
- ❌ Détection vraie fin chauffe : **IMPOSSIBLE**
- ❌ Verrou jour ne s'active **JAMAIS**
- ❌ Cumulus peut chauffer plusieurs fois par jour inutilement

### La solution (v2025-10-14d)

**Code corrigé** (lignes 1051-1065) :
```yaml
# PROTECTION CRITIQUE : Le contacteur doit être ON depuis au moins 3 minutes
# Évite faux positif quand autre automatisation coupe le cumulus
# On utilise last_changed du switch (pas du binary sensor qui recalcule en temps réel)
- condition: template
  value_template: >-
    {% set sw_id = states('input_text.cumulus_entity_contacteur') %}
    {% if sw_id in ['', 'unknown', 'unavailable'] %}
      false
    {% else %}
      {% set maintenant = now().timestamp() %}
      {% set dernier_on = as_timestamp(states[sw_id].last_changed) | float(0) %}
      {% set duree_on = maintenant - dernier_on %}
      {# Le contacteur doit être ON depuis au moins 3 minutes (180s) #}
      {{ is_state(sw_id, 'on') and duree_on >= 180 }}
    {% endif %}
```

**Pourquoi ça marche maintenant** :
- On utilise `states[sw_id].last_changed` du **contacteur physique**
- Le contacteur ne change d'état que lors d'un `switch.turn_on/off` explicite
- Il ne recalcule PAS en temps réel comme le binary_sensor
- La durée est mesurée depuis le dernier passage à ON du contacteur

**Séquence d'événements (corrigée)** :
```
T-180s : Contacteur activé (switch.turn_on)
         states[sw_id].last_changed = T-180s

T+0s   : Thermostat interne coupe
T+0s   : Import chute de 3000W
T+0s   : binary_sensor recalcule → OFF (normal)
T+0s   : Condition évalue :
         maintenant - dernier_on = T - (T-180s) = 180s
         180s >= 180s → TRUE ✅
         is_state(sw_id, 'on') = TRUE ✅
         → Condition VRAIE ✅
```

---

## 🔴 BUG CRITIQUE #2 : Deadband jamais déclenché

### Analyse ChatGPT (100% correcte)

> "L'automatisation de redémarrage après un appareil prioritaire exige désormais que `timer.cumulus_deadband_ui` soit à l'état `idle`, mais l'automatisation qui coupe le cumulus (arrêt sur appareil prioritaire) n'amorce toujours pas ce timer. Sans démarrer le deadband au moment de l'arrêt, le timer reste `idle` ; la vérification passe donc immédiatement et la protection annoncée n'existe pas."

### Le problème (v2025-10-14c)

**Code de redémarrage avec vérification** (ligne 1297-1299) :
```yaml
# AJOUT : Respect du deadband
- condition: state
  entity_id: timer.cumulus_deadband_ui
  state: "idle"
```

**Code d'arrêt SANS déclenchement** (ancien, ligne 1127-1163) :
```yaml
- service: switch.turn_off
  target:
    entity_id: "{{ sw_id }}"
# ❌ PAS de timer.start ici !
- service: logbook.log
  ...
```

**Conséquence** :
```
11h00 : Lave-linge démarre
11h00 : cumulus_arret_si_appareil_demarre déclenche
11h00 : switch.turn_off → cumulus s'arrête
11h00 : timer.cumulus_deadband_ui = idle (jamais démarré)

11h00.5s : Lave-linge s'arrête (faux déclenchement)
11h00.5s : cumulus_redemarrage_si_appareil_arrete déclenche
11h00.5s : Condition timer = idle → TRUE ✅ (problème !)
11h00.5s : switch.turn_on → cumulus redémarre immédiatement

11h01 : Lave-linge vraiment démarré
11h01 : Cycle ON/OFF rapide ❌
```

### La solution (v2025-10-14d)

**Code corrigé** (lignes 1165-1172) :
```yaml
- service: switch.turn_off
  target:
    entity_id: "{{ sw_id }}"
- service: timer.start
  target:
    entity_id: timer.cumulus_deadband_ui
  data:
    duration: "00:{{ states('input_number.cumulus_deadband_min') | int(5) }}:00"
```

**Comportement corrigé** :
```
11h00 : Lave-linge démarre
11h00 : switch.turn_off → cumulus s'arrête
11h00 : timer.start → deadband activé pour 5 min ✅

11h00.5s : Lave-linge s'arrête (faux déclenchement)
11h00.5s : cumulus_redemarrage_si_appareil_arrete déclenche
11h00.5s : Condition timer = idle → FALSE ❌
11h00.5s : Automatisation bloquée → Pas de redémarrage

11h05 : Timer expire → deadband = idle
11h05 : Si appareil toujours OFF + PV OK → Redémarrage ✅
```

---

## 📊 COMPARATIF VERSIONS

| Critère | v2025-10-14c | v2025-10-14d |
|---------|--------------|--------------|
| **Protection faux positif** | ❌ Trop stricte (bloque tout) | ✅ Utilise last_changed du switch |
| **Détection vraie fin chauffe** | ❌ Impossible | ✅ Fonctionne |
| **Deadband arrêt prioritaire** | ❌ Annoncé mais inexistant | ✅ Activé effectivement |
| **Cycles rapides ON/OFF** | ❌ Possibles | ✅ Évités |
| **Verrou jour activé** | ❌ Jamais | ✅ Quand thermostat coupe |

---

## 🔧 MODIFICATIONS APPLIQUÉES

### Modification #1 : Condition durée switch.last_changed

**Fichier** : `cumulus.yaml`
**Lignes** : 1051-1065
**Automatisation** : `cumulus_fin_detectee_temperature_max`

**Avant (v2025-10-14c)** :
```yaml
- condition: state
  entity_id: binary_sensor.cumulus_chauffe_reelle
  state: "on"
  for:
    minutes: 3
```

**Après (v2025-10-14d)** :
```yaml
- condition: template
  value_template: >-
    {% set sw_id = states('input_text.cumulus_entity_contacteur') %}
    {% if sw_id in ['', 'unknown', 'unavailable'] %}
      false
    {% else %}
      {% set maintenant = now().timestamp() %}
      {% set dernier_on = as_timestamp(states[sw_id].last_changed) | float(0) %}
      {% set duree_on = maintenant - dernier_on %}
      {{ is_state(sw_id, 'on') and duree_on >= 180 }}
    {% endif %}
```

---

### Modification #2 : Activation deadband lors arrêt prioritaire

**Fichier** : `cumulus.yaml`
**Lignes** : 1168-1172
**Automatisation** : `cumulus_arret_si_appareil_demarre`

**Ajout** :
```yaml
- service: timer.start
  target:
    entity_id: timer.cumulus_deadband_ui
  data:
    duration: "00:{{ states('input_number.cumulus_deadband_min') | int(5) }}:00"
```

**Mise à jour notification** (ligne 1179) :
```yaml
message: >
  {{ appareil_actif }} a démarré.
  Le cumulus a été arrêté temporairement.
  Redémarrage automatique après deadband ({{ states('input_number.cumulus_deadband_min') | int(5) }} min).
```

---

## ✅ TESTS RECOMMANDÉS

### Test #1 : Détection fin chauffe réelle (CRITIQUE)

**Objectif** : Vérifier que le verrou jour s'active après chauffe complète

**Procédure** :
1. Lancer chauffe complète depuis eau froide
2. Attendre ~6h (coupure thermostat interne)
3. Observer logs et états

**Résultat attendu** :
```
15:30:00 - Cumulus Démarrage PV - switch.turn_on
          → states[sw_id].last_changed = 15:30:00

21:45:00 - Thermostat coupe (chute import -2100W)
21:45:00 - Condition évalue :
           duree_on = 21:45:00 - 15:30:00 = 6h15min ✅
           duree_on >= 3min → TRUE ✅
           Verrou jour activé ✅
21:45:00 - Log : "Température max atteinte après chauffe continue >= 3min"
```

**Si échec** :
- ❌ Verrou jour = OFF après 6h → Bug réintroduit

---

### Test #2 : Protection faux positif

**Objectif** : Vérifier que les arrêts temporaires ne déclenchent pas le verrou

**Procédure** :
1. Démarrer cumulus manuellement
2. Après 1 minute, démarrer cafetière → arrêt variation brutale
3. Observer états

**Résultat attendu** :
```
11:25:00 - Cumulus démarre
          → states[sw_id].last_changed = 11:25:00

11:26:00 - Cafetière démarre (+1200W)
11:26:00 - Automatisation "variation brutale" coupe cumulus
11:26:00 - switch.turn_off
          → states[sw_id] = OFF

11:26:00 - Détection chute import (-2700W)
11:26:00 - Condition évalue :
           is_state(sw_id, 'on') = FALSE ❌
           → Condition FAUSSE
           → Verrou jour NON activé ✅
```

**Si échec** :
- ❌ Verrou jour activé après 1 min → Bug réintroduit

---

### Test #3 : Deadband effectif

**Objectif** : Vérifier que le deadband empêche redémarrages immédiats

**Procédure** :
1. Cumulus en chauffe
2. Démarrer lave-linge → cumulus s'arrête
3. Observer timer et redémarrage

**Résultat attendu** :
```
11:00:00 - Lave-linge démarre
11:00:00 - switch.turn_off
11:00:00 - timer.start (duration: 5 min) ✅
          → timer.cumulus_deadband_ui = active

11:00:30 - Lave-linge s'arrête (faux déclenchement)
11:00:30 - Redémarrage déclenche
11:00:30 - Condition timer = idle → FALSE ❌
          → Pas de redémarrage ✅

11:05:00 - Timer expire → idle
11:05:00 - Si PV OK → Redémarrage ✅
```

**Si échec** :
- ❌ Redémarrage avant 5 min → Deadband non fonctionnel

---

## 📝 LOGS ATTENDUS

### Scénario nominal (fin chauffe 6h)

```log
2025-10-14 10:30:00 INFO Cumulus Démarrage PV - Démarrage PV progressif...
2025-10-14 16:45:00 INFO Cumulus Température Max - Thermostat interne coupé détecté (chute import -2145W). Température max atteinte après chauffe continue >= 3min. Verrou jour activé.
```

### Scénario protection (arrêt 1 min)

```log
2025-10-14 11:25:00 INFO Cumulus Démarrage PV - Démarrage PV progressif...
2025-10-14 11:26:00 INFO Cumulus Variation Brutale - Arrêt temporaire - augmentation brutale import +1200W. PAS de verrou.
2025-10-14 11:31:00 INFO Cumulus Démarrage PV - Démarrage PV progressif...
```
→ **Pas de log "Température Max"** après 1 min ✅

### Scénario deadband

```log
2025-10-14 11:00:00 INFO Cumulus Arrêt Prioritaire - Arrêt temporaire Lave-linge. PAS de verrou. Deadband 5min activé.
2025-10-14 11:00:30 DEBUG Redémarrage bloqué (timer actif)
2025-10-14 11:05:00 INFO Cumulus Redémarrage - Redémarrage automatique après arrêt appareil prioritaire...
```

---

## ⚠️ RISQUES RÉSIDUELS

### Risque #1 : Switch manuel

Si l'utilisateur coupe manuellement le cumulus via l'interface, puis le rallume immédiatement, `last_changed` est réinitialisé. Une coupure thermostat dans les 3 minutes suivantes ne sera pas détectée.

**Mitigation** : Utiliser le mode `cumulus_interdit_depart` pour maintenance manuelle.

---

### Risque #2 : Deadband cumulatif

Si plusieurs automatisations déclenchent le deadband successivement, le timer est redémarré à chaque fois (mode `restart`). Cela prolonge artificiellement le délai.

**Comportement actuel** : Normal et voulu (chaque arrêt impose un nouveau délai).

---

## 🎓 LEÇONS APPRISES

### Erreur conceptuelle : Utiliser binary_sensor recalculé

**Erreur** : Utiliser `for:` sur un sensor qui recalcule en temps réel
**Cause racine** : Confusion entre état temps réel vs. historique d'états
**Solution** : Toujours vérifier la source du sensor (statique vs. template)

### Erreur d'implémentation : Protection documentée mais non codée

**Erreur** : Documenter une protection sans vérifier son déclenchement
**Cause racine** : Ajout d'une vérification sans l'action correspondante
**Solution** : Toujours tracer le cycle complet (condition → action → effet)

### Méthodologie améliorée

**Avant** :
1. Identifier bug
2. Proposer correction
3. Appliquer
4. Documenter

**Après** :
1. Identifier bug
2. Proposer correction
3. **Tracer séquence complète d'exécution**
4. **Vérifier sources des sensors (statique vs. template)**
5. Appliquer
6. Documenter
7. **Peer review (ChatGPT, utilisateur)**

---

## 📞 SUPPORT

**En cas de problème** :
1. Vérifier version du package : doit être `v2025-10-14d`
2. Activer logs debug (voir CORRECTIFS_v2025-10-14c.md)
3. Effectuer les 3 tests critiques
4. Consulter ce document pour séquences attendues

**Fichiers de référence** :
- Configuration : `packages/cumulus.yaml`
- Bugs corrigés : `packages/BUGS_CRITIQUES_v2025-10-14d.md` (ce fichier)
- Correctifs précédents : `packages/CORRECTIFS_v2025-10-14c.md`
- Risques généraux : `packages/RISQUES_cumulus_v2025-10-14b.md`

---

**Document généré le 2025-10-14**
**Auteur** : Claude Code (Anthropic)
**Peer review** : ChatGPT (OpenAI)
**Révision** : 1.0
**Package version** : v2025-10-14d
