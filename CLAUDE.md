# CLAUDE.md — Mémoire projet (LaurentFrx/Home_Assistant)

## Environnement de travail de Laurent (à retenir)
- Laurent travaille **en permanence dans l'application Claude Desktop**, qui réunit **Claude (chat)** ET **Claude Code**. C'est son environnement unique.
- ⚠️ Distinction clé (source de confusion fréquente) :
  - **Claude (chat) de l'app Desktop** dispose de serveurs MCP locaux (`desktop-commander`, `Filesystem`) → il peut **exécuter des commandes et accéder aux fichiers du PC Windows** (`C:\Users\wakaw\…`), et donc se connecter en SSH aux machines du réseau local.
  - **Claude Code** (même lancé depuis l'app Desktop) s'exécute dans un **bac à sable cloud** relié au dépôt GitHub → **aucun accès** au PC ni au réseau local (LAN). Il ne voit que les fichiers versionnés du dépôt.
- Conséquence pratique : pour toute action « live » (base SQLite, `.storage/`, redémarrage HA…), **Claude Code (cloud) ne peut pas agir directement**. Deux voies : (1) **relais SSH** où Laurent colle les commandes, ou (2) **Claude chat de l'app Desktop avec `desktop-commander`** qui fait le SSH lui-même.

## Infra Home Assistant (découverte en session)
- Hôte : Raspberry/mini-PC **Linux `192.168.1.29`**, user `laurent` (membre du groupe docker ; sudo requis pour éditer les fichiers root).
- HA en conteneur Docker **`homeassistant`** (image officielle `ghcr.io/home-assistant/home-assistant:stable`), géré par docker-compose (`/home/laurent/docker/docker-compose.yml`).
- Dossier config : **`/home/laurent/docker/homeassistant/config`** (monté sur `/config`).
- Recorder = **SQLite** `home-assistant_v2.db` (pas de clé `recorder:` → défaut via `default_config:`). `python3` présent sur l'hôte, **pas** de `sqlite3` CLI (utiliser le module python `sqlite3`).
- ⚠️ La base `home-assistant_v2.db*` et le dossier `.storage/` sont **gitignored** → absents du dépôt (donc invisibles pour Claude Code cloud).

## Capteurs d'économies solaires (package `packages/solaire_economies.yaml`)
- `sensor.savings_eur`, `sensor.savings_hp_eur` = intégrations Riemann (`platform: integration`, `round: 4`). Leur valeur cumulée se restaure depuis `.storage/core.restore_state` (champs `state.state` **et** `extra_data.native_value.decimal_str`) — l'API `/api/states` ne tient pas.
- `sensor.savings_hc_eur` = à ne jamais modifier.
- `savings_day/month/year_eur` = utility_meter (source `savings_eur`) → recalibrer via `utility_meter.calibrate`.
- `input_number.economie_baseline_eur` = helper **UI** (dans `.storage/input_number`, pas en YAML). Pour qu'il ne se réinitialise plus : vider sa « Valeur initiale ».
