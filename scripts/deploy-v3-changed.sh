#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SKIP_TESTS=1
WHAT_IF=0
MVN_EXE="${MVN_EXE:-mvn}"
RELEASE_REPOS=(
  "https://repo1.maven.org/maven2"
  "https://repo.maven.apache.org/maven2"
)
SNAPSHOT_REPOS=(
  "https://central.sonatype.com/repository/maven-snapshots"
)

MODULES=(
  "commons-maven-parent"
  "committer-core"
  "importer"
  "collector-core"
  "collector-http"
  "collector-filesystem"
  "committer-googlecloudsearch"
  "committer-elasticsearch"
  "committer-cloudsearch"
  "committer-solr"
  "committer-idol"
  "committer-azuresearch"
  "committer-neo4j"
  "committer-sql"
)

usage() {
  cat <<'EOF'
Usage: deploy-v3-changed.sh [options]

Options:
  --run-tests              Run tests during deploy (default skips tests).
  --what-if                Show what would be deployed without deploying.
  --mvn-exe <path>         Maven executable path.
  --release-repo <url>     Override release metadata repository URL.
  -h, --help               Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-tests)
      SKIP_TESTS=0
      shift
      ;;
    --what-if)
      WHAT_IF=1
      shift
      ;;
    --mvn-exe)
      [[ $# -lt 2 ]] && { echo "ERROR: --mvn-exe requires a value"; usage; exit 1; }
      MVN_EXE="$2"
      shift 2
      ;;
    --release-repo)
      [[ $# -lt 2 ]] && { echo "ERROR: --release-repo requires a value"; usage; exit 1; }
      RELEASE_REPOS=("$2")
      shift 2
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

command -v "$MVN_EXE" >/dev/null 2>&1 || { echo "ERROR: Maven executable not found: $MVN_EXE"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required but was not found in PATH."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required but was not found in PATH."; exit 1; }

resolve_tag() {
  local repo_path="$1"
  local artifact_id="$2"
  local module="$3"
  local release="$4"
  local candidates=(
    "v$release"
    "$release"
    "$artifact_id-$release"
    "$module-$release"
  )
  local t
  for t in "${candidates[@]}"; do
    if git -C "$repo_path" rev-parse -q --verify "refs/tags/$t" >/dev/null 2>&1; then
      printf '%s' "$t"
      return 0
    fi
  done
  return 1
}

get_project_value() {
  local pom="$1"
  local expr="$2"
  "$MVN_EXE" -q -f "$pom" -DforceStdout help:evaluate "-Dexpression=$expr"
}

get_latest_release() {
  local group_id="$1"
  local artifact_id="$2"
  local group_path="${group_id//./\/}"
  local repo
  for repo in "${RELEASE_REPOS[@]}"; do
    local url="${repo%/}/$group_path/$artifact_id/maven-metadata.xml"
    local release
    release="$(curl -fsSL "$url" 2>/dev/null | sed -n 's:.*<release>\(.*\)</release>.*:\1:p' | head -n1 || true)"
    if [[ -n "$release" ]]; then
      printf '%s' "$release"
      return 0
    fi
  done
  return 1
}

# Echoes the last deployed SNAPSHOT's lastUpdated timestamp as Unix epoch
# seconds (UTC), or nothing if no SNAPSHOT metadata is found.
get_snapshot_last_updated_epoch() {
  local group_id="$1"
  local artifact_id="$2"
  local group_path="${group_id//./\/}"
  local repo
  for repo in "${SNAPSHOT_REPOS[@]}"; do
    local url="${repo%/}/$group_path/$artifact_id/maven-metadata.xml"
    local last_updated
    last_updated="$(curl -fsSL "$url" 2>/dev/null | sed -n 's:.*<lastUpdated>\(.*\)</lastUpdated>.*:\1:p' | head -n1 || true)"
    if [[ -n "$last_updated" ]]; then
      local y="${last_updated:0:4}" mo="${last_updated:4:2}" d="${last_updated:6:2}"
      local h="${last_updated:8:2}" mi="${last_updated:10:2}" s="${last_updated:12:2}"
      date -u -d "${y}-${mo}-${d} ${h}:${mi}:${s}" +%s
      return 0
    fi
  done
  return 1
}

CHANGED_MODULES=()

depended_by() {
  case "$1" in
    commons-maven-parent) echo "committer-core importer collector-core collector-http collector-filesystem committer-googlecloudsearch committer-elasticsearch committer-cloudsearch committer-solr committer-idol committer-azuresearch committer-neo4j committer-sql" ;;
    committer-core) echo "importer collector-core collector-http collector-filesystem committer-googlecloudsearch committer-elasticsearch committer-cloudsearch committer-solr committer-idol committer-azuresearch committer-neo4j committer-sql" ;;
    importer) echo "collector-core collector-http collector-filesystem committer-googlecloudsearch" ;;
    collector-core) echo "collector-http collector-filesystem" ;;
    collector-http) echo "" ;;
    collector-filesystem) echo "" ;;
    committer-googlecloudsearch) echo "" ;;
    committer-elasticsearch) echo "" ;;
    committer-sql) echo "" ;;
    *) echo "" ;;
  esac
}

