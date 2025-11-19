#!/bin/bash
###############################################################################
# Script de synchronisation Git pour Home Assistant
# Remplace l'add-on Git Pull bugué par un système robuste
#
# Fonctionnalités :
# - Pull automatique depuis origin/main
# - Vérification de la configuration HA avant redémarrage
# - Rollback automatique en cas d'erreur de configuration
# - Logging détaillé avec timestamps
# - Gestion complète des erreurs
#
# Auteur : Claude Code CLI
# Date : 2025-11-19
###############################################################################

# Configuration
readonly CONFIG_DIR="/config"
readonly LOG_FILE="${CONFIG_DIR}/git_sync.log"
readonly GIT_REPO="${CONFIG_DIR}"
readonly BRANCH="main"
readonly MAX_LOG_SIZE=5242880  # 5 MB

# Codes de sortie
readonly EXIT_SUCCESS=0
readonly EXIT_GIT_ERROR=1
readonly EXIT_CONFIG_ERROR=2
readonly EXIT_RESTART_ERROR=3
readonly EXIT_ROLLBACK_ERROR=4

###############################################################################
# Fonctions utilitaires
###############################################################################

# Fonction de logging avec timestamp
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Rotation des logs si nécessaire
rotate_logs() {
    if [[ -f "${LOG_FILE}" ]] && [[ $(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null) -gt ${MAX_LOG_SIZE} ]]; then
        log "INFO" "Rotation des logs (taille > 5 MB)"
        mv "${LOG_FILE}" "${LOG_FILE}.old"
        touch "${LOG_FILE}"
    fi
}

# Vérifie la connectivité réseau
check_network() {
    log "INFO" "Vérification de la connectivité réseau..."
    if ! ping -c 1 -W 5 github.com &>/dev/null; then
        log "ERROR" "Pas de connectivité réseau vers github.com"
        return 1
    fi
    log "INFO" "Connectivité réseau OK"
    return 0
}

# Vérifie que nous sommes dans un dépôt Git
check_git_repo() {
    if [[ ! -d "${GIT_REPO}/.git" ]]; then
        log "ERROR" "Le répertoire ${GIT_REPO} n'est pas un dépôt Git"
        return 1
    fi
    return 0
}

###############################################################################
# Fonctions Git
###############################################################################

# Sauvegarde le hash du commit actuel
save_current_commit() {
    cd "${GIT_REPO}" || return 1
    local current_commit
    current_commit=$(git rev-parse HEAD)
    echo "${current_commit}" > "${CONFIG_DIR}/.last_known_good_commit"
    log "INFO" "Commit actuel sauvegardé : ${current_commit}"
}

# Récupère les modifications depuis le dépôt distant
git_fetch() {
    log "INFO" "Récupération des modifications depuis origin/${BRANCH}..."
    cd "${GIT_REPO}" || return 1

    if ! git fetch origin "${BRANCH}" 2>&1 | tee -a "${LOG_FILE}"; then
        log "ERROR" "Échec de git fetch"
        return 1
    fi

    log "INFO" "Git fetch réussi"
    return 0
}

# Vérifie s'il y a des modifications à récupérer
check_updates() {
    cd "${GIT_REPO}" || return 1
    local local_commit
    local remote_commit

    local_commit=$(git rev-parse HEAD)
    remote_commit=$(git rev-parse "origin/${BRANCH}")

    if [[ "${local_commit}" == "${remote_commit}" ]]; then
        log "INFO" "Aucune mise à jour disponible (déjà à jour)"
        return 1
    fi

    log "INFO" "Mises à jour disponibles : ${local_commit} -> ${remote_commit}"
    return 0
}

# Effectue le pull Git
git_pull() {
    log "INFO" "Début du pull Git..."
    cd "${GIT_REPO}" || return 1

    # Vérifier s'il y a des modifications locales non commitées
    if ! git diff-index --quiet HEAD --; then
        log "WARNING" "Modifications locales détectées, stash en cours..."
        if ! git stash push -m "Auto-stash avant pull $(date +%Y%m%d_%H%M%S)" 2>&1 | tee -a "${LOG_FILE}"; then
            log "ERROR" "Échec du git stash"
            return 1
        fi
    fi

    # Pull avec stratégie de merge
    if ! git pull origin "${BRANCH}" --no-edit 2>&1 | tee -a "${LOG_FILE}"; then
        log "ERROR" "Échec du git pull"
        # Tenter d'annuler le merge en cours
        git merge --abort 2>/dev/null
        return 1
    fi

    log "INFO" "Git pull réussi"
    return 0
}

