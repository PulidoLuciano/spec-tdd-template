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

Hay **una sola feature en curso a la vez** (la única excepción son los hotfixes, §9). Cada feature (`F-NNN`) se desarrolla en su propia rama, declara qué componentes toca (§8) y pasa por estas fases, siempre en orden:

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
| **LIBRE** | `docs/`, configuración (`.fases/config`, `.fases/componentes/`, `.github/`) y tooling. No hay feature activa | Se inicia una feature |
| **SPEC** | `docs/` + stubs del contrato en el `src` de los componentes declarados (§4.3) | La spec está completa y el usuario la aprueba (gate 1) |
| **TESTS** | `tests` de los componentes declarados | Todo caso documentado tiene test, los tests fallan por la razón correcta, y el usuario aprueba (gate 2) |
| **IMPL** | `src` de los componentes declarados | Pasan el 100% de los tests de **todos** los componentes y lint/tipado no tiene errores (gate 3) |

Los archivos de un componente que no son ni `src` ni `tests` (manifiestos de dependencias, lockfiles, configuración de build) se pueden tocar en cualquier fase.

### Reglas duras

- Durante **TESTS** nunca se modifica `docs/` ni ningún `src`.
- Durante **IMPL** nunca se modifica `docs/` ni ningún `tests` (incluye fixtures, helpers, mocks y configuración de tests). Las firmas públicas no cambian.
- Los componentes que la feature no declara están congelados en todas las fases.
- Las transiciones entre fases las ejecuta **el usuario** desde su terminal (`.fases/fase …`). Claude nunca avanza de fase por su cuenta.
- La fase IMPL termina cuando pasan el 100% de los tests y no hay errores de lint ni de tipos. No hay "casi listo".

### ¿Y si encontramos un error en una fase congelada?

Pasa: durante los tests se descubre que la spec es ambigua, o durante la implementación que un test es imposible de satisfacer. **No se corrige en el lugar.** El procedimiento es:

1. Se detiene la fase actual y Claude reporta el problema al usuario (qué caso, qué está mal, evidencia).
2. El usuario decide el **retroceso** formal a la fase donde está el error: `.fases/fase retroceder SPEC|TESTS`.
3. Si se volvió a SPEC, la incidencia se registra en `docs/features/F-NNN-*.md` → sección *Incidencias*.
4. Se corrige y se vuelven a pasar **todos** los gates intermedios. Ej.: error de spec detectado en IMPL → SPEC → gate 1 → ajustar tests → gate 2 → IMPL.

Así la regla nunca se rompe: no se edita lo congelado, se *descongela* explícitamente con trazabilidad. Lo mismo vale si a mitad de camino la feature necesita tocar un componente que no declaró: se retrocede a SPEC y se agrega a **Componentes:**.

## 3. Estructura del repositorio

```
.
├── CLAUDE.md                     # Reglas operativas para Claude (resumen de este doc)
├── setup.sh                      # Se corre una vez al crear el proyecto
├── .claude/settings.json         # Hooks de Claude Code
├── .github/workflows/
│   ├── ci.yml                    # CI: reglas + un job por componente
│   └── deploy-<componente>.yml   # Deploy de cada componente a staging / production / preview
├── .fases/
│   ├── estado                    # Feature y fase activas (solo lo cambia la CLI)
│   ├── config                    # Configuración global (rutas de la documentación)
│   ├── componentes/<nombre>.conf # Rutas y comandos de cada componente
│   ├── fase                      # CLI: fases, componentes, versiones, CI
│   ├── lib.sh                    # Lógica compartida por la CLI y los hooks
│   ├── plantillas/               # Lo que usa "componente agregar"
│   ├── firmas/                   # Firmas públicas guardadas en cada gate 1
│   ├── hooks/                    # Hooks de Claude Code
│   ├── githooks/pre-commit       # Hook de git
│   └── github-setup.sh           # Configura el repo en GitHub (ramas, protecciones, entornos)
├── docs/                         # La spec del producto: una sola, para todos los componentes
│   ├── METODOLOGIA.md            # Este documento
│   ├── vision.md                 # Qué es el proyecto, para quién, objetivos, fuera de alcance
│   ├── glosario.md               # Términos del dominio
│   ├── plantillas/               # Plantillas de UC, feature, ADR, requerimiento
│   ├── arquitectura/
│   │   ├── overview.md           # Componentes, diagramas, flujos de datos
│   │   └── adr/NNNN-*.md         # Architecture Decision Records
│   ├── requerimientos/
│   │   ├── funcionales.md        # RF-NNN
│   │   └── no-funcionales.md     # RNF-NNN (performance, seguridad, compatibilidad, etc.)
│   ├── casos-de-uso/UC-NNN-*.md  # Un archivo por caso de uso
│   ├── api/                      # Contratos entre componentes (OpenAPI, eventos, esquemas)
│   └── features/F-NNN-*.md       # Alcance de cada feature, componentes, incidencias
└── <componentes>/                # Donde los ubique cada proyecto (§8)
```

