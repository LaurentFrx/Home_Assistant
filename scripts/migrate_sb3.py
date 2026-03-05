#!/usr/bin/env python3
###############################################################################
# MIGRATION SB1 : solarbank_3_e2700_pro_* → sb3_*
#
# Ce script :
#   1. Sauvegarde le registre d'entités et les fichiers YAML
#   2. Renomme les 17 entités restantes dans le registre HA
#   3. Corrige toutes les références dans les fichiers YAML
#   4. Vérifie la cohérence après migration
#
# Usage : python3 /config/scripts/migrate_sb3.py
# Rollback : python3 /config/scripts/migrate_sb3.py --rollback
###############################################################################

import json
import os
import sys
import shutil
from datetime import datetime

# ═══════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

REGISTRY = '/config/.storage/core.entity_registry'
BACKUP_DIR = '/config/backups/migrate_sb3_' + datetime.now().strftime('%Y%m%d_%H%M%S')

# Fichiers YAML à corriger (identifiés par l'audit)
YAML_FILES = [
    '/config/packages/solaire_economies.yaml',
    '/config/packages/carte_batterie.yaml',
    '/config/packages/cumulus_v3_dashboard_sensors.yaml',
    '/config/packages/cumulus/sensors_base.yaml',
    '/config/lovelace/dashboard_cumulus_v3.yaml',
]

# Entités à renommer dans le registre (les 17 restantes)
# Format : ancien entity_id → nouveau entity_id
ENTITY_RENAMES = {
    'button.solarbank_3_e2700_pro_actualiser_les_details': 'button.sb3_actualiser_les_details',
    'number.solarbank_3_e2700_pro_capacite_de_la_batterie': 'number.sb3_capacite_de_la_batterie',
    'sensor.solarbank_3_e2700_pro_etat_du_cloud': 'sensor.sb3_etat_du_cloud',
    'sensor.solarbank_3_e2700_pro_mode': 'sensor.sb3_mode',
    'sensor.solarbank_3_e2700_pro_puissance_solaire': 'sensor.sb3_puissance_solaire',
    'sensor.solarbank_3_e2700_pro_solaire_pv1': 'sensor.sb3_solaire_pv1',
    'sensor.solarbank_3_e2700_pro_solaire_pv2': 'sensor.sb3_solaire_pv2',
    'sensor.solarbank_3_e2700_pro_solaire_pv3': 'sensor.sb3_solaire_pv3',
    'sensor.solarbank_3_e2700_pro_solaire_pv4': 'sensor.sb3_solaire_pv4',
    'sensor.solarbank_3_e2700_pro_ac_puissance_de_la_prise': 'sensor.sb3_ac_puissance_de_la_prise',
    'sensor.solarbank_3_e2700_pro_ac_puissance_domestique': 'sensor.sb3_ac_puissance_domestique',
    'sensor.solarbank_3_e2700_pro_puissance_de_chauffage': 'sensor.sb3_puissance_de_chauffage',
    'sensor.solarbank_3_e2700_pro_charge_du_reseau': 'sensor.sb3_charge_du_reseau',
    'sensor.solarbank_3_e2700_pro_reglage_puissance_de_sortie': 'sensor.sb3_reglage_puissance_de_sortie',
    'sensor.solarbank_3_e2700_pro_etat_de_charge': 'sensor.sb3_etat_de_charge',
    'sensor.solarbank_3_e2700_pro_energie_de_la_batterie': 'sensor.sb3_energie_de_la_batterie',
    'sensor.solarbank_3_e2700_pro_code_d_erreur': 'sensor.sb3_code_d_erreur',
}

# Remplacement texte dans les YAML (inclut aussi les refs déjà cassées)
# On remplace le pattern générique — couvre entity_id et les states('...')
TEXT_REPLACE = 'solarbank_3_e2700_pro_'
TEXT_NEW = 'sb3_'


# ═══════════════════════════════════════════════════════════════════
# FONCTIONS
# ═══════════════════════════════════════════════════════════════════

