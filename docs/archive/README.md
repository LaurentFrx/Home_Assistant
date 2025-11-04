# 📚 Archive Documentation — Cumulus Routeur Solaire

Cette archive contient l'historique complet de développement du système de gestion automatique du chauffe-eau Cumulus basé sur la production photovoltaïque.

---

## 🗂️ ORGANISATION DE L'ARCHIVE

```
archive/
├── HISTORIQUE_VERSIONS.md          ⭐ Commencez ici - Timeline complète
├── README.md                        📖 Ce fichier - Guide de navigation
│
├── changelog/                       📋 Changelogs détaillés
│   └── CHANGELOG_cumulus_v2025-10-12a.md
│
├── bugs/                            🔴 Bugs critiques & Risques
│   ├── BUGS_CRITIQUES_v2025-10-14d.md  ⭐ LECTURE ESSENTIELLE
│   └── RISQUES_cumulus_v2025-10-14b.md
│
├── correctifs/                      🔧 Correctifs & Bug fixes
│   ├── CORRECTIFS_v2025-10-14c.md
│   ├── CORRECTIFS_v2025-10-14f.md
│   ├── CORRECTIFS_v2025-10-14g.md
│   ├── CORRECTIFS_v2025-10-14h.md
│   ├── FIX_AUTOMATION_2025-10-29.md
│   ├── RESUME_CORRECTIONS_AUTOMATIONS_2025-10-29.md
│   └── cumulus_fix_unavailable_2024-11-08.md
│
├── procedures/                      📝 Guides & Procédures
│   ├── TEST_CHECKLIST_cumulus_v2025-10-12a.md
│   ├── ROLLBACK_cumulus_v2025-10-12a.md
│   ├── GUIDE_RAPIDE_SYNC.md
│   ├── INSTALLATION_FIX_DATE.md
│   └── CONFIGURATION_GIT_AUTO.md
│
└── analyses/                        📊 Analyses techniques
    ├── analyse_fichiers_cumulus.md
    ├── AMELIORATIONS_v2025-10-14e.md
    ├── CUMULUS_AMELIORATIONS_2025.md
    ├── cumulus_improvements_2025-10-24.md
    ├── LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md
    └── MODIFICATION_DERNIERE_CHAUFFE.md
```

---

## 🎯 PAR OÙ COMMENCER ?

### 1️⃣ Nouveau sur le projet ?
➡️ Lisez **[HISTORIQUE_VERSIONS.md](HISTORIQUE_VERSIONS.md)** pour comprendre l'évolution du système

### 2️⃣ Vous cherchez un bug spécifique ?
➡️ Consultez **[bugs/BUGS_CRITIQUES_v2025-10-14d.md](bugs/BUGS_CRITIQUES_v2025-10-14d.md)** - Les 2 bugs les plus graves et leurs corrections

### 3️⃣ Vous voulez installer le système ?
➡️ Allez dans **[procedures/](procedures/)** et consultez les guides d'installation

### 4️⃣ Vous déboguer un problème actuel ?
➡️ Parcourez **[correctifs/](correctifs/)** pour voir si le problème a déjà été rencontré

### 5️⃣ Vous voulez comprendre la logique ?
➡️ Lisez **[analyses/LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md](analyses/LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md)**

---

## 📂 DESCRIPTION DES DOSSIERS

### 📋 changelog/
Changelogs détaillés des versions majeures avec :
- Nouveautés introduites
- Breaking changes
- Entités créées/modifiées
- Résumés des changements

**Utilisation :** Comprendre ce qui a changé entre deux versions

---

### 🔴 bugs/
Bugs critiques identifiés et analyses de risques :
- Documentation détaillée des bugs
- Séquences d'événements (avant/après)
- Solutions appliquées
- Tests de validation
- Risques résiduels

**⭐ Lecture essentielle :** `BUGS_CRITIQUES_v2025-10-14d.md` documente les 2 bugs les plus graves qui rendaient le système partiellement non fonctionnel.

**Utilisation :** Comprendre les problèmes majeurs et leurs corrections

---

### 🔧 correctifs/
Correctifs appliqués aux différentes versions :
- Corrections de bugs mineurs
- Ajustements de comportement
- Fixes d'automations
- Résumés de corrections

**Utilisation :** Dépannage et résolution de problèmes similaires

---

