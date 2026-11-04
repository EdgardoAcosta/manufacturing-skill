# Changelog

## v1.0.2 - 2026-11-04

Adds the workshop print servers to the `manufacturing` skill: `print-server.md` (workshop-daemon code map, server layout, labeler API, how the app finds the server through OPS, deploy with `sync-devel.sh`, new Zebra queues, "users can't print" diagnosis, telemetry) and `labels.md` (ZPL template design: Labelary loop, measuring, dpi scaling, QR and font-0 sizes). New script `scripts/labeler-test.sh` posts a test label from the server with queue, printer IP and dpi read live. Site values stay in the private Obsidian runbooks.

## v1.0.1 - 2026-10-30

The skill states that `dev-status.sh`, `new-issue.sh` and `bump.sh` run as the work GitHub account (`GH_TOKEN=$(gh auth token --user EdgardoAcostaEF)` in front of each call); the scripts stay account-agnostic. Needed when the personal account is the active `gh` account, as on a machine that installs this marketplace over SSH.

## v1.0.0 - 2026-10-30

Initial release. Moves the skills that lived in `~/.claude/skills/` (manufacturing, bump-core-pkg, uxmaltech-boui) and in `ef-manufacturing/.claude/` (legacy-pr-ui-review, cbq-concurrency-test, agent ui-checklist-tester) into one plugin. Script paths are now relative to each skill's base directory; `bump.sh` no longer depends on BSD sed; Playwright paths in review-and-qa are machine-neutral.
