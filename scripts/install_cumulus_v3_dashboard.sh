#!/bin/bash
###############################################################################
# CUMULUS V3 DASHBOARD - SCRIPT D'INSTALLATION
###############################################################################
# Description : Installe le dashboard Cumulus V3 complet sur Home Assistant
# Usage : ./install_cumulus_v3_dashboard.sh [--dry-run] [--backup]
# Auteur : Laurent
# Date : 2025-11-25
###############################################################################

set -euo pipefail

#==============================================================================
# CONFIGURATION
#==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/config"
THEMES_DIR="${CONFIG_DIR}/themes"
PACKAGES_DIR="${CONFIG_DIR}/packages"
LOVELACE_DIR="${CONFIG_DIR}/lovelace"
BACKUP_DIR="${CONFIG_DIR}/backups/cumulus_v3_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${CONFIG_DIR}/logs/install_cumulus_v3_$(date +%Y%m%d_%H%M%S).log"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Options
DRY_RUN=false
DO_BACKUP=false

#==============================================================================
# FONCTIONS
#==============================================================================

log() { 
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() { 
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${GREEN}✓${NC} $1"
}

warn() { 
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${YELLOW}⚠${NC} $1"
}

error() { 
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${RED}✗${NC} $1"
    exit 1
}

header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

#==============================================================================
# PARSE ARGUMENTS
#==============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --backup) DO_BACKUP=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--backup]"
            echo ""
            echo "Options:"
            echo "  --dry-run   Simule l'installation sans modifier de fichiers"
            echo "  --backup    Crée une sauvegarde avant l'installation"
            exit 0
            ;;
        *) 
            warn "Option inconnue: $1"
            ;;
    esac
    shift
done

#==============================================================================
# DÉBUT INSTALLATION
#==============================================================================
header "CUMULUS V3 DASHBOARD - INSTALLATION"

log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN (simulation)' || echo 'PRODUCTION')"
log "Backup: $([ "$DO_BACKUP" = true ] && echo 'Activé' || echo 'Désactivé')"
echo ""

#==============================================================================
# PHASE 1 : VÉRIFICATIONS
#==============================================================================
header "PHASE 1 : Vérifications préalables"

# Vérifier qu'on est sur Home Assistant
if [ ! -d "$CONFIG_DIR" ]; then
    error "Répertoire $CONFIG_DIR non trouvé. Êtes-vous sur le serveur Home Assistant ?"
fi
success "Répertoire Home Assistant trouvé"

# Créer répertoire logs si nécessaire
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Vérifier les fichiers sources
SOURCE_FILES=(
    "${SCRIPT_DIR}/themes/warm_glassmorphism.yaml"
    "${SCRIPT_DIR}/packages/cumulus_v3_dashboard_sensors.yaml"
    "${SCRIPT_DIR}/lovelace/dashboard_cumulus_v3.yaml"
    "${SCRIPT_DIR}/button_card_templates.yaml"
)

log "Vérification des fichiers sources..."
for file in "${SOURCE_FILES[@]}"; do
    if [ -f "$file" ]; then
        success "Trouvé: $(basename "$file")"
    else
        error "Fichier manquant: $file"
    fi
done

# Vérifier les cartes custom requises
log ""
log "Cartes HACS requises :"
log "  - bubble-card"
log "  - button-card"  
log "  - apexcharts-card"
log "  - card-mod"
log "  - mushroom (optionnel)"
warn "Assurez-vous que ces cartes sont installées via HACS"

#==============================================================================
# PHASE 2 : BACKUP
#==============================================================================
if [ "$DO_BACKUP" = true ]; then
    header "PHASE 2 : Sauvegarde"
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR"
        
        # Backup thèmes existants
        if [ -d "$THEMES_DIR" ]; then
            cp -r "$THEMES_DIR" "${BACKUP_DIR}/themes_backup" 2>/dev/null || true
            success "Thèmes sauvegardés"
        fi
        
        # Backup packages existants
        if [ -d "$PACKAGES_DIR" ]; then
            cp -r "$PACKAGES_DIR" "${BACKUP_DIR}/packages_backup" 2>/dev/null || true
            success "Packages sauvegardés"
        fi
        
        success "Backup créé: $BACKUP_DIR"
    else
        log "[DRY RUN] Backup serait créé dans: $BACKUP_DIR"
    fi
fi

#==============================================================================
# PHASE 3 : CRÉATION DES RÉPERTOIRES
#==============================================================================
header "PHASE 3 : Création des répertoires"

DIRS_TO_CREATE=(
    "$THEMES_DIR"
    "$PACKAGES_DIR"
    "$LOVELACE_DIR"
)

for dir in "${DIRS_TO_CREATE[@]}"; do
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$dir"
        success "Créé/Vérifié: $dir"
    else
        log "[DRY RUN] Créerait: $dir"
    fi
done

#==============================================================================
# PHASE 4 : COPIE DES FICHIERS
#==============================================================================
header "PHASE 4 : Installation des fichiers"

# Thème
log "Installation du thème Warm Glassmorphism..."
if [ "$DRY_RUN" = false ]; then
    cp "${SCRIPT_DIR}/themes/warm_glassmorphism.yaml" "${THEMES_DIR}/"
    success "Thème installé"
else
    log "[DRY RUN] Copierait le thème"
fi

# Package sensors
log "Installation du package sensors..."
if [ "$DRY_RUN" = false ]; then
    cp "${SCRIPT_DIR}/packages/cumulus_v3_dashboard_sensors.yaml" "${PACKAGES_DIR}/"
    success "Package sensors installé"
