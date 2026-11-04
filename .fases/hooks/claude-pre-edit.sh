#!/usr/bin/env bash
# Hook PreToolUse de Claude Code: bloquea Edit/Write sobre rutas congeladas en la fase activa.
# Salir con código 2 bloquea la herramienta y le devuelve el mensaje de stderr a Claude.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

if ! command -v jq >/dev/null; then
  echo "Bloqueado: el hook de fases necesita 'jq' instalado. Pedile al usuario que lo instale." >&2
  exit 2
fi

ruta="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
[[ -n "$ruta" ]] || exit 0

ruta="$(realpath -m "$ruta")"
[[ "$ruta" == "$FASES_RAIZ"/* ]] || exit 0   # fuera del repo: no nos concierne
rel="${ruta#"$FASES_RAIZ"/}"

cargar_config
leer_estado
grupo="$(grupo_de_ruta "$rel")"

if ! permitido "$FASE" "$grupo" claude; then
  if [[ "$grupo" == maquinaria ]]; then
    echo "Bloqueado: $rel es parte de la maquinaria de fases y Claude no puede modificarla." >&2
  else
    echo "Bloqueado: $rel pertenece a '$grupo', que está congelado en la fase $FASE (feature $FEATURE)." >&2
    echo "Si encontraste un error en una fase congelada, detenete y reportáselo al usuario; no lo corrijas en el lugar." >&2
  fi
  exit 2
fi
exit 0
