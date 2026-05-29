# Runbook — Correction du spike d'économies du 29/05/2026

> **À exécuter sur l'HÔTE Home Assistant** (là où vivent `home-assistant_v2.db` et `.storage/`).
> Ce fichier a été préparé depuis une session cloud qui n'avait PAS accès à la base ni à `.storage`.
> Branche de travail : `claude/brave-heisenberg-Ma8lZ`.
>
> **Pour Claude (session hôte) :** exécute pas à pas. Avant CHAQUE étape destructive, affiche la
> commande/requête exacte et demande confirmation à Laurent. Fais le backup AVANT toute écriture.
> Ne touche JAMAIS `sensor.savings_hc_eur`, ni les données antérieures au 2026-05-29 12:00 (Paris).

---

## 0. Contexte & cibles

Spike parasite de **+109,4308 €** injecté le **29/05/2026 à 12:52:07 (Paris) = 10:52:07 UTC**, suite à une
manip matérielle Anker Solix. Il a faussé 4 capteurs (le 5e, `savings_hc_eur`, est intact).

| Entité | Type | Valeur actuelle (≈) | **CIBLE** | Action |
|---|---|---|---|---|
| `sensor.savings_eur` | integration/Riemann (YAML) | 457,1219 | **347,6911** | restore_state + stats |
| `sensor.savings_hp_eur` | integration/Riemann (YAML) | 446,3346 | **336,9038** | restore_state + stats |
| `sensor.savings_hc_eur` | integration/Riemann (YAML) | 47,1047 | **47,1047** | ⛔ NE PAS TOUCHER |
| `sensor.savings_month_eur` | utility_meter | 171,98 | **62,5506** | calibrate |
| `sensor.savings_year_eur` | utility_meter | 315,89 | **206,4587** | calibrate |
| `sensor.savings_day_eur` | utility_meter | 110,9 | **≈1,5** (réel) | calibrate |
| `input_number.economie_baseline_eur` | helper UI (.storage) | 133,63 | **133,63** + retirer `initial` | UI |
| `sensor.savings_total_eur_with_baseline` | template | — | **≈481,32** | auto (= savings_eur + baseline) |

**Delta exact à retrancher pour `savings_eur` ET `savings_hp_eur` : 109,4308.**
Vérif : 457,1219 − 347,6911 = 109,4308 ; 446,3346 − 336,9038 = 109,4308 ; 347,6911 + 133,63 = **481,3211**.

### Définitions YAML (référence, ne pas modifier ici)
- `sensor.savings_eur` : `packages/solaire_economies.yaml` lignes 367‑373 (platform integration, `unique_id: savings_eur`, `round: 4`).
- `sensor.savings_hp_eur` : lignes 375‑381 (`unique_id: savings_hp_eur`, `round: 4`).
- `sensor.savings_hc_eur` : lignes 383‑389 — **EXCLU**.
- utility_meter `savings_day/month/year_eur` : lignes 446‑459 (source `sensor.savings_eur`).
- `input_number.economie_baseline_eur` : **PAS défini en YAML** → helper créé via l'UI, stocké dans `.storage/input_number`.

### Recorder
Aucune clé `recorder:` dans la config → `default_config:` active le recorder par défaut → **SQLite**,
fichier **`home-assistant_v2.db`** dans le dossier de config. (Pas de MariaDB/PostgreSQL.) HA **2025.12.4**.

---

## Pourquoi ça « revient toujours à ~457 » (diagnostic)

Les capteurs `integration` (Riemann) sont des `RestoreSensor`. Au démarrage **et** après rechargement,
ils restaurent leur valeur cumulée depuis **`.storage/core.restore_state`**, dans le champ
**`extra_data.native_value.decimal_str`** (un `Decimal`). C'est pour ça que forcer via `/api/states`
ne tient pas : l'API change l'état affiché mais pas `extra_data`, et au prochain cycle le capteur
réimpose sa valeur interne.

➡️ **Le seul correctif durable** = modifier la valeur persistée dans `core.restore_state`
(champs `state.state` **ET** `extra_data.native_value.decimal_str`), **HA arrêté** (sinon l'arrêt propre
réécrit ~457 par-dessus).

