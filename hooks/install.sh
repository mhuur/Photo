#!/usr/bin/env bash
# Installe les hooks Git locaux. À lancer une fois après clone du repo.
# .git/hooks/ n'est pas versionné — chaque clone doit refaire l'install.
set -e
cd "$(dirname "$0")/.."
mkdir -p .git/hooks
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "✓ Hooks installés"