expand_with_deps() {
  local selected=("$@")
  local changed=1
  while [[ "$changed" -eq 1 ]]; do
    changed=0
    local m dep
    local snapshot=("${selected[@]}")
    for m in "${snapshot[@]}"; do
      for dep in $(depended_by "$m"); do
        if [[ " ${selected[*]} " != *" $dep "* ]]; then
          selected+=("$dep")
          changed=1
        fi
      done
    done
  done

  local ordered=()
  local module
  for module in "${MODULES[@]}"; do
    if [[ " ${selected[*]} " == *" $module "* ]]; then
      ordered+=("$module")
    fi
  done
  printf '%s\n' "${ordered[@]}"
}

echo
echo "Change detection summary:"
for module in "${MODULES[@]}"; do
  module_dir="$WORKSPACE_ROOT/$module"
  pom="$module_dir/pom.xml"
  [[ -f "$pom" ]] || { echo "ERROR: Missing module pom.xml: $pom"; exit 1; }

  group_id="$(get_project_value "$pom" project.groupId)"
  artifact_id="$(get_project_value "$pom" project.artifactId)"
  local_version="$(get_project_value "$pom" project.version)"

  latest_release=""
  if ! latest_release="$(get_latest_release "$group_id" "$artifact_id")"; then
    latest_release=""
  fi

  changed=0
  reason=""
  if [[ -z "$latest_release" ]]; then
    # No release exists yet under this groupId/artifactId (expected for a
    # SNAPSHOT-only project). Fall back to comparing local commit history
    # against the last deployed SNAPSHOT's timestamp instead of
    # unconditionally treating the module as changed.
    snapshot_epoch=""
    if ! snapshot_epoch="$(get_snapshot_last_updated_epoch "$group_id" "$artifact_id")"; then
      snapshot_epoch=""
    fi
    if [[ -z "$snapshot_epoch" ]]; then
      changed=1
      reason="No release or snapshot metadata"
    elif [[ -n "$(git -C "$module_dir" status --porcelain)" ]]; then
      changed=1
      reason="Working tree dirty"
    else
      last_commit_epoch="$(git -C "$module_dir" log -1 --format=%ct)"
      if [[ "$last_commit_epoch" -gt "$snapshot_epoch" ]]; then
        changed=1
        reason="Changed since last snapshot deploy"
      else
        changed=0
        reason="No changes since last snapshot deploy"
      fi
    fi
  else
    if tag="$(resolve_tag "$module_dir" "$artifact_id" "$module" "$latest_release" 2>/dev/null || true)" && [[ -n "$tag" ]]; then
      if git -C "$module_dir" diff --quiet "$tag..HEAD" -- .; then
        changed=0
        reason="No changes since tag $tag"
      else
        changed=1
        reason="Changed since tag $tag"
      fi
    else
      local_base="${local_version%-SNAPSHOT}"
      if [[ "$local_base" != "$latest_release" ]]; then
        changed=1
        reason="Version differs from release $latest_release"
      elif [[ -n "$(git -C "$module_dir" status --porcelain)" ]]; then
        changed=1
        reason="Working tree dirty"
      else
        changed=0
        reason="No matching tag and same version"
      fi
    fi
  fi

  printf '%-28s | %-44s | %-16s | %-16s | %s\n' "$module" "$artifact_id" "$local_version" "${latest_release:-n/a}" "$reason"
  if [[ "$changed" -eq 1 ]]; then
    CHANGED_MODULES+=("$module")
  fi
done

if [[ "${#CHANGED_MODULES[@]}" -eq 0 ]]; then
  echo
  echo "No modules detected as changed since latest release metadata. Nothing to deploy."
  exit 0
fi

mapfile -t DEPLOY_MODULES < <(expand_with_deps "${CHANGED_MODULES[@]}")

echo
echo "Modules selected for deploy (dependency order):"
printf ' - %s\n' "${DEPLOY_MODULES[@]}"

if [[ "$WHAT_IF" -eq 1 ]]; then
  echo
  echo "What-if mode enabled. No deploy commands were run."
  exit 0
fi

MVN_FLAGS=(-Dgpg.skip=true -Dmaven.javadoc.skip=true)
if [[ "$SKIP_TESTS" -eq 1 ]]; then
  MVN_FLAGS+=(-Dmaven.test.skip=true)
else
  MVN_FLAGS+=(-DskipTests=false)
fi

for module in "${DEPLOY_MODULES[@]}"; do
  echo
  echo "[deploy] $module"
  "$MVN_EXE" -f "$WORKSPACE_ROOT/$module/pom.xml" "${MVN_FLAGS[@]}" deploy
done

echo
echo "Deploy completed successfully for changed modules."
