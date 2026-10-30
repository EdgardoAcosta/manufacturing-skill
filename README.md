# claude-skills

Personal Claude Code marketplace. One plugin today: `ef-manufacturing`.

## Install

From GitHub:

```
/plugin marketplace add EdgardoAcosta/manufacturing-skill
/plugin install ef-manufacturing@edgardo-skills
```

From a local checkout (how the Mac that edits the skills should run it):

```
/plugin marketplace add ~/repository/personal/claude-skills
/plugin install ef-manufacturing@edgardo-skills
```

Restart Claude Code, then `/plugin` lists the skills under the `ef-manufacturing:` namespace. Remove any standalone copy of the same skills from `~/.claude/skills/` and from a repo's `.claude/skills/`, otherwise both load.

## Change a skill

1. Edit `plugins/ef-manufacturing/skills/<name>/` in the checkout, never the installed copy.
2. Bump `version` in that SKILL.md and in `plugins/ef-manufacturing/.claude-plugin/plugin.json`; add a line to `plugins/ef-manufacturing/CHANGELOG.md`.
3. `claude plugin validate ./plugins/ef-manufacturing --strict && claude plugin validate . --strict`
4. Commit, push. On every machine: `/plugin update ef-manufacturing@edgardo-skills` (installed plugins do not auto-update).

## Layout

```
.claude-plugin/marketplace.json
plugins/ef-manufacturing/
  .claude-plugin/plugin.json
  skills/<name>/SKILL.md (+ scripts/, templates/)
  agents/ui-checklist-tester.md
  CHANGELOG.md
  README.md
```
