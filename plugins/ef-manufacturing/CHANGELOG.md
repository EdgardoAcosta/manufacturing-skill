# Changelog

## v1.0.1 - 2026-10-30

The skill states that `dev-status.sh`, `new-issue.sh` and `bump.sh` run as the work GitHub account (`GH_TOKEN=$(gh auth token --user EdgardoAcostaEF)` in front of each call); the scripts stay account-agnostic. Needed when the personal account is the active `gh` account, as on a machine that installs this marketplace over SSH.

## v1.0.0 - 2026-10-30

Initial release. Moves the skills that lived in `~/.claude/skills/` (manufacturing, bump-core-pkg, uxmaltech-boui) and in `ef-manufacturing/.claude/` (legacy-pr-ui-review, cbq-concurrency-test, agent ui-checklist-tester) into one plugin. Script paths are now relative to each skill's base directory; `bump.sh` no longer depends on BSD sed; Playwright paths in review-and-qa are machine-neutral.
