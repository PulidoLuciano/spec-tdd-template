#!/usr/bin/env bash
# Configura el repo en GitHub según docs/METODOLOGIA.md §8. Lo corre el usuario, una vez.
#   - Sube main y develop. develop queda como rama por defecto (los PR apuntan ahí).
#   - Solo merge commits (sin squash ni rebase) y borrado de ramas al mergear.
#   - Protege main y develop: PR obligatorio, check "fases" en verde, sin force push. Vale también para admins.
#   - Crea los entornos staging, preview y production (production con aprobación manual).
# Requiere gh autenticado. En repos privados, la protección de ramas necesita un plan pago de GitHub.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

command -v gh >/dev/null || { echo "Falta gh (GitHub CLI)." >&2; exit 1; }
repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)" || { echo "No se encontró el repo en GitHub (¿falta el remote origin?)." >&2; exit 1; }

sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
printf '\nRepo: %s. ¿Continuar? [s/N] ' "$repo"
read -r respuesta
[[ "$respuesta" == s || "$respuesta" == S ]] || { echo "Cancelado."; exit 1; }

aviso() { echo "  ! $*"; }

echo "→ Subiendo main y develop"
git push -q -u origin main develop --follow-tags || exit 1

echo "→ Opciones del repo"
gh repo edit "$repo" --default-branch develop \
  --enable-merge-commit --enable-squash-merge=false --enable-rebase-merge=false \
  --delete-branch-on-merge || exit 1

for rama in main develop; do
  echo "→ Protegiendo $rama"
  gh api -X PUT "repos/$repo/branches/$rama/protection" --silent --input - <<'JSON' \
    || aviso "no se pudo proteger $rama (en repos privados requiere GitHub Pro/Team)."
{
  "required_status_checks": { "strict": false, "contexts": ["fases"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
done

echo "→ Entornos"
for entorno in staging preview; do
  gh api -X PUT "repos/$repo/environments/$entorno" --silent || aviso "no se pudo crear el entorno $entorno."
done
usuario_id="$(gh api user -q .id)"
gh api -X PUT "repos/$repo/environments/production" --silent --input - <<JSON \
  || { aviso "no se pudo exigir aprobación en production; se crea sin ella."; gh api -X PUT "repos/$repo/environments/production" --silent; }
{ "reviewers": [ { "type": "User", "id": $usuario_id } ] }
JSON

echo "Listo."
