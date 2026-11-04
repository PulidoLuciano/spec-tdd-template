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
```

Requiere `git` y `jq`.

## Cómo funciona

| Fase | Se puede tocar | Se sale con |
|---|---|---|
| LIBRE | `docs/`, config, tooling | `.fases/fase iniciar F-001 nombre` |
| SPEC | `docs/`, stubs en `src/` | `.fases/fase avanzar` (gate 1) |
| TESTS | `tests/` | `.fases/fase avanzar` (gate 2) |
| IMPL | `src/` | `.fases/fase avanzar` (gate 3: todo en verde) |

Las reglas se hacen cumplir con:
- un hook de Claude Code que bloquea ediciones sobre rutas congeladas,
- un hook de Claude Code que detecta cambios hechos por shell,
- un hook de git pre-commit,
- tags de git en cada gate, contra los que se verifica que nada congelado cambió.

Detalle completo en [docs/METODOLOGIA.md](docs/METODOLOGIA.md).
