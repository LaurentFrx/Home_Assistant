#!/bin/bash
# Script: create_climate_salon_corrected.sh
# Description: Crée un thermostat virtuel Salon avec température corrigée (Sonoff) + fan modes
# Usage: ./create_climate_salon_corrected.sh

set -e

CONFIG_DIR="/config"
PACKAGE_FILE="$CONFIG_DIR/packages/climate_salon_corrected.yaml"
BACKUP_DIR="$CONFIG_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "═══════════════════════════════════════════════════════"
echo "  Création Climate Salon Corrigé (Température Sonoff)"
echo "  Version avancée avec fan modes"
echo "═══════════════════════════════════════════════════════"

# Création du répertoire packages si inexistant
mkdir -p "$CONFIG_DIR/packages"
mkdir -p "$BACKUP_DIR"

# Backup si le fichier existe déjà
if [ -f "$PACKAGE_FILE" ]; then
    echo "⚠️  Fichier existant détecté, création backup..."
    cp "$PACKAGE_FILE" "$BACKUP_DIR/climate_salon_corrected_${TIMESTAMP}.yaml"
    echo "✓ Backup: $BACKUP_DIR/climate_salon_corrected_${TIMESTAMP}.yaml"
fi

# Génération du fichier package
cat > "$PACKAGE_FILE" << 'EOF'
#═══════════════════════════════════════════════════════════════════════════
# CLIMATE SALON CORRIGÉ - TEMPÉRATURE SONOFF + FAN MODES
#═══════════════════════════════════════════════════════════════════════════
# Thermostat virtuel qui utilise la vraie température du capteur Sonoff
# au lieu de la température biaisée du split Daikin en hauteur.
#
# Architecture:
# - Température source: sensor.thermo_salon_temperature (Sonoff)
# - Humidité source: sensor.thermo_salon_humidity (Sonoff)
# - Contrôle: climate.daikin_split_salon_room_temperature (actuateur)
# - Exposition: HomeKit via pont HA avec tous les modes
#═══════════════════════════════════════════════════════════════════════════

