#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_LIST_FILE="${REPO_LIST_FILE:-$SCRIPT_DIR/repos-v3.txt}"
GITHUB_ORG="${GITHUB_ORG:-Norconex}"
GIT_REMOTE_BASE="${GIT_REMOTE_BASE:-https://github.com/${GITHUB_ORG}}"
GIT_EXE="${GIT_EXE:-git}"

if [[ "$GIT_EXE" == "git" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is required but was not found in PATH."
    echo "Hint: set GIT_EXE to full path, e.g. /usr/bin/git"
    exit 1
  fi
elif [[ ! -x "$GIT_EXE" ]]; then
  echo "ERROR: configured GIT_EXE is not executable: $GIT_EXE"
  exit 1
fi

if [[ ! -f "$REPO_LIST_FILE" ]]; then
  echo "ERROR: repo list file not found: $REPO_LIST_FILE"
  exit 1
fi

echo "Workspace root: $WORKSPACE_ROOT"
echo "Repo list: $REPO_LIST_FILE"

while IFS= read -r repo || [[ -n "$repo" ]]; do
  repo="${repo%%#*}"
  repo="$(echo "$repo" | xargs)"
  [[ -z "$repo" ]] && continue

  target_dir="$WORKSPACE_ROOT/$repo"
  remote_url="$GIT_REMOTE_BASE/$repo.git"

  if [[ -d "$target_dir/.git" ]]; then
    echo "[sync] $repo"
    "$GIT_EXE" -C "$target_dir" fetch --all --prune
  elif [[ -e "$target_dir" ]]; then
    echo "[skip] $repo: path exists but is not a git repo ($target_dir)"
  else
    echo "[clone] $repo"
    "$GIT_EXE" clone "$remote_url" "$target_dir"
  fi
done < "$REPO_LIST_FILE"

echo "Done."
