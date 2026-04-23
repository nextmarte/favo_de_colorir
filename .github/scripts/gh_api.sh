#!/bin/bash
# GitHub API helper — reads token from secure file, never prints it
# Usage: gh_api.sh GET /repos/BaxiJen/favo_de_colorir

TOKEN_FILE="${HOME}/.openclaw/workspace/.github_token"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "Token file not found" >&2
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")
METHOD=${1:-GET}
ENDPOINT=${2:-/}

curl -s -H "Authorization: token $TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -X "$METHOD" \
     "https://api.github.com${ENDPOINT}"
