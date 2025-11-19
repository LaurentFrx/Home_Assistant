# Guide Git Sync - Synchronisation automatique Git pour Home Assistant

## 📋 Vue d'ensemble

Ce système remplace l'add-on Git Pull officiel (qui souffre d'un bug connu : `fatal: refusing to work with credential missing host field`) par une solution fiable basée sur :

- **Script bash robuste** avec vérification et rollback automatique
- **Automations Home Assistant** pour synchronisation automatique
- **Monitoring complet** avec sensors et notifications

## 🎯 Fonctionnalités

- ✅ **Pull automatique au boot** de Home Assistant (après 60s de délai)
- ✅ **Pull périodique** toutes les 10 minutes
- ✅ **Vérification de la config HA** avant redémarrage
- ✅ **Rollback automatique** en cas d'erreur de configuration
- ✅ **Logs détaillés** dans `/config/git_sync.log`
- ✅ **Gestion d'erreurs robuste** (réseau, conflits, etc.)
- ✅ **Monitoring** via sensors et binary sensors
- ✅ **Notifications** en cas d'erreur ou de mises à jour disponibles
- ✅ **Contrôle manuel** via interface Home Assistant

## 📁 Fichiers créés

```
/config/
├── scripts/
│   ├── git_sync.sh                 # Script principal de synchronisation
│   └── git_sync_diagnostic.sh      # Script de diagnostic
├── packages/
│   └── git_sync.yaml               # Package HA avec automations et sensors
└── docs/
    └── GIT_SYNC_GUIDE.md          # Ce guide
```

## 🚀 Installation

### Étape 1 : Configuration SSH

#### 1.1 Connexion SSH au serveur Home Assistant

```bash
ssh root@192.168.1.29 -p 22222
```

#### 1.2 Vérification/Création des clés SSH

```bash
# Créer le répertoire .ssh si nécessaire
mkdir -p /config/.ssh
chmod 700 /config/.ssh

# Générer une clé ED25519 (recommandé)
ssh-keygen -t ed25519 -C "homeassistant@192.168.1.29" -f /config/.ssh/id_ed25519 -N ""

# Afficher la clé publique à ajouter sur GitHub
cat /config/.ssh/id_ed25519.pub
```

#### 1.3 Créer le fichier de configuration SSH

```bash
cat > /config/.ssh/config << 'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile /config/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

chmod 600 /config/.ssh/config
```

#### 1.4 Ajouter la clé publique sur GitHub

1. Copiez la clé publique affichée par la commande précédente
2. Allez sur GitHub : https://github.com/settings/keys
3. Cliquez sur **"New SSH key"**
4. Donnez un titre : `Home Assistant - 192.168.1.29`
5. Collez la clé publique
6. Cliquez sur **"Add SSH key"**

#### 1.5 Tester la connexion SSH

```bash
ssh -T git@github.com
```

Vous devriez voir : `Hi LaurentFrx! You've successfully authenticated...`

#### 1.6 Configurer Git pour utiliser SSH

```bash
cd /config
git remote set-url origin git@github.com:LaurentFrx/Home_Assistant.git
```

### Étape 2 : Rendre les scripts exécutables

```bash
chmod +x /config/scripts/git_sync.sh
chmod +x /config/scripts/git_sync_diagnostic.sh
```

### Étape 3 : Vérifier la configuration

```bash
/config/scripts/git_sync_diagnostic.sh
```

Ce script va vérifier :
- ✓ Git installé et configuré
- ✓ SSH configuré correctement
- ✓ Scripts présents et exécutables
- ✓ Package YAML valide
- ✓ Connectivité réseau
- ✓ CLI Home Assistant fonctionnel

### Étape 4 : Test manuel du script

```bash
/config/scripts/git_sync.sh
```

Vérifiez les logs :

```bash
tail -f /config/git_sync.log
```

### Étape 5 : Activer le package dans Home Assistant

#### 5.1 Vérifier que les packages sont activés

Éditez `/config/configuration.yaml` et assurez-vous que cette ligne est présente :

```yaml
homeassistant:
  packages: !include_dir_named packages
```

#### 5.2 Redémarrer Home Assistant

Via l'interface :
- Paramètres → Système → Redémarrer

Ou via SSH :
```bash
ha core restart
```

