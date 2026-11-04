# Metodología de trabajo

> Este documento define *cómo* se trabaja en este proyecto. Es parte de la plantilla y no depende del lenguaje ni del stack.
> Cambiarlo requiere una decisión explícita registrada en un ADR.

## 1. Principios

1. **La documentación es la fuente de verdad.** Si algo no está documentado, no existe: no se testea ni se implementa.
2. **Los tests son la traducción ejecutable de la documentación.** Cada caso documentado (incluidos los de error) tiene al menos un test que lo verifica.
3. **El código existe solo para hacer pasar los tests.** Nada de funcionalidad "de regalo" que no esté especificada.
4. **Las fases se congelan.** Lo que se cerró en una fase no se toca en las siguientes.
5. **Trazabilidad total.** De cada requerimiento se puede llegar a sus casos de uso, a sus tests y al código que los satisface — y al revés.

## 2. Ciclo de vida de una feature

Hay **una sola feature en curso a la vez** (la única excepción son los hotfixes, §8). Cada feature (`F-NNN`) se desarrolla en su propia rama y pasa por estas fases, siempre en orden:

```
            iniciar          gate 1           gate 2           gate 3
 ┌────────┐ ───────▶ ┌──────┐ ──────▶ ┌───────┐ ──────▶ ┌──────┐ ──────▶ ┌────────┐
 │ LIBRE  │          │ SPEC │         │ TESTS │         │ IMPL │         │ LIBRE  │
 └────────┘          └──────┘         └───────┘         └──────┘         └────────┘
                        ▲                 │  ▲              │
                        └──── retroceso ──┘  └─ retroceso ──┘   (IMPL también puede volver a SPEC)
```

| Fase | Qué se puede modificar | Termina cuando |
|---|---|---|
| **LIBRE** | `docs/`, `.fases/config`, `.github/` y archivos de tooling (sin feature activa) | Se inicia una feature |
| **SPEC** | `docs/` + stubs del contrato en `src/` (solo firmas, §4.3) | La spec está completa y el usuario la aprueba (gate 1) |
| **TESTS** | `tests/` | Todo caso documentado tiene test, la suite falla por la razón correcta, y el usuario aprueba (gate 2) |
| **IMPL** | `src/` | Pasa el 100% de los tests y lint/tipado no tiene errores (gate 3) |

### Reglas duras

- Durante **TESTS** nunca se modifica `docs/` ni `src/`.
- Durante **IMPL** nunca se modifica `docs/` ni `tests/` (incluye fixtures, helpers, mocks y configuración de tests). Las firmas públicas no cambian.
- Las transiciones entre fases las ejecuta **el usuario** desde su terminal (`.fases/fase …`). Claude nunca avanza de fase por su cuenta.
- La fase IMPL termina cuando pasa el 100% de los tests y no hay errores de lint ni de tipos. No hay "casi listo".

### ¿Y si encontramos un error en una fase congelada?

Pasa: durante los tests se descubre que la spec es ambigua, o durante la implementación que un test es imposible de satisfacer. **No se corrige en el lugar.** El procedimiento es:

1. Se detiene la fase actual y Claude reporta el problema al usuario (qué caso, qué está mal, evidencia).
2. El usuario decide el **retroceso** formal a la fase donde está el error: `.fases/fase retroceder SPEC|TESTS`.
3. Si se volvió a SPEC, la incidencia se registra en `docs/features/F-NNN-*.md` → sección *Incidencias*.
4. Se corrige y se vuelven a pasar **todos** los gates intermedios. Ej.: error de spec detectado en IMPL → SPEC → gate 1 → ajustar tests → gate 2 → IMPL.

Así la regla nunca se rompe: no se edita lo congelado, se *descongela* explícitamente con trazabilidad.

## 3. Estructura del repositorio

