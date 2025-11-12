#!/bin/bash
#==============================================================================

# Script: fix_cumulus_energy_unit.sh

# Description: Supprime les statistiques de sensor.cumulus_energie_journaliere

# pour résoudre l’erreur d’unité (”” → “kWh”)

# Auteur: Laurent

# Date: 2025-11-12

# Usage: ./fix_cumulus_energy_unit.sh

#==============================================================================

set -euo pipefail

# Couleurs ANSI (format compatible)

RED=$’\033[0;31m’
GREEN=$’\033[0;32m’
YELLOW=$’\033[1;33m’
BLUE=$’\033[0;34m’
NC=$’\033[0m’

# Config

ENTITY_ID=“sensor.cumulus_energie_journaliere”
HA_DB=”/config/home-assistant_v2.db”
BACKUP_DIR=”/config/backups/statistics”
LOG_FILE=”/config/logs/fix_cumulus_unit_$(date +%Y%m%d_%H%M%S).log”

# Fonctions

log() {
echo “[$(date ‘+%Y-%m-%d %H:%M:%S’)] [$1] ${*:2}” | tee -a “${LOG_FILE}”
}

print_step() {
echo -e “${BLUE}==>${NC} $1”
log “INFO” “$1”
}

print_success() {
echo -e “${GREEN}✓${NC} $1”
log “SUCCESS” “$1”
}

print_warning() {
echo -e “${YELLOW}⚠${NC} $1”
log “WARNING” “$1”
}

print_error() {
echo -e “${RED}✗${NC} $1”
log “ERROR” “$1”
exit 1
}

#==============================================================================

# Vérifications

#==============================================================================

print_step “Vérification environnement…”
mkdir -p “${BACKUP_DIR}” “$(dirname “${LOG_FILE}”)”
[[ -f “${HA_DB}” ]] || print_error “DB introuvable: ${HA_DB}”
print_success “DB trouvée”

#==============================================================================

# Backup

#==============================================================================

print_step “Backup de sécurité…”
BACKUP_FILE=”${BACKUP_DIR}/ha_db_backup_$(date +%Y%m%d_%H%M%S).db”
cp “${HA_DB}” “${BACKUP_FILE}” || print_error “Échec backup”
print_success “Backup: ${BACKUP_FILE} ($(du -h “${BACKUP_FILE}” | cut -f1))”

#==============================================================================

# Analyse

#==============================================================================

print_step “Analyse statistiques…”
STATS_COUNT=$(sqlite3 “${HA_DB}” “SELECT COUNT(*) FROM statistics WHERE metadata_id = (SELECT id FROM statistics_meta WHERE statistic_id = ‘${ENTITY_ID}’);”)

if [[ ${STATS_COUNT} -eq 0 ]]; then
print_warning “Aucune stat trouvée pour ${ENTITY_ID}”
echo “Rien à faire. Problème peut-être déjà résolu.”
exit 0
fi

FIRST_DATE=$(sqlite3 “${HA_DB}” “SELECT datetime(MIN(start), ‘unixepoch’) FROM statistics WHERE metadata_id = (SELECT id FROM statistics_meta WHERE statistic_id = ‘${ENTITY_ID}’);”)
LAST_DATE=$(sqlite3 “${HA_DB}” “SELECT datetime(MAX(start), ‘unixepoch’) FROM statistics WHERE metadata_id = (SELECT id FROM statistics_meta WHERE statistic_id = ‘${ENTITY_ID}’);”)

echo “”
echo -e “${YELLOW}📊 Données à supprimer:${NC}”
echo “  • Entité: ${ENTITY_ID}”
echo “  • Enregistrements: ${STATS_COUNT}”
echo “  • Période: ${FIRST_DATE} → ${LAST_DATE}”
echo “  • Backup: ${BACKUP_FILE}”
echo “”

#==============================================================================

# Confirmation

#==============================================================================

echo -e “${YELLOW}⚠ ATTENTION:${NC}”
echo “  Suppression TOTALE des stats historiques.”
echo “  Régénération auto avec unité correcte (kWh).”
echo “”
read -p “Confirmer? (oui/non): “ CONFIRMATION
[[ “${CONFIRMATION}” != “oui” ]] && { print_warning “Annulé”; exit 0; }

#==============================================================================

# Suppression

#==============================================================================

print_step “Suppression statistiques…”

METADATA_ID=$(sqlite3 “${HA_DB}” “SELECT id FROM statistics_meta WHERE statistic_id = ‘${ENTITY_ID}’;”)
[[ -z “${METADATA_ID}” ]] && print_error “Metadata introuvable”
log “INFO” “Metadata ID: ${METADATA_ID}”

sqlite3 “${HA_DB}” “DELETE FROM statistics WHERE metadata_id = ${METADATA_ID};” || print_error “Échec suppression”
print_success “Statistics supprimées”

SHORT_TERM=$(sqlite3 “${HA_DB}” “SELECT COUNT(*) FROM statistics_short_term WHERE metadata_id = ${METADATA_ID};”)
if [[ ${SHORT_TERM} -gt 0 ]]; then
sqlite3 “${HA_DB}” “DELETE FROM statistics_short_term WHERE metadata_id = ${METADATA_ID};”
print_success “Statistics court-terme supprimées (${SHORT_TERM})”
fi

sqlite3 “${HA_DB}” “DELETE FROM statistics_meta WHERE id = ${METADATA_ID};”
print_success “Métadonnées supprimées”

print_step “Optimisation DB…”
sqlite3 “${HA_DB}” “VACUUM;” && print_success “DB optimisée” || print_warning “VACUUM échoué”

#==============================================================================

# Vérification

#==============================================================================

print_step “Vérification…”
REMAINING=$(sqlite3 “${HA_DB}” “SELECT COUNT(*) FROM statistics WHERE metadata_id = ${METADATA_ID};” 2>/dev/null || echo “0”)
[[ ${REMAINING} -eq 0 ]] && print_success “Suppression confirmée ✓” || print_warning “${REMAINING} stats restantes”

#==============================================================================

# Résumé

#==============================================================================

echo “”
echo -e “${GREEN}╔════════════════════════════════════════════════════════╗${NC}”
echo -e “${GREEN}║         OPÉRATION TERMINÉE AVEC SUCCÈS ✓               ║${NC}”
echo -e “${GREEN}╚════════════════════════════════════════════════════════╝${NC}”
echo “”
echo “📋 Résumé:”
echo “  • ${STATS_COUNT} enregistrements supprimés”
echo “  • Backup: ${BACKUP_FILE}”
echo “  • Log: ${LOG_FILE}”
echo “”
echo “🔄 Prochaines étapes:”
echo “  1. Optionnel: ha core restart”
echo “  2. Attendre 2-3 minutes”
echo “  3. Vérifier Développeur > Statistiques”
echo “  4. Nouvelles stats créées avec unité ‘kWh’ ✓”
echo “”

log “INFO” “Script terminé avec succès”