# Ship, release, bump, permissions

Every step that commits, pushes, tags or opens a PR needs my explicit yes for that step.

## Ship a branch ("commit and open the PR")
1. Full Pest + headed UI test pass first (see `review-and-qa.md`).
2. Short commit message, no attribution, one commit per fix on multi-fix branches.
3. Push the package branch only (`manufacturing-core-pkg`), never the ef-manufacturing host.
4. PR base: `main` unless I name a feature base (e.g. `feat/inventory`). Body short, ends with `Fixes enviaflores-legacy/ef-manufacturing#<n>` when it closes an issue.
5. Request Copilot review and start the Copilot loop.

## Release core-pkg + bump host ("new tag vX.Y.Z, you know the drill")
1. Core-pkg: I create the tag or ask for a draft release (`gh release create vX.Y.Z --draft`) only on my yes.
2. Host `ef-manufacturing`: use the `bump-core-pkg` skill (same plugin): it lists the newest tags, confirms the tag with me, regenerates from HEAD, commits and pushes main. Manual fallback: the working tree may keep composer.json/lock in dev path mode (`*@dev` + path repo `../manufacturing-core-pkg`). Never commit that diff. Regenerate from HEAD instead:
   1. Back up the working composer.json/lock to the scratchpad.
   2. `git show HEAD:composer.json` and `HEAD:composer.lock` into a scratch dir; sed the core-pkg version.
   3. In that dir: `GIT_SSH_COMMAND='ssh -i ~/.ssh/ef_ed25519 -o IdentitiesOnly=yes' composer update enviaflores/manufacturing-core-pkg --no-install --no-scripts --no-plugins --no-interaction --ignore-platform-reqs` (default mac key is the personal account; `composer clearcache` if the tag isn't seen).
   4. Diff vs HEAD: only the core-pkg block + content-hash may change. Copy both files in, commit only composer.json + composer.lock (+ permissions manifest if it changed), then restore the backups.
3. Push host main = staging deploy. Never tag/release the host (tag = prod).
4. Same bump in `ef-administration` when I ask.
5. After the staging deploy (~10 min), run the staging regression pass: every manufacturing screen loads, grids/filters work, writes only on Pruebas TI 103195. Results go to Obsidian `EF/projects/manufacturing/migration/`.

## Permissions for new screens
- New permission keys go in the host `config/uxmaltech-auth-permissions.php` in the matching section; I sync them to the auth server myself.
- Systems still on the old auth need the equivalent rows in the manufacturing DB; give me the INSERT SQL, never run it.
- List new permissions in the release notes; don't flag them as a deploy step.
- "Page not visible / empty menu": check the query/menu permission gate, then the SSO permission cache (dev/staging 500 "Permissions fetch failed [400]" = cold SSO perm snapshot, see ef-manufacturing memory `sso-perm-cache-workaround`).