## 4. Artefactos de documentación

Las plantillas están en [`docs/plantillas/`](plantillas/).

### 4.1 Requerimientos (`RF-NNN`, `RNF-NNN`)
Cada uno: ID, descripción, prioridad, criterio de aceptación verificable, casos de uso que lo cubren.

### 4.2 Casos de uso (`UC-NNN`)
Flujo principal, flujos alternativos (`A1`, `A2`…), errores (`E1`, `E2`…), postcondiciones y **ejemplos concretos**. Los ejemplos son los que se convierten casi literalmente en tests. Describen el comportamiento del producto, no de un componente. Plantilla: [`plantillas/caso-de-uso.md`](plantillas/caso-de-uso.md).

### 4.3 Contratos y stubs
Contratos formales: endpoints / funciones públicas, tipos, códigos de error. Cada error de un caso de uso mapea a un error de API concreto. **Cuando hay varios componentes, el contrato entre ellos (`docs/api/`) es lo primero que se define**: es lo que permite que cada componente se testee por su lado.

En la fase SPEC, además del documento, se crean en el `src` de cada componente declarado los **stubs** del contrato: firmas, tipos y errores, con cuerpos que solo lanzan `NotImplemented` (o el equivalente del lenguaje). Si el contrato está en un formato como OpenAPI, conviene generar los stubs del servidor y los clientes a partir de él. Los stubs permiten que los tests compilen y fallen por la razón correcta.

- Durante IMPL se rellenan los cuerpos, pero **las firmas públicas no cambian**. Cambiar una firma o el contrato es un error de spec → retroceso a SPEC.
- Si el componente define `FIRMAS_CMD`, el gate 1 guarda la salida (sus firmas públicas) y el gate 3 verifica que siga idéntica.

### 4.4 ADRs (decisiones)
Toda decisión relevante (tecnología, patrón, trade-off) se registra: *Contexto → Decisión → Alternativas consideradas → Consecuencias*. Los ADRs no se editan: si una decisión cambia, se crea uno nuevo que reemplaza al anterior. **`ADR-0001` es siempre el stack**: qué componentes tiene el proyecto y con qué tecnología se construye cada uno.

### 4.5 Feature (`F-NNN`)
Agrupa casos de uso a implementar juntos. Contiene: alcance, fuera de alcance e incidencias. El historial de fases queda en los tags de git. Dos líneas las lee la CLI:
- `**Casos de uso:** UC-001, UC-002` — para el chequeo de cobertura.
- `**Componentes:** backend, web` — qué componentes puede tocar la feature.

### 4.6 Preguntas abiertas
Cualquier duda pendiente en la documentación se marca con `[ABIERTO]`. El gate 1 no pasa mientras quede alguna en `docs/` (fuera de `plantillas/` y de este documento).

## 5. Convenciones de tests

- **Trazabilidad en el nombre:** cada test incluye el ID del caso que cubre, sin guiones: `UC003_FP` (flujo principal), `UC003_A1` (alternativo), `UC003_E2` (error). Ej.: `test_UC003_E2_usuario_inexistente_devuelve_404`. Vale en cualquier lenguaje.
- **Cobertura de especificación:** `.fases/fase cobertura` verifica que cada flujo principal, alternativo y error de los UC de la feature tenga al menos un test, en cualquier componente. Es parte del gate 2.
- **Rojo por la razón correcta:** los tests importan los stubs y fallan con `NotImplemented` o con una aserción, nunca con errores de import, sintaxis o setup.
- **Niveles:**
  - *Unitarios e integración*, dentro de cada componente, contra el contrato.
  - Los clientes (web, desktop, mobile…) mockean al servidor **a partir del contrato**, no a mano.
  - *Aceptación (e2e)*: los casos de uso completos, cruzando componentes. Van en un componente de solo tests (§8).

## 6. Gates

Cada gate se ejecuta con `.fases/fase avanzar`. La CLI corre los chequeos automáticos, pide confirmación al usuario, crea el tag de git y commitea el cambio de fase. `.fases/fase verificar` corre los mismos chequeos sin avanzar.

**Gate 1 — SPEC → TESTS** (tag `F-NNN/spec-aprobada`)
- [auto] Existe el archivo de la feature, todos sus UC y todos sus componentes.
- [auto] No quedan `[ABIERTO]` en `docs/`.
- [auto] Los stubs de cada componente declarado pasan lint y tipado.
- [manual] Cada UC tiene flujo principal, alternativos, errores y ejemplos; contratos y ADRs completos.