else
    log "[DRY RUN] Copierait le package sensors"
fi

# Button card templates
log "Installation des templates button-card..."
if [ "$DRY_RUN" = false ]; then
    # Vérifier si button_card_templates existe déjà
    if [ -f "${CONFIG_DIR}/button_card_templates.yaml" ]; then
        warn "button_card_templates.yaml existe déjà"
        log "Les templates seront ajoutés dans un fichier séparé"
        cp "${SCRIPT_DIR}/button_card_templates.yaml" "${CONFIG_DIR}/button_card_templates_cumulus_v3.yaml"
        success "Templates installés (fichier séparé)"
    else
        cp "${SCRIPT_DIR}/button_card_templates.yaml" "${CONFIG_DIR}/"
        success "Templates installés"
    fi
else
    log "[DRY RUN] Copierait les templates button-card"
fi

# Dashboard
log "Installation du dashboard..."
if [ "$DRY_RUN" = false ]; then
    cp "${SCRIPT_DIR}/lovelace/dashboard_cumulus_v3.yaml" "${LOVELACE_DIR}/"
    success "Dashboard installé"
else
    log "[DRY RUN] Copierait le dashboard"
fi

#==============================================================================
# PHASE 5 : CONFIGURATION
#==============================================================================
header "PHASE 5 : Configuration"

log "Vérification de configuration.yaml..."

CONFIG_YAML="${CONFIG_DIR}/configuration.yaml"

# Vérifier si packages est configuré
if grep -q "packages:" "$CONFIG_YAML" 2>/dev/null; then
    success "Configuration packages déjà présente"
else
    warn "Ajoutez manuellement dans configuration.yaml :"
    echo ""
    echo "  homeassistant:"
    echo "    packages: !include_dir_named packages"
    echo ""
fi

# Vérifier si themes est configuré
if grep -q "themes:" "$CONFIG_YAML" 2>/dev/null; then
    success "Configuration themes déjà présente"
else
    warn "Ajoutez manuellement dans configuration.yaml :"
    echo ""
    echo "  frontend:"
    echo "    themes: !include_dir_merge_named themes"
    echo ""
fi

# Vérifier button_card_templates
if grep -q "button_card_templates" "$CONFIG_YAML" 2>/dev/null; then
    success "Configuration button_card_templates déjà présente"
else
    warn "Ajoutez manuellement dans configuration.yaml :"
    echo ""
    echo "  button_card_templates: !include button_card_templates.yaml"
    echo ""
fi

#==============================================================================
# PHASE 6 : VALIDATION
#==============================================================================
header "PHASE 6 : Validation"

if [ "$DRY_RUN" = false ]; then
    log "Vérification de la configuration Home Assistant..."
    
    if command -v ha &> /dev/null; then
        if ha core check 2>&1 | tee -a "$LOG_FILE"; then
            success "Configuration YAML valide"
        else
            warn "Erreurs détectées - vérifiez les logs"
        fi
    else
        warn "Commande 'ha' non disponible - vérification manuelle requise"
        log "Utilisez : Configuration → Contrôle du serveur → Vérifier la configuration"
    fi
else
    log "[DRY RUN] Vérification de config sautée"
fi

#==============================================================================
# PHASE 7 : RECHARGEMENT
#==============================================================================
header "PHASE 7 : Rechargement"

if [ "$DRY_RUN" = false ]; then
    log "Rechargement de Home Assistant..."
    
    if command -v ha &> /dev/null; then
        # Recharger les thèmes
        ha frontend reload-themes 2>/dev/null && success "Thèmes rechargés" || warn "Rechargez les thèmes manuellement"
        
        # Recharger la config
        ha core reload 2>/dev/null && success "Configuration rechargée" || warn "Rechargez la configuration manuellement"
    else
        warn "Rechargement manuel requis :"
        log "  1. Configuration → Contrôle du serveur → Recharger la configuration"
        log "  2. Outils de développement → Services → homeassistant.reload_themes"
    fi
else
    log "[DRY RUN] Rechargement sauté"
fi

#==============================================================================
# RÉSUMÉ
#==============================================================================
header "INSTALLATION TERMINÉE"

echo ""
echo "📁 Fichiers installés :"
echo "   ${THEMES_DIR}/warm_glassmorphism.yaml"
echo "   ${PACKAGES_DIR}/cumulus_v3_dashboard_sensors.yaml"
echo "   ${LOVELACE_DIR}/dashboard_cumulus_v3.yaml"
echo "   ${CONFIG_DIR}/button_card_templates.yaml"
echo ""
echo "📋 Prochaines étapes :"
echo ""
echo "   1. Vérifier configuration.yaml (voir messages ci-dessus)"
echo ""
echo "   2. Ajouter le dashboard dans l'UI :"
echo "      → Paramètres → Tableaux de bord → Ajouter"
echo "      → Utiliser une vue existante d'un fichier YAML"
echo "      → Chemin : lovelace/dashboard_cumulus_v3.yaml"
echo ""
echo "   3. Activer le thème :"
echo "      → Profil utilisateur → Thème → Warm Glassmorphism"
echo ""
echo "   4. Accéder au dashboard :"
echo "      → http://votre-ha:8123/lovelace/eau-chaude"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo ""
    warn "MODE DRY RUN - Aucune modification effectuée"
    echo "Relancez sans --dry-run pour installer réellement"
fi

[ -n "${LOG_FILE:-}" ] && [ -f "$LOG_FILE" ] && echo "📝 Log : $LOG_FILE"

echo ""
success "Installation Cumulus V3 Dashboard terminée ! 🎉"
echo ""
