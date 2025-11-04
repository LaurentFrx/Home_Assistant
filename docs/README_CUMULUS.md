# 🔥 Système Cumulus Intelligent - Guide Principal

**Version actuelle :** v2025-10-14h / v2025-11-08
**Dernière mise à jour :** 03 novembre 2025
**Statut :** ✅ Production stable

---

## 🎯 EN BREF

Système automatisé de gestion du chauffe-eau électrique qui :
- ☀️ **Chauffe avec le soleil** en priorité (maximise autoconsommation PV)
- 🔋 **Protège la batterie** (arrêt si SOC < 5%)
- ⚡ **Évite les heures creuses** quand le soleil suffit
- 🛡️ **Garantit l'eau chaude** (chauffe HC si nécessaire après 50h)
- 📊 **Surveille tout** (40+ capteurs, alertes intelligentes)

**Résultat :** Facture EDF réduite, eau chaude toujours disponible, 0 gestion manuelle

---

## 📋 CONFIGURATION ACTUELLE

### Votre installation
```yaml
Capacité cumulus : 300L
Nombre de personnes : 2
Puissance : 3000W
Espacement max : 50h (chauffe urgente après)
Contacteur : Shelly Pro 1
Batterie : Solarbank Anker
```

### Seuils clés

| Paramètre | Valeur | Quand modifier |
|-----------|--------|----------------|
| `cumulus_seuil_pv_on_w` | 100W | Si démarrages trop fréquents → augmenter à 200W |
| `cumulus_espacement_max_h` | 50h | Consommation élevée → réduire à 36h |
| `cumulus_seuil_solcast_bon_kwh` | 8 kWh | Région ensoleillée → 10-12 kWh |
| `cumulus_seuil_variation_brutale_w` | 300W | Beaucoup d'appareils → augmenter à 500W |

---

## ✅ CHECKLIST MAINTENANCE MENSUELLE

### À vérifier chaque mois

- [ ] **Dashboard** : Température estimée cohérente avec ressenti ?
- [ ] **Historique** : Chauffes régulières (tous les 2-3 jours) ?
- [ ] **Santé système** : Score > 90% ?
- [ ] **Notifications** : Pas d'alertes récurrentes "incohérence" ?
- [ ] **Logs** : Pas d'erreurs répétées dans logs HA ?

### Si problème détecté

→ Consulter [GUIDE_DEPANNAGE.md](GUIDE_DEPANNAGE.md)

---

## 🚀 FONCTIONNALITÉS PRINCIPALES

### 1. ☀️ Chauffe solaire intelligente

**Comment ça marche :**
- Surveille production PV en temps réel
- Démarre quand surplus disponible (seuil progressif selon heure)
- S'arrête si gros appareil démarre (four, lave-linge)
- Redémarre automatiquement quand possible

**Exemple journée type :**
```
10h00 : Soleil faible, pas de démarrage
11h30 : Production suffisante → Cumulus démarre
12h15 : Four allumé → Cumulus s'arrête 5 min (deadband)
12h20 : Four éteint → Cumulus redémarre
14h45 : Thermostat coupe (60°C atteint) → Verrou activé
```

### 2. 🌤️ Anticipation météo (Solcast)

**Logique :**
- Prévision demain > 8 kWh → **Pas de chauffe HC ce soir** (attente soleil)
- Prévision demain < 8 kWh → **Chauffe HC activée** (sécurité)

**Scénario réel :**
```
Lundi 14h : Chauffé au soleil
Lundi soir : Météo demain = 3 kWh (mauvais)
Mardi 3h30 : Chauffe HC activée → Eau chaude garantie
```

### 3. 🛡️ Évitement intelligent heures creuses

**Ne chauffe en HC que si :**
- Besoin urgent (> 50h depuis dernière chauffe) **OU**
- Météo défavorable demain

**Économie typique :** 2-3 chauffes HC évitées par semaine

### 4. 🔋 Protection batterie

**Arrêts automatiques :**
- SOC < 5% → Stop immédiat
- Import > 1500W pendant 5 min → Stop temporaire
- Variation brutale +300W (appareil démarre) → Stop 5 min

### 5. 📊 Monitoring complet

**Vous visualisez :**
- Température eau estimée (°C)
- Litres disponibles (~)
- Heures depuis dernière chauffe
- Production PV actuelle
- État batterie (SOC)
- Historique 10 dernières chauffes
- Score santé système (0-100%)

---

## 🎨 INTERFACE UTILISATEUR

### Dashboard LAU/cumu

**Accès :** Vue `LAU/cumu` dans Lovelace

**Sections principales :**
1. **Statut temps réel** : Température, litres, état chauffe
2. **Graphique 48h** : Température + PV + Import
3. **Contrôles rapides** : Override, Interdit, Vacances
4. **Prévisions météo** : Solcast aujourd'hui/demain
5. **Configuration** : Tous les seuils modifiables

### Contrôles d'urgence

| Bouton | Effet | Quand utiliser |
|--------|-------|----------------|
| **Override** | Force chauffe immédiate | Besoin urgent d'eau chaude |
| **Interdit** | Bloque toute chauffe | Maintenance cumulus |
| **Vacances** | Désactive alertes | Absence prolongée |

---

## ⚠️ PROBLÈMES FRÉQUENTS

### "Cumulus ne chauffe plus en HC"

**Cause :** Évitement intelligent actif (météo favorable demain)

**Solutions :**
1. Vérifier `binary_sensor.cumulus_autoriser_chauffe_hc_intelligente`
2. Si OFF : Normal si < 50h écoulées ET soleil prévu demain
3. Activer `Override` pour forcer
4. Ou réduire `cumulus_espacement_max_h` à 36h

