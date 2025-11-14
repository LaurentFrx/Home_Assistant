# Configuration Claude Code CLI

Ce dossier contient la configuration spécifique pour Claude Code CLI.

## Structure

```
.claude/
├── README.md                    # Ce fichier
└── hooks/
    └── session-start.sh         # Hook exécuté au démarrage de chaque session
```

## Hooks de session

### session-start.sh

Ce hook s'exécute automatiquement au début de chaque nouvelle session Claude Code CLI.

**Fonction** : Rappelle à Claude de charger les préférences utilisateur depuis `docs/CLAUDE_PREFERENCES.md`

**Avantages** :
- Plus besoin de dire manuellement "lis mes préférences"
- Garantit que Claude a toujours le bon contexte dès le départ
- Workflow cohérent entre toutes les sessions

## Préférences utilisateur

Les préférences détaillées sont stockées dans **`docs/CLAUDE_PREFERENCES.md`**

Ce fichier contient :
- Workflow Claude Code CLI optimisé (sans Working Copy)
- Règles critiques Home Assistant
- Contexte projet cumulus
- Style de réponse attendu
- Documentation de référence

## Modification des préférences

1. Éditer `docs/CLAUDE_PREFERENCES.md`
2. Commit et push dans Git
3. Les changements seront automatiquement chargés lors de la prochaine session

## Notes

- Les hooks sont versionnés dans Git (contrairement aux préférences compte Claude.ai)
- Permet de synchroniser les préférences entre iPad et PC
- Historique des modifications via Git
