---
name: manufacturing
version: 1.0.0
description: EnviaFlores Manufacturing migration context and playbooks. Use for anything about the manufacturing team or its GitHub project 59 - creating or filling Epic/Story/Task/Bug issues, researching legacy screens (talleres, suministros, OPS, admin-api), Grafana/Loki/Tempo telemetry for ef-manufacturing or the app backend, checking what each dev (Jorge, Julio, Guillermo, Dali) is working on or whether they have tasks, assigning QA, reading the Notion migration databases or the Obsidian manufacturing notes, and reviewing/testing teammates' PRs, and shipping (commit/PR, core-pkg release, host composer bump, permissions).
---

# Manufacturing

Roster, test boundaries and repo map are in `~/repository/enviaflores/CLAUDE.md` (always loaded inside enviaflores repos). This skill holds the playbooks. Read only the file the task needs.

| Task | Read |
|---|---|
| Who is who, modules per dev, QA rotation, unknown board logins | `team.md` |
| Create or fill an issue (Epic / Story / Task / Bug), project 59 fields | `issues.md` + `templates/` + `scripts/new-issue.sh` |
| Find how a legacy screen works (repo, controller, tables, rules) | `legacy-research.md` |
| Telemetry: errors, latency, alerts, dashboards, ECS/ALB | `grafana.md` |
| What is each dev doing, who has no task, my pending work | `scripts/dev-status.sh` (see `team.md`) |
| Notion databases, @mentions, QA User field | `notion.md` |
| Obsidian notes (trackers, checklists, runbooks) | `obsidian.md` |
| Review or test a teammate's PR, work a QA bug | `review-and-qa.md` |
| Commit/PR, core-pkg release + host bump, permissions for new screens | `releases.md` |
| CBQ brokers and daemons in the dev container (redis, sqs/elasticmq, ordered event commands), never prod | `cbq.md` |

## Always
- Spanish for issue bodies, Notion and team-facing text.
- No code comments by default, config files included. Add one only when the code is not self-explanatory or encodes a business rule, then one line, always in English. No block headers, no "why we chose this" (that goes in the commit/PR).
- Preview anything outward (issue, Notion row, Grafana rule) and wait for an explicit yes. Never post GitHub comments; status notes go to Obsidian.
- Legacy is the business-logic source of truth. Parity first; deviate only for real defects (wrong data, lost rows, security) and list them.
- Diagrams: in a presentation or deck, build them with the `archify` skill (export the diagram only, no cards or index, into the slide). In Obsidian notes, use mermaid.
- Keep this skill current: when I learn a durable fact about the team, the board, legacy or telemetry, edit the matching file in the skills repo checkout (`~/repository/personal/claude-skills/plugins/ef-manufacturing/skills/manufacturing/`), never the installed plugin copy, then push and run `claude plugin update ef-manufacturing@edgardo-skills`. Do not write a new memory for it.
