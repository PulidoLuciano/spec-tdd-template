#!/usr/bin/env bash
# Lógica compartida por la CLI (.fases/fase) y los hooks.

FASES_RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RAMAS_PROTEGIDAS="main develop"

# ── Configuración ────────────────────────────────────────────────────────────

# Carga .fases/config y todos los componentes de .fases/componentes/*.conf en:
#   COMPONENTES            nombres
#   C_RUTA[n]              raíz del componente ("." = raíz del repo)
#   C_SRC[n] C_TESTS[n]    prefijos de ruta, ya relativos a la raíz del repo
#   C_TEST[n] C_LINT[n] C_TIPADO[n] C_FIRMAS[n]   comandos (se corren dentro de C_RUTA)
cargar_config() {
  local f n RUTA RUTAS_SRC RUTAS_TESTS TEST_CMD LINT_CMD TYPECHECK_CMD FIRMAS_CMD
  # shellcheck source=/dev/null
  source "$FASES_RAIZ/.fases/config"
  DIR_DOCS="${RUTAS_DOCS%% *}"; DIR_DOCS="${DIR_DOCS%/}"
  COMPONENTES=()
  declare -gA C_RUTA=() C_SRC=() C_TESTS=() C_TEST=() C_LINT=() C_TIPADO=() C_FIRMAS=()
  for f in "$FASES_RAIZ"/.fases/componentes/*.conf; do
    [[ -e "$f" ]] || continue
    n="$(basename "$f" .conf)"
    RUTA=. RUTAS_SRC="" RUTAS_TESTS="" TEST_CMD="" LINT_CMD="" TYPECHECK_CMD="" FIRMAS_CMD=""
    # shellcheck source=/dev/null
    source "$f"
    COMPONENTES+=("$n")
    C_RUTA[$n]="$RUTA"
    # shellcheck disable=SC2086
    C_SRC[$n]="$(prefijar "$RUTA" $RUTAS_SRC)"
    # shellcheck disable=SC2086
    C_TESTS[$n]="$(prefijar "$RUTA" $RUTAS_TESTS)"
    C_TEST[$n]="$TEST_CMD"; C_LINT[$n]="$LINT_CMD"; C_TIPADO[$n]="$TYPECHECK_CMD"; C_FIRMAS[$n]="$FIRMAS_CMD"
  done
}

# prefijar <raíz> <prefijos...>: antepone la raíz del componente a cada prefijo.
prefijar() {
  local raiz="${1%/}" p salida=(); shift
  for p in "$@"; do
    if [[ "$raiz" == . ]]; then salida+=("$p")
    elif [[ "$p" == . || "$p" == ./ ]]; then salida+=("$raiz/")
    else salida+=("$raiz/$p"); fi
  done
  echo "${salida[*]}"
}

existe_componente() {
  [[ -n "${C_RUTA[$1]+x}" ]]
}

# todos_los_prefijos src|tests
todos_los_prefijos() {
  local n out=()
  for n in "${COMPONENTES[@]}"; do
    # shellcheck disable=SC2206
    if [[ "$1" == src ]]; then out+=(${C_SRC[$n]}); else out+=(${C_TESTS[$n]}); fi
  done
  echo "${out[*]}"
}

# ── Estado ───────────────────────────────────────────────────────────────────

# Lee FEATURE y FASE desde un contenido de estado (por defecto, el del working tree).
# Se parsea en vez de hacer source para no ejecutar nada.
leer_estado() {
  local contenido
  if [[ $# -gt 0 ]]; then contenido="$1"; else contenido="$(cat "$FASES_RAIZ/.fases/estado")"; fi
  FEATURE="$(sed -n 's/^FEATURE=//p' <<<"$contenido")"
  FASE="$(sed -n 's/^FASE=//p' <<<"$contenido")"
}

rama_actual() {
  git -C "$FASES_RAIZ" symbolic-ref --short -q HEAD
}

# ── Documentación ────────────────────────────────────────────────────────────

archivo_feature() {
  (cd "$FASES_RAIZ" && compgen -G "$DIR_DOCS/features/${1:-$FEATURE}-*.md" | head -1)
}

casos_de_uso_de_feature() {
  sed -n 's/^\*\*Casos de uso:\*\*//p' "$FASES_RAIZ/$1" | grep -oE 'UC-[0-9]+' | sort -u
}

# Componentes que declara la feature en la línea "**Componentes:** backend, web".
componentes_de_feature() {
  sed -n 's/^\*\*Componentes:\*\*//p' "$FASES_RAIZ/$1" | tr ',' ' ' | grep -oE '[a-z0-9-]+' | sort -u
}