### 📝 procedures/
Guides pratiques et procédures :
- **Checklists de tests** - Valider une nouvelle version
- **Procédures rollback** - Revenir en arrière en cas de problème
- **Guides installation** - Installer correctifs et configurations
- **Configuration Git** - Synchronisation automatique

**Utilisation :** Suivre les bonnes pratiques d'installation et maintenance

---

### 📊 analyses/
Analyses techniques approfondies :
- Logique des algorithmes (verrou intelligent, détection fin de chauffe)
- Améliorations proposées
- Analyse de fichiers
- Documentation des modifications

**Utilisation :** Comprendre le fonctionnement interne du système

---

## 🔍 RECHERCHE PAR PROBLÈME

### "Mon cumulus ne démarre pas"
1. [analyses/CUMULUS_AMELIORATIONS_2025.md](analyses/CUMULUS_AMELIORATIONS_2025.md) - Diagnostic refus démarrage
2. [correctifs/FIX_AUTOMATION_2025-10-29.md](correctifs/FIX_AUTOMATION_2025-10-29.md) - Corrections automations

### "Le verrou jour s'active trop tôt"
1. [bugs/BUGS_CRITIQUES_v2025-10-14d.md](bugs/BUGS_CRITIQUES_v2025-10-14d.md) - Bug critique #1
2. [correctifs/CORRECTIFS_v2025-10-14c.md](correctifs/CORRECTIFS_v2025-10-14c.md) - Protection faux positifs

### "Entités unavailable"
1. [correctifs/cumulus_fix_unavailable_2024-11-08.md](correctifs/cumulus_fix_unavailable_2024-11-08.md) - Fix complet unavailable

### "Cycles ON/OFF rapides"
1. [bugs/BUGS_CRITIQUES_v2025-10-14d.md](bugs/BUGS_CRITIQUES_v2025-10-14d.md) - Bug critique #2 (deadband)
2. [correctifs/RESUME_CORRECTIONS_AUTOMATIONS_2025-10-29.md](correctifs/RESUME_CORRECTIONS_AUTOMATIONS_2025-10-29.md)

### "Je veux comprendre le verrou intelligent"
1. [analyses/LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md](analyses/LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md) - Documentation complète

### "Comment tester ma nouvelle version ?"
1. [procedures/TEST_CHECKLIST_cumulus_v2025-10-12a.md](procedures/TEST_CHECKLIST_cumulus_v2025-10-12a.md) - Checklist complète

### "Comment revenir en arrière ?"
1. [procedures/ROLLBACK_cumulus_v2025-10-12a.md](procedures/ROLLBACK_cumulus_v2025-10-12a.md) - Procédure rollback

---

## 📊 STATISTIQUES DE L'ARCHIVE

| Catégorie | Nombre de fichiers |
|-----------|-------------------|
| **Changelog** | 1 |
| **Bugs & Risques** | 2 |
| **Correctifs** | 7 |
| **Procédures** | 5 |
| **Analyses** | 6 |
| **TOTAL** | **21 fichiers** |

**Période couverte :** Octobre 2024 - Novembre 2025
**Versions documentées :** v2025-10-12a à v2025-11-08
**Bugs critiques corrigés :** 7

---

## 🚀 DOCUMENTATION ACTUELLE

**⚠️ IMPORTANT :** Cette archive contient l'**historique** du projet.

Pour la documentation **à jour** du système Cumulus en production, consultez :

- **[../README_CUMULUS.md](../README_CUMULUS.md)** - Documentation principale (À CRÉER)
- **[../GUIDE_INSTALLATION.md](../GUIDE_INSTALLATION.md)** - Guide installation (À CRÉER)
- **[../GUIDE_UTILISATION.md](../GUIDE_UTILISATION.md)** - Guide utilisateur (À CRÉER)

Retour à la [racine de docs/](../)

---

## 📞 CONTRIBUTIONS & CRÉDITS

**Développement principal :** Claude Code (Anthropic)
**Peer review bugs critiques :** ChatGPT (OpenAI)
**Tests & validation :** Utilisateur final

**Remerciements spéciaux :**
- ChatGPT pour l'identification des 2 bugs critiques en v2025-10-14d qui ont sauvé le système

---

## ℹ️ MÉTADONNÉES

**Dernière mise à jour archive :** 2025-11-04
**Organisation :** Automatisée via Claude Code
**Format :** Markdown (GitHub-flavored)
**Historique Git :** Préservé via `git mv`

---

**📝 Ce fichier a été généré automatiquement**
**🤖 Par Claude Code lors de la réorganisation de la documentation**
