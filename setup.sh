#!/usr/bin/env bash
# Prepara un proyecto recién creado desde la plantilla. Se corre una vez por clon.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

faltan=()
for cmd in git jq; do command -v "$cmd" >/dev/null || faltan+=("$cmd"); done
if (( ${#faltan[@]} )); then
  echo "Faltan dependencias: ${faltan[*]}" >&2
  exit 1
fi

[[ -d .git ]] || git init -q -b main
git config core.hooksPath .fases/githooks
chmod +x .fases/fase .fases/lib.sh .fases/hooks/*.sh .fases/githooks/* .fases/github-setup.sh scripts/*.sh

# develop sale de main
if git rev-parse -q --verify HEAD >/dev/null && ! git rev-parse -q --verify refs/heads/develop >/dev/null; then
  if git rev-parse -q --verify refs/remotes/origin/develop >/dev/null; then
    git branch -q develop origin/develop
  else
    git branch -q develop main
  fi
  echo "Rama develop creada."
fi
git rev-parse -q --verify refs/heads/develop >/dev/null && git switch -q develop

echo "Listo: hook pre-commit activo y CLI de fases en .fases/fase"
echo
.fases/fase estado
echo

echo "Próximos pasos (ver docs/METODOLOGIA.md §9):"
echo "  1. .fases/github-setup.sh   (sube develop y configura las protecciones en GitHub)"
echo "  2. git switch -c docs/inicio"
echo "  3. Completar docs/vision.md, docs/glosario.md y docs/arquitectura/adr/0001-stack.md"
echo "  4. Completar .fases/config y los pasos del stack en .github/workflows/"
echo "  5. PR a develop. Después: .fases/fase iniciar F-001 <nombre>"
