# Issues

Repo `enviaflores-legacy/ef-manufacturing`. Board: GitHub Project #59, owner org `enviaflores`, id `PVT_kwDOAEdJu84BHxyJ`.

## Hierarchy and naming
| Level | Issue type | Label | Title |
|---|---|---|---|
| Epic | Epic | Epic | `MFG \| <Proyecto> \| <Menú / objetivo>` (e.g. `MFG \| Migración de administradores \| Menú materiales`) |
| Story (HU) | Feature | Story | `MFG \| <Proyecto> \| <Menú> \| <Submódulo>` |
| Task | Task | - | `MFG \| <Proyecto> \| <qué se hace>`, sub-issue of the Story |
| Bug | Bug | - | `MFG \| <Proyecto> \| <qué falla>`, sub-issue of the Story it breaks |

Org issue type ids: Task `IT_kwDOCt0SvM4BaJSs`, Bug `IT_kwDOCt0SvM4BaJSt`, Feature `IT_kwDOCt0SvM4BaJSu`, Epic `IT_kwDOCt0SvM4B5Bh3`.

## Bodies
Spanish, no emojis (strip them even though older issues have them). Templates:
- Story: `templates/story.md` (model: #286)
- Task: `templates/task.md` (model: #694)
- Bug: `templates/bug.md` (model: #695)

Task and Bug bodies start with `Historia padre: #<n>`.

## How to get the content
1. Read the parent Story/Epic, all sibling sub-issues (open and closed), and the Notion row.
2. Migration Stories: document everything legacy does (see `legacy-research.md`): repo, controller, route, what the user sees and does, filters, actions, endpoints, tables, rules, permissions, legacy quirks as facts. Validate every claim down to the layer that builds the query.
3. Don't ask about legacy defects, scope cuts or implementation choices; those are the dev's call. Ask only about facts I can't find (which screen, who uses it).
4. Tasks/Bugs on the new system: read the code in `manufacturing-core-pkg` / `ef-manufacturing-app-be` and cite `repo · path:line`.
5. Split sub-issues the way the user sees the screen (one per tab or URL), not per backend method.
6. Never add a "Por validar" section or `[POR VALIDAR]` marks. The issue must be fully formed when created: ask me every open question in chat (AskUserQuestion) before the preview and write the answers into the body.

## Creating
Preview title + body + fields in chat, always in Spanish: paste the actual Spanish text, never an English summary. Wait for yes, then:

```bash
GH_TOKEN=$(gh auth token --user EdgardoAcostaEF) scripts/new-issue.sh \
  --title "MFG | Recibo de material | ..." --body-file body.md --type Task \
  --parent 122 --assignee EdgardoAcostaEF --project "Recibo de material" \
  --status Definition --sprint "Sprint 22 - 2026" [--label Story] [--dry-run]
```

It creates the issue, sets the type, links it as sub-issue, adds it to project 59, sets Status/Project/Sprint and verifies the board fields. Run with `--dry-run` first to validate option names. It refuses bodies with emojis.

Defaults (don't ask about them): assignee `EdgardoAcostaEF` unless I name someone else, even if the related issue belongs to another dev; Status Definition; current sprint.

Gotchas:
- Assign `EdgardoAcostaEF`, not `EdgardoAcosta` (silently ignored).
- `issue.projectItems` returns empty for this cross-org project. Verify fields through the ProjectV2Item node (the script does).
- Moving sub-issues to another parent: `addSubIssue(input:{issueId, subIssueId, replaceParent:true})`.
- Images: create the issue anyway and tell me exactly where to take the screenshot.

## Project 59 fields
- Project `PVTSSF_lADOAEdJu84BHxyJzg_Babo`: Incidente Github, Incidencias, OC Spot, Optimización OC Locales, App Manufactura: Reingeniería, Recibo de material, Criterios de calidad, Migración de administradores, Mejoras Migración de Sistemas, Alta Cedis Villa Guerrero, Proyectos de mejora, Puente Operativo PVO365, Rediseño sistema producción, Surtido a Picking, Ajustes de inventario, Vida de anaquel, OC Consigna, PVO Material, Mejoras OC Spot.
- Status `PVTSSF_lADOAEdJu84BHxyJzg4bqx0`: Definition, Backlog, In Progress, Hold, PR Ready, PR In review, PR Approved, Ready for Demo, Ready for test, Staging, QA Testing, Rejected by QA, Approved by QA, Deploying, Production, Done, Canceled, Rejected.
- Sprint `PVTIF_lADOAEdJu84BHxyJzg4bqys`: two-week iterations, `Sprint N - 2026` (Sprint 22 starts 2026-10-19).
- Also: Project Priority, Size, Story points, Blocked, Scope Change, Start/Target date.
The script resolves option ids by name at run time, so names are enough.
