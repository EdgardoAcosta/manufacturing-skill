# Notion

Always show the change before writing to Notion and wait for a yes. Read rows back after writing.

## Databases
| What | Link / id |
|---|---|
| Happy Paths por submódulo (Migración de sistemas): one row per module, fields incl. QA User | page `5a12d54c2aae451489035a9f1f9f2b4e`, view `7ba99e96d6064f1384437338ab0ca72e`, data source `collection://f68c38a2-04b1-4aa6-b6f0-63f633ad5e95` |
| Migración de módulos - Plan & Gantt (live source for Story bodies) | page `38dc30965c7a46b5ac2f02bd9418e560`, view `389ef8a4db418037ad52000c833a3840` |
| Issues de Feedback - Alta de Materiales (QA feedback, mirrors GitHub #424-#590; Estatus syncs from GitHub, never set by hand) | `a87cfdb115e6411aac3f2f966bf0cd36`, view `ca30702a08ef438c847ee16f894f854f` |

Each migration Story links its Notion page at the bottom ("Fuente viva").

## Mentions
Text properties (e.g. QA User) only accept this format:
`<mention url="user://<user-id>/<email>">Name</mention>`
`<mention-user>` tags are stored as literal text. User ids are in `~/repository/enviaflores/CLAUDE.md`.

## Manufactura hub (team-facing docs)
Page `408ef8a4db418065bb70fa1da1aff336` (https://app.notion.com/p/Manufactura-408ef8a4db418065bb70fa1da1aff336), top level of the **IT** teamspace (`231ef8a4-db41-813d-85a1-00424bd34c9a`), created 2026-10-29. Everything manufacturing-related that other people must read or act on (runbooks, printer setup, system map, procedures, decisions) lives under it; Obsidian keeps working notes, trackers and drafts. Older manufacturing pages that still live elsewhere in IT: PM Operations > App Manufactura (Backend de manufactura: Headers, Responses), Pruebas Activas, Soporte Sistemas, Auditoría de Seguridad; DevOps > Monitoring holds the company alert convention (every alert needs a valid `runbook_url`). Link them from the hub, do not move them unless asked.

Hub structure (created 2026-10-29, Spanish, no emojis, every page/row has a Responsable):
| Section | Id | Use |
|---|---|---|
| Sistemas | page `408ef8a4db4181fdaf1dea88e87f856e` | one page per system: Admin web `408ef8a4db418169b051fc621825b1bb`, Backend app `408ef8a4db4181d38b9bf56de2105de1`, App móvil `408ef8a4db418144bdfec83a586ab327`, Servidores de impresión `408ef8a4db41819bb4dffc1b484edd63`, Lambdas `408ef8a4db4181b69c3bd29192f350e7` |
| Observabilidad | page `408ef8a4db41814d86dbfec214d5a8e5` | SLOs, dashboards, alert catalogue, "cuando suena una alerta" |
| Runbooks | database `0fdcb3b5de9946ea82b712909e56c478`, data source `collection://1dd8efb8-9e47-4fd6-9bd3-7e817476a60a` | one row per alert (Tipo=Alerta: Sistema, Severidad, Grupo Grafana, UID regla) or procedure (Tipo=Procedimiento); views "Alertas por sistema", "Procedimientos"; template rows Tipo=Plantilla (`408ef8a4db4181429eafd615f3f553ab` alerta, `408ef8a4db418172b9e0c98ded2d6a34` procedimiento). Grafana `runbook_url` points at the row URL |
| Cómo trabajamos | page `408ef8a4db41815e9933c8b3a1ee46b8` | task flow, QA rotation, environments, test data; links DevOps pages |
| Decisiones | database `0949bbfdc11240a6ac15db2ad8240c42`, data source `collection://91dde448-c686-4639-9398-f575fe735f68` | ADR-lite rows (Fecha, Estado, Sistema, Responsable); template row Estado=plantilla `408ef8a4db41812988bbd6ce6a3d399b` |
| Proyectos | page `408ef8a4db41812980a5e86f6f8f72f4` | links only to Iniciativas, migration DBs, PM Operations pages |
Rule: Notion = what others read or act on; Obsidian = working notes, trackers, drafts. A note that moves keeps a one-line pointer in Obsidian and stops being edited there. Generic dev docs stay in DevOps (IT teamspace), link them.
Content loaded 2026-10-29: 30 alert rows (Estado=borrador, Responsable=Edgardo, `UID regla` set; uid->page map in the session scratchpad `uid-to-notion.tsv`), procedure row "Dar de alta una impresora Zebra en CUPS" (`408ef8a4db418103ba4ff23579c18507`, root ssh line scrubbed), Referencia rápida tables in the 4 system pages, Lambdas page = full Lambdas map, Observabilidad has SLO v0 table, alert catalogue (30 mentions), tableros pendientes and data-quality defects. Not in Notion by decision: Decisiones rows from design notes, APK procedure, Obsidian pointer lines (Edgardo, 2026-10-29). Repo maps (web, app-be, flutter) pending his call.
