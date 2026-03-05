Parfait, l'audit est clair. Voici le résumé :

**27 références à corriger dans 5 fichiers :**
- `solaire_economies.yaml` — 18 refs (le plus impacté)
- `carte_batterie.yaml` — 3 refs
- `cumulus_v3_dashboard_sensors.yaml` — 2 refs
- `cumulus/sensors_base.yaml` — 2 refs
- `lovelace/dashboard_cumulus_v3.yaml` — 1 ref

**Aucune référence dans** : automations, configuration.yaml, scripts — c'est bon.

BusyBox ne gère pas bien les heredocs, je vais créer un script Python qui est plus fiable sur HA OS. Laisse-moi le préparer.Le script fait tout en 4 phases : backup → renommage registre → correction YAML → vérification. Il a aussi un mode rollback en cas de problème.

**Pour le déployer sur ton Pi**, depuis ton PC Windows :

```powershell
scp C:\Users\wakaw\Downloads\migrate_sb3.py ha:/config/scripts/migrate_sb3.py
```

(Adapte le chemin du téléchargement si nécessaire)

Puis sur le Pi :

```bash
python3 /config/scripts/migrate_sb3.py
```

Le script va :
1. Tout sauvegarder dans `/config/backups/migrate_sb3_YYYYMMDD_HHMMSS/`
2. Renommer les 17 entités dans le registre
3. Corriger les 27 références dans les 5 fichiers YAML
4. Vérifier qu'il ne reste aucune trace de l'ancien préfixe

Si tout est vert, tu fais :
```bash
ha core restart
```

Si problème :
```bash
python3 /config/scripts/migrate_sb3.py --rollback
ha core restart
```