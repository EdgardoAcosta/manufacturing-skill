# Obsidian

Vault `~/my-second-brain`, Obsidian MCP. Rules in the vault's `AGENTS.md`: read only folders I name in the request (a request that says "check the manufacturing notes" names `EF/projects/manufacturing/`). Elsewhere, only check that a filename exists. `EF/people/`, `EF/hiring/` and credential notes need that exact folder named. Never delete notes; never write secrets. Spanish for manufacturing notes.

## Manufacturing notes (`EF/projects/manufacturing/`)
| Note | Use |
|---|---|
| `migration/bugs-materials.md` | "Errores comunes (revisar primero)" = 15-pattern UI checklist for every PR test (read only that top section, the note is large); Dali QA matrix (single table, short Estado values); "Barrido de patrones (2026-10-02)" table |
| `migration/bugs-mobile.md` | mobile app bug tracker |
| `migration/pvo.md` | PVO migration notes |
| `migration/roles-y-permisos.md` | roles and permissions of the new system |
| `migration/ops-proxy-inventario.md` | OPS proxy / inventory plan |
| `migration/staging-full-pass-2026-10-14.md` | last full staging pass results |
| `servicios-externos.md`, `auth-propuesta-rutas-abiertas.md`, `kafka-inventario-plan-de-accion.md`, `impresoras-zebra-cups.md`, `apk-firmado-por-play-a-s3.md` | design notes |

Other EF folders (need naming in the request): `EF/projects/migracion-legacy/` (Feedback migración - Menú materiales), `EF/projects/legacy-repos/` (legacy maintenance, telemetry), `EF/reference/observability/` (ef-stack, Observabilidad en EF, workshop-grafana), `EF/reference/process/` (`Estructura de una tarea.md`, dev containers).

## Index of this setup
`EF/reference/setup/Claude Code - contexto EF.md` lists the CLAUDE.md layers, this skill's files, scripts and per-repo agents/skills. Update it whenever a file, script or agent is added or removed here.

## When to write
- Status, decisions and progress notes go here, never as GitHub comments.
- After every status change of a tracked QA issue, update its row in the `bugs-materials` matrix.
