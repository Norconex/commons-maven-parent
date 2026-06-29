#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SET_VERSION=""
INCLUDE_SQL=0
SKIP_TESTS=1
MVN_EXE="${MVN_EXE:-mvn}"
GIT_EXE="${GIT_EXE:-git}"

usage() {
  cat <<'EOF'
Usage: build-v3-local.sh [options]

Options:
  --set-version <version>  Rewrite module versions/properties before build.
                           This modifies pom.xml files in your working tree.
  --include-sql            Include committer-sql in the build.
  --run-tests              Run tests (default is -DskipTests).
  -h, --help               Show this help.

Examples:
  ./scripts/build-v3-local.sh
  ./scripts/build-v3-local.sh --set-version 3.2.0-LOCAL-SNAPSHOT
  ./scripts/build-v3-local.sh --set-version 3.2.0-LOCAL-SNAPSHOT --include-sql
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --set-version)
      SET_VERSION="${2:-}"
      [[ -z "$SET_VERSION" ]] && { echo "ERROR: --set-version requires a value"; exit 1; }
      shift 2
      ;;
    --include-sql)
      INCLUDE_SQL=1
      shift
      ;;
    --run-tests)
      SKIP_TESTS=0
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

if [[ "$MVN_EXE" == "mvn" ]]; then
  if ! command -v mvn >/dev/null 2>&1; then
    echo "ERROR: mvn is required but was not found in PATH."
    echo "Hint: set MVN_EXE to full path, e.g. /opt/apache-maven-3.9.9/bin/mvn"
    exit 1
  fi
elif [[ ! -x "$MVN_EXE" ]]; then
  echo "ERROR: configured MVN_EXE is not executable: $MVN_EXE"
  exit 1
fi

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

MODULES=(
  "commons-maven-parent"
  "committer-core"
  "importer"
  "collector-core"
  "collector-http"
  "collector-filesystem"
  "committer-googlecloudsearch"
  "committer-elasticsearch"
)

if [[ "$INCLUDE_SQL" -eq 1 ]]; then
  MODULES+=("committer-sql")
fi

module_dir() {
  echo "$WORKSPACE_ROOT/$1"
}

ensure_exists() {
  local module="$1"
  local dir
  dir="$(module_dir "$module")"
  [[ -d "$dir" ]] || { echo "ERROR: Missing module directory: $dir"; exit 1; }
  [[ -f "$dir/pom.xml" ]] || { echo "ERROR: Missing pom.xml in: $dir"; exit 1; }
}

ensure_clean_git() {
  local module="$1"
  local dir
  dir="$(module_dir "$module")"
  if [[ -d "$dir/.git" ]]; then
    if [[ -n "$("$GIT_EXE" -C "$dir" status --porcelain)" ]]; then
      echo "ERROR: Working tree is not clean: $module"
      echo "       Commit/stash changes first, or run without --set-version."
      exit 1
    fi
  fi
}

set_property_if_present() {
  local module="$1"
  local property="$2"
  local dir
  dir="$(module_dir "$module")"
  if grep -q "<$property>" "$dir/pom.xml"; then
    "$MVN_EXE" -q -f "$dir/pom.xml" versions:set-property \
      "-Dproperty=$property" "-DnewVersion=$SET_VERSION" \
      -DgenerateBackupPoms=false
  fi
}

update_parent_if_commons_parent() {
  local module="$1"
  local dir
  dir="$(module_dir "$module")"
  if grep -q "<artifactId>norconex-collector-parent</artifactId>" "$dir/pom.xml"; then
    "$MVN_EXE" -q -f "$dir/pom.xml" versions:update-parent \
      "-DparentVersion=[$SET_VERSION]" \
      -DallowSnapshots=true -DgenerateBackupPoms=false
  fi
}

for module in "${MODULES[@]}"; do
  ensure_exists "$module"
done

if [[ -n "$SET_VERSION" ]]; then
  for module in "${MODULES[@]}"; do
    ensure_clean_git "$module"
  done

  echo "Applying version override: $SET_VERSION"
  for module in "${MODULES[@]}"; do
    dir="$(module_dir "$module")"
    "$MVN_EXE" -q -f "$dir/pom.xml" versions:set \
      "-DnewVersion=$SET_VERSION" -DgenerateBackupPoms=false
  done

  for module in "${MODULES[@]}"; do
    [[ "$module" == "commons-maven-parent" ]] && continue
    [[ "$module" == "committer-sql" ]] && continue
    update_parent_if_commons_parent "$module"
  done

  set_property_if_present "collector-core" "norconex-importer.version"
  set_property_if_present "collector-core" "norconex-committer-core.version"

  set_property_if_present "collector-http" "norconex-collector-core.version"
  set_property_if_present "collector-http" "norconex-importer.version"
  set_property_if_present "collector-http" "norconex-committer-core.version"

  set_property_if_present "collector-filesystem" "norconex-collector-core.version"
  set_property_if_present "collector-filesystem" "norconex-importer.version"
  set_property_if_present "collector-filesystem" "norconex-committer-core.version"

  set_property_if_present "committer-googlecloudsearch" "norconex-importer.version"
  set_property_if_present "committer-googlecloudsearch" "norconex-committer-core.version"

  set_property_if_present "committer-elasticsearch" "norconex-committer-core.version"
fi

MVN_ARGS=()
if [[ "$SKIP_TESTS" -eq 1 ]]; then
  MVN_ARGS+=("-DskipTests")
fi

echo "Building modules in order..."
for module in "${MODULES[@]}"; do
  dir="$(module_dir "$module")"
  echo "[build] $module"
  "$MVN_EXE" -f "$dir/pom.xml" "${MVN_ARGS[@]}" install
done

echo "Build completed successfully."
if [[ -n "$SET_VERSION" ]]; then
  echo "Version override mode changed pom.xml files to: $SET_VERSION"
fi
