#!/usr/bin/env bash
# Create an issue in enviaflores-legacy/ef-manufacturing wired to project 59.
# Usage: new-issue.sh --title T --body-file F --type Task|Bug|Feature|Epic [--parent N] [--assignee LOGIN]
#        [--project "Recibo de material"] [--status Definition] [--sprint "Sprint 22 - 2026"] [--label Story] [--dry-run]
set -euo pipefail
REPO=enviaflores-legacy/ef-manufacturing
PROJECT_ID=PVT_kwDOAEdJu84BHxyJ
F_PROJECT=PVTSSF_lADOAEdJu84BHxyJzg_Babo
F_STATUS=PVTSSF_lADOAEdJu84BHxyJzg4bqx0
F_SPRINT=PVTIF_lADOAEdJu84BHxyJzg4bqys
title= body= type= parent= assignee= project= status=Definition sprint= label= dry=

while [ $# -gt 0 ]; do
  case $1 in
    --title) title=$2; shift 2;; --body-file) body=$2; shift 2;; --type) type=$2; shift 2;;
    --parent) parent=$2; shift 2;; --assignee) assignee=$2; shift 2;; --project) project=$2; shift 2;;
    --status) status=$2; shift 2;; --sprint) sprint=$2; shift 2;; --label) label=$2; shift 2;;
    --dry-run) dry=1; shift;; *) echo "unknown arg $1" >&2; exit 1;;
  esac
done
[ -n "$title" ] && [ -f "$body" ] && [ -n "$type" ] || { echo "need --title, --body-file, --type" >&2; exit 1; }
perl -CSD -ne 'exit 1 if /[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]/' "$body" || { echo "body has emojis, remove them" >&2; exit 1; }

fields=$(gh api graphql -f id=$PROJECT_ID -f query='query($id:ID!){node(id:$id){... on ProjectV2{fields(first:40){nodes{
  ... on ProjectV2SingleSelectField{id options{id name}} ... on ProjectV2IterationField{id configuration{iterations{id title}}}}}}}}')
opt() { echo "$fields" | jq -r --arg f "$1" --arg n "$2" '.data.node.fields.nodes[]|select(.id==$f)|(.options//[])[]|select(.name==$n).id'; }
iter() { echo "$fields" | jq -r --arg n "$1" '.data.node.fields.nodes[]|select(.id=="'$F_SPRINT'")|.configuration.iterations[]|select(.title==$n).id'; }
typeId=$(gh api graphql -f query='{organization(login:"enviaflores-legacy"){issueTypes(first:20){nodes{id name}}}}' | jq -r --arg t "$type" '.data.organization.issueTypes.nodes[]|select(.name==$t).id')
[ -n "$typeId" ] || { echo "unknown type $type" >&2; exit 1; }
projOpt=; [ -z "$project" ] || { projOpt=$(opt $F_PROJECT "$project"); [ -n "$projOpt" ] || { echo "unknown Project option '$project'" >&2; exit 1; }; }
statOpt=$(opt $F_STATUS "$status"); [ -n "$statOpt" ] || { echo "unknown Status '$status'" >&2; exit 1; }
iterId=; [ -z "$sprint" ] || { iterId=$(iter "$sprint"); [ -n "$iterId" ] || { echo "unknown sprint '$sprint'" >&2; exit 1; }; }
parentId=; [ -z "$parent" ] || parentId=$(gh api graphql -f query="{repository(owner:\"enviaflores-legacy\",name:\"ef-manufacturing\"){issue(number:$parent){id title}}}" --jq .data.repository.issue.id)

echo "title=$title | type=$type($typeId) | parent=#${parent:--} | assignee=${assignee:--} | project=${project:--} | status=$status | sprint=${sprint:--} | label=${label:--}"
[ -z "$dry" ] || { echo "dry run, nothing created"; exit 0; }

args=(-R $REPO --title "$title" --body-file "$body")
[ -z "$assignee" ] || args+=(--assignee "$assignee")
[ -z "$label" ] || args+=(--label "$label")
url=$(gh issue create "${args[@]}")
num=${url##*/}
iid=$(gh api graphql -f query="{repository(owner:\"enviaflores-legacy\",name:\"ef-manufacturing\"){issue(number:$num){id}}}" --jq .data.repository.issue.id)
gh api graphql -f query="mutation{updateIssueIssueType(input:{issueId:\"$iid\",issueTypeId:\"$typeId\"}){issue{number}}}" >/dev/null
[ -z "$parentId" ] || gh api graphql -f query="mutation{addSubIssue(input:{issueId:\"$parentId\",subIssueId:\"$iid\"}){issue{number}}}" >/dev/null
item=$(gh api graphql -f query="mutation{addProjectV2ItemById(input:{projectId:\"$PROJECT_ID\",contentId:\"$iid\"}){item{id}}}" --jq .data.addProjectV2ItemById.item.id)
setf() { gh api graphql -f query="mutation{updateProjectV2ItemFieldValue(input:{projectId:\"$PROJECT_ID\",itemId:\"$item\",fieldId:\"$1\",value:{$2}}){projectV2Item{id}}}" >/dev/null; }
setf $F_STATUS "singleSelectOptionId:\"$statOpt\""
[ -z "$projOpt" ] || setf $F_PROJECT "singleSelectOptionId:\"$projOpt\""
[ -z "$iterId" ] || setf $F_SPRINT "iterationId:\"$iterId\""
# Verify through the item node: issue.projectItems is empty for this cross-org project.
gh api graphql -f query="{node(id:\"$item\"){... on ProjectV2Item{
  s:fieldValueByName(name:\"Status\"){... on ProjectV2ItemFieldSingleSelectValue{name}}
  p:fieldValueByName(name:\"Project\"){... on ProjectV2ItemFieldSingleSelectValue{name}}
  i:fieldValueByName(name:\"Sprint\"){... on ProjectV2ItemFieldIterationValue{title}}}}}" --jq '.data.node|"board: status=\(.s.name) project=\(.p.name) sprint=\(.i.title)"'
echo "$url"
