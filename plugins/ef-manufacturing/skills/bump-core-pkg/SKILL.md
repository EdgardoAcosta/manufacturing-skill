---
name: bump-core-pkg
version: 1.0.0
description: Bump manufacturing-core-pkg in the ef-manufacturing host to a released tag and push main (staging deploy). Use when Edgardo says "new version of core vX.Y.Z", "bump core", "deploy core to staging". Looks up the latest tags, confirms the tag with him, regenerates composer.json/lock from HEAD, commits "Bump manufacturing-core-pkg to vX.Y.Z" with no co-author and pushes main only. Never tags or releases the host.
---

# Bump manufacturing-core-pkg in the host

Script paths below are relative to this skill's base directory. Host repo: `~/repository/enviaflores/ef-manufacturing`. Package: `enviaflores-legacy/manufacturing-core-pkg`. Push to `main` = staging deploy. A host tag = prod: never create one here.

## Steps

1. **Find the candidate tag.** Use the GitHub API, not `git fetch` (SSH to GitHub has hung mid-session):
   ```bash
   scripts/bump.sh --tags
   ```
   Prints the 3 newest tags with date, the release notes of the newest one, the commits since the tag the host pins today, and whether any permission/config file changed.
2. **Confirm with Edgardo** (AskUserQuestion): "Bump host to `<newest tag>`?" with the release notes summarised in one line per PR. If he named a version, offer that one first; if it is not the newest, say which is newer. This confirmation is the approval for the commit and the push; do not ask again afterwards.
3. **Regenerate and apply:**
   ```bash
   scripts/bump.sh vX.Y.Z
   ```
   The script checks out `main` (refuses if tracked files are modified), pulls fast-forward, rebuilds `composer.json`/`composer.lock` from `HEAD` in a scratch dir (never from the working tree, which may be in dev path mode), restores `plugin-api-version` to the value on `HEAD`, and prints the diff. It refuses if any changed line is outside the core-pkg block and the content-hash.
4. **Commit and push:**
   ```bash
   scripts/bump.sh vX.Y.Z --commit
   ```
   Commit message `Bump manufacturing-core-pkg to vX.Y.Z`, no co-author or attribution lines, only `composer.json` and `composer.lock` staged, `git push origin main`.
5. **Report:** commit sha, what the tag contains (PR list), new permissions if the tag added any (they go to the host `config/uxmaltech-auth-permissions.php` in a separate change, see `manufacturing` skill `releases.md`), and that staging deploys in about 10 minutes. The host has no `/build-info` route; verify by opening one of the changed screens on staging.

## Rules
- Only `main`, only `composer.json` + `composer.lock`. Any other dirty tracked file blocks the run.
- If the SSH `composer update` hangs or fails, do not hand-edit the lock; report it.
- `ef-administration` gets the same bump only when asked.
