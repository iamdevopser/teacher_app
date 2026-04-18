#!/usr/bin/env bash
#
# If origin exists: git push to origin (current branch).
# If not and GITHUB_TOKEN is set: create public repo (folder name), push via HTTPS, then sanitize remote URL.
# Usage: GITHUB_TOKEN=ghp_xxx ./scripts/github_repo_bootstrap.sh
#
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

BRANCH="$(git branch --show-current)"
if [[ -z "$BRANCH" ]]; then BRANCH=main; fi

if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin "$BRANCH"
  exit 0
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "No git remote 'origin'. Set GITHUB_TOKEN or: git remote add origin https://github.com/USER/REPO.git"
  exit 1
fi

NAME="$(basename "$ROOT")"
USER_JSON="$(curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user)"
LOGIN="$(echo "$USER_JSON" | sed -n 's/.*"login": "\([^"]*\)".*/\1/p' | head -1)"
if [[ -z "$LOGIN" ]]; then
  echo "Could not resolve GitHub user from token."
  exit 1
fi

curl -sfS -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/user/repos" \
  -d "{\"name\":\"$NAME\",\"private\":false,\"auto_init\":false}" >/dev/null

# One-shot HTTPS push (token); then remove token from stored remote URL.
git remote add origin "https://${GITHUB_TOKEN}@github.com/${LOGIN}/${NAME}.git" 2>/dev/null || \
  git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${LOGIN}/${NAME}.git"

git push -u origin "$BRANCH"
git remote set-url origin "https://github.com/${LOGIN}/${NAME}.git"

echo "Remote (no token in URL): https://github.com/${LOGIN}/${NAME}.git"
echo "Configure credentials for future pushes (Git Credential Manager or SSH)."