---

## 1. Détecter comment HA tourne (lecture seule)

```bash
# Depuis le dossier de config HA (celui qui contient configuration.yaml)
pwd; ls -la home-assistant_v2.db .storage/core.restore_state 2>/dev/null

# Conteneur Docker ?
docker ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | grep -i hass

# Service systemd (Core/venv) ?
systemctl list-units --type=service 2>/dev/null | grep -i home-assistant

# Processus
ps aux | grep -i "[h]omeassistant"
```
Note la méthode trouvée : **Docker** → `docker stop/start <nom>` ; **systemd** → `sudo systemctl stop/start home-assistant@homeassistant` (adapter le nom d'unité).

---

## 2. Pré-vol : noter les valeurs live (lecture seule)

Via Developer Tools → Template, ou API. Note les 6 valeurs actuelles (savings_eur, hp, hc, month, year, day)
pour comparaison post-fix et pour calculer la vraie valeur du jour.

```
valeur réelle du jour (savings_day_eur) ≈ valeur_actuelle_day − 109,4308
```

---

## 3. ARRÊTER Home Assistant

```bash
# Docker :
docker stop <nom_du_conteneur_hass>
# OU systemd :
sudo systemctl stop home-assistant@homeassistant
```
Vérifier qu'aucun processus HA ne tourne (`ps aux | grep [h]omeassistant`).
L'arrêt propre écrit l'état courant (~457) dans `core.restore_state` — c'est attendu, on l'édite juste après.

---

## 4. SAUVEGARDE (obligatoire, AVANT toute écriture)

```bash
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p backups_fix_spike/$TS
cp -av home-assistant_v2.db        backups_fix_spike/$TS/ 2>/dev/null
cp -av home-assistant_v2.db-wal    backups_fix_spike/$TS/ 2>/dev/null
cp -av home-assistant_v2.db-shm    backups_fix_spike/$TS/ 2>/dev/null
cp -av .storage                    backups_fix_spike/$TS/storage_backup
echo "Sauvegarde dans : $(pwd)/backups_fix_spike/$TS"
ls -la backups_fix_spike/$TS
```
**Indiquer le chemin de la sauvegarde à Laurent.** (Le dossier `backups_fix_spike/` est hors git via `.gitignore` ? sinon l'ajouter.)

Optionnel mais conseillé (checkpoint WAL pour une base propre) :
```bash
sqlite3 home-assistant_v2.db "PRAGMA wal_checkpoint(TRUNCATE);"
```

---

## 5. Fix A — `core.restore_state` (les 2 capteurs integration)  ⚑ cœur du correctif

D'abord INSPECTER (montrer à Laurent) :
```bash
python3 - <<'PY'
import json
d = json.load(open(".storage/core.restore_state"))
for it in d["data"]:
    eid = it.get("state",{}).get("entity_id")
    if eid in ("sensor.savings_eur","sensor.savings_hp_eur","sensor.savings_hc_eur"):
        nv = (it.get("extra_data") or {}).get("native_value")
        print(eid, "| state =", it["state"].get("state"),
              "| native_value =", nv.get("decimal_str") if isinstance(nv,dict) else nv)
PY
```

Puis ÉCRIRE (après confirmation) — patche `state.state` ET `extra_data.native_value.decimal_str` :
```bash
python3 - <<'PY'
import json
PATH = ".storage/core.restore_state"
TARGETS = {"sensor.savings_eur":"347.6911", "sensor.savings_hp_eur":"336.9038"}  # hc EXCLU
d = json.load(open(PATH))
chg = []
for it in d["data"]:
    eid = it.get("state",{}).get("entity_id")
    if eid in TARGETS:
        new = TARGETS[eid]
        old_s = it["state"].get("state"); it["state"]["state"] = new
        ed = it.get("extra_data") or {}; nv = ed.get("native_value")
        old_nv = nv.get("decimal_str") if isinstance(nv,dict) else None
        if isinstance(nv,dict) and "decimal_str" in nv: nv["decimal_str"] = new
        chg.append((eid, old_s, new, old_nv))
for eid,os_,ns,onv in chg:
    print(f"{eid}: state {os_} -> {ns} ; native_value {onv} -> {ns}")
assert len(chg)==2, f"Attendu 2 entités, trouvé {len(chg)} — STOP, vérifier"
json.dump(d, open(PATH,"w"), ensure_ascii=False)
print("OK écrit.")
PY
```
> Si l'une des 2 entités n'apparaît pas (assert échoue), NE PAS écrire : vérifier le nom/entity_id.
> `last_valid_state` dans `extra_data` = le dernier débit (€/h) source, **on n'y touche pas**.

---

## 6. Fix B — `input_number.economie_baseline_eur` : ne plus se réinitialiser

Le helper est dans `.storage` (pas en YAML), donc **rien à retirer dans un fichier YAML**.
Sa réinit à 0 vient du champ **« Valeur initiale »** du helper.

**Méthode recommandée (UI, après redémarrage) :**
Paramètres → Appareils & services → **Aides** → `economie_baseline_eur` → ⚙️ →
**vider le champ « Valeur initiale »** (le laisser vide) → Enregistrer.
Sans valeur initiale, le helper **restaure sa dernière valeur** au lieu de repartir de 0.

**Alternative (HA arrêté, JSON) :** retirer la clé `"initial"` de l'item correspondant dans
`.storage/input_number`. Identifier l'item via `.storage/core.entity_registry`
(entity_id `input_number.economie_baseline_eur` → `unique_id` → champ `id` dans `.storage/input_number`).
Vérifier aussi que `core.restore_state` contient bien `133.63` pour cette entité.

---

## 7. Fix C — Colonne `state` des statistiques (alignée sur la `sum` déjà ajustée)

⚠️ La `sum` a DÉJÀ été ajustée par Laurent (−109,4308 depuis 2026-05-29T10:00:00Z). **NE PAS retoucher `sum`.**
On ne corrige QUE la colonne `state`, et **uniquement les lignes réellement gonflées** (≈457 / ≈446).

### 7.1 Récupérer les metadata_id (lecture seule)
```sql
SELECT id, statistic_id FROM statistics_meta
WHERE statistic_id IN ('sensor.savings_eur','sensor.savings_hp_eur');
```

### 7.2 INSPECTER autour du spike (lecture seule) — vérifier où `state` saute
```sql
-- Long terme (horaire). Le spike (10:52 UTC) tombe dans la ligne start=10:00 UTC.
SELECT m.statistic_id, datetime(s.start_ts,'unixepoch') AS start_utc, s.state, s.sum
FROM statistics s JOIN statistics_meta m ON m.id=s.metadata_id
WHERE m.statistic_id IN ('sensor.savings_eur','sensor.savings_hp_eur')
  AND s.start_ts >= 1780045200   -- 09:00 UTC, pour voir avant/après
ORDER BY m.statistic_id, s.start_ts;
```
Confirmer : avant 10:00 UTC `state`≈347/336 (NE PAS toucher) ; à partir de 10:00 UTC `state`≈457/446.

### 7.3 Vérifier la continuité de `sum` (lecture seule, NE PAS modifier)
Confirmer que `sum` est déjà continue (pas de marche de ~109). Si oui → ne rien faire sur `sum`.

### 7.4 CORRIGER `state` (après confirmation) — DANS UNE TRANSACTION
Bornes UTC : horaire `start_ts >= 1780048800` (10:00 UTC) ; 5-min `start_ts >= 1780051800` (10:50 UTC).
```sql
BEGIN;
-- Long terme (horaire)
UPDATE statistics
SET state = state - 109.4308
WHERE metadata_id IN (SELECT id FROM statistics_meta
                      WHERE statistic_id IN ('sensor.savings_eur','sensor.savings_hp_eur'))
  AND start_ts >= 1780048800;        -- 2026-05-29 10:00:00 UTC

-- Court terme (5 min) : le bucket du spike est 10:50 UTC
UPDATE statistics_short_term
SET state = state - 109.4308
WHERE metadata_id IN (SELECT id FROM statistics_meta
                      WHERE statistic_id IN ('sensor.savings_eur','sensor.savings_hp_eur'))
  AND start_ts >= 1780051800;        -- 2026-05-29 10:50:00 UTC
-- Vérifier les counts AVANT de valider :
SELECT changes();
COMMIT;   -- ou ROLLBACK; si les valeurs ne sont pas cohérentes
```
> Re-jouer le SELECT 7.2 après COMMIT : `state` doit être continu (≈347/336 de part et d'autre du spike).
> ⚠️ Adapter les bornes si l'inspection 7.2 montre un décalage (selon l'arrondi des `start_ts`).

### 7.5 (Optionnel) Table `states` — historique récent du capteur
Cosmétique (graphe d'historique récent). Non requis : `core.restore_state` règle déjà le live.
Si souhaité, retrancher 109,4308 des lignes `states` gonflées des 2 entités après le spike
(jointure via `states_meta`), **toujours après inspection** et dans une transaction. Ne PAS toucher `savings_hc`.

---

## 8. REDÉMARRER HA et vérifier le live

```bash
# Docker :
docker start <nom_du_conteneur_hass>
# OU systemd :
sudo systemctl start home-assistant@homeassistant
```
Attendre le démarrage complet, puis vérifier (Developer Tools → Template) :
- `sensor.savings_eur` ≈ **347,6911** ✅
- `sensor.savings_hp_eur` ≈ **336,9038** ✅
- `sensor.savings_hc_eur` = **47,1047** (inchangé) ✅
- `sensor.savings_total_eur_with_baseline` ≈ **481,32** ✅
- `input_number.economie_baseline_eur` = **133,63** ✅

Si les valeurs sont bonnes → faire le Fix B (UI) maintenant (vider « Valeur initiale »).

---

## 9. Fix D — Recalibrer les utility_meter

Une fois `savings_eur` à 347,6911, les compteurs month/year/day pointent encore l'ancienne valeur.
Quand la source chute de 457→347, le utility_meter voit un delta négatif → il le traite comme un reset
(n'ajoute rien). On fixe ensuite la valeur exacte avec `utility_meter.calibrate`.

Developer Tools → Actions (Services), ou YAML :
```yaml
service: utility_meter.calibrate
target: { entity_id: sensor.savings_month_eur }
data:   { value: 62.5506 }
```
```yaml
service: utility_meter.calibrate
target: { entity_id: sensor.savings_year_eur }
data:   { value: 206.4587 }
```
```yaml
# Valeur réelle du jour = (valeur day notée à l'étape 2) − 109.4308  (≈ 1.5)
service: utility_meter.calibrate
target: { entity_id: sensor.savings_day_eur }
data:   { value: 1.5 }     # ← remplacer par la vraie valeur calculée
```
Vérifier ensuite : month ≈ 62,5506 ; year ≈ 206,4587 ; day ≈ valeur réelle.
> Astuce : laisser passer une mise à jour de la source pour confirmer que les deltas suivants sont corrects.

---

## 10. Vérification finale (checklist)

- [ ] `savings_eur` = 347,6911 (live) et stable après un rechargement de l'intégration
- [ ] `savings_hp_eur` = 336,9038 (live)
- [ ] `savings_hc_eur` = 47,1047 (INCHANGÉ)
- [ ] `savings_month_eur` = 62,5506
- [ ] `savings_year_eur` = 206,4587
- [ ] `savings_day_eur` ≈ 1,5 (valeur réelle du jour)
- [ ] `savings_total_eur_with_baseline` ≈ 481,32
- [ ] `economie_baseline_eur` = 133,63 ET « Valeur initiale » vidée (ne se réinitialisera plus)
- [ ] Stats : `sum` continue (déjà fait) ET `state` continu après correction
- [ ] `savings_hc` et toute donnée < 2026-05-29 12:00 (Paris) intacts

---

## 11. Rollback (si problème)

```bash
# Arrêter HA, puis restaurer depuis la sauvegarde :
docker stop <hass>    # ou systemctl stop ...
cp -av backups_fix_spike/<TS>/home-assistant_v2.db* .
rm -rf .storage && cp -av backups_fix_spike/<TS>/storage_backup .storage
docker start <hass>   # ou systemctl start ...
```