def backup_files():
    """Sauvegarde tous les fichiers avant modification."""
    os.makedirs(BACKUP_DIR, exist_ok=True)

    # Backup du registre
    src = REGISTRY
    dst = os.path.join(BACKUP_DIR, 'core.entity_registry')
    shutil.copy2(src, dst)
    print(f'  [OK] Registre sauvegardé → {dst}')

    # Backup des YAML
    for f in YAML_FILES:
        if os.path.exists(f):
            # Préserver la structure de répertoire
            rel = f.replace('/config/', '')
            dst = os.path.join(BACKUP_DIR, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(f, dst)
            print(f'  [OK] {f} → {dst}')
        else:
            print(f'  [!!] {f} — fichier non trouvé, ignoré')

    print(f'\n  Backups dans : {BACKUP_DIR}')
    return True


def rename_entities_in_registry():
    """Renomme les entity_id dans le registre HA."""
    print('\n--- Phase 2 : Renommage dans le registre ---')

    with open(REGISTRY, 'r') as f:
        data = json.load(f)

    entities = data.get('data', {}).get('entities', [])
    renamed = 0
    not_found = []

    for entity in entities:
        old_id = entity.get('entity_id', '')
        if old_id in ENTITY_RENAMES:
            new_id = ENTITY_RENAMES[old_id]
            entity['entity_id'] = new_id
            # Mettre à jour aussi object_id_base pour cohérence
            new_base = new_id.split('.', 1)[1] if '.' in new_id else new_id
            # Ne pas écraser object_id_base si c'est un nom friendly
            # (certaines entités ont has_entity_name=true)
            renamed += 1
            print(f'  [OK] {old_id} → {new_id}')

    # Vérifier qu'on a tout trouvé
    found_ids = {e.get('entity_id', '') for e in entities}
    for old_id, new_id in ENTITY_RENAMES.items():
        if new_id not in found_ids and old_id not in found_ids:
            not_found.append(old_id)

    if not_found:
        print(f'\n  [WARN] Entités non trouvées dans le registre :')
        for nf in not_found:
            print(f'    - {nf}')

    # Écrire le registre modifié
    with open(REGISTRY, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f'\n  {renamed} entités renommées dans le registre')
    return renamed


def fix_yaml_references():
    """Remplace toutes les références dans les fichiers YAML."""
    print('\n--- Phase 3 : Correction des références YAML ---')

    total_replacements = 0

    for filepath in YAML_FILES:
        if not os.path.exists(filepath):
            print(f'  [SKIP] {filepath} — non trouvé')
            continue

        with open(filepath, 'r') as f:
            content = f.read()

        count = content.count(TEXT_REPLACE)
        if count == 0:
            print(f'  [OK] {filepath} — aucune référence à corriger')
            continue

        new_content = content.replace(TEXT_REPLACE, TEXT_NEW)

        with open(filepath, 'w') as f:
            f.write(new_content)

        total_replacements += count
        print(f'  [OK] {filepath} — {count} remplacement(s)')

    print(f'\n  {total_replacements} références corrigées au total')
    return total_replacements


def verify_migration():
    """Vérifie qu'il ne reste aucune référence à l'ancien préfixe."""
    print('\n--- Phase 4 : Vérification post-migration ---')

    errors = 0

    # Vérifier les YAML
    for filepath in YAML_FILES:
        if not os.path.exists(filepath):
            continue
        with open(filepath, 'r') as f:
            content = f.read()
        remaining = content.count(TEXT_REPLACE)
        if remaining > 0:
            print(f'  [ERREUR] {filepath} — encore {remaining} références non corrigées !')
            errors += 1
        else:
            print(f'  [OK] {filepath} — propre')

    # Vérifier le registre
    with open(REGISTRY, 'r') as f:
        reg_content = f.read()
    remaining_reg = reg_content.count('"entity_id": "sensor.solarbank_3_e2700_pro_')
    remaining_reg += reg_content.count('"entity_id": "button.solarbank_3_e2700_pro_')
    remaining_reg += reg_content.count('"entity_id": "number.solarbank_3_e2700_pro_')
    # Aussi sans espace après :
    remaining_reg += reg_content.count('"entity_id":"sensor.solarbank_3_e2700_pro_')
    remaining_reg += reg_content.count('"entity_id":"button.solarbank_3_e2700_pro_')
    remaining_reg += reg_content.count('"entity_id":"number.solarbank_3_e2700_pro_')

    if remaining_reg > 0:
        print(f'  [ERREUR] Registre — encore {remaining_reg} entités non renommées !')
        errors += 1
    else:
        print(f'  [OK] Registre — toutes les entités renommées')

    # Scan global pour détecter des refs oubliées
    print('\n  Scan global /config/packages/ et /config/lovelace/ ...')
    scan_dirs = ['/config/packages/', '/config/lovelace/']
    orphan_files = []
    for scan_dir in scan_dirs:
        for root, dirs, files in os.walk(scan_dir):
            for fname in files:
                if fname.endswith(('.yaml', '.yml')):
                    fpath = os.path.join(root, fname)
                    with open(fpath, 'r') as f:
                        c = f.read()
                    if TEXT_REPLACE in c:
                        orphan_files.append(fpath)

    if orphan_files:
        print(f'  [WARN] Références résiduelles trouvées dans :')
        for of in orphan_files:
            print(f'    - {of}')
        errors += len(orphan_files)
    else:
        print(f'  [OK] Aucune référence résiduelle détectée')

    return errors


def rollback():
    """Restaure les fichiers depuis le dernier backup."""
    # Trouver le backup le plus récent
    backup_base = '/config/backups/'
    if not os.path.exists(backup_base):
        print('[ERREUR] Aucun répertoire de backup trouvé')
        return False

    backups = sorted([d for d in os.listdir(backup_base) if d.startswith('migrate_sb3_')])
    if not backups:
        print('[ERREUR] Aucun backup de migration trouvé')
        return False

    latest = os.path.join(backup_base, backups[-1])
    print(f'Restauration depuis : {latest}')

    # Restaurer le registre
    reg_backup = os.path.join(latest, 'core.entity_registry')
    if os.path.exists(reg_backup):
        shutil.copy2(reg_backup, REGISTRY)
        print(f'  [OK] Registre restauré')

    # Restaurer les YAML
    for f in YAML_FILES:
        rel = f.replace('/config/', '')
        src = os.path.join(latest, rel)
        if os.path.exists(src):
            shutil.copy2(src, f)
            print(f'  [OK] {f} restauré')

    print('\n  Rollback terminé. Redémarrer HA : ha core restart')
    return True


# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

if __name__ == '__main__':

    if '--rollback' in sys.argv:
        print('=' * 60)
        print('  ROLLBACK MIGRATION SB3')
        print('=' * 60)
        rollback()
        sys.exit(0)

    print('=' * 60)
    print('  MIGRATION SB1 : solarbank_3_e2700_pro → sb3')
    print('=' * 60)
    print(f'  Date : {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    print(f'  17 entités à renommer')
    print(f'  5 fichiers YAML à corriger')
    print(f'  27 références à mettre à jour')
    print('=' * 60)

    # Phase 1 : Backup
    print('\n--- Phase 1 : Sauvegarde ---')
    backup_files()

    # Phase 2 : Renommage registre
    renamed = rename_entities_in_registry()

    # Phase 3 : Correction YAML
    fixed = fix_yaml_references()

    # Phase 4 : Vérification
    errors = verify_migration()

    # Résumé
    print('\n' + '=' * 60)
    if errors == 0:
        print('  MIGRATION RÉUSSIE')
        print(f'  {renamed} entités renommées')
        print(f'  {fixed} références corrigées')
        print(f'  Backup dans : {BACKUP_DIR}')
        print('')
        print('  PROCHAINE ÉTAPE :')
        print('    ha core restart')
        print('')
        print('  EN CAS DE PROBLÈME :')
        print('    python3 /config/scripts/migrate_sb3.py --rollback')
        print('    ha core restart')
    else:
        print(f'  MIGRATION TERMINÉE AVEC {errors} AVERTISSEMENT(S)')
        print('  Vérifier les erreurs ci-dessus avant de redémarrer')
        print(f'  Rollback possible : python3 /config/scripts/migrate_sb3.py --rollback')
    print('=' * 60)