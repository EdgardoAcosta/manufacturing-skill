# ef-manufacturing plugin

Skills, scripts and one agent for the EnviaFlores Manufacturing migration work.

| Item | Kind | Use |
|---|---|---|
| `manufacturing` | skill | Team, board 59, issues, legacy research, Grafana, Notion, Obsidian, review and QA, releases, CBQ, workshop print servers and ZPL labels. Scripts `dev-status.sh`, `new-issue.sh`, `labeler-test.sh`, templates. |
| `bump-core-pkg` | skill | Bump manufacturing-core-pkg in the host and push main. Script `bump.sh`. |
| `uxmaltech-boui` | skill | AdminLTE to BOUI migration conventions. |
| `legacy-pr-ui-review` | skill | Review and Playwright-test a legacy-port PR or local change. |
| `cbq-concurrency-test` | skill | Live concurrency test of the EventCommands/CBQ toolkit. Scripts under `scripts/`. |
| `ui-checklist-tester` | agent | Runs the Errores comunes UI checklist on a migrated screen. Needs the `.claude/ui-checks/` harness inside the ef-manufacturing checkout. |

Install: `/plugin install ef-manufacturing --marketplace EdgardoAcosta/manufacturing-skill` (or add the marketplace first, see the repository README).

Script paths in every SKILL.md are relative to that skill's base directory (Claude Code prints it when the skill loads).

Not in the plugin, copy by hand to a new machine: `~/.claude/CLAUDE.md`, `~/repository/enviaflores/CLAUDE.md`, the project memory under `~/.claude/projects/<project dir>/memory/`, MCP servers in `~/.claude.json`, `gh` login, SSH keys, the `.claude/ui-checks/` harness of the ef-manufacturing repo.