template:
  - climate:
      - name: "Salon Climate Corrigé"
        unique_id: climate_salon_corrected_template
        
        # Température actuelle (Sonoff - VRAIE température)
        current_temperature_template: >
          {{ states('sensor.thermo_salon_temperature') | float(20) }}
        
        # Humidité actuelle (Sonoff)
        current_humidity_template: >
          {{ states('sensor.thermo_salon_humidity') | int(0) }}
        
        # Consigne actuelle (depuis Daikin)
        temperature_template: >
          {{ state_attr('climate.daikin_split_salon_room_temperature', 'temperature') | float(20) }}
        
        # Mode HVAC actuel (depuis Daikin)
        hvac_mode_template: >
          {{ states('climate.daikin_split_salon_room_temperature') }}
        
        # Fan mode actuel (depuis Daikin)
        fan_mode_template: >
          {{ state_attr('climate.daikin_split_salon_room_temperature', 'fan_mode') }}
        
        # Preset mode (si supporté par Daikin)
        preset_mode_template: >
          {{ state_attr('climate.daikin_split_salon_room_temperature', 'preset_mode') | default('none') }}
        
        # Modes HVAC disponibles
        hvac_modes:
          - 'off'
          - 'heat'
          - 'cool'
          - 'auto'
          - 'dry'
          - 'fan_only'
        
        # Fan modes disponibles (Daikin)
        fan_modes:
          - 'auto'
          - 'quiet'
          - '1'
          - '2'
          - '3'
          - '4'
          - '5'
        
        # Preset modes (si supporté)
        preset_modes:
          - 'none'
          - 'eco'
          - 'boost'
        
        # Limites de température
        min_temp: 16
        max_temp: 30
        temp_step: 0.5
        
        # Disponibilité (capteur Sonoff ET climate Daikin opérationnels)
        availability_template: >
          {{ has_value('sensor.thermo_salon_temperature') and 
             has_value('climate.daikin_split_salon_room_temperature') and
             states('climate.daikin_split_salon_room_temperature') not in ['unavailable', 'unknown'] }}
        
        # ACTION: Changer mode HVAC (on/off, heat, cool, etc.)
        set_hvac_mode:
          - service: climate.set_hvac_mode
            target:
              entity_id: climate.daikin_split_salon_room_temperature
            data:
              hvac_mode: '{{ hvac_mode }}'
        
        # ACTION: Changer température de consigne
        set_temperature:
          - service: climate.set_temperature
            target:
              entity_id: climate.daikin_split_salon_room_temperature
            data:
              temperature: '{{ temperature }}'
              hvac_mode: '{{ hvac_mode if hvac_mode is defined else state_attr("climate.daikin_split_salon_room_temperature", "hvac_mode") }}'
        
        # ACTION: Changer vitesse ventilation
        set_fan_mode:
          - service: climate.set_fan_mode
            target:
              entity_id: climate.daikin_split_salon_room_temperature
            data:
              fan_mode: '{{ fan_mode }}'
        
        # ACTION: Changer preset mode
        set_preset_mode:
          - service: climate.set_preset_mode
            target:
              entity_id: climate.daikin_split_salon_room_temperature
            data:
              preset_mode: '{{ preset_mode }}'

  # SENSORS HELPERS (Affichage dashboard et debug)
  - sensor:
      # Écart température Sonoff vs Daikin (pour debug)
      - name: "Salon Écart Température"
        unique_id: salon_temperature_delta
        unit_of_measurement: "°C"
        device_class: temperature
        state_class: measurement
        state: >
          {% set sonoff = states('sensor.thermo_salon_temperature') | float(0) %}
          {% set daikin = state_attr('climate.daikin_split_salon_room_temperature', 'current_temperature') | float(0) %}
          {{ (daikin - sonoff) | round(1) }}
        availability: >
          {{ has_value('sensor.thermo_salon_temperature') and 
             has_value('climate.daikin_split_salon_room_temperature') }}
        attributes:
          temperature_sonoff: >
            {{ states('sensor.thermo_salon_temperature') }}
          temperature_daikin: >
            {{ state_attr('climate.daikin_split_salon_room_temperature', 'current_temperature') }}

      # Résumé état climat (pour affichage rapide)
      - name: "Salon Climate État"
        unique_id: salon_climate_status
        state: >
          {% set climate = states('climate.salon_climate_corrige') %}
          {% set temp = states('sensor.thermo_salon_temperature') | float(20) %}
          {% set target = state_attr('climate.salon_climate_corrige', 'temperature') | float(20) %}
          {% set fan = state_attr('climate.salon_climate_corrige', 'fan_mode') | default('auto') %}
          {% if climate == 'off' %}
            Éteint ({{ temp }}°C)
          {% elif climate == 'heat' %}
            Chauffage {{ temp }}°C → {{ target }}°C ({{ fan }})
          {% elif climate == 'cool' %}
            Climatisation {{ temp }}°C → {{ target }}°C ({{ fan }})
          {% elif climate == 'dry' %}
            Déshumidification {{ temp }}°C ({{ fan }})
          {% elif climate == 'fan_only' %}
            Ventilation {{ temp }}°C ({{ fan }})
          {% else %}
            {{ climate | title }} {{ temp }}°C
          {% endif %}

      # Action actuelle du climate (heating/cooling/idle)
      - name: "Salon Climate Action"
        unique_id: salon_climate_action
        state: >
          {% set hvac = states('climate.salon_climate_corrige') %}
          {% set temp = states('sensor.thermo_salon_temperature') | float(20) %}
          {% set target = state_attr('climate.salon_climate_corrige', 'temperature') | float(20) %}
          {% if hvac == 'off' %}
            idle
          {% elif hvac == 'heat' %}
            {{ 'heating' if temp < target - 0.3 else 'idle' }}
          {% elif hvac == 'cool' %}
            {{ 'cooling' if temp > target + 0.3 else 'idle' }}
          {% else %}
            idle
          {% endif %}

  # BINARY SENSOR: Détection si climate actif
  - binary_sensor:
      - name: "Salon Climate Actif"
        unique_id: salon_climate_active
        device_class: running
        state: >
          {{ states('climate.salon_climate_corrige') not in ['off', 'unavailable', 'unknown'] }}