### "Température estimée incohérente"

**Cause :** Modèle thermique simplifié (déperdition 0,3°C/h)

**Solutions :**
1. Ajuster déperdition selon isolation :
   - Cumulus récent/bien isolé : `0.2`
   - Cumulus ancien : `0.4`
2. Modifier dans `packages/cumulus.yaml` ligne ~600
3. **Idéal :** Installer sonde température physique

### "binary_sensor.cumulus_chauffe_reelle = unavailable"

**Vérifications :**
1. `sensor.cumulus_import_reseau_w` a une valeur ?
2. `sensor.cumulus_pv_power_w` a une valeur ?
3. Contacteur en `on` ou `off` (pas `unknown`) ?

**Action :** Consulter attributs du sensor pour diagnostic

### "Pas de notifications"

**Vérifications :**
1. Mode vacances désactivé ?
2. Service `persistent_notification` actif ?
3. Notifications visibles panneau latéral HA ?

---

## 📚 DOCUMENTATION DÉTAILLÉE

### Pour aller plus loin

| Document | Contenu | Quand consulter |
|----------|---------|-----------------|
| [GUIDE_DEPANNAGE.md](GUIDE_DEPANNAGE.md) | Résolution problèmes | En cas de dysfonctionnement |
| [ARCHITECTURE_TECHNIQUE.md](ARCHITECTURE_TECHNIQUE.md) | Détails sensors/automations | Pour comprendre le fonctionnement |
| [HISTORIQUE_VERSIONS.md](archive/HISTORIQUE_VERSIONS.md) | Évolution du projet | Curiosité historique |

### Archives

Toute la documentation des versions précédentes est dans `/docs/archive/`
- CHANGELOG multiples
- Correctifs successifs
- Analyses de bugs

**→ Ne pas consulter sauf besoin spécifique de traçabilité**

---

## 🔧 VERSION ACTUELLEMENT INSTALLÉE

### Comment vérifier ?

1. Ouvrir `packages/cumulus.yaml`
2. Chercher commentaire en haut de fichier
3. Ou vérifier présence de :
   - Automation `cumulus_redemarrage_apres_deadband` → v2025-10-14h minimum
   - Sensor `cumulus_consommation_reelle_w` → v2025-11-08

### Quelle version utiliser ?

| Version | Recommandation | Raison |
|---------|----------------|--------|
| **v2025-11-08** | ✅ **RECOMMANDÉE** | Fix unavailable, détection fin chauffe robuste |
| v2025-10-14h | ✅ Stable | Tous bugs critiques corrigés |
| < v2025-10-14d | ❌ Non recommandée | Bugs critiques non corrigés |

---

## 🚀 ÉVOLUTIONS FUTURES PRÉVUES

### Court terme (prochaines semaines)

1. **Score opportunité PV** : Décision graduée au lieu de ON/OFF
2. **Prédiction durée chauffe** : Apprentissage basé sur historique
3. **Stratégie batterie avancée** : Adaptation seuils selon SOC

### Moyen terme (prochains mois)

4. **Profil consommation** : Apprentissage patterns usage eau chaude
5. **Multi-sources météo** : Croiser Solcast + autres sources
6. **Diagnostic prédictif** : Détecter anomalies avant panne

### Long terme (à évaluer)

- **Compteur dédié** : Shelly EM sur circuit cumulus (éliminer calcul indirect)
- **Sonde température physique** : Remplacer estimation
- **Intégration tarif dynamique** : Tempo, EJP, etc.

---

## 📞 SUPPORT

### Problème technique

1. Consulter [GUIDE_DEPANNAGE.md](GUIDE_DEPANNAGE.md)
2. Vérifier logs Home Assistant
3. Consulter attributs sensors pour diagnostic

### Évolution souhaitée

1. Vérifier si dans roadmap ci-dessus
2. Documenter besoin précis
3. Évaluer impact sur système actuel

### Question sur fonctionnement

1. Consulter [ARCHITECTURE_TECHNIQUE.md](ARCHITECTURE_TECHNIQUE.md)
2. Examiner code dans `packages/cumulus.yaml`
3. Activer mode debug pour traçabilité détaillée

---

## ⚡ COMMANDES RAPIDES

### Forcer une chauffe immédiate
```yaml
# Via interface ou services HA
input_boolean.cumulus_override: ON
```

### Réinitialiser verrou jour
```yaml
input_boolean.cumulus_verrou_jour: OFF
```

### Modifier dernière chauffe manuellement
```yaml
# Via interface
input_datetime.cumulus_derniere_chauffe_complete: [date_heure]
```

### Désactiver temporairement
```yaml
input_boolean.cumulus_interdit: ON
```

---

## 📈 STATISTIQUES TYPIQUES

### Performance attendue

- **Chauffes solaires :** 70-80% (selon météo)
- **Chauffes HC :** 20-30%
- **Économie annuelle :** 150-250€ (vs HC systématique)
- **Disponibilité eau chaude :** 99.9%
- **Interventions manuelles :** 0-1 par mois

### Indicateurs santé

- **Score système :** > 90%
- **Espacement moyen chauffes :** 24-48h
- **Durée chauffe moyenne :** 1h30-2h30
- **Interruptions PV :** 0-2 par chauffe

---

**🎯 Système opérationnel et autonome - Profitez de votre eau chaude solaire !**

---

*Pour toute question ou amélioration de cette documentation : voir section Support ci-dessus*
