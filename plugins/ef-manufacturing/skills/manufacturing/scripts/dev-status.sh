#!/usr/bin/env bash
# Per-dev workload on GitHub project 59 (enviaflores). Usage: dev-status.sh [login ...]
set -euo pipefail
PROJECT_ID=PVT_kwDOAEdJu84BHxyJ
CACHE=${TMPDIR:-/tmp}/mfg-project59-items.json
ACTIVE='Definition|Backlog|In Progress|Hold|PR Ready|PR In review|PR Approved|Ready for Demo|Ready for test|Staging|QA Testing|Rejected by QA'

fetch() {
  local cursor="" out="[]"
  while :; do
    local page
    page=$(gh api graphql -f id="$PROJECT_ID" -f after="$cursor" -f query='
      query($id:ID!,$after:String){node(id:$id){... on ProjectV2{items(first:100,after:$after){
        pageInfo{hasNextPage endCursor}
        nodes{
          status:fieldValueByName(name:"Status"){... on ProjectV2ItemFieldSingleSelectValue{name}}
          sprint:fieldValueByName(name:"Sprint"){... on ProjectV2ItemFieldIterationValue{title startDate}}
          proj:fieldValueByName(name:"Project"){... on ProjectV2ItemFieldSingleSelectValue{name}}
          content{__typename ... on Issue{number title url updatedAt repository{nameWithOwner} assignees(first:10){nodes{login}}}
                             ... on PullRequest{number title url updatedAt repository{nameWithOwner} assignees(first:10){nodes{login}}}}
        }}}}}' )
    out=$(jq -s '.[0] + .[1].data.node.items.nodes' <(echo "$out") <(echo "$page"))
    [ "$(echo "$page" | jq -r .data.node.items.pageInfo.hasNextPage)" = true ] || break
    cursor=$(echo "$page" | jq -r .data.node.items.pageInfo.endCursor)
  done
  echo "$out" > "$CACHE"
}

if [ -n "${REFRESH:-}" ] || [ ! -s "$CACHE" ] || [ -n "$(find "$CACHE" -mmin +10)" ]; then fetch; fi

today=$(date +%F)
filter=$(jq -cn '$ARGS.positional' --args "$@")

jq -r --arg today "$today" --arg active "$ACTIVE" --argjson only "$filter" '
  [ .[] | select(.content.number != null) | select((.status.name // "") | test("^(\($active))$"))
    | . as $i | ($i.content.assignees.nodes | if length==0 then [{login:"(unassigned)"}] else . end)[]
    | {login, status:($i.status.name), sprint:($i.sprint.title // "-"), sprintStart:($i.sprint.startDate // ""),
       proj:($i.proj.name // "-"), n:$i.content.number, repo:$i.content.repository.nameWithOwner,
       title:$i.content.title, updated:$i.content.updatedAt[0:10]} ]
  | map(select(($only|length)==0 or (.login as $l | $only | index($l))))
  | group_by(.login)[]
  | . as $g
  | "\n## \($g[0].login)  (\($g|length) active" +
      (if any($g[]; .status=="In Progress") then ")" else ", NO In Progress)" end),
    ( $g | group_by(.status)[] | "  \(.[0].status): \(length)" ),
    ( $g | sort_by(.updated) | reverse | .[] |
      "    \(.status) | \(.sprint) | \(.repo|split("/")[1])#\(.n) | \(.updated) | \(.title[0:90])" )
' "$CACHE"
