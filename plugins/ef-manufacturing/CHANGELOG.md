# Changelog

## v1.0.0 - 2026-10-30

Initial release. Moves the skills that lived in `~/.claude/skills/` (manufacturing, bump-core-pkg, uxmaltech-boui) and in `ef-manufacturing/.claude/` (legacy-pr-ui-review, cbq-concurrency-test, agent ui-checklist-tester) into one plugin. Script paths are now relative to each skill's base directory; `bump.sh` no longer depends on BSD sed; Playwright paths in review-and-qa are machine-neutral.
