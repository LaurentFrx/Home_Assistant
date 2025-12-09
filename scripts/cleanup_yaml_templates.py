#!/usr/bin/env python3
"""
Script de nettoyage des templates YAML avec espaces blancs excessifs.
Supprime les lignes vides multiples dans les value_template et message.
"""
import re
import sys


def clean_template_whitespace(content):
    """Nettoie les espaces blancs excessifs dans les templates."""

    # Pattern 1: value_template avec lignes vides multiples après l'apostrophe
    # Exemple: value_template: '\n\n\n\n\n  {% set ... %}'
    # Devient: value_template: >\n  {% set ... %}
    pattern1 = r"value_template:\s*['\"](\n+\s*)"

    def replace_value_template(match):
        # Remplacer par le style > (multiline sans quotes)
        return "value_template: >\n  "

    # Pattern 2: Lignes vides multiples dans les templates entre les lignes
    # Exemple: {% set ... %}\n\n\n\n\n{% set ... %}
    # Devient: {% set ... %}\n{% set ... %}

    def clean_multiline_spaces(text):
        """Réduit les lignes vides multiples à maximum 1 ligne vide."""
        # Dans les value_template et message, réduire 3+ newlines consécutifs à 1
        lines = text.split('\n')
        cleaned = []
        empty_count = 0

        for line in lines:
            stripped = line.strip()
            if stripped == '':
                empty_count += 1
                # Maximum 1 ligne vide consécutive
                if empty_count <= 1:
                    cleaned.append(line)
            else:
                empty_count = 0
                cleaned.append(line)

        return '\n'.join(cleaned)

    # Appliquer le nettoyage
    content = clean_multiline_spaces(content)

    # Pattern 3: Nettoyer les templates avec \n\n dans les strings
    # Exemple: "\n\n{{ states(...)\n\n }}"
    # Devient: "{{ states(...) }}"
    pattern3 = r'"(\n+)\s*(\{\{[^}]+\}\})\s*(\n+)"'

    def clean_inline_template(match):
        template_content = match.group(2).strip()
        return f'"{template_content}"'

    content = re.sub(pattern3, clean_inline_template, content)

    # Pattern 4: Messages avec beaucoup de lignes vides
    # message: '\n\n\n\n\nTexte\n\n\n\n\n'
    # Nettoyer pour avoir maximum 1 ligne vide avant/après le contenu
    pattern4 = r"(message:\s*['\"])\n+\s+"
    content = re.sub(pattern4, r"\1\n        ", content)

    return content


def main():
    if len(sys.argv) < 2:
        print("Usage: cleanup_yaml_templates.py <fichier.yaml>")
        sys.exit(1)

    filepath = sys.argv[1]

    # Lire le fichier
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Nettoyer
    cleaned = clean_template_whitespace(content)

    # Compter les lignes économisées
    original_lines = content.count('\n')
    cleaned_lines = cleaned.count('\n')
    saved_lines = original_lines - cleaned_lines

    # Écrire le fichier nettoyé
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(cleaned)

    print(f"✅ Fichier nettoyé: {filepath}")
    print(f"   Lignes originales: {original_lines}")
    print(f"   Lignes après: {cleaned_lines}")
    print(f"   Lignes économisées: {saved_lines} ({saved_lines/original_lines*100:.1f}%)")


if __name__ == "__main__":
    main()
