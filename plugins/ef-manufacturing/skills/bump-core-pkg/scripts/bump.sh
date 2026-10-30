#!/usr/bin/env bash
# Bump enviaflores/manufacturing-core-pkg in the ef-manufacturing host.
#   bump.sh --tags            show newest tags, release notes and commits since the current pin
#   bump.sh vX.Y.Z            regenerate composer.json/lock on main and print the diff
#   bump.sh vX.Y.Z --commit   same, then commit (no co-author) and push origin main
set -euo pipefail

HOST="${HOST_REPO:-$HOME/repository/enviaflores/ef-manufacturing}"
PKG="enviaflores/manufacturing-core-pkg"
GH_REPO="enviaflores-legacy/manufacturing-core-pkg"
SSH_CMD='ssh -i ~/.ssh/ef_ed25519 -o IdentitiesOnly=yes -o ConnectTimeout=20'

current_pin() {
  git -C "$HOST" show origin/main:composer.json | jq -r --arg p "$PKG" '.require[$p]'
}

if [[ "${1:-}" == "--tags" ]]; then
  git -C "$HOST" fetch -q origin main
  pin=$(current_pin)
  echo "host main pins: $pin"
  echo "== newest tags"
  gh api "repos/$GH_REPO/tags?per_page=3" -q '.[] | .name + " " + .commit.sha[0:7]'
  newest=$(gh api "repos/$GH_REPO/tags?per_page=1" -q '.[0].name')
  echo "== release $newest"
  gh release view "$newest" -R "$GH_REPO" --json publishedAt,body -q '.publishedAt + "\n" + .body' 2>/dev/null || echo "(no release object for $newest)"
  echo "== commits $pin...$newest"
  gh api "repos/$GH_REPO/compare/$pin...$newest" -q '.commits[] | .sha[0:7] + " " + (.commit.message | split("\n")[0])'
  echo "== permission/config files touched"
  gh api "repos/$GH_REPO/compare/$pin...$newest" -q '.files[].filename' | grep -i 'permission\|manifest\|^config/' || echo "(none)"
  exit 0
fi

version="${1:?usage: bump.sh --tags | bump.sh vX.Y.Z [--commit]}"
commit="${2:-}"
[[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "bad version: $version" >&2; exit 1; }
gh api "repos/$GH_REPO/git/ref/tags/$version" -q .ref >/dev/null || { echo "tag $version not found on $GH_REPO" >&2; exit 1; }

cd "$HOST"
if [[ -n "$(git status --porcelain --untracked-files=no | grep -v ' composer\.\(json\|lock\)$' || true)" ]]; then
  echo "tracked files modified in $HOST; refusing" >&2
  git status --short --untracked-files=no >&2
  exit 1
fi
git checkout -q main
git pull -q --ff-only origin main

pin=$(jq -r --arg p "$PKG" '.require[$p]' <(git show HEAD:composer.json))
[[ "$pin" == "$version" ]] && { echo "main already pins $version"; exit 0; }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
git show HEAD:composer.json > "$scratch/composer.json"
git show HEAD:composer.lock > "$scratch/composer.lock"
plugin_api=$(jq -r '."plugin-api-version"' "$scratch/composer.lock")
sed -i.bak "s|\"$PKG\": \"$pin\"|\"$PKG\": \"$version\"|" "$scratch/composer.json" && rm -f "$scratch/composer.json.bak"

( cd "$scratch" && GIT_SSH_COMMAND="$SSH_CMD" timeout 180 composer update "$PKG" \
    --no-install --no-scripts --no-plugins --no-interaction --ignore-platform-reqs 2>&1 | tail -4 )

sed -i.bak "s|\"plugin-api-version\": \"[^\"]*\"|\"plugin-api-version\": \"$plugin_api\"|" "$scratch/composer.lock" && rm -f "$scratch/composer.lock.bak"
cp "$scratch/composer.json" composer.json
cp "$scratch/composer.lock" composer.lock

echo "== diff"
git --no-pager diff --stat -- composer.json composer.lock
changed=$(git --no-pager diff -U0 -- composer.json composer.lock | grep '^[-+]' | grep -v '^[-+][-+]' || true)
echo "$changed"
if echo "$changed" | grep -v 'manufacturing-core-pkg\|content-hash\|"version":\|"reference":\|"url":\|"time":' | grep -q .; then
  echo "diff touches lines outside the core-pkg block; not committing" >&2
  exit 1
fi

if [[ "$commit" == "--commit" ]]; then
  git add composer.json composer.lock
  git commit -q -m "Bump manufacturing-core-pkg to $version"
  git push -q origin main
  echo "== pushed"
  git log -1 --format='%h %s'
fi
