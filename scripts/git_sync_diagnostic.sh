#!/bin/bash
###############################################################################
# Script de diagnostic pour Git Sync
# Vérifie que tout est correctement configuré
#
# Usage : ./git_sync_diagnostic.sh
#
# Auteur : Claude Code CLI
# Date : 2025-11-19
###############################################################################

# Couleurs pour l'affichage
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

readonly CHECK="✓"
readonly CROSS="✗"
readonly WARNING="⚠"

# Compteurs
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

###############################################################################
# Fonctions d'affichage
###############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
    ((CHECKS_PASSED++))
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
    ((CHECKS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC} $1"
    ((CHECKS_WARNING++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

###############################################################################
# Fonctions de vérification
###############################################################################

check_git_installed() {
    print_header "Vérification de Git"

    if command -v git &> /dev/null; then
        local git_version
        git_version=$(git --version)
        print_success "Git est installé : ${git_version}"
    else
        print_error "Git n'est pas installé"
        return 1
    fi
}

check_git_repo() {
    if [[ -d /config/.git ]]; then
        print_success "Répertoire /config est un dépôt Git"

        # Vérifier le remote
        cd /config || return 1
        local remote_url
        remote_url=$(git config --get remote.origin.url)

        if [[ -n "${remote_url}" ]]; then
            print_success "Remote configuré : ${remote_url}"

            # Vérifier la branche
            local current_branch
            current_branch=$(git branch --show-current)
            print_info "Branche actuelle : ${current_branch}"
        else
            print_error "Pas de remote 'origin' configuré"
            return 1
        fi
    else
        print_error "/config n'est pas un dépôt Git"
        return 1
    fi
}

check_ssh_config() {
    print_header "Vérification SSH"

    if [[ -d /config/.ssh ]]; then
        print_success "Répertoire /config/.ssh existe"

        # Vérifier les permissions
        local ssh_perms
        ssh_perms=$(stat -c %a /config/.ssh 2>/dev/null || stat -f %OLp /config/.ssh 2>/dev/null)
        if [[ "${ssh_perms}" == "700" ]]; then
            print_success "Permissions du répertoire .ssh correctes (700)"
        else
            print_warning "Permissions du répertoire .ssh : ${ssh_perms} (recommandé : 700)"
        fi

        # Vérifier les clés
        if [[ -f /config/.ssh/id_ed25519 ]] || [[ -f /config/.ssh/id_rsa ]]; then
            print_success "Clé SSH privée trouvée"

            # Vérifier la clé publique
            if [[ -f /config/.ssh/id_ed25519.pub ]] || [[ -f /config/.ssh/id_rsa.pub ]]; then
                print_success "Clé SSH publique trouvée"

                # Afficher la clé publique
                echo ""
                print_info "Clé publique à ajouter sur GitHub :"
                echo "----------------------------------------"
                cat /config/.ssh/id_ed25519.pub 2>/dev/null || cat /config/.ssh/id_rsa.pub 2>/dev/null
                echo "----------------------------------------"
            else
                print_warning "Clé SSH publique non trouvée"
            fi
        else
            print_error "Aucune clé SSH trouvée dans /config/.ssh/"
            print_info "Générez une clé avec : ssh-keygen -t ed25519 -C 'homeassistant@192.168.1.29' -f /config/.ssh/id_ed25519"
        fi

        # Vérifier le fichier config SSH
        if [[ -f /config/.ssh/config ]]; then
            print_success "Fichier SSH config trouvé"
        else
            print_warning "Pas de fichier SSH config"
            print_info "Créez /config/.ssh/config avec :"
            echo "    Host github.com"
            echo "      IdentityFile /config/.ssh/id_ed25519"
            echo "      StrictHostKeyChecking no"
        fi
    else
        print_error "Répertoire /config/.ssh n'existe pas"
        print_info "Créez-le avec : mkdir -p /config/.ssh && chmod 700 /config/.ssh"
        return 1
    fi
}

check_git_sync_script() {
    print_header "Vérification du script Git Sync"

    if [[ -f /config/scripts/git_sync.sh ]]; then
        print_success "Script git_sync.sh existe"

        # Vérifier si exécutable
        if [[ -x /config/scripts/git_sync.sh ]]; then
            print_success "Script est exécutable"
        else
            print_error "Script n'est PAS exécutable"
            print_info "Rendez-le exécutable avec : chmod +x /config/scripts/git_sync.sh"
        fi

        # Vérifier le shebang
        local first_line
        first_line=$(head -n 1 /config/scripts/git_sync.sh)
        if [[ "${first_line}" == "#!/bin/bash" ]]; then
            print_success "Shebang correct"
        else
            print_warning "Shebang : ${first_line}"
        fi
    else
        print_error "Script /config/scripts/git_sync.sh non trouvé"
        return 1
    fi
}

check_git_sync_package() {
    print_header "Vérification du package Git Sync"

    if [[ -f /config/packages/git_sync.yaml ]]; then
        print_success "Package git_sync.yaml existe"

        # Vérifier la syntaxe YAML (basique)
        if command -v python3 &> /dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('/config/packages/git_sync.yaml'))" 2>/dev/null; then
                print_success "Syntaxe YAML valide"
            else
                print_error "Syntaxe YAML invalide"
                return 1
            fi
        fi
    else
        print_error "Package /config/packages/git_sync.yaml non trouvé"
        return 1
    fi
}

check_ha_packages_enabled() {
    print_header "Vérification de la configuration HA"

    if [[ -f /config/configuration.yaml ]]; then
        if grep -q "packages:" /config/configuration.yaml && grep -q "!include packages/\*\.yaml" /config/configuration.yaml; then
            print_success "Les packages sont activés dans configuration.yaml"
        else
            print_warning "Les packages ne semblent pas activés"
            print_info "Ajoutez dans configuration.yaml :"
            echo "    homeassistant:"
            echo "      packages: !include_dir_named packages"
        fi
    else
        print_error "/config/configuration.yaml non trouvé"
        return 1
    fi
}

check_log_file() {
    print_header "Vérification des logs"

    if [[ -f /config/git_sync.log ]]; then
        print_success "Fichier de log existe"

        local log_size
        log_size=$(stat -c%s /config/git_sync.log 2>/dev/null || stat -f%z /config/git_sync.log 2>/dev/null)
        print_info "Taille du log : ${log_size} octets"

        # Afficher les dernières lignes
        if [[ ${log_size} -gt 0 ]]; then
            echo ""
            print_info "Dernières lignes du log :"
            echo "----------------------------------------"
            tail -n 10 /config/git_sync.log
            echo "----------------------------------------"
        fi
    else
        print_warning "Fichier de log n'existe pas encore (normal si jamais exécuté)"
    fi
}

check_network() {
    print_header "Vérification réseau"

    if ping -c 1 -W 5 github.com &>/dev/null; then
        print_success "Connectivité vers github.com OK"
    else
        print_error "Impossible de joindre github.com"
        return 1
    fi

    # Test de connexion SSH à GitHub
    if ssh -T git@github.com -o StrictHostKeyChecking=no -o ConnectTimeout=10 2>&1 | grep -q "successfully authenticated"; then
        print_success "Authentication SSH GitHub réussie"
    else
        print_warning "Authentication SSH GitHub non confirmée"
        print_info "Vérifiez que votre clé SSH est ajoutée sur GitHub"
    fi
}

check_ha_cli() {
    print_header "Vérification de ha CLI"

    if command -v ha &> /dev/null; then
        print_success "ha CLI est disponible"

        # Tester ha core check
        if ha core check &> /dev/null; then
            print_success "ha core check fonctionne"
        else
            print_warning "ha core check a retourné une erreur"
        fi
    else
        print_error "ha CLI n'est pas disponible"
        print_info "Assurez-vous d'exécuter ce script sur Home Assistant OS"
        return 1
    fi
}

###############################################################################
# Fonction principale
###############################################################################

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Diagnostic Git Sync pour Home Assistant  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    check_git_installed
    check_git_repo
    check_ssh_config
    check_git_sync_script
    check_git_sync_package
    check_ha_packages_enabled
    check_ha_cli
    check_network
    check_log_file

    # Résumé
    print_header "Résumé"
    echo -e "${GREEN}Vérifications réussies  : ${CHECKS_PASSED}${NC}"
    echo -e "${YELLOW}Avertissements          : ${CHECKS_WARNING}${NC}"
    echo -e "${RED}Vérifications échouées  : ${CHECKS_FAILED}${NC}"
    echo ""

    if [[ ${CHECKS_FAILED} -eq 0 ]]; then
        print_success "Tous les contrôles critiques sont passés !"
        echo ""
        print_info "Vous pouvez tester le script avec :"
        echo "    /config/scripts/git_sync.sh"
        echo ""
        print_info "Ensuite, rechargez Home Assistant pour activer le package :"
        echo "    ha core restart"
        echo ""
        return 0
    else
        print_error "Certains contrôles critiques ont échoué"
        echo ""
        print_info "Corrigez les erreurs ci-dessus avant de continuer"
        echo ""
        return 1
    fi
}

# Exécution
main "$@"
