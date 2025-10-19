#!/usr/bin/env python3
"""Validation YAML pour cumulus.yaml"""
import yaml
import sys

try:
    with open(r'\\192.168.1.29\config\packages\cumulus.yaml', 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    print("✓ Syntaxe YAML valide")
    print(f"✓ {len(config.get('automation', []))} automatisations chargées")
    print(f"✓ {len(config.get('template', [{}])[0].get('sensor', []))} sensors templates")
    print(f"✓ {len(config.get('template', [{}])[0].get('binary_sensor', []))} binary sensors templates")
    sys.exit(0)
except yaml.YAMLError as e:
    print(f"✗ Erreur YAML: {e}")
    sys.exit(1)
except Exception as e:
    print(f"✗ Erreur: {e}")
    sys.exit(1)
