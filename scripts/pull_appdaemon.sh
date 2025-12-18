#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SRC_DIR="$REPO_ROOT/appdaemon"
ADDON_DIR="/addon_configs/a0d7b954_appdaemon"

rsync -a --delete \
  --exclude 'secrets.yaml' \
  --exclude '__pycache__/' \
  --exclude '*.pyc' \
  "$ADDON_DIR/" "$SRC_DIR/"

echo "OK: AppDaemon importé dans $SRC_DIR"
