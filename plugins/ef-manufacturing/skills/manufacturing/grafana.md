# Grafana and telemetry

Grafana: https://grafana.enviatechnologies.com (OSS 13.1). Use the Grafana MCP; if it is down or times out, use `gcx` (context `local`: `gcx traces query -d tempo`, `gcx metrics query -d prometheus`, `gcx dashboards get <uid> -o json`) or REST with the token in `~/.claude.json` -> `mcpServers.grafana.env` (never print it). No local `aws` CLI: CloudWatch goes through Grafana.

## Datasources
Prometheus `prometheus` · Loki `P8E80F9AEF21F6940` · Tempo `tempo` · CloudWatch `P561CB7FAE9DC47C2` (us-west-2; POST `/api/ds/query`, `matchExact: true` or you get duplicate AZ/TG series). Collector: https://collector.enviatechnologies.com (OTLP/HTTP).

## Services
| System | service_name | Runs on |
|---|---|---|
| Admin UI (host `ef-manufacturing`) | `ef-manufacturing` prod, `ef-manufacturing-staging` | ECS `enviaflores-prod`: `ef-manufacturing` (web, 4-6 tasks), `ef-manufacturing-cbq` (2 tasks, emits no telemetry). ALB `app/ecs-prod/5dedd765565556b8`, TGs `efmfg-prod-blue/eb99a1b1abce5f3a`, `efmfg-prod-green/ba367e039b629f96` |
| Mobile backend | `ef-manufacturing-app-be` (staging uses the same name) | ECS `ef-manufacturing-app-be` (web) + `ef-manufacturing-app-be-cbq`. TGs `efmfgbe-prod-blue/39ff97b0684333e2`, `efmfgbe-prod-green/06098f7115062859` |
| Flutter app | `manufacturing-flutter` (builds >= 1.0.14), `manufacturing-product-flutter` (<= 1.0.13) | devices |
| Legacy ops app | `ef-operations-mobile-*` | devices |

Infra source: `enviaflores/system-operations` `terraform/ecs/ef-manufacturing.tf`. Prod deploy = CodePipeline on semver tag of host main.

## Query rules
- Every Loki query carries `deployment_environment_name="production"|"staging"`; every TraceQL query `resource.deployment.environment.name="..."`. Prometheus spanmetrics have no env label (staging and prod mixed for app-be).
- `service_name="ef-manufacturing"` is polluted by ef-lastmile (copy-pasted OTEL name, `service_version="1.0.0"`, no ECS attrs). Filter `aws_ecs_task_family="ef-manufacturing"`.
- Loki errors live in structured metadata (`error_message`, `error_stack`, `detected_level`, `exception_message`), not the line body: use `| detected_level="error"` or `| error_message=~".+"`, not `|~ "error"` (matches Spanish text and business 422s).
- App-be: each HTTP request logs a `[CBQ] ... deprecated` WARN with `http_target`; counting those = requests that reached PHP (tells edge 503s from app errors).
- Flutter failures: Loki `service_name="manufacturing-flutter"`, fields `error_reason`, `http_response_status_code`.
- Prometheus keeps about 2 h only. Anything longer (SLO windows, `increase[7d]`) is garbage: use CloudWatch (ALB/ECS, 14d+) or Tempo search (max 168h per query).
- Two spanmetrics generations: `traces_spanmetrics_*` (labels service, span_name, span_kind, status_code) and `span_metrics_*` (service_name, http_route, aws_ecs_task_family, service_version; no http status code).
- Span status=error is set only for HTTP >= 500; 4xx are OK.
- Flutter span attrs `device.simulator` and `app.debug` are booleans in Tempo: compare `!= true`, never `!= "true"` (string never matches). In Loki they are strings (`app_debug="true"`).
- TraceQL metrics are expensive: intrinsics ~40 MB/h, `by(span.<generic attr>)` ~11x more; parallel 6h queries 504. Prefer Prom spanmetrics for name-level panels, intrinsics or dedicated columns otherwise. Tempo cannot back alert rules.
- Big responses (`alerting_rules_read list`) overflow context: dump to file and parse with jq.

## Dashboards (folder Manufacturing, uid `eft3is0zgnjswb`)
BackEnd `edfxb8z` · Admin `edbw9w4` (Prom span_metrics, v6) · SLA `sla-manufacturing` (prod only) · Flutter app `edg8s8h` · Ops app legacy `ops-app-legacy`. Old `manufacturing-laravel-app` series = stray old image, not real traffic.

## Alerts
- Rule groups in folder Manufacturing (30 rules, 2026-10-29): `ef-manufacturing-app-be` (10 MFG-BE), `manufacturing-flutter` (7 MFG-APP), `ef-manufacturing` (7 MFG-UI), `print-servers` (6 PRINT). Every rule has `runbook_url` (`obsidian://` heading links until the swap to the Notion Runbooks rows runs; script `swap_runbook_urls.sh --dry-run|--apply` in the 2026-10-29 session scratchpad, per-UID PUT); provenance is empty, so per-UID PUT on `/api/v1/provisioning/alert-rules/{uid}` works, never a group write. Labels `team=manufacturing`, `system`, `severity` -> contact point `Manufacturing` (Slack `ef-manufacturing-team`), repeat 4 h.
- New rules only in folder Manufacturing, in a new rule group (group writes re-save existing rules). Never edit, pause, move or delete any existing rule; there are 72 org-wide rules from other teams. Propose fixes to existing rules, don't apply them.
- Build alerts CloudWatch-first (ALB 5xx ratio, TargetResponseTime p95, UnHealthyHostCount, ECS RunningTaskCount; "cbq down" = RunningTaskCount < 2), Loki bursts as safety net, Prometheus only for <= 10 min windows. Copy the `baseline:` annotation style of SF-* rules.
- Prod baselines (2026-09-30, 14d): admin 5xx ~1.2 % of ~9.7k req, ALB p95 hourly median 0.41 s, Loki ERROR 3-33/day.
- The 4 Loki-backed MFG-APP rules (5xx burst, login failing, bearer rejected, session-expired loop) carry `| app_debug!="true"` since 2026-10-27: QA/dev debug builds can be compiled with `ENVIRONMENT=production` against prod OPS and used to page. Workshop is deliberately NOT filtered. The 3 Prometheus spanmetrics rules cannot filter env or debug (no such labels).

## Staging incidents
Staging ships Tempo + Loki as `ef-manufacturing-staging`, but `deployment.environment.name` was `production` until the OTEL_DEPLOYMENT_ENVIRONMENT fix (uxmaltech/core >= 1.2.0). Verify the host header before trusting a "staging" panel.