# Componentes declarados por la feature activa (vacío en LIBRE o si no hay archivo).
componentes_declarados() {
  local f
  [[ -n "$FEATURE" && "$FEATURE" != - ]] || return 0
  f="$(archivo_feature)"
  [[ -z "$f" ]] || componentes_de_feature "$f"
}

archivo_uc() {
  (cd "$FASES_RAIZ" && { compgen -G "$DIR_DOCS/casos-de-uso/$1-*.md"; compgen -G "$DIR_DOCS/casos-de-uso/$1.md"; } | head -1)
}

# IDs de un caso de uso: FP, más cada A<n> de los flujos alternativos y cada E<n> de la tabla de errores.
ids_de_uc() {
  echo FP
  grep -oE '^[[:space:]]*-[[:space:]]*\*\*A[0-9]+\*\*' "$FASES_RAIZ/$1" | grep -oE 'A[0-9]+' | sort -uV
  grep -oE '^\|[[:space:]]*E[0-9]+[[:space:]]*\|' "$FASES_RAIZ/$1" | grep -oE 'E[0-9]+' | sort -uV
}

# ── Permisos ─────────────────────────────────────────────────────────────────

# clasificar <ruta relativa>: deja en GRUPO (maquinaria|config|docs|src|tests|libre)
# y en GRUPO_COMP el componente, si corresponde. Gana el prefijo más largo
# (así tests/e2e/ de un componente e2e le gana a tests/ de un componente en la raíz).
clasificar() {
  local ruta="$1" n p largo=0
  GRUPO=libre GRUPO_COMP=""
  case "$ruta" in
    .fases/config|.fases/componentes/*|.github/*) GRUPO=config; return ;;
    .fases/*|.claude/*) GRUPO=maquinaria; return ;;
  esac
  for p in $RUTAS_DOCS; do [[ "$ruta" == "$p"* ]] && { GRUPO=docs; return; }; done
  for n in "${COMPONENTES[@]}"; do
    for p in ${C_SRC[$n]}; do
      if [[ "$ruta" == "$p"* && ${#p} -gt $largo ]]; then GRUPO=src; GRUPO_COMP="$n"; largo=${#p}; fi
    done
    for p in ${C_TESTS[$n]}; do
      if [[ "$ruta" == "$p"* && ${#p} -gt $largo ]]; then GRUPO=tests; GRUPO_COMP="$n"; largo=${#p}; fi
    done
  done
}

# fase_permite <fase> <grupo> <claude|git>: el grupo es editable en esa fase (sin mirar componentes).
# Claude nunca puede tocar la maquinaria; un humano solo en fase LIBRE.
fase_permite() {
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

# ruta_permitida <ruta> <fase> <claude|git> <componentes declarados>
# Devuelve 0 si en esa fase se puede modificar esa ruta. src/ y tests/ solo son editables
# en los componentes que declara la feature. Deja MOTIVO con la explicación si no.
ruta_permitida() {
  local ruta="$1" fase="$2" modo="$3" declarados=" ${4//$'\n'/ } "
  MOTIVO=""
  clasificar "$ruta"
  [[ "$(basename "$ruta")" == .gitkeep ]] && return 0
  if ! fase_permite "$fase" "$GRUPO" "$modo"; then
    case "$GRUPO" in
      maquinaria) MOTIVO="$ruta es parte de la maquinaria de fases." ;;
      config)     MOTIVO="$ruta es configuración: solo se modifica en fase LIBRE." ;;
      src|tests)  MOTIVO="$ruta es $GRUPO del componente '$GRUPO_COMP', congelado en la fase $fase." ;;
      *)          MOTIVO="$ruta ($GRUPO) está congelado en la fase $fase." ;;
    esac
    return 1
  fi
  if [[ ( "$GRUPO" == src || "$GRUPO" == tests ) && "$declarados" != *" $GRUPO_COMP "* ]]; then
    MOTIVO="$ruta es $GRUPO del componente '$GRUPO_COMP', que la feature no declara en **Componentes:**."
    return 1
  fi
  return 0
}

# Lista los archivos modificados respecto de HEAD (staged, unstaged y no trackeados).
archivos_modificados() {
  git -C "$FASES_RAIZ" diff --name-only --no-renames HEAD 2>/dev/null
  git -C "$FASES_RAIZ" ls-files --others --exclude-standard
}
