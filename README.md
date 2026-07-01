# Norconex Commons Maven Parent

Maven parent POM for many Norconex Maven projects.

# Local v3 Workspace Automation

This repository now includes helper scripts under `scripts/` to support a
"virtual monorepo" workflow for v3 local development.

- `scripts/checkout-v3.sh` and `scripts/checkout-v3.bat`
  - Clones or syncs sibling repositories listed in `scripts/repos-v3.txt`.
  - Default workspace layout is siblings under the same parent folder as
    `commons-maven-parent`.

- `scripts/build-v3-local.sh` and `scripts/build-v3-local.bat`
  - Builds the core v3 chain locally in dependency order:
    - `commons-maven-parent`
    - `committer-core`
    - `importer`
    - `collector-core`
    - `collector-http`
    - `collector-filesystem`
    - `committer-googlecloudsearch`
    - `committer-elasticsearch`
  - Optional: include `committer-sql` with `--include-sql`.
  - Default uses current versions and `-DskipTests`.
  - Optional `--set-version <version>` rewrites module versions/properties
    before build. This modifies `pom.xml` files in the working tree.

- `scripts/commit-push-v3.sh` and `scripts/commit-push-v3.bat`
  - Commits and pushes all dirty sibling repositories listed in
    `scripts/repos-v3.txt`.
  - Prompts for one shared commit message unless `--message` is supplied.
  - Prompts for confirmation unless `--yes` is supplied.

## Examples

Unix/macOS:

```bash
cd commons-maven-parent
./scripts/checkout-v3.sh
./scripts/build-v3-local.sh
./scripts/build-v3-local.sh --set-version 3.2.0-LOCAL-SNAPSHOT
./scripts/commit-push-v3.sh
./scripts/commit-push-v3.sh --message "Align v3 snapshot release metadata" --yes
```

Windows:

```bat
cd commons-maven-parent
scripts\checkout-v3.bat
scripts\build-v3-local.bat
scripts\build-v3-local.bat --set-version 3.2.0-LOCAL-SNAPSHOT
scripts\commit-push-v3.bat
scripts\commit-push-v3.bat --message "Align v3 snapshot release metadata" --yes
```
