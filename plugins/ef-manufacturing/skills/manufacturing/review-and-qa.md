# PR review, PR testing and QA bugs

## Before touching a QA issue
Triage first: real defect, or something deliberately dropped/hidden? List ALL sibling sub-issues of the parent (open and closed, `gh api graphql ... subIssues`), read their Notion rows, PR bodies and Edwin's requests. Quote the earlier request. Verdict per issue: valid / not valid (intentional) / needs decision, with evidence, before any branch.

## Working a bug
1. Context: issue + sub-issues + Notion page.
2. Reproduce first on current code (Playwright). Not reproducible = report with evidence, no code.
3. Branch `bug/ISSUE-<n>-<slug>` from main.
4. Fix, then test on the real screen. Writes only on Pruebas TI (103195).
5. PR body ends with `Fixes enviaflores-legacy/ef-manufacturing#<n>`. Commit/push only on my yes.
6. When fixes touch the same screen, test them combined (each control alone + combined + Limpiar, every tab).

## Testing a teammate's PR
- Run every applicable "Errores comunes" pattern from Obsidian `bugs-materials` (filters send a request and survive reload, including inherited ones; modals close with X, Cerrar and Esc, no backdrop left, fields reset on reopen, save then reopen) plus a legacy parity check. Report pass/fail/N.A. per pattern. The `ui-checklist-tester` agent in ef-manufacturing runs this.
- Smoke-test a new script on one case before the full matrix.
- Reproduce races with real clicks; Playwright `fill`/`selectOption` bypass blockScreen overlays.
- Found a bug: describe the fix (file + snippet). Don't edit their branch unless I say "apply it".
- Comment draft for me: only bugs + example fixes (passing results stay in chat), `##`/`###` headings and lists, no `---` separators. No bugs = say so, nothing to post. I post it.

## Copilot findings
- Check each finding against legacy (file:line + data) before acting. Legacy does the same = keep parity and add a one-line "legacy behavior" comment. Only visible-nothing fixes (e.g. skip an unused query) go in.
- On my own PRs fix only findings my change introduced; list pre-existing ones as follow-ups.
- After each push to a PR branch: `gh pr edit <n> --add-reviewer copilot-pull-request-reviewer`. Loop per branch: findings -> fix -> full Pest + headed UI test -> push -> request again, until clean. If findings churn round after round, stop and ask.

## Playwright (ef-manufacturing dev, https://ef-manufacturing.localhost)
- One session: use the MCP's default page; never open extra contexts/pages.
- SSO expired: click "Ingresar con Google" yourself (the browser keeps the Google session). Never ask me to log in. Save `storageState` to `~/.claude/projects/<this project's dir>/playwright-state.json` after login; restore cookies for `ef-manufacturing.localhost` + `ef-auth-staging.enviaflores.com` with `addCookies`.
- "Browser already in use": copy the MCP profile (macOS `~/Library/Caches/ms-playwright-mcp/<profile>`, Linux `~/.cache/ms-playwright-mcp/<profile>`) (rsync excluding `Singleton*`, `*Cache*`, `Service Worker`) and `launchPersistentContext(copy, {channel:'chrome', ignoreHTTPSErrors:true})`. Don't kill the other session's Chrome.
- Faked responses: delay with `page.waitForTimeout`, never `setTimeout`; wrap handlers in try/catch with `route.abort()` in catch; wait for held requests before `unrouteAll`. A crashing handler once let 2 real writes through.
- When clearing cookies to fix a staging 500, clear only ef-manufacturing-staging / ef-auth-staging cookies, never Google's.
- TomSelect: `el.tomselect.setValue`; sync commands take ~8 s in dev.

## Assign a QA bug to its dev
1. Bug's parent Story -> its sub-issues -> assignee + author of the PR that closed each one (`closedByPullRequestsReferences`). The dev of the sibling that built the screen owns the bug.
2. If the bug may live in another module (e.g. data written by a different screen), check that Story's sub-issues too.
3. Confirm with `git log --format='%an <%ae>'` on the files in core-pkg. Old commits by "David Peña" <david.vazquez@> predate the current team; ownership goes to whoever fixed it later.
4. Preview `gh issue edit <n> --add-assignee <dev> --remove-assignee EdgardoAcostaEF`, run on yes. Severity stays for me to set.