**Gate 2 — TESTS → IMPL** (tag `F-NNN/tests-aprobados`)
- [auto] Cobertura de especificación completa.
- [auto] Desde `F-NNN/spec-aprobada` no cambió nada en `docs/` ni en ningún `src`.
- [auto] Los tests de **cada** componente declarado fallan (si un componente está declarado, tiene que tener tests nuevos).
- [manual] Los tests fallan por la razón correcta; el usuario revisó los tests.

**Gate 3 — IMPL → LIBRE** (tag `F-NNN/cerrada`)
- [auto] Tests, lint y tipado en verde en **todos** los componentes, no solo los declarados: ningún cambio rompe otro componente.
- [auto] Desde `F-NNN/tests-aprobados` no cambió nada en `docs/` ni en ningún `tests`.
- [auto] Firmas públicas idénticas a las del gate 1 (en los componentes con `FIRMAS_CMD`).

## 7. Enforcement

1. **`.fases/estado`** indica la feature y fase activas. Solo lo cambia la CLI.
2. **La CLI pide confirmación por terminal interactiva** para las transiciones y para publicar versiones. Claude no tiene terminal interactiva, así que no puede hacerlas.
3. **Hook de Claude Code (PreToolUse)**: bloquea `Edit`/`Write` sobre rutas congeladas según la fase y los componentes declarados, y siempre sobre la maquinaria (`.fases/`, `.claude/`).
4. **Hook de Claude Code (PostToolUse sobre Bash)**: si un comando de shell modificó una ruta congelada, se lo informa a Claude de inmediato para que lo revierta.
5. **Hook de git pre-commit**: rechaza commits que modifiquen rutas congeladas (protege también contra ediciones manuales), y cualquier commit directo en `main` o `develop`. Restaurar un archivo congelado a su versión del último gate siempre está permitido.
6. **Tags de git por gate**: permiten verificar con `git diff <tag>` que lo congelado no cambió; los gates 2 y 3 lo hacen automáticamente.
7. **CI en GitHub Actions**: en cada PR verifica que la rama de origen sea válida para el destino, que la feature esté cerrada, y corre tests, lint y tipado de cada componente. Con la protección de ramas de GitHub, un PR que no pasa el CI no se puede mergear.

Estos mecanismos evitan errores y descuidos, no un sabotaje deliberado (`git commit --no-verify` existe). La última garantía son los gates, que comparan contra los tags.

## 8. Componentes

Un proyecto tiene uno o más **componentes**: backend, web, desktop, mobile, una librería, tests e2e… Cada componente tiene su lenguaje, sus comandos y su forma de desplegarse. La plantilla no trae ninguno: cada proyecto crea los que tiene, y puede agregar más en cualquier momento.

Un componente existe si tiene su archivo `.fases/componentes/<nombre>.conf`. Se crean en fase LIBRE con:

```bash
.fases/fase componente agregar <nombre> <ruta> [--solo-tests]
```

Esto crea la carpeta con `src/` y `tests/`, el archivo de configuración, el job del componente en `ci.yml` y su `deploy-<nombre>.yml`. Después hay que completar los comandos y la preparación del stack en esos archivos.

**Ejemplos:**

| Proyecto | Comandos |
|---|---|
| Un solo componente, en la raíz | `componente agregar app .` |
| Backend + web | `componente agregar backend backend`<br>`componente agregar web web` |
| Backend + web + mobile + e2e | `componente agregar backend apps/backend`<br>`componente agregar web apps/web`<br>`componente agregar mobile apps/mobile`<br>`componente agregar e2e tests/e2e --solo-tests` |

Un componente `--solo-tests` (como `e2e`) no tiene `src` ni deploy: toda su carpeta cuenta como tests.

**Compatibilidad entre versiones.** Si hay clientes que se instalan (mobile, desktop), en producción conviven versiones viejas que la gente no actualizó. El servidor nuevo tiene que seguir funcionando con ellas. Conviene escribirlo desde el principio como requerimiento no funcional: versionado de la API y cuántas versiones atrás se soportan.

## 9. Ramas, versiones y entornos

```
main      ──●────────────────────────────────●──────────────●──────▶  producción (tags backend/v1.2.0, web/v1.5.0…)
             \                              / \            /
              \                  release/2026-11  hotfix/F-004
               \                           /     \
develop   ──────●───────●───────●─────────●───────●───────────────▶  staging
                 \     /  \     /
            feature/F-001  feature/F-002
```