```
.
├── CLAUDE.md                     # Reglas operativas para Claude (resumen de este doc)
├── setup.sh                      # Se corre una vez al crear el proyecto
├── .claude/settings.json         # Hooks de Claude Code
├── .github/workflows/            # CI (ci.yml) y deploys (deploy.yml)
├── scripts/deploy.sh             # Deploy a un entorno; lo completa cada proyecto
├── .fases/
│   ├── estado                    # Feature y fase activas (solo lo cambia la CLI)
│   ├── config                    # Comandos y rutas propios del stack del proyecto
│   ├── fase                      # CLI de transiciones y verificaciones
│   ├── lib.sh                    # Lógica compartida por la CLI y los hooks
│   ├── hooks/                    # Hooks de Claude Code
│   ├── githooks/pre-commit       # Hook de git
│   └── github-setup.sh           # Configura el repo en GitHub (ramas, protecciones)
├── docs/
│   ├── METODOLOGIA.md            # Este documento
│   ├── vision.md                 # Qué es el proyecto, para quién, objetivos, fuera de alcance
│   ├── glosario.md               # Términos del dominio
│   ├── plantillas/               # Plantillas de UC, feature, ADR
│   ├── arquitectura/
│   │   ├── overview.md           # Componentes, diagramas, flujos de datos
│   │   └── adr/NNNN-*.md         # Architecture Decision Records
│   ├── requerimientos/
│   │   ├── funcionales.md        # RF-NNN
│   │   └── no-funcionales.md     # RNF-NNN (performance, seguridad, etc.)
│   ├── casos-de-uso/UC-NNN-*.md  # Un archivo por caso de uso
│   ├── api/                      # Contratos (OpenAPI / firmas / esquemas)
│   └── features/F-NNN-*.md       # Alcance de cada feature, historial, incidencias
├── tests/
└── src/
```

Las rutas `docs/`, `src/` y `tests/` se pueden ajustar en `.fases/config` (por ejemplo, para incluir archivos de configuración de tests como parte de `tests/`).

## 4. Artefactos de documentación

Las plantillas están en [`docs/plantillas/`](plantillas/).

### 4.1 Requerimientos (`RF-NNN`, `RNF-NNN`)
Cada uno: ID, descripción, prioridad, criterio de aceptación verificable, casos de uso que lo cubren.

### 4.2 Casos de uso (`UC-NNN`)
Flujo principal, flujos alternativos (`A1`, `A2`…), errores (`E1`, `E2`…), postcondiciones y **ejemplos concretos**. Los ejemplos son los que se convierten casi literalmente en tests. Plantilla: [`plantillas/caso-de-uso.md`](plantillas/caso-de-uso.md).

### 4.3 API y stubs del contrato
Contratos formales: endpoints / funciones públicas, tipos, códigos de error. Cada error de un caso de uso mapea a un error de API concreto.

En la fase SPEC, además del documento, se crean en `src/` los **stubs** de la API pública: firmas, tipos y errores, con cuerpos que solo lanzan `NotImplemented` (o el equivalente del lenguaje). Son la versión ejecutable del contrato y permiten que los tests compilen y fallen por la razón correcta.

- Durante IMPL se rellenan los cuerpos, pero **las firmas públicas no cambian**. Cambiar una firma es un error de spec → retroceso a SPEC.
- Si `.fases/config` define `FIRMAS_CMD`, el gate 1 guarda la salida (la lista de firmas públicas) y el gate 3 verifica que siga idéntica.

### 4.4 ADRs (decisiones)
Toda decisión relevante (tecnología, patrón, trade-off) se registra: *Contexto → Decisión → Alternativas consideradas → Consecuencias*. Los ADRs no se editan: si una decisión cambia, se crea uno nuevo que reemplaza al anterior. **`ADR-0001` es siempre el stack** del proyecto, y define lo que va en `.fases/config`.

### 4.5 Feature (`F-NNN`)
Agrupa casos de uso a implementar juntos. Contiene: alcance (qué UC incluye), fuera de alcance e incidencias. El historial de fases queda en los tags de git. La línea `**Casos de uso:** UC-001, UC-002` es la que lee el chequeo de cobertura.

### 4.6 Preguntas abiertas
Cualquier duda pendiente en la documentación se marca con `[ABIERTO]`. El gate 1 no pasa mientras quede alguna en `docs/` (fuera de `plantillas/` y de este documento).

## 5. Convenciones de tests

