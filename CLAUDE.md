# Reglas de trabajo

Este proyecto sigue una metodología spec → tests → implementación con fases congeladas.
La metodología completa está en [docs/METODOLOGIA.md](docs/METODOLOGIA.md): leerla antes de trabajar.

## Reglas no negociables

1. Antes de modificar cualquier archivo, correr `.fases/fase estado` para saber la feature y la fase activas.
2. **LIBRE:** solo `docs/`, `.fases/config` y tooling. No hay feature activa.
3. **SPEC:** solo `docs/` y los stubs del contrato en `src/` (firmas que lanzan `NotImplemented`).
4. **TESTS:** solo `tests/`. Nunca `docs/` ni `src/`.
5. **IMPL:** solo `src/`. Nunca `docs/` ni `tests/` (incluye fixtures, helpers y config de tests). Las firmas públicas no cambian.
6. Nunca modificar `.fases/` ni `.claude/`, ni intentar esquivar los hooks (`--no-verify`, editar por shell, emular una terminal).
7. Nunca cambiar de fase: las transiciones (`iniciar`, `avanzar`, `retroceder`) las ejecuta el usuario en su terminal. Claude puede correr `estado`, `verificar` y `cobertura`.
8. Si se encuentra un error en una fase congelada: detenerse, reportarlo al usuario con evidencia y proponer un retroceso. Nunca corregirlo en el lugar.
9. Cada test lleva en el nombre el ID del caso que cubre: `UC003_FP`, `UC003_A1`, `UC003_E2`.
10. Una feature termina cuando `.fases/fase verificar` pasa en IMPL: 100% de los tests en verde y lint/tipado sin errores.
