#!/bin/bash
# Helper script for GitHub API calls — uses token from file, never exposed in output
eval "$(cat ~/.openclaw/workspace/credentials/github_token.txt 2>/dev/null || echo 'echo \"Token not found\"; exit 1')"
