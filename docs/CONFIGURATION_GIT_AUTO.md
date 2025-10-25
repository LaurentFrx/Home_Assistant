# Configuration Git Pull Automatique - Home Assistant

**Date :** 2025-10-25
**Objectif :** Synchroniser automatiquement votre HA avec GitHub

---

## 🎯 MÉTHODE RECOMMANDÉE : Add-on "Git Pull"

### Étape 1 : Installer l'add-on

1. **Ouvrez Home Assistant**
2. **Paramètres → Modules complémentaires → Boutique des modules complémentaires**
3. **Cherchez : "Git Pull"**
4. **Cliquez sur "Git Pull" (par Poeschl)**
5. **Installez**

---

### Étape 2 : Configurer l'add-on

1. **Allez dans l'onglet "Configuration"**

2. **Collez cette configuration :**

```yaml
repository: https://github.com/LaurentFrx/Home_Assistant.git
auto_restart: false
repeat:
  active: true
  interval: 300
deployment_key: []
deployment_key_protocol: rsa
```

**Explication :**
- `repository` : Votre repo GitHub
- `auto_restart: false` : Ne redémarre pas automatiquement (vous le ferez manuellement)
- `repeat.active: true` : Pull automatique
- `repeat.interval: 300` : Toutes les 5 minutes (300 secondes)

3. **Sauvegardez**

---

### Étape 3 : Démarrer l'add-on

1. **Allez dans l'onglet "Info"**
2. **Cliquez sur "DÉMARRER"**
3. **Activez "Démarrer au boot"**
4. **Cliquez sur "LOGS" pour voir l'activité**

---

### Étape 4 : Premier Pull manuel

1. **Allez dans l'onglet "Info"**
2. **Cliquez sur "REDÉMARRER"**
3. **Regardez les logs :**

Vous devriez voir :
```
Cloning into '/config'...
remote: Enumerating objects...
Receiving objects: 100%
Resolving deltas: 100%
```

---

### Étape 5 : Vérifier les fichiers

1. **Ouvrez File Editor**
2. **Vérifiez que les nouveaux fichiers sont présents :**
   - ✅ `cumulus_fix_date_auto.yaml`
   - ✅ `packages/cumulus.yaml` (mis à jour)
   - ✅ `docs/` (nouveau dossier)

---

### Étape 6 : Redémarrer Home Assistant

1. **Paramètres → Système → Redémarrer**
2. **Attendez le redémarrage**

---

### Étape 7 : Vérifier les automations

1. **Paramètres → Automations et Scènes**
2. **Cherchez "Cumulus"**
3. **Vous devriez voir 5 nouvelles automations :**
   - ✅ Cumulus — Init dernière chauffe au démarrage
   - ✅ Cumulus — MAJ dernière chauffe après fin
   - ✅ Cumulus — Protection date invalide
   - ✅ Cumulus — Maintenance hebdo date
   - ✅ Cumulus — Correction besoin urgent anormal

---

## ⚙️ ALTERNATIVE : Configuration manuelle Git

Si vous préférez configurer Git manuellement via SSH :

### Prérequis
- SSH activé sur Home Assistant
- Accès terminal

### Configuration

```bash
# 1. SSH vers votre Home Assistant
ssh root@homeassistant.local

# 2. Aller dans le dossier config
cd /config

# 3. Initialiser Git (si pas déjà fait)
git init

# 4. Configurer le remote
git remote add origin https://github.com/LaurentFrx/Home_Assistant.git

# 5. Configurer Git
git config user.name "Laurent"
git config user.email "laurent@feroux.fr"

# 6. Premier pull
git fetch origin main
git reset --hard origin/main

# 7. Vérifier
ls -la
```

---

## 🔄 AUTOMATISATION DU PULL

### Option A : Automation Home Assistant

Créez une automation qui pull toutes les heures :

```yaml
automation:
  - id: git_pull_auto
    alias: "Git Pull automatique"
    trigger:
      - platform: time_pattern
        hours: "/1"  # Toutes les heures
    action:
      - service: hassio.addon_restart
        data:
          addon: a0d7b954_git_pull
```

### Option B : Cron Job (Advanced)

```bash
# Sur Home Assistant OS (via SSH)
crontab -e

# Ajoutez cette ligne :
*/5 * * * * cd /config && git pull origin main
```

---

## 📊 MONITORING

