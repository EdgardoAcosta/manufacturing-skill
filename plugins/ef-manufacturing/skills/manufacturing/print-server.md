# Print servers (workshop-daemon)

One Ubuntu box per workshop runs `workshop-daemon` (repo `~/repository/enviaflores/workshop-daemon`): a CakePHP 2 API in front of CUPS that the mobile app calls to print QR labels. The code is the source of truth; read it before answering. Site values (hosts, SSH ports, LAN IPs, printers) are not here: they live in Obsidian `EF/reference/runbooks/Despliegue servidor de impresion.md`, section "Servidores" (name that folder in the request), or come from the queries below.

## Rules
- Never SSH or run anything on a server. Give one short command, wait for the pasted output, then the next. `sudo` only when the command needs it.
- Never print `EnviaFlores.Ops.uuid` from `app/Config/<host>.php`: it is the OPS api key (it goes in the URL path). `Ping.php` runs `SetDebug(true)`, so `debug.log` contains it too; don't echo pasted lines that carry it.
- Prod OPS and the prod DB are read-only. Test prints only when the user asks.

## Code map
| What | Where |
|---|---|
| Per-host config (OPS host, protocol, api key) | `app/Config/<php_uname -n>.php`, loaded by `bootstrap.php` when the hostname matches; never synced |
| Endpoints | `app/Config/routes.php`; labels `V1LabelerController`, CUPS `V1PrinterController`, queues `V1AdminController`, plotter `V1PlotterController`; Swagger at `/documentation` |
| Label templates | `app/Config/LabelTemplates/*.zpl` (Zebra, authored at 300 dpi) and `*.tspl` |
| Heartbeat | `app/Console/Command/JobScheduler/Ping.php` -> `Ops->Request('workshops/local-ops', 'PUT')` with `local_ipaddress = GetLocalIPAddresses()` (`hostname --all-ip-addresses`, `bootstrap.php`) and `lp_devices` |
| Deployed version | `app/Config/version` (commit sha) |
| Installer | `utils/build/ubuntu-20.04/v1.5/` (`install.sh`, `conf/`): nginx 1.19.7 built from source (`efnginx.service`), php-fpm, CUPS, autossh tunnels (`tunnelssh`, `tunnelnginx`) |
| Ansible | `ansible/` (`playbook.yml` CUPS/TSPL, `observability.yml` + role `vector`); Ubuntu 20.04 = Python 3.8, run with `uvx --python 3.12 --from 'ansible==10.*' ansible-playbook` |

## On the server
| What | Where |
|---|---|
| App | `/opt/eftech/html/workshop-node`, owner `eftech:eftech` |
| Daemon nginx | port 4857, logs in `/opt/eftech/logs/` (name varies per install: `ls` first; `access.log` or `<host>-4857.access.log`). Files hold binary bytes: `grep -a` |
| App logs | `app/tmp/logs/{debug,error}.log` |
| CUPS | `lpstat -h localhost:<port>`; sites use 2631 (installer default 631): `ss -ltnp \| grep cups` if unsure |
| Cron | `/etc/cron.d/eftech`: `cake job_scheduler` every minute as `eftech`, output to /dev/null. Proof it runs: `grep CRON /var/log/syslog \| tail -3`, then `JobSchedulerPing` Starting/Ending + `response_code =>` in `debug.log` |
| Remote access | autossh reverse tunnels to a passthru host (ports in the OPS row below) or Tailscale |

## Labeler API (port 4857)
- `GET /labeler/connected`: CUPS queues named `ZTC*` (`?show_all=true` for all).
- `POST /labeler/jobs`: JSON with `template_name`, `printer_name` (queue), `printer_dpi` (default 203; must match the printer, 300 for 300-dpi heads), `job_name`, template fields (`uuid` uppercase, `small_uuid` derived), optional `copies`, `items[]` batch, `template_body` inline. `?debug=1` returns the final ZPL and does not print.
- `GET /printer/jobs?printer_name=<queue>&status=completed`: CUPS history by `job_name`, proves a job reached CUPS.
- Test from the server itself: `scripts/labeler-test.sh` (picks the first `ZTC-*` queue, reads printer IP and dpi live, posts a test label; `DEBUG=1` = ZPL only). Copy it to `/tmp` on the server and run with `sh`, no sudo.