# Rollback vers le dernier commit connu bon
rollback_git() {
    log "WARNING" "Rollback vers le dernier commit connu bon..."
    cd "${GIT_REPO}" || return 1

    if [[ ! -f "${CONFIG_DIR}/.last_known_good_commit" ]]; then
        log "ERROR" "Pas de commit de sauvegarde trouvé, impossible de rollback"
        return 1
    fi

    local last_good_commit
    last_good_commit=$(cat "${CONFIG_DIR}/.last_known_good_commit")

    log "INFO" "Rollback vers : ${last_good_commit}"

    if ! git reset --hard "${last_good_commit}" 2>&1 | tee -a "${LOG_FILE}"; then
        log "ERROR" "Échec du rollback Git"
        return 1
    fi

    log "INFO" "Rollback réussi"
    return 0
}

###############################################################################
# Fonctions Home Assistant
###############################################################################

# Vérifie la configuration Home Assistant
check_ha_config() {
    log "INFO" "Vérification de la configuration Home Assistant..."

    local check_output
    check_output=$(ha core check 2>&1)
    local check_status=$?

    echo "${check_output}" >> "${LOG_FILE}"

    if [[ ${check_status} -ne 0 ]] || echo "${check_output}" | grep -qi "error\|invalid"; then
        log "ERROR" "La configuration Home Assistant contient des erreurs"
        echo "${check_output}" | grep -i "error" | tee -a "${LOG_FILE}"
        return 1
    fi

    log "INFO" "Configuration Home Assistant valide"
    return 0
}

# Redémarre Home Assistant
restart_ha() {
    log "INFO" "Redémarrage de Home Assistant..."

    if ! ha core restart 2>&1 | tee -a "${LOG_FILE}"; then
        log "ERROR" "Échec du redémarrage de Home Assistant"
        return 1
    fi

    log "INFO" "Commande de redémarrage envoyée avec succès"
    return 0
}

###############################################################################
# Fonction principale
###############################################################################

main() {
    log "INFO" "=========================================="
    log "INFO" "Début de la synchronisation Git"
    log "INFO" "=========================================="

    # Rotation des logs si nécessaire
    rotate_logs

    # Vérifications préliminaires
    if ! check_git_repo; then
        log "ERROR" "Vérification du dépôt Git échouée"
        exit ${EXIT_GIT_ERROR}
    fi

    if ! check_network; then
        log "WARNING" "Pas de connectivité réseau, synchronisation annulée"
        exit ${EXIT_SUCCESS}  # On ne considère pas ça comme une erreur fatale
    fi

    # Sauvegarder le commit actuel avant de faire quoi que ce soit
    save_current_commit

    # Fetch depuis le dépôt distant
    if ! git_fetch; then
        log "ERROR" "Échec de la récupération des modifications"
        exit ${EXIT_GIT_ERROR}
    fi

    # Vérifier s'il y a des mises à jour
    if ! check_updates; then
        log "INFO" "Aucune mise à jour, fin de la synchronisation"
        log "INFO" "=========================================="
        exit ${EXIT_SUCCESS}
    fi

    # Effectuer le pull
    if ! git_pull; then
        log "ERROR" "Échec du pull Git"
        exit ${EXIT_GIT_ERROR}
    fi

    # Vérifier la configuration après le pull
    if ! check_ha_config; then
        log "ERROR" "Configuration invalide après le pull, rollback nécessaire"

        if ! rollback_git; then
            log "CRITICAL" "Échec du rollback, intervention manuelle requise !"
            exit ${EXIT_ROLLBACK_ERROR}
        fi

        # Vérifier que la config est bonne après rollback
        if ! check_ha_config; then
            log "CRITICAL" "Configuration toujours invalide après rollback !"
            exit ${EXIT_CONFIG_ERROR}
        fi

        log "INFO" "Rollback réussi, configuration restaurée"
        exit ${EXIT_CONFIG_ERROR}
    fi

    # Configuration valide, redémarrer Home Assistant
    if ! restart_ha; then
        log "ERROR" "Échec du redémarrage de Home Assistant"
        exit ${EXIT_RESTART_ERROR}
    fi

    log "INFO" "=========================================="
    log "INFO" "Synchronisation terminée avec succès"
    log "INFO" "Home Assistant redémarre avec la nouvelle configuration"
    log "INFO" "=========================================="

    exit ${EXIT_SUCCESS}
}

# Exécution du script
main "$@"