- **Trazabilidad en el nombre:** cada test incluye el ID del caso que cubre, sin guiones: `UC003_FP` (flujo principal), `UC003_A1` (alternativo), `UC003_E2` (error). Ej.: `test_UC003_E2_usuario_inexistente_devuelve_404`.
- **Cobertura de especificación:** `.fases/fase cobertura` verifica que cada flujo principal, alternativo y error de los UC de la feature tenga al menos un test. Es parte del gate 2.
- **Rojo por la razón correcta:** los tests importan los stubs y fallan con `NotImplemented` o con una aserción, nunca con errores de import, sintaxis o setup.
- **Niveles:** unitarios (lógica de dominio), integración (componentes + infraestructura), aceptación (casos de uso completos desde la API).

## 6. Gates

Cada gate se ejecuta con `.fases/fase avanzar`. La CLI corre los chequeos automáticos, pide confirmación al usuario, crea el tag de git y commitea el cambio de fase. `.fases/fase verificar` corre los mismos chequeos sin avanzar.

**Gate 1 — SPEC → TESTS** (tag `F-NNN/spec-aprobada`)
- [auto] Existe el archivo de la feature y todos sus UC.
- [auto] No quedan `[ABIERTO]` en `docs/`.
- [auto] Los stubs pasan lint y tipado.
- [manual] Cada UC tiene flujo principal, alternativos, errores y ejemplos; contratos de API y ADRs completos.

**Gate 2 — TESTS → IMPL** (tag `F-NNN/tests-aprobados`)
- [auto] Cobertura de especificación completa.
- [auto] La suite de tests falla (no hay implementación).
- [manual] Los tests fallan por la razón correcta; el usuario revisó los tests.

**Gate 3 — IMPL → LIBRE** (tag `F-NNN/cerrada`)
- [auto] 100% de la suite en verde (incluidas las features anteriores).
- [auto] Lint y tipado sin errores.
- [auto] Desde `F-NNN/tests-aprobados` no cambió nada en `docs/` ni `tests/`.
- [auto] Firmas públicas idénticas a las del gate 1 (si hay `FIRMAS_CMD`).

## 7. Enforcement

1. **`.fases/estado`** indica la feature y fase activas. Solo lo cambia la CLI.
2. **La CLI pide confirmación por terminal interactiva.** Claude no tiene terminal interactiva, así que no puede avanzar ni retroceder fases.
3. **Hook de Claude Code (PreToolUse)**: bloquea `Edit`/`Write` sobre rutas congeladas según la fase, y siempre sobre la maquinaria (`.fases/`, `.claude/`).
4. **Hook de Claude Code (PostToolUse sobre Bash)**: si un comando de shell modificó una ruta congelada, se lo informa a Claude de inmediato para que lo revierta.
5. **Hook de git pre-commit**: rechaza commits que modifiquen rutas congeladas según la fase (protege también contra ediciones manuales), y cualquier commit directo en `main` o `develop`. Restaurar un archivo congelado a su versión del último gate siempre está permitido.
6. **Tags de git por gate**: permiten verificar con `git diff <tag>` que lo congelado no cambió; el gate 3 lo hace automáticamente.
7. **CI en GitHub Actions**: en cada PR verifica que la rama de origen sea válida para el destino, que la feature esté cerrada y que pasen tests, lint y tipado. Con la protección de ramas de GitHub, un PR que no pasa el CI no se puede mergear.

Estos mecanismos evitan errores y descuidos, no un sabotaje deliberado (`git commit --no-verify` existe). La última garantía es el gate 3, que compara contra los tags.

## 8. Ramas, releases y entornos

```
main      ──●──────────────────────────────●────────────●──────▶  producción (tags v1.0.0, v1.0.1…)
             \                            / \          /
              \                 release/v1.0  hotfix/F-004
               \                         /     \
develop   ──────●───────●───────●───────●───────●──────────────▶  staging
                 \     /  \     /
            feature/F-001  feature/F-002
```

