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

[[ -d .git ]] || git init -q
git config core.hooksPath .fases/githooks
chmod +x .fases/fase .fases/lib.sh .fases/hooks/*.sh .fases/githooks/*

echo "Listo: hook pre-commit activo y CLI de fases en .fases/fase"
echo
.fases/fase estado
echo
echo "Próximos pasos (ver docs/METODOLOGIA.md §8):"
echo "  1. Completar docs/vision.md y docs/glosario.md"
echo "  2. Escribir docs/arquitectura/adr/0001-stack.md"
echo "  3. Completar .fases/config con los comandos de tests, lint y tipado"
echo "  4. .fases/fase iniciar F-001 <nombre>"
