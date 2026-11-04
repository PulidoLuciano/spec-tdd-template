#!/usr/bin/env bash
# Despliega el proyecto a un entorno: staging | production | preview.
# Lo implementa cada proyecto según su ADR de infraestructura.
set -euo pipefail

entorno="${1:?uso: scripts/deploy.sh staging|production|preview}"

case "$entorno" in
  staging|production|preview) ;;
  *) echo "Entorno desconocido: $entorno" >&2; exit 1 ;;
esac

echo "::warning::scripts/deploy.sh todavía no está implementado; no se desplegó nada a $entorno."