| Rama | Contiene | Sale de | Entra a | Deploy |
|---|---|---|---|---|
| `main` | Producción | — | — | Producción, al crear un tag `v*` |
| `develop` | Features cerradas, todavía sin release | `main` | `main` (vía `release/*`) | Staging, en cada merge |
| `feature/F-NNN-*` | Una feature en curso, en todas sus fases | `develop` | `develop` | Preview manual |
| `release/vX.Y.Z` | Lo que va en el próximo release | `develop` | `main` | — |
| `hotfix/F-NNN-*` | Un bug urgente de producción | `main` | `main`, y después `main` → `develop` | Preview manual |
| `docs/*`, `chore/*` | Trabajo en fase LIBRE (visión, ADRs, tooling) | `develop` | `develop` | — |

### Reglas

1. **Nunca se commitea directo en `main` ni en `develop`.** Todo entra por pull request.
2. **Los PR solo se abren con la feature cerrada** (gate 3 pasado, rama en `LIBRE`). `develop` y `main` siempre están en verde.
3. **Siempre merge commit, nunca squash ni rebase.** Así se conservan el historial de fases y los tags de cada gate.
4. **No se trae `develop` a una feature en curso.** Mientras la feature está en SPEC, TESTS o IMPL, su base no cambia. Si al abrir el PR hay conflictos, se resuelven con un retroceso formal.
5. **Los tags se suben con la rama:** `git push --follow-tags`.

### Features
1. Desde `develop` actualizado: `.fases/fase iniciar F-NNN nombre` crea la rama `feature/F-NNN-nombre` y pasa a SPEC.
2. Ciclo completo de fases en la rama. Para probar a mitad de camino: deploy de preview (abajo).
3. Con la feature cerrada: `git push --follow-tags` y PR a `develop`. Al mergear, se despliega a staging.

### Releases
1. Elegir hasta qué commit de `develop` entra en el release (puede ser cualquiera, no necesariamente el último).
2. `git switch -c release/vX.Y.Z <commit>` y `git push -u origin release/vX.Y.Z`.
3. PR de `release/vX.Y.Z` a `main`. En la rama de release solo se permiten ajustes de fase LIBRE (por ejemplo, el changelog).
4. Después del merge, crear el tag `vX.Y.Z` sobre `main` (o un *Release* desde la web de GitHub). Eso dispara el deploy a producción.
5. Si hubo commits en la rama de release, PR de `main` a `develop` para no perderlos.

Versionado semántico: `X` cambios incompatibles, `Y` features nuevas, `Z` hotfixes.

### Hotfixes
1. Desde `main` actualizado: `.fases/fase iniciar F-NNN nombre` crea la rama `hotfix/F-NNN-nombre`.
2. Ciclo completo: un bug en producción es un caso que faltaba o estaba mal en la spec. Se documenta, se escribe un test que lo reproduce (y falla), y se corrige.
3. PR a `main`, tag `vX.Y.Z+1` y deploy a producción.
4. PR de `main` a `develop`.

### Entornos
| Entorno | Se despliega | Para qué |
|---|---|---|
| **production** | Al crear un tag `v*` en `main` | Usuarios reales |
| **staging** | En cada push a `develop` | Probar features cerradas integradas, antes de un release |
| **preview** | A mano, desde cualquier rama (Actions → Deploy → *Run workflow*) | Mirar una feature en curso sin mergearla |

El deploy en sí depende del stack: lo implementa `scripts/deploy.sh <entorno>` y se decide en un ADR de infraestructura. Los secretos de cada entorno se cargan en los *Environments* de GitHub; en `production` conviene exigir aprobación manual.

## 9. Primeros pasos en un proyecto nuevo

1. Crear el repo desde la plantilla, correr `./setup.sh` (crea `develop`) y `.fases/github-setup.sh` (protecciones en GitHub).
2. En una rama `docs/inicio` desde `develop`, en fase LIBRE: completar `docs/vision.md`, `docs/glosario.md` y escribir `ADR-0001` (stack).
3. Completar `.fases/config` con los comandos de tests, lint y tipado del stack, instalar el tooling y ajustar `.gitignore` (las transiciones exigen el árbol limpio).
4. Completar los pasos marcados en `.github/workflows/ci.yml` para instalar el stack en el CI.
5. PR a `develop`. Después, desde `develop`: `.fases/fase iniciar F-001 <nombre>`.
