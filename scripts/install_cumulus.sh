#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ CUMULUS INTELLIGENT - SCRIPT D'INSTALLATION ET MIGRATION                   ║
# ║ Installation automatique complète du système cumulus v2                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝
#
# Auteur: Laurent
# Version: 2.0.0
# Date: 2024-11
#
# UTILISATION:
# 1. Copier ce script sur le serveur HA: scp install_cumulus.sh root@192.168.1.29:/config/
# 2. Se connecter en SSH: ssh root@192.168.1.29
# 3. Rendre exécutable: chmod +x /config/install_cumulus.sh
# 4. Exécuter: /config/install_cumulus.sh

set -e  # Arrêt si erreur

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ CONFIGURATION                                                           │
# └─────────────────────────────────────────────────────────────────────────┘
HA_CONFIG="/config"
BACKUP_DIR="/config/backups/cumulus_$(date +%Y%m%d_%H%M%S)"
GITHUB_REPO="https://raw.githubusercontent.com/LaurentFrx/Home_Assistant/main"
LOCAL_FILES="/home/claude"  # Chemin local des fichiers créés

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ FONCTIONS UTILITAIRES                                                   │
# └─────────────────────────────────────────────────────────────────────────┘
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        log_info "Créé répertoire: $1"
    fi
}

backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$BACKUP_DIR/$(basename $1).bak"
        log_info "Sauvegardé: $1"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ VÉRIFICATIONS PRÉLIMINAIRES                                             │