#═══════════════════════════════════════════════════════════════════════════
# EXPOSITION HOMEKIT
#═══════════════════════════════════════════════════════════════════════════
# IMPORTANT: Si vous avez déjà une config homekit: ailleurs, fusionnez cette
# section avec l'existante (ne pas dupliquer la clé homekit:)

homekit:
  - name: "Technique HA Pont"
    port: 21063
    
    # Mode de filtrage
    filter:
      include_entities:
        # Nouveau thermostat corrigé (température Sonoff)
        - climate.salon_climate_corrige
        
        # Autres entités à exposer (exemples à adapter)
        # - light.salon
        # - switch.cumulus
        # - sensor.temperature_exterieure
      
      exclude_entities:
        # Masquer l'ancien climate Daikin (évite confusion)
        - climate.daikin_split_salon_room_temperature
        
        # Masquer sensors techniques/debug
        - sensor.salon_ecart_temperature
        - sensor.salon_climate_etat
        - sensor.salon_climate_action
        - binary_sensor.salon_climate_actif
    
    # Configuration spécifique des entités exposées
    entity_config:
      climate.salon_climate_corrige:
        name: "Séjour"
        code: null  # Pas de code PIN requis
        linked_humidity_sensor: sensor.thermo_salon_humidity
        # Si vous avez un capteur de batterie pour le Sonoff:
        # linked_battery_sensor: sensor.thermo_salon_battery

EOF

echo ""
echo "✓ Fichier créé: $PACKAGE_FILE"
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  PROCHAINES ÉTAPES"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "1. Vérifier la configuration YAML:"
echo "   ha core check"
echo ""
echo "2. Si OK, redémarrer Home Assistant:"
echo "   ha core restart"
echo ""
echo "3. Attendre 2-3 minutes (redémarrage + sync iCloud)"
echo ""
echo "4. Vérifier les nouvelles entités (Développeur → États):"
echo "   • climate.salon_climate_corrige"
echo "   • sensor.salon_ecart_temperature"
echo "   • sensor.salon_climate_etat"
echo "   • sensor.salon_climate_action"
echo "   • binary_sensor.salon_climate_actif"
echo ""
echo "5. Tester dans l'app Maison:"
echo "   • Ouvrir app Maison → Séjour"
echo "   • Vérifier température = 28.5°C (Sonoff, pas Daikin)"
echo "   • Tester changement consigne"
echo "   • Tester fan modes (si disponible dans HomeKit)"
echo ""
echo "6. Mettre à jour votre carte Lovelace:"
echo "   • Remplacer toutes les occurrences de:"
echo "     'climate.daikin_split_salon_room_temperature'"
echo "   • Par:"
echo "     'climate.salon_climate_corrige'"
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  NOTES IMPORTANTES"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "✓ Version template: climate ACTIVÉE"
echo "  → Tous les modes Daikin exposés (heat/cool/dry/fan)"
echo "  → Tous les fan modes exposés (auto/quiet/1-5)"
echo "  → Température = VRAIE valeur Sonoff"
echo ""
echo "⚠️  CONFIG HOMEKIT:"
echo "  Si vous avez DÉJÀ une section 'homekit:' ailleurs,"
echo "  vous devez FUSIONNER les configurations, pas les dupliquer."
echo "  Gardez un seul bloc homekit: avec tous vos include_entities."
echo ""
echo "⚠️  CONFLIT POTENTIEL:"
echo "  L'ancien climate Daikin est masqué dans HomeKit mais"
echo "  reste fonctionnel dans HA. Ne le supprimez PAS car"
echo "  le nouveau climate l'utilise comme actuateur."
echo ""
echo "💡 DEBUG:"
echo "  • sensor.salon_ecart_temperature : montre l'écart"
echo "    entre température Daikin (en haut) et Sonoff (réel)"
echo "  • Utile pour valider que tout fonctionne correctement"
echo ""

# Option: Validation syntaxe YAML
if command -v yamllint &> /dev/null; then
    echo "Validation YAML..."
    if yamllint -d relaxed "$PACKAGE_FILE" 2>/dev/null; then
        echo "✓ Syntaxe YAML valide"
    else
        echo "⚠️  Avertissements YAML détectés (vérifier manuellement)"
    fi
    echo ""
fi

echo "Script terminé avec succès !"
echo ""
echo "Prêt à exécuter: ha core check && ha core restart"