### Étape 6 : Vérification post-installation

Après le redémarrage, vérifiez que les entités suivantes sont disponibles :

**Input Booleans :**
- `input_boolean.git_sync_auto_enabled` (activé par défaut)
- `input_boolean.git_sync_notify_enabled` (activé par défaut)

**Sensors :**
- `sensor.git_derniere_synchronisation`
- `sensor.git_statut_derniere_sync`
- `sensor.git_commit_actuel`
- `sensor.git_commits_en_retard`

**Binary Sensors :**
- `binary_sensor.git_updates_available`

**Automations :**
- `automation.git_sync_on_startup`
- `automation.git_sync_periodic`
- `automation.git_sync_error_notification`
- `automation.git_sync_updates_available`

**Scripts :**
- `script.git_sync_manual`
- `script.git_sync_show_logs`

## 🎮 Utilisation

### Synchronisation manuelle

Via l'interface Home Assistant :

1. Allez dans **Paramètres → Développeur → Services**
2. Choisissez le service `script.git_sync_manual`
3. Cliquez sur **Appeler le service**

Ou via SSH :

```bash
/config/scripts/git_sync.sh
```

### Activer/Désactiver la synchronisation automatique

Via l'interface Home Assistant :

1. Allez dans **Paramètres → Appareils et services → Entités**
2. Recherchez `input_boolean.git_sync_auto_enabled`
3. Activez ou désactivez selon vos besoins

### Consulter les logs

#### Dernières lignes

```bash
tail -n 50 /config/git_sync.log
```

#### Suivre les logs en temps réel

```bash
tail -f /config/git_sync.log
```

#### Afficher tout le log

```bash
cat /config/git_sync.log
```

## 📊 Monitoring

### Dashboard recommandé

Ajoutez ces cartes à votre dashboard :

```yaml
type: entities
title: Git Synchronisation
entities:
  - entity: input_boolean.git_sync_auto_enabled
    name: Synchronisation automatique
  - entity: input_boolean.git_sync_notify_enabled
    name: Notifications
  - entity: sensor.git_derniere_synchronisation
    name: Dernière synchronisation
  - entity: sensor.git_statut_derniere_sync
    name: Statut
  - entity: sensor.git_commit_actuel
    name: Commit actuel
  - entity: binary_sensor.git_updates_available
    name: Mises à jour disponibles
  - entity: sensor.git_commits_en_retard
    name: Commits en retard
  - type: button
    name: Synchroniser maintenant
    action_name: Sync
    tap_action:
      action: call-service
      service: script.git_sync_manual
```

### Notifications

Le système envoie automatiquement des notifications dans ces cas :

1. **Au démarrage** : Confirmation de la synchronisation au boot
2. **En cas d'erreur** : Détails de l'erreur et comment investiguer
3. **Mises à jour disponibles** : Si la sync auto est désactivée et que des commits sont disponibles

## 🔧 Dépannage

### Le script ne s'exécute pas

```bash
# Vérifier les permissions
ls -la /config/scripts/git_sync.sh

# Rendre exécutable
chmod +x /config/scripts/git_sync.sh

# Tester manuellement
/config/scripts/git_sync.sh
```

### Erreur "Permission denied (publickey)"

```bash
# Vérifier que la clé SSH est correctement configurée
cat /config/.ssh/config

# Tester la connexion GitHub
ssh -T git@github.com

# Vérifier que le remote utilise SSH et non HTTPS
cd /config
git remote -v

# Si nécessaire, changer pour SSH
git remote set-url origin git@github.com:LaurentFrx/Home_Assistant.git
```

### Erreur "Configuration invalide"

Le script a détecté une erreur dans la configuration après le pull et a automatiquement fait un rollback.

```bash
# Consulter les logs pour voir l'erreur
tail -n 100 /config/git_sync.log

# Vérifier manuellement la configuration
ha core check
```

### Les automations ne se déclenchent pas

```bash
# Vérifier que le package est chargé
ha core check

# Vérifier les automations
cd /config
grep -r "git_sync" automations/

# Redémarrer Home Assistant
ha core restart
```

### Consulter les erreurs détaillées

```bash
# Logs du script
tail -f /config/git_sync.log

# Logs Home Assistant
ha core logs
```

