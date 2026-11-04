# spec-tdd-template

Plantilla para proyectos que siguen una metodología **spec → tests → implementación** con fases congeladas, pensada para trabajar con Claude Code.

- La documentación (requerimientos, casos de uso con sus errores, API, arquitectura) es la fuente de verdad.
- Los tests se escriben a partir de la documentación, antes del código, y deben fallar.
- El código se escribe solo para hacer pasar los tests.
- Mientras se escriben los tests no se puede tocar la documentación; mientras se implementa no se puede tocar ni la documentación ni los tests.

Es independiente del lenguaje: lo propio de cada stack se configura en `.fases/config`.

## Uso

```bash
gh repo create mi-proyecto --template <usuario>/spec-tdd-template --private --clone
cd mi-proyecto
./setup.sh
.fases/github-setup.sh
```

Requiere `git`, `jq` y `gh`. `setup.sh` activa el hook de git y crea `develop`; `github-setup.sh` configura las protecciones de ramas y los entornos en GitHub (en repos privados, la protección de ramas requiere un plan pago).

## Cómo funciona

| Fase | Se puede tocar | Se sale con |
|---|---|---|
| LIBRE | `docs/`, config, tooling | `.fases/fase iniciar F-001 nombre` |
| SPEC | `docs/`, stubs en `src/` | `.fases/fase avanzar` (gate 1) |
| TESTS | `tests/` | `.fases/fase avanzar` (gate 2) |
| IMPL | `src/` | `.fases/fase avanzar` (gate 3: todo en verde) |

## Ramas y entornos

| Rama | Contiene | Deploy |
|---|---|---|
| `main` | Producción | `production`, al crear un tag `v*` |
| `develop` | Features cerradas, sin release todavía | `staging`, en cada merge |
| `feature/F-NNN-*` | Una feature en curso | `preview`, a mano |
| `release/vX.Y.Z` | Lo que va en el próximo release | — |
| `hotfix/F-NNN-*` | Un bug urgente de producción | `preview`, a mano |

Todo entra por PR y con merge commit. El deploy lo implementa cada proyecto en `scripts/deploy.sh`.

## Enforcement

Las reglas se hacen cumplir con:
- un hook de Claude Code que bloquea ediciones sobre rutas congeladas,
- un hook de Claude Code que detecta cambios hechos por shell,
- un hook de git pre-commit, que también rechaza commits directos en `main` y `develop`,
- CI en GitHub Actions, que en cada PR valida la rama de origen, que la feature esté cerrada y que todo esté en verde,
- tags de git en cada gate, contra los que se verifica que nada congelado cambió.

Detalle completo en [docs/METODOLOGIA.md](docs/METODOLOGIA.md).
