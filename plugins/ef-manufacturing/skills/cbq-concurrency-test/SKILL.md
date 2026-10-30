---
name: cbq-concurrency-test
version: 1.0.0
description: Concurrent live test (real HTTP calls, NOT Pest) of every command in manufacturing-core-pkg that uses the EventCommands/CBQ toolkit — inventory movements over Kafka, idempotency, redelivery, and the Redis commands. Use when the user asks to "test all the commands", "run the concurrency test", "check the engines still work" after changes to the toolkit or the engines.
---

# CBQ / EventCommands concurrency test

Checks, against the running daemons and the legacy dev DB, that the commands still work when
fired **concurrently**: kardex order, idempotency, redelivery, identity per flow, and
that nothing fails in the log. Real HTTP calls from the logged-in session; **no Pest**.

## Rules (do not break)

- Writes **only on workshop 103195** (Pruebas TI). Do not touch real pending requests (61543, 61770, 61774).
- Do not edit ids or rows by hand. DB = **SELECT + LIMIT** only (never UPDATE/DELETE/DDL/SET).
- Leave test data in place, labeled in `comments` with `QA <tag>` (e.g. `QA PR140 toolkit-v2`).
- Legacy is the source of truth: rules that block (e.g. waste `isAlreadyProcessing` → `waste_already_exist`)
  are the expected result, not a bug.
- Do not commit/push. Do not change `.env` or restart daemons without asking.
- The legacy dev DB is refreshed daily from prod: yesterday's ids may no longer exist.

## Routing (so the results make sense)

| What | Broker | Why |
|---|---|---|
| UI calls (`sync:true`): create, resolve, add waste, cycle count, storage capacity, previews | **Redis** (`default`) | the CBQ controller picks the broker by command name (`handles` in `config/uxmaltech.php`); `sync` only means "wait for the reply" |
| Stock movements (`dispatchTo` after commit) | **Kafka** async | `EventRoute` per stream (`invt_mgmt`, `invt_mgmt_adjust_review`, `invt_production`) in `config/manufacturing-core.php` |

Commands that don't move stock **never** reach Kafka; an idle Kafka daemon is correct for them.
Only the engines (`MgmtAdjustmentEngine`, `MgmtInventoryEngine`, `ProductionInventoryEngine`) write
`current_quantity`, and they run only inside the Kafka consumers.

## Environment

- Container `ef-manufacturing-frankenphp`; package mounted at `/manufacturing-core-pkg`.
- Daemons: `php artisan uxmaltech:cbq-daemon --broker=kafka` and `--broker=default`. They must have started
  **after** the last code change:
  ```sh
  docker exec ef-manufacturing-frankenphp sh -c 'ps -o pid,lstart,args -u vscode | grep cbq-daemon | grep -v grep; ls -l --time-style=full-iso /manufacturing-core-pkg/src/EventCommands'
  ```
  If they are older → ask the user to restart them.
- Scripts in `scripts/` (copy into the container):
  ```sh
  SK=<this skill's base directory>/scripts
  for f in snapshot.php redeliver.php logscan.sh; do docker cp $SK/$f ef-manufacturing-frankenphp:/tmp/$f; done
  # run: docker exec ef-manufacturing-frankenphp sh -c 'cd /app && php artisan tinker --execute "$(cat /tmp/snapshot.php)" 2>&1 | tail -60'
  # log: docker exec ef-manufacturing-frankenphp sh -c 'cd /app && sh /tmp/logscan.sh'
  ```
- "Permissions fetch failed [400]" in the daemon (SSO perm cache) →
  `php artisan tinker --execute "$(cat /tmp/perm-refresh.php)"` and retry.
- **504 at ~30s** with a burst of >~12 sync calls: the web tier gives up waiting on the serial Redis
  daemon (~1.2 s per message); **the command still runs**. Fire in waves of 3–5, or confirm the uuid
  in the log ("processed successfully") before calling it a failure.

## Browser (Playwright)

1. New context with `ignoreHTTPSErrors:true` and open
   `https://ef-manufacturing.localhost/inventory-adjustments/raw-material/review`.
   If it lands on SSO login → **stop and ask the user to log in**.
2. Always use the last context:
   `const ctxs = page.context().browser().contexts(); const p = ctxs[ctxs.length-1].pages()[0];`
3. Helper for `browser_run_code_unsafe`:
   ```js
   const token = await p.evaluate(() => document.querySelector('meta[name=csrf-token]')?.content);
   const T0 = Date.now();
   const post = (label, path, data) => p.request.post('https://ef-manufacturing.localhost'+path,
     {data:{...data, sync:true}, headers:{'X-CSRF-TOKEN':token,'Accept':'application/json'}, timeout:120000})
     .then(async r => { const ms = Date.now()-T0; const t = await r.text(); try { const j = JSON.parse(t); const d = j.data ?? j;
       return label+' → '+r.status()+' '+ms+'ms '+(j.uuid??'')+' '+(d.result??'')+' '+JSON.stringify(d.data??{}).slice(0,150)+(d.errorMsg?' | '+String(d.errorMsg).replace(/<br>/g,' '):''); }
       catch { return label+' → '+r.status()+' '+ms+'ms '+t.slice(0,160); } });
   // fire in parallel: return await Promise.all([ post(...), post(...) ]);
   ```

## Test data

