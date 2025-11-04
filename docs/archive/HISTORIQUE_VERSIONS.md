# 📜 HISTORIQUE DES VERSIONS — Cumulus Routeur Solaire

Documentation complète de l'évolution du système de gestion automatique du chauffe-eau Cumulus basé sur la production photovoltaïque.

---

## 📅 TIMELINE DES VERSIONS

### v2025-11-08 — Fix Unavailable
**Date :** 2024-11-08
**Type :** 🐛 Correction critique
**Focus :** Entités unavailable

**Corrections :**
- Correction `binary_sensor.cumulus_chauffe_reelle` (unavailable récurrents)
- Nouveau `sensor.cumulus_consommation_reelle_w` robuste
- Nouveau `binary_sensor.cumulus_etat_coherent` (détection incohérences)
- Automation fin de chauffe universelle

**Fichiers :**
- [cumulus_fix_unavailable_2024-11-08.md](correctifs/cumulus_fix_unavailable_2024-11-08.md)

---

### v2025-10-29 — Corrections Automations & Logique Verrou
**Date :** 2025-10-29
**Type :** 🔧 Correctifs + 📖 Documentation
**Focus :** Automations + logique verrou intelligent

**Modifications :**
- Corrections automation variation brutale
- Ajustements logique verrou journalier
- Documentation complète verrou intelligent
- Modification détection dernière chauffe

**Fichiers :**
- [FIX_AUTOMATION_2025-10-29.md](correctifs/FIX_AUTOMATION_2025-10-29.md)
- [RESUME_CORRECTIONS_AUTOMATIONS_2025-10-29.md](correctifs/RESUME_CORRECTIONS_AUTOMATIONS_2025-10-29.md)
- [LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md](analyses/LOGIQUE_VERROU_INTELLIGENT_2025-10-29.md)
- [MODIFICATION_DERNIERE_CHAUFFE.md](analyses/MODIFICATION_DERNIERE_CHAUFFE.md)

---

### v2025-10-24 — Améliorations
**Date :** 2025-10-24
**Type :** ✨ Améliorations
**Focus :** Optimisations diverses

**Améliorations :**
- Optimisations calcul PV
- Amélioration détection besoins
- Affinements seuils

**Fichiers :**
- [cumulus_improvements_2025-10-24.md](analyses/cumulus_improvements_2025-10-24.md)

---

### v2025-10-14h — Correctifs
**Date :** 2025-10-14
**Type :** 🔧 Correctifs
**Itération :** h (8ème itération)

**Fichiers :**
- [CORRECTIFS_v2025-10-14h.md](correctifs/CORRECTIFS_v2025-10-14h.md)

---

### v2025-10-14g — Correctifs
**Date :** 2025-10-14
**Type :** 🔧 Correctifs
**Itération :** g (7ème itération)

**Fichiers :**
- [CORRECTIFS_v2025-10-14g.md](correctifs/CORRECTIFS_v2025-10-14g.md)

---

### v2025-10-14f — Correctifs
**Date :** 2025-10-14
**Type :** 🔧 Correctifs
**Itération :** f (6ème itération)

**Fichiers :**
- [CORRECTIFS_v2025-10-14f.md](correctifs/CORRECTIFS_v2025-10-14f.md)

---

### v2025-10-14e — Améliorations
**Date :** 2025-10-14
**Type :** ✨ Améliorations
**Itération :** e (5ème itération)

**Améliorations :**
- Nouvelles fonctionnalités
- Optimisations performances

**Fichiers :**
- [AMELIORATIONS_v2025-10-14e.md](analyses/AMELIORATIONS_v2025-10-14e.md)

---

### v2025-10-14d — 🔴 BUGS CRITIQUES CORRIGÉS
**Date :** 2025-10-14
**Type :** 🔴 Correction bugs critiques
**Itération :** d (4ème itération)
**Peer review :** ChatGPT (OpenAI)

