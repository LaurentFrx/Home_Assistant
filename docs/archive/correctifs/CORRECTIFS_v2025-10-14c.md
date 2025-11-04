# CORRECTIFS CRITIQUES - Package Cumulus v2025-10-14c

**Date** : 2025-10-14
**Version** : v2025-10-14c
**Fichier** : `packages/cumulus.yaml`

---

## ✅ CORRECTIONS APPLIQUÉES

### 🔧 CORRECTION #1 CRITIQUE : Protection faux positif fin de chauffe

**Lignes modifiées** : 1031-1125
**Automatisation** : `cumulus_fin_detectee_temperature_max`
**Gravité** : 🔴 CRITIQUE

#### Problème identifié

L'automatisation détectait toute chute d'import > 2100W et activait le **verrou jour** même lors d'arrêts temporaires causés par d'autres automatisations.

**Scénario catastrophique** :
```
11h25 : Cumulus démarre (température 35°C)
11h50 : Cafetière démarre → automatisation "variation brutale" coupe le cumulus
11h50 : Import chute de 2700W → automatisation "fin de chauffe" se déclenche
11h50 : VERROU JOUR activé alors que température NON atteinte (35°C ≠ 65°C)
12h00 : Cumulus ne peut plus redémarrer de la journée
Soir  : Douche froide pour les utilisateurs
```

#### Solutions appliquées (3 protections)

**Protection #1 - Durée minimale de chauffe** (lignes 1049-1053)
```yaml
- condition: state
  entity_id: binary_sensor.cumulus_chauffe_reelle
  state: "on"
  for:
    minutes: 3
```
→ Le cumulus doit chauffer **au moins 3 minutes** avant de pouvoir déclencher la fin de chauffe.

**Protection #2 - Confirmation après délai** (lignes 1080-1086)
```yaml
- delay:
    seconds: 15
- condition: template
  value_template: >-
    {% set chute = import_declenchement - import_actuel %}
    {{ chute > (puissance_cumulus * 0.6) }}
```
→ Vérifie que l'import reste bas 15 secondes après la détection (pas un transitoire).

**Protection #3 - Switch toujours ON** (lignes 1089-1090)
```yaml
- condition: template
  value_template: "{{ sw_id != '' and sw_id not in ['unknown', 'unavailable'] and states(sw_id) == 'on' }}"
```
→ Vérifie que le contacteur n'a pas été coupé entre-temps par une autre automatisation.

#### Comportement corrigé

| Scénario | Avant | Après |
|----------|-------|-------|
| Cumulus chauffe 30s → arrêt variation brutale | ❌ Verrou activé | ✅ Pas de verrou (< 3min) |
| Cumulus chauffe 6h → thermostat coupe | ✅ Verrou activé | ✅ Verrou activé |
| Cumulus chauffe 5min → limiteur import coupe | ❌ Verrou activé | ✅ Pas de verrou (switch OFF détecté) |

---

### 🔧 CORRECTION #2 : Harmonisation logique redémarrage

**Lignes modifiées** : 1272-1338
**Automatisation** : `cumulus_redemarrage_si_appareil_arrete`
**Gravité** : 🟠 MAJEUR

#### Problème identifié

**Incohérence logique entre démarrage et redémarrage** :

| Critère | Démarrage initial | Redémarrage (ancien) | Problème |
|---------|-------------------|----------------------|----------|
| Seuil PV | Progressif (50%→100%) | 100% strict | Trop restrictif |
| Deadband | Respecté | Non vérifié | Cycles rapides possibles |

**Conséquence** : Un cumulus qui démarre facilement à 10h30 (50% du seuil, 7h restantes) ne peut pas redémarrer après un arrêt prioritaire à 11h00 (même conditions).

#### Solutions appliquées

**Ajout #1 - Respect du deadband** (lignes 1297-1299)
```yaml
- condition: state
  entity_id: timer.cumulus_deadband_ui
  state: "idle"
```
→ Évite les redémarrages immédiats après un arrêt (temporisation de 5 min par défaut).