| Rama | Contiene | Sale de | Entra a |
|---|---|---|---|
| `main` | Producción | — | — |
| `develop` | Features cerradas, todavía sin publicar | `main` | `main` (vía `release/*`) |
| `feature/F-NNN-*` | Una feature en curso, en todas sus fases | `develop` | `develop` |
| `release/<nombre>` | Lo que va en la próxima salida a producción | `develop` | `main` |
| `hotfix/F-NNN-*` | Un bug urgente de producción | `main` | `main`, y después `main` → `develop` |
| `docs/*`, `chore/*` | Trabajo en fase LIBRE (visión, ADRs, componentes, tooling) | `develop` | `develop` |

### Reglas

1. **Nunca se commitea directo en `main` ni en `develop`.** Todo entra por pull request.
2. **Los PR solo se abren con la feature cerrada** (gate 3 pasado, rama en `LIBRE`). `develop` y `main` siempre están en verde.
3. **Siempre merge commit, nunca squash ni rebase.** Así se conservan el historial de fases y los tags de cada gate.
4. **No se trae `develop` a una feature en curso.** Mientras la feature está en SPEC, TESTS o IMPL, su base no cambia. Si al abrir el PR hay conflictos, se resuelven con un retroceso formal.
5. **Los tags se suben con la rama:** `git push --follow-tags`.

### Features
1. Desde `develop` actualizado: `.fases/fase iniciar F-NNN nombre` crea la rama `feature/F-NNN-nombre` y pasa a SPEC.
2. Ciclo completo de fases en la rama. Para probar a mitad de camino: deploy de preview (abajo).
3. Con la feature cerrada: `git push --follow-tags` y PR a `develop`. Al mergear, los componentes que cambiaron se despliegan a staging.

### Versiones y releases

**Cada componente tiene su propia versión**, con tags `<componente>/vX.Y.Z` (versionado semántico: `X` cambios incompatibles, `Y` features nuevas, `Z` hotfixes). Así un hotfix del backend no obliga a publicar mobile en las tiendas.

1. Elegir hasta qué commit de `develop` entra en el release (puede ser cualquiera, no necesariamente el último).
2. `git switch -c release/<nombre> <commit>` y `git push -u origin release/<nombre>`. El nombre es libre (`release/2026-11`, `release/login`).
3. PR de `release/<nombre>` a `main`. En la rama de release solo se permiten ajustes de fase LIBRE (por ejemplo, el changelog).
4. Después del merge, desde `main`: `.fases/fase pendientes` muestra qué componentes tienen cambios sin publicar. Para cada uno: `.fases/fase publicar <componente> vX.Y.Z`. Eso crea y sube el tag, y el tag dispara el deploy a producción de ese componente.
5. Si hubo commits en la rama de release, PR de `main` a `develop` para no perderlos.

### Hotfixes
1. Desde `main` actualizado: `.fases/fase iniciar F-NNN nombre` crea la rama `hotfix/F-NNN-nombre`.
2. Ciclo completo: un bug en producción es un caso que faltaba o estaba mal en la spec. Se documenta, se escribe un test que lo reproduce (y falla), y se corrige.
3. PR a `main` y `.fases/fase publicar <componente> vX.Y.Z+1`.
4. PR de `main` a `develop`.

### Entornos
| Entorno | Se despliega | Para qué |
|---|---|---|
| **production** | Al publicar una versión (`<componente>/v*` en `main`) | Usuarios reales |
| **staging** | En cada push a `develop`, solo los componentes que cambiaron | Probar features cerradas integradas, antes de un release |
| **preview** | A mano, desde cualquier rama (Actions → Deploy &lt;componente&gt; → *Run workflow*) | Mirar una feature en curso sin mergearla |

Qué significa "desplegar" depende del componente: subir a un servidor, publicar un sitio, subir un build a TestFlight / Play internal testing, o publicar instaladores. Se implementa en `deploy-<componente>.yml` y se decide en un ADR de infraestructura. Los secretos de cada entorno se cargan en los *Environments* de GitHub; en `production` conviene exigir aprobación manual.

## 10. Primeros pasos en un proyecto nuevo

1. Crear el repo desde la plantilla, correr `./setup.sh` (crea `develop`) y `.fases/github-setup.sh` (protecciones en GitHub).
2. En una rama `docs/inicio` desde `develop`, en fase LIBRE: completar `docs/vision.md`, `docs/glosario.md` y escribir `ADR-0001` (componentes y stack).
3. Crear cada componente con `.fases/fase componente agregar`, completar su `.conf`, su job en `ci.yml` y su `deploy-<nombre>.yml`, instalar el tooling y ajustar `.gitignore` (las transiciones exigen el árbol limpio).
4. PR a `develop`. Después, desde `develop`: `.fases/fase iniciar F-001 <nombre>`.