# └─────────────────────────────────────────────────────────────────────────┘
check_requirements() {
    log_info "Vérification des prérequis..."

    # Vérifier qu'on est sur Home Assistant
    if [ ! -f "$HA_CONFIG/configuration.yaml" ]; then
        log_error "Ce script doit être exécuté sur un serveur Home Assistant!"
    fi

    # Vérifier les entités critiques
    log_info "Vérification des entités requises..."

    # Liste des entités requises
    local required_entities=(
        "switch.shellypro1_ece334ee1b64"
        "sensor.smart_meter_grid_import"
        "sensor.aps_power_w"
        "sensor.pv_total_entree_sb_aps_w"
        "sensor.system_sanguinet_etat_de_charge_du_sb"
    )

    # Note: Vérification simplifiée, en production utiliser l'API HA
    log_warning "Assurez-vous que les entités suivantes existent:"
    for entity in "${required_entities[@]}"; do
        echo "  - $entity"
    done

    read -p "Continuer l'installation ? (o/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        log_error "Installation annulée"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ SAUVEGARDE CONFIGURATION EXISTANTE                                      │
# └─────────────────────────────────────────────────────────────────────────┘
backup_existing() {
    log_info "Sauvegarde de la configuration existante..."

    create_directory "$BACKUP_DIR"

    # Sauvegarder les fichiers existants
    backup_file "$HA_CONFIG/packages/cumulus.yaml"
    backup_file "$HA_CONFIG/automations/cumulus.yaml"

    # Sauvegarder tous les dashboards cumulus
    for file in $HA_CONFIG/lovelace/*cumulus*.yaml; do
        [ -f "$file" ] && backup_file "$file"
    done

    log_success "Sauvegarde complète dans: $BACKUP_DIR"
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ INSTALLATION DES PACKAGES                                               │
# └─────────────────────────────────────────────────────────────────────────┘
install_packages() {
    log_info "Installation des packages cumulus v2..."

    # Créer structure de répertoires
    create_directory "$HA_CONFIG/packages/cumulus"

    # Copier les fichiers du package
    log_info "Copie des fichiers core..."

    # Core configuration
    cat > "$HA_CONFIG/packages/cumulus/core.yaml" << 'EOF'
# Insérer ici le contenu de core.yaml
# (Copié depuis le fichier créé précédemment)
EOF

    # Note: En production, télécharger depuis GitHub ou copier depuis local
    if [ -f "$LOCAL_FILES/packages/cumulus/core.yaml" ]; then
        cp "$LOCAL_FILES/packages/cumulus/core.yaml" "$HA_CONFIG/packages/cumulus/"
        log_success "core.yaml installé"
    fi

    if [ -f "$LOCAL_FILES/packages/cumulus/sensors_base.yaml" ]; then
        cp "$LOCAL_FILES/packages/cumulus/sensors_base.yaml" "$HA_CONFIG/packages/cumulus/"
        log_success "sensors_base.yaml installé"
    fi

    if [ -f "$LOCAL_FILES/packages/cumulus/sensors_calcul.yaml" ]; then
        cp "$LOCAL_FILES/packages/cumulus/sensors_calcul.yaml" "$HA_CONFIG/packages/cumulus/"
        log_success "sensors_calcul.yaml installé"
    fi

    if [ -f "$LOCAL_FILES/packages/cumulus/automations_pv.yaml" ]; then
        cp "$LOCAL_FILES/packages/cumulus/automations_pv.yaml" "$HA_CONFIG/packages/cumulus/"
        log_success "automations_pv.yaml installé"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ INSTALLATION DES DASHBOARDS                                             │
# └─────────────────────────────────────────────────────────────────────────┘
install_dashboards() {
    log_info "Installation des dashboards..."

    # Dashboard utilisateur
    if [ -f "$LOCAL_FILES/lovelace_cumulus_utilisateur_v2.yaml" ]; then
        cp "$LOCAL_FILES/lovelace_cumulus_utilisateur_v2.yaml" "$HA_CONFIG/lovelace/"
        log_success "Dashboard utilisateur installé"
    fi

    # Dashboard admin
    if [ -f "$LOCAL_FILES/lovelace_cumulus_admin_v2.yaml" ]; then
        cp "$LOCAL_FILES/lovelace_cumulus_admin_v2.yaml" "$HA_CONFIG/lovelace/"
        log_success "Dashboard admin installé"
    fi

    # Widget compact
    if [ -f "$LOCAL_FILES/lovelace_cumulus_widget.yaml" ]; then
        cp "$LOCAL_FILES/lovelace_cumulus_widget.yaml" "$HA_CONFIG/lovelace/"
        log_success "Widget compact installé"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ CONFIGURATION HOME ASSISTANT                                            │
# └─────────────────────────────────────────────────────────────────────────┘
configure_ha() {
    log_info "Configuration de Home Assistant..."

    # Vérifier si packages est activé dans configuration.yaml
    if ! grep -q "packages:" "$HA_CONFIG/configuration.yaml"; then
        log_info "Ajout de la configuration packages..."
        cat >> "$HA_CONFIG/configuration.yaml" << 'EOF'

# Cumulus Intelligent v2 - Packages
homeassistant:
  packages:
    cumulus: !include_dir_named packages/cumulus
EOF
        log_success "Configuration packages ajoutée"
    else
        log_warning "Configuration packages déjà présente"
    fi

    # Ajouter les dashboards dans ui-lovelace.yaml si mode YAML
    if [ -f "$HA_CONFIG/ui-lovelace.yaml" ]; then
        log_info "Ajout des dashboards dans ui-lovelace.yaml..."
        # Note: Implémentation simplifiée, adapter selon structure existante
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ MIGRATION DES DONNÉES                                                   │
# └─────────────────────────────────────────────────────────────────────────┘
migrate_data() {
    log_info "Migration des données existantes..."

    # Créer un script Python pour migrer via l'API HA
    cat > /tmp/migrate_cumulus.py << 'EOF'
#!/usr/bin/env python3
import requests
import json
import sys

# Configuration
HA_URL = "http://localhost:8123"
TOKEN = "YOUR_TOKEN_HERE"  # À remplacer

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "content-type": "application/json",
}

# Lire les valeurs actuelles des input_number
entities_to_migrate = [
    ("input_number.cumulus_seuil_pv_w", "input_number.cumulus_seuil_pv_statique_w"),
    ("input_number.cumulus_import_max", "input_number.cumulus_import_max_w"),
    # Ajouter autres mappings
]

for old_entity, new_entity in entities_to_migrate:
    try:
        # Récupérer ancienne valeur
        response = requests.get(
            f"{HA_URL}/api/states/{old_entity}",
            headers=headers
        )
        if response.status_code == 200:
            old_value = response.json()["state"]

            # Définir nouvelle valeur
            data = {
                "entity_id": new_entity,
                "value": old_value
            }
            requests.post(
                f"{HA_URL}/api/services/input_number/set_value",
                headers=headers,
                json=data
            )
            print(f"Migré: {old_entity} -> {new_entity} = {old_value}")
    except Exception as e:
        print(f"Erreur migration {old_entity}: {e}")
EOF

    log_warning "Migration manuelle des valeurs requise - Script créé dans /tmp/migrate_cumulus.py"
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ VÉRIFICATION ET RELOAD                                                  │
# └─────────────────────────────────────────────────────────────────────────┘
verify_and_reload() {
    log_info "Vérification de la configuration..."

    # Vérifier la configuration
    ha core check

    if [ $? -eq 0 ]; then
        log_success "Configuration valide!"

        read -p "Recharger Home Assistant maintenant ? (o/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            log_info "Rechargement de Home Assistant..."
            ha core reload
            sleep 10
            log_success "Home Assistant rechargé!"
        fi
    else
        log_error "Erreur de configuration! Vérifier les logs."
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ POST-INSTALLATION                                                       │
# └─────────────────────────────────────────────────────────────────────────┘
post_install() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALLATION TERMINÉE !                           ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    log_success "Le système Cumulus Intelligent v2 est installé!"
    echo
    echo "PROCHAINES ÉTAPES:"
    echo "1. Accéder au dashboard utilisateur: http://192.168.1.29:8123/lovelace/cumulus-simple"
    echo "2. Accéder au dashboard admin: http://192.168.1.29:8123/lovelace/cumulus-admin"
    echo "3. Configurer les paramètres initiaux dans le dashboard admin"
    echo "4. Vérifier les entités dans Developer Tools > States"
    echo
    echo "CONFIGURATION RECOMMANDÉE:"
    echo "- Seuil PV: 100W (ajuster selon votre installation)"
    echo "- Import max: 500W (selon votre contrat)"
    echo "- Température cible PV: 58°C"
    echo "- Température cible HC: 52°C"
    echo "- SOC minimum: 10%"
    echo
    echo "TESTS:"
    echo "1. Forcer une chauffe manuelle depuis le dashboard"
    echo "2. Vérifier les logs dans le dashboard admin"
    echo "3. Attendre les conditions PV pour test automatique"
    echo
    log_info "Sauvegarde disponible dans: $BACKUP_DIR"
    echo
    echo "Support: github.com/LaurentFrx/Home_Assistant/issues"
    echo
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ MENU PRINCIPAL                                                          │
# └─────────────────────────────────────────────────────────────────────────┘
show_menu() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║          CUMULUS INTELLIGENT v2 - INSTALLATION                       ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    echo "1) Installation complète (recommandé)"
    echo "2) Installation packages uniquement"
    echo "3) Installation dashboards uniquement"
    echo "4) Sauvegarde configuration actuelle"
    echo "5) Migration des données"
    echo "6) Vérification configuration"
    echo "7) Restauration depuis sauvegarde"
    echo "0) Quitter"
    echo
    read -p "Choix: " choice

    case $choice in
        1)
            check_requirements
            backup_existing
            install_packages
            install_dashboards
            configure_ha
            migrate_data
            verify_and_reload
            post_install
            ;;
        2)
            install_packages
            verify_and_reload
            ;;
        3)
            install_dashboards
            ;;
        4)
            backup_existing
            ;;
        5)
            migrate_data
            ;;
        6)
            ha core check
            ;;
        7)
            read -p "Chemin de la sauvegarde: " backup_path
            if [ -d "$backup_path" ]; then
                cp -r "$backup_path"/* "$HA_CONFIG/"
                log_success "Restauration effectuée"
                verify_and_reload
            else
                log_error "Sauvegarde non trouvée"
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            log_error "Choix invalide"
            ;;
    esac
}

# ┌─────────────────────────────────────────────────────────────────────────┐
# │ EXECUTION                                                               │
# └─────────────────────────────────────────────────────────────────────────┘
# Si argument fourni, exécution directe
if [ "$1" == "--auto" ]; then
    check_requirements
    backup_existing
    install_packages
    install_dashboards
    configure_ha
    migrate_data
    verify_and_reload
    post_install
else
    # Sinon afficher le menu
    show_menu
fi
