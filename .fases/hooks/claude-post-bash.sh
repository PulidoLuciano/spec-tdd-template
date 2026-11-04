#!/usr/bin/env bash
# Hook PostToolUse de Claude Code sobre Bash: detecta si un comando de shell
# modificó rutas congeladas en la fase activa y se lo informa a Claude.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"
git -C "$FASES_RAIZ" rev-parse -q --verify HEAD >/dev/null || exit 0

cargar_config
leer_estado

violaciones=""
while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  permitido "$FASE" "$(grupo_de_ruta "$rel")" git || violaciones+="  $rel"$'\n'
done < <(archivos_modificados | sort -u)

if [[ -n "$violaciones" ]]; then
  {
    echo "Atención: hay cambios sin commitear en rutas congeladas en la fase $FASE (feature $FEATURE):"
    printf '%s' "$violaciones"
    echo "Si los hiciste vos, revertilos (git checkout / git clean). Si no, avisale al usuario."
  } >&2
  exit 2
fi
exit 0
