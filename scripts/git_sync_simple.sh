#!/bin/bash
###############################################################################
# Script de synchronisation Git SIMPLIFIÉ pour Home Assistant
# Version allégée sans vérification complexe
#
# Auteur : Claude Code CLI
# Date : 2025-11-19
###############################################################################

# Configuration
readonly CONFIG_DIR="/config"
readonly LOG_FILE="${CONFIG_DIR}/git_sync.log"
readonly GIT_REPO="${CONFIG_DIR}"
readonly BRANCH="main"

###############################################################################
# Fonctions
###############################################################################

# Logging avec timestamp
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Vérification réseau simplifiée
check_network() {
    log "INFO" "Vérification réseau..."
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        log "INFO" "Réseau OK"
        return 0
    else
        log "WARNING" "Pas de réseau, abandon"
        return 1
    fi
}

# Git pull simple
do_git_pull() {
    log "INFO" "Début pull Git depuis origin/${BRANCH}..."
    cd "${GIT_REPO}" || {
        log "ERROR" "Impossible d'aller dans ${GIT_REPO}"
        return 1
    }

    # Fetch
    if ! git fetch origin "${BRANCH}" 2>&1 | tee -a "${LOG_FILE}"; then
        log "ERROR" "Échec git fetch"
        return 1
    fi

    # Vérifier si maj disponible
    local local_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse "origin/${BRANCH}")

    if [[ "${local_commit}" == "${remote_commit}" ]]; then
        log "INFO" "Déjà à jour (pas de nouvelle version)"
        return 0
    fi

    log "INFO" "Mise à jour disponible : ${local_commit:0:7} -> ${remote_commit:0:7}"

    # Pull
    if ! git pull origin "${BRANCH}" --no-edit 2>&1 | tee -a "${LOG_FILE}"; then
        log "ERROR" "Échec git pull"
        git merge --abort 2>/dev/null
        return 1
    fi

    log "INFO" "✅ Pull réussi !"
    log "INFO" "IMPORTANT : Vérifiez votre config et redémarrez HA manuellement si nécessaire"
    return 0
}

###############################################################################
# Main
###############################################################################

main() {
    log "INFO" "=========================================="
    log "INFO" "Git Sync SIMPLE - Début"
    log "INFO" "=========================================="

    if ! check_network; then
        exit 0
    fi

    if ! do_git_pull; then
        log "ERROR" "Échec de la synchronisation"
        exit 1
    fi

    log "INFO" "=========================================="
    log "INFO" "Synchronisation terminée avec succès"
    log "INFO" "=========================================="
    exit 0
}

main "$@"
