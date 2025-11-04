# 🚀 GUIDE RAPIDE : Synchronisation automatique GitHub ↔ Home Assistant

**Temps estimé :** 5 minutes
**Niveau :** Débutant

---

## ✅ ÉTAPES RAPIDES

### 1️⃣ Installer l'add-on "Git Pull"

1. **Ouvrez votre Home Assistant dans le navigateur**
2. **Cliquez sur :** Paramètres (⚙️) → Modules complémentaires → Boutique
3. **Cherchez :** `Git Pull`
4. **Cliquez sur :** "Git Pull" par Poeschl
5. **Cliquez sur :** INSTALLER
6. **Attendez** la fin de l'installation (30-60 secondes)

---

### 2️⃣ Configurer l'add-on

1. **Dans l'add-on Git Pull, cliquez sur :** Configuration
2. **Effacez tout le contenu**
3. **Copiez-collez ceci :**

```yaml
repository: https://github.com/LaurentFrx/Home_Assistant.git
auto_restart: false
repeat:
  active: true
  interval: 300
deployment_key: []
deployment_key_protocol: rsa
```

4. **Cliquez sur :** SAUVEGARDER (icône disquette en haut à droite)

---

### 3️⃣ Démarrer l'add-on

1. **Cliquez sur l'onglet :** Info
2. **Cliquez sur :** DÉMARRER
3. **Activez :** Démarrer au boot (toggle)
4. **Cliquez sur :** ACTUALISER (pour voir les logs)

**Vous devriez voir dans les logs :**
```
Cloning into '/config'...
remote: Enumerating objects...
Receiving objects: 100%
✓ Git pull finished
```

---

### 4️⃣ Vérifier les fichiers

1. **Installez "File Editor" si pas déjà fait :**
   - Paramètres → Modules complémentaires → Boutique
   - Cherchez "File Editor"
   - Installez

2. **Ouvrez File Editor**

3. **Vérifiez que ces fichiers sont présents :**
   - ✅ `cumulus_fix_date_auto.yaml`
   - ✅ `packages/cumulus.yaml`
   - ✅ `docs/` (dossier avec plusieurs .md)

---

### 5️⃣ Redémarrer Home Assistant

1. **Paramètres → Système → REDÉMARRER**
2. **Attendez 1-2 minutes**

---

### 6️⃣ Vérifier les automations

1. **Paramètres → Automations et Scènes**
2. **Dans la barre de recherche, tapez :** `Cumulus`
3. **Vous devriez voir 5 nouvelles automations :**
   - ✅ Cumulus — Init dernière chauffe au démarrage
   - ✅ Cumulus — MAJ dernière chauffe après fin
   - ✅ Cumulus — Protection date invalide
   - ✅ Cumulus — Maintenance hebdo date
   - ✅ Cumulus — Correction besoin urgent anormal

---

### 7️⃣ Vérifier que "besoin urgent" est OFF

1. **Developer Tools → States**
2. **Cherchez :** `binary_sensor.cumulus_besoin_chauffe_urgente`
3. **État devrait être :** `off` ✅

---

## 🎉 TERMINÉ !

Votre Home Assistant se synchronise maintenant automatiquement avec GitHub **toutes les 5 minutes**.

---

## 🔄 WORKFLOW DE SYNCHRONISATION

```
┌──────────────────────────────────────────┐
│  Vous modifiez un fichier sur votre PC  │
└──────────────┬───────────────────────────┘
               │
               ▼
        git add / commit / push
               │
               ▼
┌──────────────────────────────────────────┐
│            GitHub (cloud)                │
└──────────────┬───────────────────────────┘
               │
               ▼ (toutes les 5 minutes)
       Add-on Git Pull détecte
               │
               ▼
┌──────────────────────────────────────────┐
│     Home Assistant (automatiquement)     │
│   Fichiers mis à jour sans redémarrage  │
└──────────────────────────────────────────┘
               │
               ▼ (vous décidez quand)
         Redémarrage manuel
               │
               ▼
      Nouvelles automations actives
```

---

## 📝 POUR AJOUTER/MODIFIER DES FICHIERS

### Sur votre PC :

```bash
# 1. Allez dans le dossier
cd C:\Users\wakaw\OneDrive\Documents\VSCode-HA-cumulus\homeassistant-cumulus

# 2. Modifiez vos fichiers (avec VS Code, Notepad++, etc.)

# 3. Commitez
git add .
git commit -m "Description de vos changements"
git push origin main

# 4. Attendez 5 minutes (ou redémarrez l'add-on Git Pull dans HA)

# 5. Vos fichiers sont automatiquement dans HA !
```

---

## 🛠️ SI ÇA NE FONCTIONNE PAS

### Problème 1 : "Repository not found"

**Solution :**
- Vérifiez que votre repository GitHub est **PUBLIC**
- Ou configurez un Deploy Key (voir CONFIGURATION_GIT_AUTO.md)

### Problème 2 : Les fichiers n'apparaissent pas

**Solution :**
1. **Git Pull add-on → Info → REDÉMARRER**
2. **Regardez les logs**
3. **Si erreur, vérifiez l'URL du repository**

### Problème 3 : "Already up to date"

**C'est normal !** Ça veut dire que HA a déjà les derniers fichiers.

### Problème 4 : Les automations n'apparaissent pas

**Solution :**
1. Vérifiez que `cumulus_fix_date_auto.yaml` est dans `/config/packages/`
2. Vérifiez que packages est activé dans `configuration.yaml` :
   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```
3. Redémarrez HA

---

## ⚡ COMMANDES RAPIDES

### Forcer un pull immédiat

1. **Git Pull add-on → Info → REDÉMARRER**

### Voir les logs de synchronisation

1. **Git Pull add-on → Journal**

### Désactiver temporairement

1. **Git Pull add-on → Info → ARRÊTER**

---

## 🎯 AVANTAGES DE CETTE MÉTHODE

| Avant | Après |
|-------|-------|
| ❌ Copier-coller manuel des fichiers | ✅ Synchronisation automatique |
| ❌ Risque d'oubli de fichiers | ✅ Tout synchronisé automatiquement |
| ❌ Pas de versioning | ✅ Historique Git complet |
| ❌ Difficile de revenir en arrière | ✅ `git checkout` pour restaurer |
| ❌ Pas de backup automatique | ✅ GitHub = backup cloud |

---

## 📚 DOCUMENTATION COMPLÈTE

- **Configuration avancée :** [CONFIGURATION_GIT_AUTO.md](docs/CONFIGURATION_GIT_AUTO.md)
- **Correctif date :** [INSTALLATION_FIX_DATE.md](docs/INSTALLATION_FIX_DATE.md)
- **Fix unavailable :** [cumulus_fix_unavailable_2024-11-08.md](docs/cumulus_fix_unavailable_2024-11-08.md)

---

**Besoin d'aide ?** Consultez la documentation complète ou ouvrez une issue sur GitHub !