## How the app finds the server
1. Every minute `Ping` PUTs the server's IPs to OPS.
2. OPS stores them in table `ops-workshop-local` (legacy prod DB, schema `enviaflores_production`): `workshop_id`, `ip_address` (public), `port`, `url_schema`, `conn_path`, `tunnel_host`, `ssh_tunnel_port`, `nginx_tunnel_port`, `data` (PHP serialized, holds `local_ipaddress`), `last_seen`.
3. The app calls `v1/workshop/local-print-servers`; with `conn_path=local` it uses `data.local_ipaddress[0]` + `port` (`mobile/mfg-main/packages/domain/.../local_server.dart`). LAN IP must be first in `hostname --all-ip-addresses`; Tailscale/docker IPs after it.

Check the row (SELECT with LIMIT, read-only): `` SELECT id, workshop_id, ip_address, port, url_schema, conn_path, tunnel_host, ssh_tunnel_port, nginx_tunnel_port, last_seen, data FROM enviaflores_production.`ops-workshop-local` WHERE workshop_id = <id> LIMIT 5; ``. `last_seen` is local time (America/Monterrey), the DB clock is UTC. More than one row per workshop = the app may pick the wrong one.

## Deploy and printers
- Code: `sync-devel.sh` (`HOSTS`, `PORT`, `SSH_USER`, `SSH_KEY`, `REMOTE`, `DRY_RUN`). Always `DRY_RUN=1` first. Only `app/ lib/ plugins/ index.php .htaccess` go up; never vendor/, composer.*, `app/tmp/`, `app/Config/<host>.php`. New files land `root:root`: user chowns to `eftech:eftech`. Before deploying: tar backup in `/root`, `php -l` on the server's PHP (7.2: no `fn`, no typed props). Full steps: runbook `Despliegue servidor de impresion.md`.
- New Zebra: `nc -zv -w3 <ip> 9100`; read facts with SGD over 9100: `printf '! U1 getvar "head.resolution.in_dpi"\r\n' | nc -w2 <ip> 9100` (also `device.product_name`, `device.unique_id`, `ip.dhcp.enable`). Queue `ZTC-<model>-<serial>`: `lpadmin -h localhost:<port> -p <queue> -v socket://<ip>:9100 -m drv:///sample.drv/zebra.ppd -o printer-is-shared=true -E`. If DHCP is on, ask for a reservation. Tell the app team the dpi.
- Observability: runbook `Observabilidad servidor de impresion.md` (Vector, no Ansible) or `ansible/observability.yml`. Vector >= 0.57 does not expand `${VAR}`: secrets backend. opentelemetry sink `batch` goes under `protocol:`. The Grafana ingress has fail2ban: never probe its auth endpoints without credentials.

## "Users can't print": diagnose in this order
1. Does the request reach the server? `grep -a 'POST /labeler' <access log> | tail`. Only `127.0.0.1` lines = no client reaches it.
2. Does it print locally? `labeler-test.sh` on the server. Prints = server and printer are fine.
3. Did CUPS finish it? `GET /printer/jobs` or `lpstat -h localhost:<port> -W completed -o | tail`.
4. Is the IP the app uses right? `hostname --all-ip-addresses` vs the OPS row above; `last_seen` advancing.
5. Did the box reboot or lose link? `journalctl --list-boots \| tail -3`, `grep -E 'DHCP|Link is' /var/log/syslog \| tail`; Grafana `host_boot_time`.
6. Firewall: `sudo iptables -S INPUT \| head`.
7. **Is the client on the same LAN?** Check the device's own IP and gateway before blaming the server (a phone/laptop on a carrier modem's Wi-Fi is on another subnet and times out). Then `sudo tcpdump -ni <iface> tcp port 4857` while the client retries: no packets = network.
8. Printer side: `nc -zv` 9100; Energy Star/sleep makes the reachability check flap.

## Telemetry
Loki `{service_name="print-server"} | site="<SITE>"`. Prometheus (job `print-server`, labels `site`, `instance`): `print_check_ok{check,queue}`, `host_boot_time`, `host_uptime`, `host_network_receive_bytes_total`. Dashboard "Print Servers" uid `a8cnqb` (folder Manufacturing), alert group `print-servers` (see `grafana.md` Alerts). During an incident use only the Grafana MCP. Gap in metrics = box down or no network, not a Vector bug, until proven.