**2 BUGS CRITIQUES IDENTIFIÉS ET CORRIGÉS :**

#### BUG CRITIQUE #1 : Condition impossible sur binary_sensor
**Problème :** La condition `binary_sensor.cumulus_chauffe_reelle` ON depuis 3 min était IMPOSSIBLE à satisfaire car le sensor recalcule en temps réel et passe à OFF dès la chute d'import.

**Impact :**
- ❌ Détection fin de chauffe IMPOSSIBLE
- ❌ Verrou jour ne s'active JAMAIS
- ❌ Risque chauffes multiples inutiles par jour

**Solution :** Utiliser `states[sw_id].last_changed` du contacteur physique au lieu du binary_sensor recalculé.

#### BUG CRITIQUE #2 : Deadband jamais déclenché
**Problème :** L'automatisation vérifie que le deadband est `idle` mais ne le démarre JAMAIS lors de l'arrêt prioritaire.

**Impact :**
- ❌ Protection deadband inexistante
- ❌ Cycles ON/OFF rapides possibles
- ❌ Redémarrages immédiats après faux déclenchements

**Solution :** Ajouter `timer.start` dans l'action d'arrêt prioritaire.

**Fichiers :**
- [BUGS_CRITIQUES_v2025-10-14d.md](bugs/BUGS_CRITIQUES_v2025-10-14d.md) ⭐ **LECTURE ESSENTIELLE**

---

### v2025-10-14c — Correctifs Protection Faux Positifs
**Date :** 2025-10-14
**Type :** 🔧 Correctifs critiques
**Itération :** c (3ème itération)

**Corrections :**
- Protection faux positif fin de chauffe (condition 3 minutes)
- Ajout vérifications état contacteur
- Amélioration détection vraie fin de chauffe

**ATTENTION :** Cette version contenait les 2 bugs critiques corrigés en v2025-10-14d.

**Fichiers :**
- [CORRECTIFS_v2025-10-14c.md](correctifs/CORRECTIFS_v2025-10-14c.md)

---

### v2025-10-14b — Analyse Risques
**Date :** 2025-10-14
**Type :** ⚠️ Analyse risques
**Itération :** b (2ème itération)

**Contenu :**
- Identification risques système
- Documentation points d'attention
- Recommandations sécurité

**Fichiers :**
- [RISQUES_cumulus_v2025-10-14b.md](bugs/RISQUES_cumulus_v2025-10-14b.md)

---

### v2025-10-12a — Amélioration Précision PV
**Date :** 2025-10-12
**Type :** ✨ Nouveautés + 📋 Changelog
**Version précédente :** v2025-10-10c

**OBJECTIF :** Améliorer précision déclenchement PV

**Nouveautés :**
1. **Helper modifiable :** `input_number.cumulus_alpha_aps` (coefficient efficacité onduleur)
2. **Sensor :** `sensor.cumulus_capacity_factor` (détection pleine capacité)
3. **Sensor :** `sensor.cumulus_pv_effectif_w` (PV corrigé par efficacité)
4. **Sensor :** `sensor.cumulus_sb_dispo_w` (SolarBank disponible)
5. **Automation :** Diagnostic refus démarrage (notifications persistantes)

**Breaking Change :**
- Automation ON PV utilise maintenant `pv_effectif_w` au lieu de `pv_power_w`
- Déclenchement plus conservateur (PV effectif < PV brut)

**Fichiers :**
- [CHANGELOG_cumulus_v2025-10-12a.md](changelog/CHANGELOG_cumulus_v2025-10-12a.md)
- [TEST_CHECKLIST_cumulus_v2025-10-12a.md](procedures/TEST_CHECKLIST_cumulus_v2025-10-12a.md)
- [ROLLBACK_cumulus_v2025-10-12a.md](procedures/ROLLBACK_cumulus_v2025-10-12a.md)

---

## 🎯 SYNTHÈSE GÉNÉRALE