- `invt_mgmt` **55792** = Musgo (material 31) on 103195.
- `invt_production` **4832** = Ruscus (material 14), `invt_mgmt` **17074**.
- Legacy actor: user 101470. Session workshop = `usuarios.workshop_id` (not 103195 for this user).

## Steps

### 0. Baseline
```sh
docker exec ef-manufacturing-frankenphp sh -c 'rm -f /tmp/cc_base.json; cd /app && wc -l < storage/logs/laravel.log > /tmp/logmark && php artisan tinker --execute "$(cat /tmp/snapshot.php)" 2>&1 | tail -5'
```
Write down the stock for 55792 and 4832.

### 1. Movements (reach Kafka) — each block in a single `Promise.all`

| # | Fire | Expected |
|---|---|---|
| 1 | 4× `POST /v1/cmd/inventory-adjustments/raw-material/create` `{workshop_id:103195, invt_mgmt_id:55792, operation:'add'\|'subtract', adjust_type_id:9, quantity:N, comments:'QA <tag> Rx', force:false}` | 4 ids |
| 2 | 5× `POST /v1/cmd/inventory-adjustments/raw-material/review/resolve` on the **same** id `{id, status:'accepted', comments, force:false}` | 1 ok + 4 "La solicitud ya fue procesada"; 1 kardex row |
| 3 | 3 accepts of **different** requests (`force:true`) + 3× `POST /v1/cmd/inventory-adjustments/affiliates/create` `{workshop_id:103195, material_id:31, adjust_type:8, quantity:'1', comments}` | all ok; unbroken chain on 55792 |
| 4 | 3× `/v1/cmd/inventory/raw-material-decrease` `{workshop_id:103195, material_id:31, quantity:1, type:'mgmt', comments}` + 1× `/raw-material-decrease/batch` `{…, materials_qty:{'31':1}}` + 3× `/v1/cmd/inventory/picking-decreases/add` `{workshop_id:103195, material_id:14, quantity:1, type:'operational', comments}` + 1× `/picking-decreases/batch` `{workshop_id:103195, type:'operational', materials_qty:{'14':1}}` | raw-material: 1 ok, the rest `waste_already_exist` (legacy); picking: 4 ok, in order |
| 5 | On a new request: reject ×2 + accept ×1 at once; on another: cancel ×2 | exactly 1 winner each; kardex only if accept wins |
| 6 | Create `subtract` with a quantity > stock, `force:false` | negative-stock `warning`, no write |

### 2. Redelivery (idempotency)
Write the ids of events already applied and re-dispatch them twice each:
```sh
docker exec ef-manufacturing-frankenphp sh -c 'echo "{\"mp\":<req_id>,\"mp_qty\":<qty>,\"aff\":<aff_id>,\"mw\":<waste_id>,\"pw\":<picking_waste_id>}" > /tmp/redeliver_ids.json; cd /app && timeout 280 php artisan tinker --execute "$(cat /tmp/redeliver.php)" 2>&1 | tail -8'
```
(For an MP `subtract` pass `"mp_source":"adjust_exit"`.) Expected: "movimiento saltado" ×N and 0 new rows.

### 3. The other commands (Redis only, no movement) — waves of 3–5

| Command | Payload | Expected |
|---|---|---|
| `/v1/cmd/inventory/picking-decreases/preview-csv` | `{workshop_id:103195, materials_qty:{'14':1,'164':2}}` | rows with stock |
| `/v1/cmd/inventory/raw-material-decreases/preview-csv` | `{workshop_id:103195, materials_qty:{'31':1}}` | rows with stock |
| `/v1/cmd/inventory/cycle-count-config/add` ×2, category **not** yet configured on 103195 | `{workshop_id:103195, material_category_id, frequency:'monthly', weekday:3, full_count:false}` | **only 1 row** created |
| `/v1/cmd/inventory/cycle-count-config/add` ×2, existing category | — | "Ese taller ya está configurado…" |
| `/v1/cmd/inventory/cycle-count-config/update` ×3 | `{id:<config 103195>, same values}` | ok |
| `/v1/cmd/inventory/cycle-count/reset` ×2 on a `pending` count | `{cycle_count_id}` | "Sólo se puede reiniciar un conteo iniciado…" |
| `/v1/cmd/inventory/storage-capacity` ×3 | `{workshop_id:103195, material_id:14, packages_per_label:<current value>}` | ok, value unchanged |
| `/v1/cmd/inventory/workshop-picking/adjust` | `{invt_mgmt_id, operation, adjust_type_id:<picking type, e.g. 14>, quantity, comments}` | uses the **session** workshop: if it isn't 103195 only validations are tested — do NOT write to another workshop |

### 4. Checks
1. `snapshot.php` again: `chain … breaks=0` for both; total delta = sum of the accepted events;
   `request_platform = 'ef-manufacturing:<SOURCE_TABLE>'` on every new row.
2. `logscan.sh`: 0 identity/movement failures; "Sending message to Kafka" only for
   `*.movement.v1`, `mgmt-remove.v1`, `production-remove.v1`; any dead-letter → read its `exception_message`
   (don't guess the cause).
3. Quick UI: the 5 screens load and show the records (raw-material review and requests,
   affiliates, raw-material waste, picking waste).

## Report

A table per block: command · what was fired · expected · result (✅/⚠️) · ids · stock before→after.
Separate what **was tested live** from what **was not** (e.g. same-id collision across two flows,
rows written before the identity change, `StockValidation` not ported). Every cause stated must have
evidence in the log or the DB; if a claim was not verified, say so.
