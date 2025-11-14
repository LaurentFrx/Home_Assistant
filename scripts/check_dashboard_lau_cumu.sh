#!/bin/bash
#
# Script de vérification du dashboard-lau/cumu
# Analyse les entités requises et leur disponibilité
#

ENTITIES_FILE="/home/user/Home_Assistant/lovelace/entities_lau_cumu.txt"
CUMULUS_PACKAGE="/home/user/Home_Assistant/packages/cumulus.yaml"

echo "=========================================="
echo "  VERIFICATION DASHBOARD-LAU/CUMU"
echo "=========================================="
echo ""
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Liste des entités requises
echo "=== ENTITÉS REQUISES ==="
grep -v "^#" "$ENTITIES_FILE" | grep -v "^$" | grep -v "^ENTITÉS" | grep -v "^===" | sort

echo ""
echo "=== ANALYSE DE LA CONFIGURATION ==="
echo ""

# Fonction pour vérifier si une entité est définie
check_entity() {
    local entity=$1
    local entity_type=${entity%%.*}
    local entity_name=${entity#*.}

    # Chercher dans cumulus.yaml
    if grep -q "name: ${entity_name}" "$CUMULUS_PACKAGE" 2>/dev/null; then
        echo "✅ $entity - Défini dans packages/cumulus.yaml"
        return 0
    fi

    # Chercher dans templates
    if grep -q "- name: ${entity_name}" "$CUMULUS_PACKAGE" 2>/dev/null; then
        echo "✅ $entity - Défini dans packages/cumulus.yaml (template)"
        return 0
    fi

    # Vérifier si c'est un switch externe (Shelly)
    if [[ "$entity" == "switch.shellypro1"* ]]; then
        echo "⚠️  $entity - Entité externe (Shelly), non définie localement"
        return 0
    fi

    # Chercher utilisation (même si pas défini)
    if grep -rq "$entity" /home/user/Home_Assistant --include="*.yaml" 2>/dev/null; then
        echo "⚠️  $entity - Utilisé mais NON DÉFINI dans packages/cumulus.yaml"
        return 1
    else
        echo "❌ $entity - NON TROUVÉ"
        return 1
    fi
}

# Compter les problèmes
missing=0
warnings=0
ok=0

while IFS= read -r entity; do
    # Ignorer les commentaires et lignes vides
    [[ "$entity" =~ ^#.*$ ]] && continue
    [[ -z "$entity" ]] && continue
    [[ "$entity" =~ ^ENTITÉS.*$ ]] && continue
    [[ "$entity" =~ ^===.*$ ]] && continue

    if check_entity "$entity"; then
        ((ok++))
    else
        ((missing++))
    fi
done < "$ENTITIES_FILE"

echo ""
echo "=== RÉSUMÉ ==="
echo "Total entités: $((ok + missing))"
echo "✅ OK/Externes: $ok"
echo "⚠️  Manquantes: $missing"
echo ""

if [ $missing -gt 0 ]; then
    echo "⚠️  ATTENTION: Certaines entités sont manquantes ou non définies!"
    echo "   Ces entités doivent être créées manuellement dans Home Assistant"
    echo "   ou ajoutées dans packages/cumulus.yaml"
    exit 1
else
    echo "✅ Toutes les entités sont correctement configurées!"
    exit 0
fi