### Évolution du projet
Le système Cumulus a connu **14 versions documentées** entre octobre 2024 et novembre 2025, avec une concentration importante de correctifs en octobre 2025 (8 versions en 18 jours).

### Types de modifications
- **Nouveautés** : 1 version majeure (v2025-10-12a)
- **Bugs critiques** : 3 versions (v2025-10-14d, v2025-10-14c, 2024-11-08)
- **Correctifs** : 7 versions
- **Améliorations** : 3 versions
- **Analyses** : 2 versions

### Bugs critiques corrigés (7 identifiés)

#### 🔴 CRITIQUE - 2024-11-08
1. **Entités unavailable récurrents** - `binary_sensor.cumulus_chauffe_reelle` indisponible
2. **Calcul consommation défaillant** - Sensor `cumulus_consommation_reelle_w` retournait valeurs incohérentes

#### 🔴 CRITIQUE - v2025-10-14d
3. **Condition impossible binary_sensor** - Verrou jour ne s'activait JAMAIS (sensor recalculé en temps réel)
4. **Deadband fantôme** - Protection deadband documentée mais jamais activée

#### 🔴 CRITIQUE - v2025-10-14c
5. **Faux positifs fin de chauffe** - Verrou jour activé lors d'arrêts temporaires (25 minutes de chauffe)
6. **Arrêts intempestifs** - Cycles ON/OFF rapides lors de variations import
7. **Double chauffe quotidienne** - Absence de verrou efficace permettait 2+ chauffes/jour

---

## 📚 DOCUMENTATION ASSOCIÉE

### Documents généraux
- [CUMULUS_AMELIORATIONS_2025.md](analyses/CUMULUS_AMELIORATIONS_2025.md) - Liste améliorations générales 2025
- [analyse_fichiers_cumulus.md](analyses/analyse_fichiers_cumulus.md) - Analyse structure fichiers projet

### Procédures
- [GUIDE_RAPIDE_SYNC.md](procedures/GUIDE_RAPIDE_SYNC.md) - Synchronisation Git
- [INSTALLATION_FIX_DATE.md](procedures/INSTALLATION_FIX_DATE.md) - Installation fix date
- [CONFIGURATION_GIT_AUTO.md](procedures/CONFIGURATION_GIT_AUTO.md) - Configuration Git automatique
- [TEST_CHECKLIST_cumulus_v2025-10-12a.md](procedures/TEST_CHECKLIST_cumulus_v2025-10-12a.md) - Checklist tests v2025-10-12a
- [ROLLBACK_cumulus_v2025-10-12a.md](procedures/ROLLBACK_cumulus_v2025-10-12a.md) - Procédure rollback v2025-10-12a

---

## 🔍 NAVIGATION DANS L'ARCHIVE

L'archive est organisée par type de document :

- **[changelog/](changelog/)** - Changelogs détaillés des versions
- **[bugs/](bugs/)** - Bugs critiques et analyses de risques
- **[correctifs/](correctifs/)** - Correctifs et fixes appliqués
- **[procedures/](procedures/)** - Guides, checklists et procédures
- **[analyses/](analyses/)** - Analyses techniques et améliorations

Consultez [README.md](README.md) dans ce dossier pour plus de détails sur l'organisation.

---

## 🚀 DOCUMENTATION PRINCIPALE

Pour la documentation à jour du système Cumulus, consultez :
- `docs/README_CUMULUS.md` - Documentation principale (À CRÉER)
- `docs/GUIDE_INSTALLATION.md` - Guide installation (À CRÉER)
- `docs/GUIDE_UTILISATION.md` - Guide utilisateur (À CRÉER)

---

**📝 Document généré automatiquement le 2025-11-04**
**🤖 Par Claude Code (Anthropic)**
**📦 Versions documentées :** v2025-10-12a à v2025-11-08
**🔢 Total fichiers archivés :** 21 documents
