# Reglas de trabajo

Este proyecto sigue una metodología spec → tests → implementación con fases congeladas.
La metodología completa está en [docs/METODOLOGIA.md](docs/METODOLOGIA.md): leerla antes de trabajar.

## Reglas no negociables

1. Antes de modificar cualquier archivo, correr `.fases/fase estado` para saber la feature y la fase activas.
2. **LIBRE:** solo `docs/`, configuración (`.fases/config`, `.fases/componentes/`, `.github/`) y tooling. No hay feature activa.
3. **SPEC:** solo `docs/` y los stubs del contrato en el `src` de los componentes declarados (firmas que lanzan `NotImplemented`).
4. **TESTS:** solo los `tests` de los componentes declarados. Nunca `docs/` ni ningún `src`.
5. **IMPL:** solo el `src` de los componentes declarados. Nunca `docs/` ni ningún `tests` (incluye fixtures, helpers y config de tests). Las firmas públicas no cambian.
   Los componentes que la feature no declara en `**Componentes:**` están congelados siempre. `.fases/fase componentes` lista las rutas de cada uno.
6. Nunca modificar `.fases/` ni `.claude/` (y `.github/` solo en fase LIBRE), ni intentar esquivar los hooks (`--no-verify`, editar por shell, emular una terminal).
7. Nunca cambiar de fase ni publicar versiones: `iniciar`, `avanzar`, `retroceder` y `publicar` los ejecuta el usuario en su terminal. Claude puede correr `estado`, `verificar`, `cobertura`, `componentes`, `pendientes` y, en fase LIBRE, `componente agregar`.
8. Si se encuentra un error en una fase congelada: detenerse, reportarlo al usuario con evidencia y proponer un retroceso. Nunca corregirlo en el lugar.
9. Cada test lleva en el nombre el ID del caso que cubre: `UC003_FP`, `UC003_A1`, `UC003_E2`.
10. Una feature termina cuando `.fases/fase verificar` pasa en IMPL: 100% de los tests de todos los componentes en verde y lint/tipado sin errores.

## Ramas (ver docs/METODOLOGIA.md §9)

11. Nunca commitear en `main` ni en `develop`. Cada feature vive en `feature/F-NNN-*` (o `hotfix/F-NNN-*`), que crea `.fases/fase iniciar`.
12. Nunca hacer push, abrir PR, mergear ni crear tags de versión sin que el usuario lo pida explícitamente.
13. Siempre merge commit, nunca squash ni rebase. Los tags se suben con `git push --follow-tags`.
14. No traer `develop` a una feature en curso.
