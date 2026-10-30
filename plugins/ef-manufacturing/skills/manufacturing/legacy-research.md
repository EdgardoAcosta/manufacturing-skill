# Legacy research

Legacy = source of truth for business logic. Never decide a rule, filter or Copilot finding on reasoning alone: grep legacy first.

## Where the code is
All under `~/repository/enviaflores-legacy/` (CakePHP 2 unless noted).

| Repo | Host | What lives there |
|---|---|---|
| `enviaflores-admin-talleres` | talleres.enviaflores.com, administrators. | workshop screens: producción, planeación, contenedores, tableros (última milla, avance), PVO taller |
| `enviaflores-admin-suministros` | suministros.enviaflores.com, administrators. | materials catalog, categorías, motivos de rechazo, inventario, caducidad, desactivaciones, PVO suministros |
| `ops-enviafores-api` | ops.enviaflores.com (staging: ops-staging.enviaflores.com/v3) | OPS backend that most screens proxy to; inventory, receipts, EventManager dispatch, per-entity `*_log` models |
| `enviaflores-admin-api` | api.enviaflores.com, api-internal. | admin-api v2: generic ORM over HTTP used by portals (applies `conditions` as sent; DataTableComponent search maps by field position) |
| `comercial-backoffice` | comercial.enviaflores.com, administrators. | Comercial screens (PVO comercial, OC comercial) |
| `administracion-enviaflores` | - | Finanzas/administración (Audits: impuestos de material/producto) |
| `enviaflores-admin-affiliates` | afiliados.enviaflores.com | affiliate portal (goes to `ef-suppliers`) |
| `enviaflores-admin-proveedores` | proveedores.enviaflores.com | supplier portal |
| `enviaflores-admin-staff` | staff.enviaflores.com | Staff back-office (users, affiliates admin) |
| `enviaflores-admin-mesa-control`, `-operators`, `-cx`, `-soporte` | mc., operadores. | other back-offices |
| `enviaflores-eventmanager-cakephp` | event.enviaflores.com | Event Manager queue worker (SAP, email, accounting, inventory events) |
| `enviaflores-api-v3`, `enviaflores-payment-daemon` | endpoint., payment. | storefront API, payments |

## Tracing a screen
1. From the URL (`talleres.enviaflores.com/<controller>/<action>`) open `app/Controller/<Name>Controller.php` in the repo for that host. Note line numbers.
2. Follow the view: `app/View/<Name>/<action>.ctp`, its `datatable/*.ctp`, `webroot/js/<...>.js` (filters, buttons, AJAX calls).
3. Follow the data: direct models, or the OPS / admin-api endpoint it calls. Open that controller in `ops-enviafores-api` or `enviaflores-admin-api` and go down to the query.
4. Permissions: the controller's `isAuthorized`/profile checks and the menu config.
5. When screens are merged (e.g. PVO in Suministros + Talleres + Comercial), grep every legacy repo, not just the one named in the issue. Merge = union: any feature used by any system gets ported behind its own permission. Dead code (no caller) is not ported; say so with evidence.
6. Data checks: capped SELECT on the dev legacy DB only (see CLAUDE.md). The test workshop 103195 has hand-edited data, so validate parity on a real workshop (e.g. Monterrey 3) read-only.

## Rules when porting
- Port rules exactly (filters, exclusions, hand-picked ids, validations). Report legacy quirks as facts; deviate only for real defects and list them.
- WebSocket/socket.io -> Ably (`RealtimeService`); Memcached -> Redis.
- SAP updates and emails go through the Event Manager (`EventManagerService` HTTP push), never direct SAP/SMTP or local jobs. OPS is the model: `EventManager->Request(...)`.
- History/bitácora screens: legacy uses one typed `*_log` table per entity (e.g. `users_change_log`: one row per changed field, actor from `X-ENVIAFLORES-ORIGIN`), not a polymorphic audit table. Look for that table before assuming Spatie activitylog.
- Legacy dev DB is a daily prod copy: a teammate's write missing there is usually the copy cycle, not a bug.
- QuickSight dashboard ids live only in prod Config files on side branches: `git grep "QUICKSIGHT_DASHBOARD" $(git for-each-ref --format='%(refname)' refs/heads refs/remotes) -- '*Config*'`.