**Ajout #2 - Logique progressive identique** (lignes 1301-1318)
```yaml
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
→ **EXACTEMENT** la même logique que l'automatisation de démarrage initial.

#### Comportement corrigé

**Exemple concret** :
```
10h30 : Cumulus démarre (50% seuil, 7h restantes) ✅
11h00 : Lave-linge démarre → cumulus s'arrête
11h35 : Lave-linge termine (après 30s + 5min deadband)
```

| Conditions | Avant | Après |
|-----------|-------|-------|
| Puissance disponible | 1800W | 1800W |
| Seuil dynamique | 3200W | 3200W |
| Temps restant | 6h30 | 6h30 |
| **Résultat** | ❌ Pas de redémarrage (1800 < 3200) | ✅ Redémarrage OK (1800 > 50% × 3200) |

---

## 📊 RÉCAPITULATIF DES MODIFICATIONS

| Automatisation | Lignes | Modifications |
|----------------|--------|---------------|
| `cumulus_fin_detectee_temperature_max` | 1031-1125 | + Protection 3min chauffe<br>+ Vérification switch ON<br>+ Log "chauffe continue >= 3min" |
| `cumulus_redemarrage_si_appareil_arrete` | 1272-1338 | + Vérification deadband<br>+ Logique progressive identique<br>+ Log enrichi avec valeurs |

**Total automatisations** : 14 (inchangé)
**Total lignes modifiées** : ~150 lignes

---

## ✅ VALIDATION CHECKLIST

- [x] Version changée en `v2025-10-14c` dans le header (ligne 2)
- [x] Correctifs v2025-10-14c ajoutés dans le header (lignes 7-9)
- [x] Automatisation #4 modifiée avec 3 protections
- [x] Automatisation #7 modifiée avec logique progressive
- [x] Aucun nom d'entité modifié
- [x] Aucune autre automatisation touchée
- [x] Structure YAML préservée (indentation 2 espaces)
- [x] Tous les commentaires originaux conservés

---

## 🔍 TESTS RECOMMANDÉS

### Test #1 : Protection faux positif (CRITIQUE)

**Objectif** : Vérifier qu'un arrêt temporaire ne déclenche pas le verrou jour

**Procédure** :
1. Démarrer le cumulus manuellement (override ON)
2. Après 1 minute, démarrer un appareil puissant (cafetière)
3. Observer l'arrêt par "variation brutale"
4. Vérifier que `input_boolean.cumulus_verrou_jour` reste OFF

**Résultat attendu** :
- ✅ Cumulus s'arrête (variation détectée)
- ✅ Log : "Arrêt temporaire - augmentation brutale import +1200W"
- ✅ `input_boolean.cumulus_verrou_jour` = OFF
- ✅ Redémarrage possible après deadband

**Résultat si échec** :
- ❌ Verrou jour activé → Cumulus bloqué toute la journée

---

### Test #2 : Détection vraie fin de chauffe

**Objectif** : Vérifier que le thermostat interne déclenche bien le verrou

**Procédure** :
1. Lancer une chauffe complète (eau froide → 65°C)
2. Attendre 6h environ
3. Observer la coupure du thermostat interne

**Résultat attendu** :
- ✅ Après 3+ minutes de chauffe continue
- ✅ Chute d'import détectée (~2100W)
- ✅ Délai 15s de confirmation OK
- ✅ Log : "Température max atteinte après chauffe continue >= 3min"
- ✅ `input_boolean.cumulus_verrou_jour` = ON
- ✅ Notification envoyée avec bilan PV

---

### Test #3 : Redémarrage harmonisé

**Objectif** : Vérifier que le redémarrage utilise la logique progressive

**Procédure** :
1. 10h30 : Lancer le cumulus (7h restantes, 50% seuil OK)
2. 11h00 : Démarrer lave-linge → cumulus s'arrête
3. 11h35 : Lave-linge termine (après deadband 5min)
4. Observer le redémarrage automatique

**Résultat attendu** :
- ✅ Cumulus redémarre automatiquement
- ✅ Log : "Redémarrage automatique après arrêt appareil prioritaire (logique progressive)"
- ✅ Log contient : Disponible=1800W, Seuil dynamique=3200W, Temps restant=6h30

**Calcul attendu** :
```
Temps restant = 6h30 > 5h → seuil = 50% × 3200W = 1600W
Puissance disponible = 1800W > 1600W → ✅ Redémarrage OK
```

---

### Test #4 : Respect deadband

**Objectif** : Vérifier que le redémarrage respecte le délai anti-flapping

**Procédure** :
1. Cumulus en chauffe
2. Limiteur import coupe le cumulus (deadband activé 5 min)
3. Observer que le cumulus ne redémarre pas immédiatement même si conditions OK

**Résultat attendu** :
- ✅ `timer.cumulus_deadband_ui` actif pendant 5 min
- ✅ Pas de redémarrage avant expiration du timer
- ✅ Redémarrage après 5 min si PV OK

---

## 📝 LOGS ATTENDUS

### Scénario nominal (fin de chauffe réelle)

```
2025-10-14 15:23:45 - Cumulus Démarrage PV - Démarrage PV progressif. Disponible=2100W...
2025-10-14 21:45:12 - Cumulus Température Max - Thermostat interne coupé détecté (chute import -2145W). Température max atteinte après chauffe continue >= 3min. Verrou jour activé.
```

### Scénario arrêt temporaire (protection activée)

```
2025-10-14 11:25:30 - Cumulus Démarrage PV - Démarrage PV progressif...
2025-10-14 11:26:45 - Cumulus Variation Brutale - Arrêt temporaire - augmentation brutale import +1200W. PAS de verrou.
2025-10-14 11:32:00 - Cumulus Redémarrage - Redémarrage automatique après arrêt appareil prioritaire (logique progressive)...
```

### Logs à NE PAS voir (= bug)

```
❌ "Température max atteinte après chauffe continue >= 3min" après seulement 1 minute
❌ Verrou jour activé alors que cumulus_temperature_physique_c < 60°C
❌ Redémarrage refusé alors que logique progressive devrait accepter
```

---

## ⚠️ POINTS DE VIGILANCE

### Risque résiduel #1 : Chauffe lente

Si le cumulus chauffe très lentement (PV faible), il peut rester en chauffe > 3 min sans atteindre température max. Si une autre automatisation le coupe après 4 min, la protection est contournée.

**Mitigation actuelle** : Protection finale vérifie que le switch est toujours ON après le délai de 15s.

**Amélioration future** : Ajouter une condition sur la durée totale minimale de chauffe (ex: >= 1h) pour activer le verrou.

---

### Risque résiduel #2 : Deadband trop court

Si `input_number.cumulus_deadband_min` est réglé à 1 minute, le redémarrage peut être trop rapide après un arrêt limiteur.

**Recommandation** : Conserver deadband à 5 minutes minimum.

---

### Risque résiduel #3 : Fenêtre PV très courte

Si la fenêtre PV se termine dans < 2h et que le cumulus est arrêté/redémarré, la logique progressive exige 100% du seuil → redémarrage difficile.

**Comportement attendu** : C'est voulu pour éviter de démarrer une chauffe qui ne finira pas. La chauffe sera reportée en HC si activée.

---

## 🔧 CONFIGURATION RECOMMANDÉE

### Paramètres optimaux pour v2025-10-14c

```yaml
input_number:
  cumulus_deadband_min: 5          # Ne pas descendre sous 5 min
  cumulus_on_delay_s: 10           # Délai confirmation démarrage
  cumulus_marge_secu_pv: 1.2       # Marge sécurité 20%
  cumulus_espacement_max_h: 50     # Chauffe urgente après 50h
