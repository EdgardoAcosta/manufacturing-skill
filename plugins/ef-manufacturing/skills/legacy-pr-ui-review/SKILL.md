---
name: legacy-pr-ui-review
version: 1.0.0
description: Review and test changes that port a legacy screen into manufacturing-core-pkg — either a PR (ours or a teammate's) or local code not pushed yet (a bug branch, uncommitted work). Legacy is the source of truth, every claim is validated against legacy code or the DB, the definitive test is a Playwright run on the real screen, and the output is a pass/fail matrix. Use when the user asks to "test this PR", "review Julio's/Jorge's changes", "test my changes", "is the fix done?", "run the full test", or "run the Obsidian bug list against this screen".
---

# Legacy-port review and UI test (PRs and local code)

How we review and test changes that migrate legacy admin screens (CakePHP: `enviaflores-admin-talleres`, `enviaflores-admin-suministros`, `administracion-enviaflores`, the OPS API `ops-enviafores-api`) into `manufacturing-core-pkg` and the `ef-manufacturing` host.

## Rules that are not negotiable

1. **Legacy is the source of truth.** The business logic (filters, exclusions, validations, texts, side effects, order of operations) is whatever legacy does. Port it exactly. A "better" behavior is a bug unless it fixes a legacy defect, and that fix must be flagged as such.
2. **Do not assume. Validate against legacy.** Every claim in a finding must point to evidence: a legacy file and line, a DB query result, or a captured request/response. If you cannot find evidence, say "not verified" or ask. Never present a guess as a fact ("the user is confused", "this is probably intentional").
3. **The Playwright UI test on the real screen is the definitive test.** Calling a command or query directly, or a passing Pest suite, does **not** prove the feature works. A fix is only "done" when a real click in the browser produces the right request, the right DB change, and the right UI state. Direct calls are allowed only as supporting evidence (timing, totals, payload shape), never as the verdict.
4. **The output is a pass/fail matrix.** Every tested point gets a row with ✅ Pass, ❌ Fail, ⚠️ Partial/minor, ⏭️ Deferred (with reason), or "Not tested" (with reason).
5. **Read-only by default.** Writes only on the test workshop (103195, Pruebas TI) and test supplier, with labeled data left in place. DB access: `SELECT … LIMIT` only. Never write to real workshops even in dev (the dev DB is a daily prod copy).
6. **No outward writes without an explicit OK.** Drafting a PR comment is fine; posting it, committing, pushing, tagging or releasing needs the user's yes for that specific action.

## Two modes

| | PR mode | Local mode |
|---|---|---|
| What | An open PR or a stack of PRs (ours or a teammate's) | Our own branch or uncommitted work, not pushed yet |
| Code under test | `git checkout --detach origin/<head>` in the package | The working copy as it is (`git status`, `git diff`, `git diff --cached`) |
| Input for step 2 | Earlier review comments on the PR(s) + author replies | The issue (GitHub/Notion), its reproduction steps, and the user's notes |
| Fixing bugs found | Never edit the branch: describe the fix in the comment | Fix them in the same branch, then re-run the affected rows |
| Output | Matrix + draft PR comment | Matrix + list of changed files, ready for the user to approve the commit |

In local mode, **reproduce the bug first** on the unfixed code (or explain why it can't be reproduced) before testing the fix, and run the whole checklist against every screen the change touches, not only the reported bug.

## Workflow

### 1. Scope
- **PR mode:** list the PR(s) with `gh pr view N --json headRefName,baseRefName,commits`. For stacked PRs, map the full chain (each base → head) and check for branches in the chain **without** their own PR. Get the exact head SHA; if the history was rewritten, diff against the last tested SHA (`git diff <old> <new> --stat`) so you test everything new, not only the latest commit.
- **Local mode:** record the branch, the base it came from, and the full set of changes (committed on the branch + staged + unstaged). Make sure nothing unrelated is mixed in (other features, dev-only toggles like the composer path symlink); if it is, list it and leave it out of the scope.
- Both: list the touched files vs the base: new commands, queries, UI classes, JS files. This is your test inventory: every command, query, screen, tab, filter, button and modal in that list gets a row.

### 2. Gather what was already said
- **PR mode:** read every earlier review comment on all PRs of the stack (yours and others'). Each point becomes a row to re-test. Read the author's replies and docs: a point explicitly deferred with a reason is ⏭️ Deferred, not a fail. Check that the reason is real.
- **Local mode:** read the issue and its reproduction steps, related issues on the same screen (test them together: sibling fixes can break each other), and the Obsidian tracker row. Each reported symptom becomes a row.

### 3. Read legacy for each feature
For every screen, tab, filter and action:
- Open the legacy view (`.ctp`), its JS (`View/<Controller>/js`, `tabs/js`), the controller action and the OPS model method it calls.
- Write down: which filters it sends and how, what each button does, confirm texts, success/error messages, what the backend writes (tables, columns, actor), what it excludes, and any side effects (cache, websockets, logs).
- Compare the port against that list, item by item. Missing actions, unwired buttons, different texts and missing side effects are parity bugs.

### 4. Static checks (fast, before the UI)
- Every new command and query has a `check.permission:` middleware.
- Every command call from JS sends `sync: true` and decides success with `cmdOk` / `cmdErr`.
- Every rendered button or filter has a JS listener. grep the class or field name in `resources/js`: rendered but never listened to = dead UI.
- Error paths: business errors show the real reason; DB errors go through the shared error helper; `LegacyActor::idOrFail()` failures are not swallowed into a generic message.
- Run the package Pest suite in the container (raise the memory limit if needed). Compare failures against `main`: only new failures count.

### 5. Environment
- Make sure the container serves the code under test: the PR head (PR mode) or your working copy (local mode), through the path-symlinked package. Clear caches and rebuild assets (`npm run build` in the container) after every JS change.
- Make sure the CBQ daemon is running and the queue is empty before testing writes. Restart it after PHP changes (it caches code).
- Check which workshop the screen resolves for your account. If it is not the test workshop and the param is ignored, **stop all writes** and ask the user.
- Dev adds ~8–9 s per request. A 422 or slow grid in dev must be re-checked with a direct timed call before reporting it as a bug.

### 6. Playwright UI test
One browser session for the whole run (reuse the login; only ask the user to log in if the session lands on SSO). For each tab or screen:
- Load: rows appear, columns match legacy, no console errors.
- Every filter: choose a value with a real click, capture the request payload, confirm the row count changes and matches a `SELECT COUNT` in the DB, then clear it and confirm it returns to the base count.
- Search: by text and by numeric id; compare with what legacy searched.
- Every button: click it. Dialogs must open with the legacy text; Cancelar must send nothing. Confirm writes only on the test workshop, then verify with `SELECT … LIMIT`.
- Modals: open → cancel/X → reopen must be clean; save → reopen must be clean; double click must send one request.
- Detail pages: every tab or grid loads, images load (check `naturalWidth` and console 404s), breadcrumbs work.
- Dependent fields (A loads B): change A, confirm B is cleared and the old B value is no longer in the request.
- Record evidence for every row: request body, count, DB value, console errors.

### 7. Run the consolidated common-errors checklist
Run every item of the list below against every touched screen. Each item is a row in the matrix.

## Consolidated common-errors checklist

Grouped from the recurring QA defects (Notion issues and earlier PR reviews). Check all of them, every time.

**Commands and saving**
1. Save says "error" although it saved, or the other way round. Every `cmd.*` call needs `sync: true`, and the real result decides the toast and the modal close.
2. Double click creates duplicates. The button must lock while saving and unlock on error.
3. Wrong actor or "No autorizado". Legacy columns need the legacy user id (`LegacyActor`), not the SSO id. Commands run in the daemon without a session. A user without a legacy id must get a clear reason.
4. Useless error message or raw SQL in the UI. Business errors show the real reason; DB errors are translated.

**Grids, filters and search**
5. Filters do not filter, or "Aplicar" gives a 500. Watch for vendor column filters, list options sending indexes instead of ids, falsy values (`0`) dropped by the UI library (use non-falsy values like `yes`/`no`), and chips showing `[object Object]`.
6. Search does not search, finds nothing, or gives a 500. Compare searched fields with legacy (id, SKU, name, creator…), test numeric and text terms, watch joined/qualified columns and AND vs OR.
7. Clicking a sortable header gives a 500. Sort every sortable column both ways.
8. Filters or page lost on reload. Grids using the table filter need `persistState()`. Custom filter panels outside the grid are only justified when a filter needs remote search.
9. Slow grid → 422 or "An error happened while fetching the data". Check per-row queries and heavy joins against the 10 s grid budget, on a big workshop.
10. Export ignores filters or does nothing. CSV = grid = DB with the same filters.

**Modals and UI**
11. Modals: black screen, they don't close, don't clear, or open empty. Test open → cancel → reopen and save → reopen.
12. Half-built UI. Buttons or filters that are rendered but have no handler, placeholders, "coming soon". Either wire it or don't render it.
13. Dependent selects keep stale values. Changing the parent must clear the child before filtering.
14. Broken images or links. Legacy often stores URLs without a scheme; the UI must add `https://`.

**Data and validation**
15. Quantity validation. Try `1.5`, `0`, `-5`, a value above the pending amount, and a value above the column's maximum. Validate on the server, not only in JS.
16. Legacy parity. Columns, labels, colors, actions, confirm texts and side effects that legacy had. Compare column by column, action by action.
17. Not a code problem. Before changing code, check the data in the DB or storage (empty S3, files never uploaded, missing logs, data issues).

**Navigation and permissions**
18. Menu and names. The menu entry is in the right group with the requested name, and every screen is reachable from the UI (no page that only works by typing its URL).
19. Permission gating. Every new query and command route has a permission check; hidden buttons are also enforced on the server.

## Output

### Matrix (always)
One table per area. Columns: point, result, evidence.

| Point | Result | Evidence |
|---|---|---|
| Área filter in «Líneas activas» | ✅ Pass | 62 → 40, only area 3; request `invt_mfg_area_id:[3]` |
| «Activo» filter in «Administración de líneas» | ❌ Fail | no request sent; no JS listener for `planningAdminActive` |
| Send to production | Not tested | writes blocked: account forced to a non-test workshop |

Sections, in this order:
1. Earlier review comments (each one re-tested).
2. New findings per screen or tab.
3. The common-errors checklist (one row per item).
4. Static checks and Pest (new failures only).
5. What was not tested and why.
6. Verdict: ready to merge or not, in one or two lines.

### Local mode: after the matrix
- Every ❌ found in the touched screens is fixed in the same branch and its row re-run in Playwright until it passes. A fix is not done while its UI row fails.
- Add or update Pest tests for the fixed logic, and run the suite.
- Report the changed files and stop: commit and push only when the user approves, without co-author lines.

### PR comment (PR mode; draft only, post on explicit OK)
- In Spanish, `##`/`###` headings and lists, never `---` separators.
- Bugs and fixes only: no "what works" sections, no side notes unless the user asks.
- Each bug: how to reproduce, where it is (`file:line`), and a simple fix (a short snippet when it helps).
- No AI attribution or co-author lines.
