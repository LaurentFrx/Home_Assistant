#!/usr/bin/env python3
"""
Vérification des entités du dashboard-lau/cumu
Analyse la configuration et identifie les entités manquantes
"""

import yaml
import re
from pathlib import Path

# Chemins
ENTITIES_FILE = Path("/home/user/Home_Assistant/lovelace/entities_lau_cumu.txt")
CUMULUS_PACKAGE = Path("/home/user/Home_Assistant/packages/cumulus.yaml")

def load_entities_list():
    """Charge la liste des entités requises"""
    entities = []
    with open(ENTITIES_FILE) as f:
        for line in f:
            line = line.strip()
            # Ignorer commentaires et lignes vides
            if not line or line.startswith('#') or line.startswith('ENTITÉS') or line.startswith('==='):
                continue
            entities.append(line)
    return sorted(entities)

def parse_cumulus_yaml():
    """Parse le fichier cumulus.yaml et extrait toutes les entités définies"""
    defined_entities = {
        'input_boolean': set(),
        'input_datetime': set(),
        'input_number': set(),
        'input_text': set(),
        'sensor': set(),
        'binary_sensor': set(),
        'timer': set(),
    }

    with open(CUMULUS_PACKAGE) as f:
        config = yaml.safe_load(f)

    # Parser les différentes sections
    for entity_type in ['input_boolean', 'input_datetime', 'input_number', 'input_text', 'timer']:
        if entity_type in config:
            for entity_name in config[entity_type].keys():
                defined_entities[entity_type].add(f"{entity_type}.{entity_name}")

    # Parser les templates (sensor et binary_sensor)
    if 'template' in config:
        for template_section in config['template']:
            if 'sensor' in template_section:
                for sensor in template_section['sensor']:
                    if 'name' in sensor:
                        defined_entities['sensor'].add(f"sensor.{sensor['name']}")
            if 'binary_sensor' in template_section:
                for sensor in template_section['binary_sensor']:
                    if 'name' in sensor:
                        defined_entities['binary_sensor'].add(f"binary_sensor.{sensor['name']}")

    return defined_entities

def categorize_entity(entity, defined_entities):
    """Catégorise une entité comme OK, MANQUANTE ou EXTERNE"""
    # Switch Shelly = entité externe
    if entity.startswith('switch.shellypro1'):
        return 'EXTERNE', 'Entité Shelly (intégration)'

    # Vérifier si définie dans cumulus.yaml
    entity_type = entity.split('.')[0]
    if entity_type in defined_entities:
        if entity in defined_entities[entity_type]:
            return 'OK', 'Défini dans packages/cumulus.yaml'

    # Vérifier si c'est une entité qui devrait être créée manuellement
    manual_entities = [
        'binary_sensor.cumulus_lave_linge_actif',
        'binary_sensor.cumulus_lave_vaisselle_actif',
        'sensor.cumulus_besoin_journalier_litres',
        'sensor.cumulus_capacity_factor',
        'sensor.cumulus_eau_chaude_disponible_40c_litres',
        'sensor.cumulus_seuil_pv_dynamique_w',
        'sensor.cumulus_solcast_forecast_today',
        'sensor.cumulus_solcast_forecast_tomorrow',
        'sensor.cumulus_temperature_physique_c',
        'sensor.cumulus_temps_restant_fenetre_pv_h',
        'input_boolean.cumulus_autoriser_hc',
        'input_boolean.cumulus_interdit',
        'input_boolean.cumulus_vacances',
        'input_boolean.temp_atteinte_aujourdhui',
    ]

    if entity in manual_entities:
        return 'MANQUANTE', 'À créer manuellement dans Home Assistant'

    # Vérifier les renommages possibles
    renames = {
        'input_boolean.cumulus_interdit': 'input_boolean.cumulus_interdit_depart',
        'input_boolean.cumulus_vacances': 'input_boolean.cumulus_mode_vacances',
    }

    if entity in renames:
        new_name = renames[entity]
        if new_name in defined_entities.get(entity_type, set()):
            return 'RENOMMÉ', f'Renommé en {new_name}'

    return 'MANQUANTE', 'Non défini'

def main():
    print("=" * 60)
    print("  DIAGNOSTIC DASHBOARD-LAU/CUMU")
    print("=" * 60)
    print()

    # Charger les données
    required_entities = load_entities_list()
    defined_entities = parse_cumulus_yaml()

    print(f"📊 Entités requises: {len(required_entities)}")
    print()

    # Analyser chaque entité
    results = {
        'OK': [],
        'EXTERNE': [],
        'MANQUANTE': [],
        'RENOMMÉ': []
    }

    for entity in required_entities:
        status, reason = categorize_entity(entity, defined_entities)
        results[status].append((entity, reason))

    # Afficher les résultats
    print("=" * 60)
    print("RÉSULTATS PAR CATÉGORIE")
    print("=" * 60)
    print()

    if results['OK']:
        print(f"✅ ENTITÉS OK ({len(results['OK'])})")
        print("-" * 60)
        for entity, reason in results['OK']:
            print(f"  ✓ {entity}")
            print(f"    → {reason}")
        print()

    if results['EXTERNE']:
        print(f"🔌 ENTITÉS EXTERNES ({len(results['EXTERNE'])})")
        print("-" * 60)
        for entity, reason in results['EXTERNE']:
            print(f"  → {entity}")
            print(f"    → {reason}")
        print()

    if results['RENOMMÉ']:
        print(f"🔄 ENTITÉS RENOMMÉES ({len(results['RENOMMÉ'])})")
        print("-" * 60)
        for entity, reason in results['RENOMMÉ']:
            print(f"  ⚠️  {entity}")
            print(f"    → {reason}")
        print()

    if results['MANQUANTE']:
        print(f"❌ ENTITÉS MANQUANTES ({len(results['MANQUANTE'])})")
        print("-" * 60)
        for entity, reason in results['MANQUANTE']:
            print(f"  ✗ {entity}")
            print(f"    → {reason}")
        print()

    # Résumé final
    print("=" * 60)
    print("RÉSUMÉ")
    print("=" * 60)
    total = len(required_entities)
    ok_count = len(results['OK']) + len(results['EXTERNE'])
    missing_count = len(results['MANQUANTE'])
    renamed_count = len(results['RENOMMÉ'])

    print(f"Total entités:        {total}")
    print(f"✅ OK/Externes:        {ok_count}")
    print(f"🔄 Renommées:          {renamed_count}")
    print(f"❌ Manquantes:         {missing_count}")
    print()

    # Santé globale
    health_pct = ((ok_count + renamed_count) / total) * 100

    if health_pct >= 90:
        health = "🟢 EXCELLENT"
    elif health_pct >= 70:
        health = "🟡 BON"
    elif health_pct >= 50:
        health = "🟠 MOYEN"
    else:
        health = "🔴 CRITIQUE"

    print(f"État du dashboard:    {health} ({health_pct:.0f}%)")
    print()

    if missing_count > 0:
        print("⚠️  ACTIONS REQUISES:")
        print("   1. Créer manuellement les entités manquantes dans Home Assistant")
        print("   2. Ou ajouter les définitions dans packages/cumulus.yaml")
        print("   3. Mettre à jour les références si des entités ont été renommées")
        return 1
    else:
        print("✅ Toutes les entités sont configurées!")
        return 0

if __name__ == "__main__":
    exit(main())
