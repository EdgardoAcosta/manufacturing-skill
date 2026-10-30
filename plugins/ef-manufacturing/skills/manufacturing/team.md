# Team

## Manufacturing devs
| Name | GitHub | Notion user id | Email | Known modules (built / PRs reviewed) |
|---|---|---|---|---|
| Edgardo Acosta (me, lead) | EdgardoAcostaEF | - | edgardo.acosta@enviaflores.com | materials, deactivations, PVO #350, OC/receipt backend, infra/telemetry |
| Jorge Saavedra | jorgesaavedraEF | 25dd872b-594c-8165-b052-0002969ab2bb | jorge.saavedra@enviaflores.com | Producción #280 (PR #191), Configuración de productos #272 (PR #196), Avance de última milla en vivo #287 (PR #228); legacy owner `administracion-enviaflores` |
| Julio Cavazos | julioccqEF | fc28c02a-817e-4052-a0b3-4951cb11ca55 | julio.cavazos@enviaflores.com | Planeación de producción #278 (PRs 156-179); legacy owner `admin-proveedores`, `admin-affiliates` |
| Guillermo Cavazos ("Memo") | GCavazosEF | 217d872b-594c-81a1-91ae-0002103015b3 | guillermo.cavazos@enviaflores.com | Disponibilidad del producto #276 (PR #181), Venta por hora - Flor #282 (PR #187), Avance de última milla por pedido #289 (PR #200); legacy owner `admin-suministros` |

The dev of a module = assignee of its GitHub sub-issues. Check there when this table is stale.

## Others
| Name | GitHub | Role |
|---|---|---|
| Dali | DaliVzz | QA; files QA issues (epic #219 materials, tracker in Obsidian `bugs-materials`) |
| Edwin Alvarado | ealvarado-ef | business requester; his Notion requests and Finanzas decisions can invalidate QA issues |
| Lucy Pérez | - | Comercial Afiliados owner (affiliate portal modules) |
| David Peña | efdhpv | PO team dev (david.vazquez@enviaflores.com); built core-pkg PurchaseOrders (OC edit tabs incl. Materiales rechazados) and original Materials transfers module |

Other logins seen on project 59 with no confirmed name or role yet: EmilioDinen, MauricioCarreonG, aMarFlo, efhectormurillo, ericchiquilloEF, jadelagarza-ef, LupitaRey, azorperezm, carlosmonjaras, frankocampo, humbertotrevinoEF, ivan-marquezEF, luciaramirez93, valentinodepaola-ef. Ask before assuming who they are; add them here once known.

## QA rotation
- QA user for a module must not be the dev who built it.
- Rotation = Jorge, Julio, Guillermo. I (Edgardo) am not in it.
- Notion field "QA User" takes an @mention (format in `notion.md`). Show the distribution before writing.

## Dev status
`scripts/dev-status.sh [login ...]` (path relative to this skill's base directory)
- Pulls all project 59 items (cached 10 min in `$TMPDIR/mfg-project59-items.json`, `REFRESH=1` forces).
- Per dev: count of active items by Status, flag `NO In Progress`, then each item `status | sprint | repo#n | updated | title`, newest first.
- Active = Definition, Backlog, In Progress, Hold, PR Ready/In review/Approved, Ready for Demo/test, Staging, QA Testing, Rejected by QA.
- "My pending work" = only Backlog, Definition, In Progress for EdgardoAcostaEF. Flag stale rows (e.g. Definition with an open PR).
- For other cuts, query the cache with jq (fields: status, sprint, proj, content.number/title/assignees/updatedAt).