### Vérifier le dernier pull

1. **Ouvrez SSH ou Terminal**
2. **Exécutez :**
   ```bash
   cd /config
   git log -1 --oneline
   ```

Vous devriez voir :
```
4e480a3 fix: Correction critique binary_sensor.cumulus_chauffe_reelle
```

### Vérifier les fichiers synchronisés

```bash
cd /config
git status
```

Devrait afficher :
```
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

---

## 🛡️ SÉCURITÉ : Utiliser un Deploy Key (Optionnel)

Pour éviter d'utiliser vos credentials GitHub :

### 1. Générer une clé SSH

```bash
ssh-keygen -t ed25519 -C "homeassistant-git" -f ~/.ssh/ha_deploy_key
```

### 2. Ajouter la clé publique sur GitHub

1. **Copiez la clé publique :**
   ```bash
   cat ~/.ssh/ha_deploy_key.pub
   ```

2. **GitHub → Repository → Settings → Deploy keys**
3. **Add deploy key**
4. **Collez la clé publique**
5. **Cochez "Allow write access" si vous voulez push depuis HA**

### 3. Configurer Git pour utiliser la clé

```bash
git config core.sshCommand "ssh -i ~/.ssh/ha_deploy_key"
```

---

## 🎯 WORKFLOW COMPLET

Voici le workflow idéal :

```
┌─────────────────┐
│  Vous modifiez  │
│   sur PC local  │
└────────┬────────┘
         │ git push
         ▼
┌─────────────────┐
│     GitHub      │
│  (repository)   │
└────────┬────────┘
         │ Git Pull (auto toutes les 5min)
         ▼
┌─────────────────┐
│ Home Assistant  │
│   (production)  │
└─────────────────┘
```

---

## ⚠️ ATTENTION : Conflits

Si vous modifiez des fichiers **à la fois** sur PC **et** dans Home Assistant, vous aurez des conflits.

**Règle d'or :**
- ✅ Modifiez sur PC → Push → HA pull automatiquement
- ❌ Ne modifiez PAS les mêmes fichiers dans HA et PC simultanément

**Si conflit :**
```bash
cd /config
git stash  # Sauvegarde les changements locaux
git pull   # Récupère depuis GitHub
git stash pop  # Réapplique les changements locaux (peut causer conflit)
```

---

## 🧪 TEST DE SYNCHRONISATION

### Test 1 : Modifier un fichier sur PC

1. **Sur PC, créez un fichier test :**
   ```bash
   cd C:\Users\wakaw\OneDrive\Documents\VSCode-HA-cumulus\homeassistant-cumulus
   echo "Test sync" > test_sync.txt
   git add test_sync.txt
   git commit -m "test: Test synchronisation"
   git push origin main
   ```

2. **Attendez 5 minutes (ou redémarrez l'add-on Git Pull)**

3. **Dans HA File Editor, vérifiez que `test_sync.txt` apparaît**

### Test 2 : Vérifier les logs

1. **Git Pull add-on → Logs**
2. **Vous devriez voir :**
   ```
   Updating 4e480a3..xxxxxx
   Fast-forward
    test_sync.txt | 1 +
    1 file changed, 1 insertion(+)
   ```

---

## 📞 DÉPANNAGE

### "Repository not found"

**Solution :**
- Vérifiez l'URL : `https://github.com/LaurentFrx/Home_Assistant.git`
- Vérifiez que le repository est public (ou configurez un deploy key)

### "Permission denied"

**Solution :**
- Le repository est privé → Utilisez un deploy key
- Ou rendez le repository public

### "Not a git repository"

**Solution :**
```bash
cd /config
rm -rf .git
git init
git remote add origin https://github.com/LaurentFrx/Home_Assistant.git
git fetch origin main
git reset --hard origin/main
```

---

## ✅ CHECKLIST FINALE

```yaml
☐ Add-on "Git Pull" installé
☐ Configuration avec URL du repository
☐ Add-on démarré avec "Démarrer au boot" activé
☐ Premier pull réussi (voir les logs)
☐ Fichiers visibles dans File Editor
☐ Home Assistant redémarré
☐ 5 automations "Cumulus" visibles
☐ Script cumulus_reset_derniere_chauffe disponible
☐ Test de synchronisation réussi
```

---

**Prochaine étape :** Suivez ce guide et dites-moi si vous rencontrez un problème ! 🚀
