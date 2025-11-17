# Préférences Claude Code CLI

> **Dernière mise à jour** : 2025-11-14
> **Version** : 2.0 (optimisée Claude Code CLI uniquement)

---

## Contexte général

Je programme essentiellement en YAML dans Home Assistant et crée des documents pour le travail des élèves de collège en espagnol.

---

## Workflow Claude Code CLI

### Environnement

- **Claude Code CLI** : app iOS ou web Chrome (comportement identique)
- **Repo Git** : github.com/LaurentFrx/Home_Assistant (branche : détectée auto)
- **Serveur HA** : 192.168.1.29 (accès SSH)
- **Script de sync** : /config/scripts/git_sync.sh (alias : `gs` sur serveur HA)

### Workflow ultra-simplifié

1. Je décris mon besoin
2. Claude crée/modifie les fichiers directement dans le repo
3. Claude commit et push automatiquement sur la branche appropriée

### Obsolète (ne plus utiliser)

- ❌ Working Copy (obsolète avec Claude Code CLI)
- ❌ Artifacts ou create_file (Claude Code CLI gère directement les fichiers)
- ❌ Copier-coller manuel
- ❌ Distinction iPad/PC (comportement identique)

---

## Méthode de travail - Scripts bash auto-documentés

Privilégier les scripts bash auto-documentés pour économiser les tokens.

### Workflow optimal en 3 phases

- **Phase 1 (Conception)** : Je décris mon besoin, Claude génère un script bash complet et commenté dans le repo (~8 000 tokens)
- **Phase 2 (Exécution)** : J'exécute le script en SSH sur mon serveur HA, sans IA impliquée (0 tokens)
- **Phase 3 (Debug)** : Si erreur, je colle le message, Claude corrige le script (~2 000 tokens)

**Résultat** : ~10 000 tokens au lieu de 65 000 avec copier-coller répétitifs = **83% d'économie**

Les scripts sont réutilisables à l'infini sans consommer de tokens.

---

## Règles critiques Home Assistant

### 1. NOMS D'ENTITÉS (ABSOLU - NE JAMAIS VIOLER)

- **INTERDICTION FORMELLE** de renommer une entité existante sans demande explicite
- Les noms d'entités sont des identifiers techniques utilisés dans toute la config
- Un changement de nom casse TOUTES les références (automations, dashboards, scripts)
- Si modification nécessaire : **TOUJOURS demander confirmation avant**
- Préserver les noms même si non conventionnels ou mal formés

### 2. YAML - Syntaxe et validation

- **Indentation** : 2 espaces UNIQUEMENT (jamais de tabs)
- **Strings** : guillemets simples `'texte'` pour éviter échappements
- **Templates Jinja2** : toujours entre guillemets simples `'{{ template }}'`
- **Booleans** : `on`/`off` ou `true`/`false` (minuscules, sans guillemets)
- **Numbers** : sans guillemets (integers ou floats)
- **Listes** : tiret + espace `- item` ou format inline `[item1, item2]`
- **Dictionnaires** : clé + deux-points + espace `key: value`
- **Commentaires** : `#` en début de ligne ou après valeur
- **TOUJOURS** vérifier la syntaxe YAML avant de proposer du code

### 3. Templates Jinja2 - Best practices

- Utiliser `states('entity_id')` plutôt que `states.entity_id.state`
- `state_attr('entity_id', 'attribute')` pour les attributs
- `is_state('entity_id', 'state')` pour comparaisons
- Toujours gérer les cas `None`/`Unknown`/`Unavailable`
- Conversions : `| int(0)`, `| float(0.0)`, `| default('valeur')`
- Tests conditionnels : `{% if %}` `{% elif %}` `{% else %}` `{% endif %}`
- Éviter les templates trop complexes (> 5 lignes → split en sensors)

### 4. Structure de fichiers

- `/config/packages/` : fichiers thématiques modulaires (ex: cumulus.yaml)
- Chaque package contient : `input_*`, sensors, automations, scripts liés
- `/config/automations/` : automations via UI (ne pas éditer manuellement)
- `/config/scripts/` : scripts bash utilitaires
- `/config/lovelace/` : dashboards YAML (vs UI mode)
- Toujours grouper les entités liées dans le même fichier package

