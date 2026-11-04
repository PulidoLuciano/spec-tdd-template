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

if ! ruta_permitida "$rel" "$FASE" claude "$(componentes_declarados)"; then
  echo "Bloqueado: $MOTIVO" >&2
  if [[ "$GRUPO" != maquinaria && "$GRUPO" != config ]]; then
    echo "Si encontraste un error en una fase congelada, detenete y reportáselo al usuario; no lo corrijas en el lugar." >&2
  fi
  exit 2
fi
exit 0
