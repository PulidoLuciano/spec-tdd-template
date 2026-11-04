#!/usr/bin/env bash
# Lógica compartida por la CLI (.fases/fase) y los hooks.

FASES_RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

cargar_config() {
  # shellcheck source=/dev/null
  source "$FASES_RAIZ/.fases/config"
}

# Lee FEATURE y FASE desde un archivo de estado (por defecto, el del working tree).
# Se parsea en vez de hacer source para no ejecutar nada.
leer_estado() {
  local contenido
  if [[ $# -gt 0 ]]; then contenido="$1"; else contenido="$(cat "$FASES_RAIZ/.fases/estado")"; fi
  FEATURE="$(sed -n 's/^FEATURE=//p' <<<"$contenido")"
  FASE="$(sed -n 's/^FASE=//p' <<<"$contenido")"
}

# Imprime el grupo de una ruta relativa a la raíz:
# maquinaria | config | docs | src | tests | libre
grupo_de_ruta() {
  local ruta="$1" p
  case "$ruta" in
    .fases/config) echo config; return ;;
    .fases/*|.claude/*) echo maquinaria; return ;;
  esac
  for p in $RUTAS_DOCS;  do [[ "$ruta" == "$p"* ]] && { echo docs;  return; }; done
  for p in $RUTAS_SRC;   do [[ "$ruta" == "$p"* ]] && { echo src;   return; }; done
  for p in $RUTAS_TESTS; do [[ "$ruta" == "$p"* ]] && { echo tests; return; }; done
  echo libre
}

# permitido <fase> <grupo> <claude|git>
# Devuelve 0 si en esa fase se puede modificar ese grupo.
# Claude nunca puede tocar la maquinaria; un humano solo en fase LIBRE.
permitido() {
  local fase="$1" grupo="$2" modo="$3"
  case "$grupo" in
    libre)      return 0 ;;
    maquinaria) [[ "$modo" == git && "$fase" == LIBRE ]] ;;
    config)     [[ "$fase" == LIBRE ]] ;;
    docs)       [[ "$fase" == LIBRE || "$fase" == SPEC ]] ;;
    src)        [[ "$fase" == SPEC || "$fase" == IMPL ]] ;;
    tests)      [[ "$fase" == TESTS ]] ;;
    *)          return 1 ;;
  esac
}

# Lista los archivos modificados respecto de HEAD (staged, unstaged y no trackeados).
archivos_modificados() {
  git -C "$FASES_RAIZ" diff --name-only --no-renames HEAD 2>/dev/null
  git -C "$FASES_RAIZ" ls-files --others --exclude-standard
}
