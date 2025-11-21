#!/usr/bin/env python3
"""
Script de correction automatique des entités Cumulus v2
Détecte et remplace automatiquement les noms d'entités
"""

import os
import re
import glob

# Configuration
PACKAGES_DIR = "/home/user/Home_Assistant/packages/cumulus"

# Mapping des entités à remplacer (VOUS DEVEZ REMPLIR LA COLONNE DE DROITE)
ENTITY_MAPPING = {
    # Format: "ancienne_entité": "nouvelle_entité"

    # SWITCH CUMULUS
    "switch.shellypro1_ece334ee1b64": "switch.VOTRE_CONTACTEUR_ICI",

    # IMPORT RÉSEAU
    "sensor.smart_meter_grid_import": "sensor.VOTRE_IMPORT_ICI",

    # PRODUCTION APS
    "sensor.aps_power_w": "sensor.VOTRE_APS_ICI",

    # SOC SOLARBANK
    "sensor.system_sanguinet_etat_de_charge_du_sb": "sensor.VOTRE_SOC_ICI",

    # PV TOTAL
    "sensor.pv_total_entree_sb_aps_w": "sensor.VOTRE_PV_TOTAL_ICI",
}

def replace_entities_in_file(filepath, mapping):
    """Remplace les entités dans un fichier"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Remplacer chaque entité
    for old_entity, new_entity in mapping.items():
        if "VOTRE_" not in new_entity:  # Ne remplacer que si configuré
            content = content.replace(old_entity, new_entity)
            print(f"  ✓ Remplacé: {old_entity} → {new_entity}")

    # Sauvegarder si modifié
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    print("=" * 80)
    print("CORRECTION AUTOMATIQUE DES ENTITÉS CUMULUS V2")
    print("=" * 80)
    print()

    # Vérifier que les entités sont configurées
    unconfigured = [k for k, v in ENTITY_MAPPING.items() if "VOTRE_" in v]
    if unconfigured:
        print("❌ ERREUR: Vous devez d'abord configurer les entités dans ce script!")
        print()
        print("Éditez le fichier et remplacez:")
        for old, new in ENTITY_MAPPING.items():
            if "VOTRE_" in new:
                print(f"  {old}")
                print(f"  → {new}")
                print()
        return

    # Parcourir tous les fichiers YAML
    yaml_files = glob.glob(f"{PACKAGES_DIR}/*.yaml")

    print(f"Traitement de {len(yaml_files)} fichiers...")
    print()

    modified_count = 0
    for filepath in yaml_files:
        filename = os.path.basename(filepath)
        print(f"📄 {filename}")

        if replace_entities_in_file(filepath, ENTITY_MAPPING):
            modified_count += 1
            print(f"  ✅ Fichier modifié")
        else:
            print(f"  ⏭️  Aucun changement nécessaire")
        print()

    print("=" * 80)
    print(f"✅ Terminé! {modified_count} fichier(s) modifié(s)")
    print()
    print("PROCHAINES ÉTAPES:")
    print("1. Recharger Home Assistant (Developer Tools > YAML > Reload All)")
    print("2. Vérifier les entités dans Developer Tools > States")
    print("=" * 80)

if __name__ == "__main__":
    main()
