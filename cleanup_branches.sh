#!/bin/bash
# Script de nettoyage des branches GitHub obsolètes
# Généré le 2025-11-17 par Claude Code

echo "🧹 NETTOYAGE DES BRANCHES OBSOLÈTES"
echo "===================================="
echo ""
echo "Ce script va supprimer les branches suivantes :"
echo ""
echo "📦 BRANCHES MERGÉES (déjà dans main) :"
echo "  - claude/resume-conversation-01UTcc4DNgWXs4SXHWPnUA9B"
echo "  - claude/cumulus-markdown-synthesis-011CUkmnAo6nGWQePJ8M6kJ5"
echo "  - claude/analyze-working-copy-necessity-01NgSodVLL6muePW2weKHL7C"
echo "  - feat/cumulus-2025-10-02b"
echo ""
echo "🗑️  BRANCHES OBSOLÈTES :"
echo "  - doc-reorganization (11 jours, 23 commits de retard)"
echo "  - claude/review-markdown-files-01WCSpYLFWna8YBaACueyycv (contenu .md récupéré)"
echo ""
echo "⚠️  BRANCHES CONSERVÉES (non touchées) :"
echo "  - claude/fix-solcast-cache-corruption-* (décision en attente)"
echo ""
read -p "Continuer ? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Annulé"
    exit 1
fi

echo ""
echo "🗑️  Suppression des branches distantes..."
echo ""

# Branches mergées
git push origin --delete claude/resume-conversation-01UTcc4DNgWXs4SXHWPnUA9B && echo "✅ resume-conversation supprimée"
git push origin --delete claude/cumulus-markdown-synthesis-011CUkmnAo6nGWQePJ8M6kJ5 && echo "✅ cumulus-markdown-synthesis supprimée"
git push origin --delete claude/analyze-working-copy-necessity-01NgSodVLL6muePW2weKHL7C && echo "✅ analyze-working-copy supprimée"
git push origin --delete feat/cumulus-2025-10-02b && echo "✅ feat/cumulus-2025-10-02b supprimée"

# Branches obsolètes
git push origin --delete doc-reorganization && echo "✅ doc-reorganization supprimée"
git push origin --delete claude/review-markdown-files-01WCSpYLFWna8YBaACueyycv && echo "✅ review-markdown-files supprimée"

echo ""
echo "🧹 Nettoyage des références locales..."
git fetch --prune origin

echo ""
echo "✅ NETTOYAGE TERMINÉ !"
echo ""
echo "📊 Branches restantes :"
git branch -r | grep -v "HEAD"
echo ""
echo "💡 Pour supprimer la branche Solcast plus tard :"
echo "   git push origin --delete claude/fix-solcast-cache-corruption-017ZHLWAtzfc5v1iwuCEHZLW"