## 🔐 Sécurité

- ✅ **SSH uniquement** : Pas de tokens en clair
- ✅ **Clés ED25519** : Cryptographie moderne et sécurisée
- ✅ **Permissions strictes** : 700 pour .ssh, 600 pour les clés
- ✅ **Pas de secrets versionnés** : Le .gitignore protège secrets.yaml
- ✅ **Rollback automatique** : Évite les configurations cassées

## ⚙️ Configuration avancée

### Modifier la fréquence de synchronisation

Éditez `/config/packages/git_sync.yaml` :

```yaml
automation:
  - id: git_sync_periodic
    trigger:
      - platform: time_pattern
        minutes: "/5"  # Changez 10 en 5 pour toutes les 5 minutes
```

### Désactiver le redémarrage automatique

Si vous voulez seulement pull sans redémarrer :

Éditez `/config/scripts/git_sync.sh` et commentez ces lignes :

```bash
# Configuration valide, redémarrer Home Assistant
# if ! restart_ha; then
#     log "ERROR" "Échec du redémarrage de Home Assistant"
#     exit ${EXIT_RESTART_ERROR}
# fi
```

### Ajouter des notifications personnalisées

Ajoutez dans `/config/packages/git_sync.yaml` :

```yaml
automation:
  - id: git_sync_success_notification
    alias: "Git Sync - Notification de succès"
    trigger:
      - platform: state
        entity_id: sensor.git_statut_derniere_sync
        to: "Succès"
    action:
      - service: notify.mobile_app_votre_telephone
        data:
          title: "✅ Git Sync"
          message: "Synchronisation réussie"
```

## 📝 Logs

### Format des logs

```
[2025-11-19 10:30:00] [INFO] Début de la synchronisation Git
[2025-11-19 10:30:01] [INFO] Vérification de la connectivité réseau...
[2025-11-19 10:30:02] [INFO] Connectivité réseau OK
[2025-11-19 10:30:03] [INFO] Récupération des modifications depuis origin/main...
[2025-11-19 10:30:05] [INFO] Git fetch réussi
[2025-11-19 10:30:05] [INFO] Mises à jour disponibles : abc123 -> def456
[2025-11-19 10:30:06] [INFO] Début du pull Git...
[2025-11-19 10:30:08] [INFO] Git pull réussi
[2025-11-19 10:30:08] [INFO] Vérification de la configuration Home Assistant...
[2025-11-19 10:30:15] [INFO] Configuration Home Assistant valide
[2025-11-19 10:30:15] [INFO] Redémarrage de Home Assistant...
[2025-11-19 10:30:16] [INFO] Synchronisation terminée avec succès
```

### Rotation automatique

Les logs sont automatiquement rotationnés quand ils dépassent 5 MB.

## 🆘 Support

### Diagnostic complet

```bash
/config/scripts/git_sync_diagnostic.sh
```

### Fichiers à vérifier

1. `/config/git_sync.log` - Logs de synchronisation
2. `/config/.last_known_good_commit` - Commit de rollback
3. `/config/packages/git_sync.yaml` - Configuration du package
4. `/config/scripts/git_sync.sh` - Script principal

### Réinitialisation complète

En cas de problème majeur :

```bash
# Sauvegarder les logs actuels
cp /config/git_sync.log /config/git_sync.log.backup

# Réinitialiser Git au dernier commit propre
cd /config
git fetch origin main
git reset --hard origin/main

# Retester
/config/scripts/git_sync_diagnostic.sh
/config/scripts/git_sync.sh
```

## 📚 Ressources

- [Documentation Home Assistant](https://www.home-assistant.io/)
- [Git Documentation](https://git-scm.com/doc)
- [SSH Key Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

## ✅ Checklist de vérification

- [ ] Clés SSH générées et ajoutées sur GitHub
- [ ] Remote Git configuré en SSH
- [ ] Scripts exécutables (`chmod +x`)
- [ ] Diagnostic sans erreur
- [ ] Test manuel du script réussi
- [ ] Package chargé dans Home Assistant
- [ ] Entités visibles dans l'interface
- [ ] Automations actives
- [ ] Notifications fonctionnelles

---

**Auteur** : Claude Code CLI
**Date** : 2025-11-19
**Version** : 1.0