### 5. Automations - Architecture

- **Structure en 4 couches** : Paramètres → Sensors → Détecteurs d'état → Logique de contrôle
- **trigger** : événements qui déclenchent (time, state, numeric_state, template)
- **condition** : validations avant action (and, or, not, template)
- **action** : séquence d'actions (service calls, delays, choose)
- **Mode d'exécution** : single/restart/queued/parallel selon cas d'usage
- Utiliser `mode: restart` pour automations fréquentes
- **TOUJOURS** ajouter condition pour éviter boucles infinies

### 6. Sensors template - Bonnes pratiques

- Préférer `sensor.template` avec update mode (time_pattern, state trigger)
- `device_class` approprié (energy, power, temperature, etc.)
- `state_class` pour statistics (measurement, total, total_increasing)
- `unit_of_measurement` pour affichage et conversions
- `availability_template` pour gérer les capteurs indisponibles
- Éviter les sensor updates trop fréquents (throttle avec time_pattern)

### 7. Debugging et logs

- `ha core check` : valider config avant reload
- `ha core reload` : recharger sans redémarrage
- Logs : `/config/home-assistant.log` ou via UI Developer Tools
- Template Editor : tester templates en temps réel
- States : vérifier valeurs actuelles des entités
- Events : inspecter événements système

### 8. Performance et optimisation

- Limiter les automations avec `trigger: template` (CPU intensif)
- Utiliser `trigger_variables` pour calculs une seule fois
- Préférer `numeric_state` à template pour comparaisons numériques
- Éviter les `scan_interval < 30s` sauf nécessité absolue
- Désactiver recorder pour entités non-essentielles
- Utiliser `input_number.set_value` sans créer états historiques

### 9. Sécurité et secrets

- Passwords et tokens dans `secrets.yaml` (jamais en clair)
- Référence : `!secret nom_du_secret`
- Git : `secrets.yaml` dans `.gitignore`
- API tokens : génération via UI Profile

### 10. Documentation et maintenance

- Commentaires explicites en français dans YAML
- Messages de commit descriptifs en français
- README.md pour chaque projet complexe
- Documentation inline pour logique complexe
- Versionning Git systématique de toute modification

### 11. Gestion des erreurs

- Toujours prévoir les cas d'erreur (unavailable, unknown, none)
- `default` filters dans templates : `| default(0)`
- Conditions de sécurité dans automations
- Notifications en cas d'erreur critique
- Logs explicites pour debug

### 12. Intégrations et devices

- Vérifier compatibilité version HA avant ajout intégration
- Éviter les intégrations obsolètes ou non maintenues
- Préférer intégrations officielles vs custom
- Documenter les intégrations custom (HACS)

---

## Style de réponse attendu

- Réponses techniques précises et concises
- Code production-ready, testé conceptuellement
- Pas de simplifications excessives : je suis développeur expérimenté
- Anticiper les edge cases et les mentionner
- Proposer des alternatives quand pertinent
- Expliquer le "pourquoi" des choix techniques
- Fournir des exemples concrets basés sur mon contexte réel

---

## Contexte projet actuel

### Système de gestion cumulus 3000W avec optimisation solaire PV

- **Équipements** : SolarBank + APS inverter + monitoring multi-capteurs
- **Architecture** : 4 couches (config → sensors → détecteurs → contrôle)
- **Objectif** : maximiser autoconsommation, minimiser coûts réseau
- **Modes** : OFF, PV (surplus solaire), HC (heures creuses), FORCE
- **Contraintes** : détection précise états, notifications intelligentes, interface famille

### Documentation de référence

- `docs/README_CUMULUS.md` : documentation complète du système
- `docs/ARCHITECTURE_TECHNIQUE.md` : architecture détaillée
- `docs/GUIDE_DEPANNAGE.md` : guide de dépannage
- `SYNTHESE_CUMULUS_COMPLETE.md` : synthèse technique complète
