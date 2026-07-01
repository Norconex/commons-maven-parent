#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_LIST_FILE="${REPO_LIST_FILE:-$SCRIPT_DIR/repos-v3.txt}"
GIT_EXE="${GIT_EXE:-git}"
COMMIT_MESSAGE=""
AUTO_YES=0

usage() {
  cat <<'EOF'
Usage: commit-push-v3.sh [options]

Commit and push all dirty sibling repositories listed in repos-v3.txt
using the same commit message.

Options:
  --message <message>   Shared commit message. If omitted, you will be prompted.
  --repos-file <path>   Override repository list file.
  --yes                 Skip confirmation prompt.
  -h, --help            Show this help.

Examples:
  ./scripts/commit-push-v3.sh
  ./scripts/commit-push-v3.sh --message "Align v3 snapshot docs"
  ./scripts/commit-push-v3.sh --message "Align v3 snapshot docs" --yes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --message)
      COMMIT_MESSAGE="${2:-}"
      [[ -z "$COMMIT_MESSAGE" ]] && { echo "ERROR: --message requires a value"; exit 1; }
      shift 2
      ;;
    --repos-file)
      REPO_LIST_FILE="${2:-}"
      [[ -z "$REPO_LIST_FILE" ]] && { echo "ERROR: --repos-file requires a value"; exit 1; }
      shift 2
      ;;
    --yes)
      AUTO_YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

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

if [[ -z "$COMMIT_MESSAGE" ]]; then
  read -r -p "Shared commit message: " COMMIT_MESSAGE
fi

if [[ -z "$COMMIT_MESSAGE" ]]; then
  echo "ERROR: commit message cannot be empty."
  exit 1
fi

DIRTY_REPOS=()
while IFS= read -r repo || [[ -n "$repo" ]]; do
  repo="${repo%%#*}"
  repo="$(echo "$repo" | xargs)"
  [[ -z "$repo" ]] && continue

  target_dir="$WORKSPACE_ROOT/$repo"
  if [[ ! -d "$target_dir/.git" ]]; then
    echo "[skip] $repo: not a git repository at $target_dir"
    continue
  fi

  if [[ -n "$("$GIT_EXE" -C "$target_dir" status --porcelain)" ]]; then
    DIRTY_REPOS+=("$repo")
  fi
done < "$REPO_LIST_FILE"

if [[ ${#DIRTY_REPOS[@]} -eq 0 ]]; then
  echo "No dirty repositories found."
  exit 0
fi

echo "Workspace root: $WORKSPACE_ROOT"
echo "Repo list: $REPO_LIST_FILE"
echo "Commit message: $COMMIT_MESSAGE"
echo "Repositories to commit and push:"
for repo in "${DIRTY_REPOS[@]}"; do
  echo "  - $repo"
done

if [[ "$AUTO_YES" -ne 1 ]]; then
  read -r -p "Proceed with commit and push? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

for repo in "${DIRTY_REPOS[@]}"; do
  target_dir="$WORKSPACE_ROOT/$repo"
  echo "[commit] $repo"
  "$GIT_EXE" -C "$target_dir" add -A
  "$GIT_EXE" -C "$target_dir" commit -m "$COMMIT_MESSAGE"
  echo "[push] $repo"
  "$GIT_EXE" -C "$target_dir" push
done

echo "Done."