```

### Logs debug (optionnel)

Ajouter dans `configuration.yaml` :
```yaml
logger:
  default: info
  logs:
    homeassistant.components.automation.cumulus_fin_detectee_temperature_max: debug
    homeassistant.components.automation.cumulus_redemarrage_si_appareil_arrete: debug
    homeassistant.components.automation.cumulus_arret_si_variation_brutale_import: debug
```

---

## 📈 ÉVOLUTIONS FUTURES

### Court terme (v2025-10-15)
- [ ] Ajouter statistique nombre de faux positifs évités
- [ ] Notification détaillée lors d'arrêt temporaire (température actuelle)
- [ ] Graphique historique des démarrages/arrêts

### Moyen terme (v2025-11)
- [ ] Apprentissage automatique durée chauffe selon température départ
- [ ] Prédiction fin de chauffe basée sur courbe consommation
- [ ] Sonde température physique pour éliminer le modèle Newton

### Long terme (2026)
- [ ] Compteur dédié cumulus (éliminer calcul indirect)
- [ ] Intégration météo secondaire (OpenWeatherMap + Solcast)
- [ ] Optimisation multicritère (coût électricité + autoconsommation PV)

---

## 📞 SUPPORT

**En cas de problème** :
1. Vérifier les logs avec niveau debug activé
2. Consulter [RISQUES_cumulus_v2025-10-14b.md](RISQUES_cumulus_v2025-10-14b.md)
3. Vérifier que la version HA est >= 2024.6
4. Tester les automatisations en mode manuel (override ON)

**Fichiers de référence** :
- Configuration complète : `packages/cumulus.yaml`
- Analyse des risques : `packages/RISQUES_cumulus_v2025-10-14b.md`
- Correctifs actuels : `packages/CORRECTIFS_v2025-10-14c.md` (ce fichier)

---

**Document généré automatiquement le 2025-10-14**
**Auteur** : Claude Code (Anthropic)
**Révision** : 1.0
**Package version** : v2025-10-14c
