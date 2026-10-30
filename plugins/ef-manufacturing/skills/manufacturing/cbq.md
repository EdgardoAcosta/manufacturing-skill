# CBQ brokers and daemons

Everything here is for the **dev container only**. Prod and staging daemons are ECS services owned by SysOps (`enviaflores/system-operations`, `terraform/ecs/ef-manufacturing.tf`); never start, stop or reconfigure them from here.

## How routing works
- `config/uxmaltech.php` has one broker block per name: `default`, `redis`, `kafka`, `sqs`. The block name is what `--broker=<name>` and `CBQ::command(..., $broker)` refer to; the `driver` key inside picks the vendor driver.
- Screen commands (`CBQ::command()` from the UI, e.g. `cmd.inventory.raw-material-decrease.add.v1`) use the `default` broker: `UXMAL_BACKEND_CBQ_BROKER_DEFAULT_DRIVER` (redis), queue `UXMAL_BACKEND_CBQ_REDIS_QUEUE` (`uxmal-app-local-queue` in dev). They are sync: the browser waits up to 15 s.
- Ordered inventory consumers (`manufacturing-core-pkg` `EventCommands`: `RemoveMgmtInventory`, `RemoveProductionInventory`, `RemoveMgmtInventoryByCycleCount`, affiliate adjustments) use the broker named by `EF_EVENT_COMMANDS_BROKER`, or `EF_EVENT_COMMANDS_<STREAM>_BROKER` per stream (`INVT_MGMT`, `INVT_PRODUCTION`). Resolved by `EventRoute`. Order per row comes from `fifoKeyOn` (`{invt_mgmt_id}`): Kafka partitions on `fifo_key`; SQS FIFO groups on the reply channel, which `DispatchesEvent::orderingChannel()` sets to `fifo:<key>` on every broker. Redis and sync give no order.

## One daemon per broker, always up
- A queue is drained only by a daemon started for that broker name. No daemon = commands wait in the queue, the screen shows `Request timed out after 15 seconds`, and the command still runs when a daemon appears.
- Start in the background: `docker exec -d ef-manufacturing-frankenphp sh -c 'php artisan uxmaltech:cbq-daemon --broker=<name> > /tmp/<name>-daemon.log 2>&1'`. List: `docker exec ef-manufacturing-frankenphp pgrep -af "artisan uxmaltech:cbq-daemon"`. Prod uses `uxmaltech:mt-cbq-daemon` (Swoole pool, `UXMAL_BACKEND_CBQ_MT_WORKER_NUM`).
- Leave every daemon running. Restart one only after a code change it must load (core-pkg, vendor, config): the process keeps the code in memory. Never stop a daemon to inspect a queue; read its log, the queue stats and the DB.
- Recreating the container kills them and VS Code does not restart them: start them by hand. The app loads core-pkg from the `vendor` volume, not from the mounted checkout; to run branch code live copy the file into `/app/vendor/enviaflores/manufacturing-core-pkg/...` and restart the daemon.

## Local SQS (ElasticMQ)
- Compose service `elasticmq` (`.devcontainer/docker-compose.yml`, queues in `.devcontainer/elasticmq.conf`): `ef-mfg-inventory-dev.fifo` + `ef-mfg-inventory-dev-dlq.fifo`, redrive after 5 receives. Stats: `curl -s http://localhost:9325/statistics/queues | jq`.
- `.env` to route through it: `EF_EVENT_COMMANDS_BROKER=sqs`, `UXMAL_BACKEND_CBQ_SQS_ENDPOINT=http://elasticmq:9324`, `UXMAL_BACKEND_CBQ_SQS_PREFIX=http://elasticmq:9324/000000000000`, `UXMAL_BACKEND_CBQ_SQS_QUEUE=ef-mfg-inventory-dev.fifo`, `UXMAL_BACKEND_CBQ_SQS_KEY=elasticmq`, `UXMAL_BACKEND_CBQ_SQS_SECRET=elasticmq`.
- The key/secret are required: Laravel loads `.env` into `$_ENV` only, `getenv()` never sees it, so the AWS SDK default chain falls to the instance metadata service and fails. The `sqs` block passes `credentials.key/secret` from those two variables; unset = task role (prod).
- Peeking with `ReceiveMessage` counts as a receive against `maxReceiveCount`; peek at most once, with `VisibilityTimeout => 0`.
- AWS queues (prod/staging): system-operations#522 (#523 queues, #524 daemon). Names `ef-mfg-inventory[-staging].fifo` + `-dlq.fifo`.

## Verifying a run
Per message: daemon log `Message received ... (receiveCount: 1)` then `Message processed and deleted successfully`; queue visible/in flight back to 0, DLQ 0. On the dev legacy DB (`db.ef-production-dev`): waste `status=finished`, one `invt_mgmt_transaction_log` row per waste with `current_qty` equal to the previous row's `new_qty` of the same `invt_mgmt_id`, `invt_mgmt.current_quantity` equal to the last `new_qty`. Live-verified 2026-10-28 with 15 wastes on Taller de Pruebas TI (103195).
