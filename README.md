# Databricks Asset Bundle (DAB) repository template

A starting point for a [Databricks Asset Bundle](https://docs.databricks.com/dev-tools/bundles/index.html)
deployed automatically by GitHub Actions, hardened for use in a **public**
GitHub repository.

Use this as a starting point when you want:

- Auto-deploy to a `dev` Databricks target on every PR.
- Auto-deploy to a `prod` Databricks target on push to `main`, gated by a
  required reviewer on the GitHub `production` environment.
- No secrets, identities, or workspace URLs hard-coded in the repo —
  everything sourced from bundle variables backed by GitHub Secrets and a
  local `.envrc`.
- Supply-chain hardening: all GitHub Actions SHA-pinned, `allowed_actions`
  restricted to an explicit allowlist, `sha_pinning_required` enforced.

Toolchain:
- **[uv](https://docs.astral.sh/uv/)** — environment & dependency management
- **[poetry-core](https://python-poetry.org/)** — PEP 517 build backend
- **[ruff](https://docs.astral.sh/ruff/)** — linting & formatting
- **pytest** — testing
- **[databricks CLI](https://docs.databricks.com/dev-tools/cli/databricks-cli.html)** — bundle deploys and workspace auth

---

## Prerequisites

| Tool | Why | Install |
|---|---|---|
| [`databricks`](https://docs.databricks.com/dev-tools/cli/databricks-cli.html) | Bundle deploys and workspace auth | `brew install databricks` (macOS) or download release |
| [`gh`](https://cli.github.com/) | Repo setup commands run via GitHub REST API | `brew install gh`, then `gh auth login` |
| [`direnv`](https://direnv.net/) | Auto-loads `.envrc` for local bundle deploys | `brew install direnv`, then hook into your shell ([instructions](https://direnv.net/docs/hook.html)) |
| [`uv`](https://docs.astral.sh/uv/) | Python build/dep manager used by the bundle's `artifacts:` block and CI | `brew install uv` or `pipx install uv` |
| Python 3.11 | Required by the workload bundle | `uv python install 3.11` |

You'll also need:

- A GitHub account with **admin** access to the repository.
- A Databricks workspace where you can create a service principal (workspace-
  admin in Databricks) and grant catalog permissions.

---

## One-time Databricks setup (manual, UI-only)

These cannot be automated — they require workspace-admin actions in the
Databricks console.

1. **Get the workspace URL.** From your workspace landing page, copy the URL
   (e.g. `https://dbc-xxxx.cloud.databricks.com`). You'll need this everywhere.

2. **Create the deployer service principal.**
   Account console → User management → Service principals → Add. Name it
   something like `github-actions-dab-deployer`. **Copy the Application ID
   (UUID)** — this is your `DATABRICKS_CLIENT_ID` / `DATABRICKS_PROD_SP_ID`.

3. **Add the SP to your workspace.**
   Workspace settings → Identity and access → Service principals → Add → pick
   the SP you just created.

4. **Generate an OAuth M2M secret for the SP.**
   Workspace settings → Identity and access → Service principals → click the
   SP → Secrets → Generate secret. **Copy the secret immediately — it is shown
   only once.** This is your `DATABRICKS_CLIENT_SECRET`.

5. **Grant the SP catalog and schema permissions.**
   Catalog Explorer → your catalog → Permissions → grant the SP `USE CATALOG`,
   `USE SCHEMA`, `CREATE SCHEMA`. On the `dev` / `prod` schemas the bundle
   targets, grant the privileges the workloads need (`CREATE TABLE`, `MODIFY`,
   etc.) — `ALL PRIVILEGES` is the simplest if you're not optimizing.

6. **Verify auth from your laptop:**

   ```sh
   export DATABRICKS_HOST="https://dbc-xxxx.cloud.databricks.com"
   export DATABRICKS_CLIENT_ID="<sp-application-id>"
   export DATABRICKS_CLIENT_SECRET="<sp-secret>"
   databricks current-user me
   ```

---

## One-time GitHub repo setup

Replace `<owner>/<repo>` with your repo slug throughout.

### 1. Add the repository secrets

Settings → Secrets and variables → Actions → **New repository secret**:

| Secret | Value |
|---|---|
| `DATABRICKS_HOST` | Workspace URL from Databricks step 1 |
| `DATABRICKS_CLIENT_ID` | SP Application ID from Databricks step 2 |
| `DATABRICKS_CLIENT_SECRET` | SP OAuth secret from Databricks step 4 |
| `DATABRICKS_PROD_SP_ID` | Same value as `DATABRICKS_CLIENT_ID` (bundle reads it as a variable) |
| `ALERTS_EMAIL` | Address that receives job-failure notifications |
| `BUNDLE_OWNER_EMAIL` | Owner of shared workspace-infra deploys — feeds `workspace.root_path`, must stay constant once set |

### 2. Restrict Actions to a hardened allowlist

```sh
gh api -X PUT repos/<owner>/<repo>/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false

gh api -X PUT repos/<owner>/<repo>/actions/permissions --input - <<'EOF'
{"enabled": true, "allowed_actions": "selected", "sha_pinning_required": true}
EOF

gh api -X PUT repos/<owner>/<repo>/actions/permissions/selected-actions --input - <<'EOF'
{"github_owned_allowed": false, "verified_allowed": false,
 "patterns_allowed": ["actions/checkout@*", "actions/setup-python@*", "databricks/setup-cli@*"]}
EOF
```

### 3. Create the `production` environment

UI: Settings → Environments → **New environment** → name it `production`.
(The prod workflow references `environment: production`.)

### 4. After flipping the repo to public, run the public-only protections

These API calls return 422 on free private repos. Run them the moment the
repo is public.

```sh
MY_USER_ID=$(gh api user --jq .id)

gh api -X PUT repos/<owner>/<repo>/environments/production --input - <<EOF
{"reviewers": [{"type": "User", "id": $MY_USER_ID}],
 "deployment_branch_policy": {"protected_branches": true, "custom_branch_policies": false},
 "can_admins_bypass": true}
EOF

gh api -X PUT repos/<owner>/<repo>/actions/permissions/fork-pr-contributor-approval \
  -f approval_policy=all_external_contributors
```

### 5. UI-only repo settings (also after going public)

- Settings → **Branches** → Add rule → `main`: require PR, require status
  check `Deploy to dev`, optionally disallow bypassing.
- Settings → **Code security**: enable Secret scanning, Push protection,
  Dependabot alerts, Dependabot security updates.
- Settings → **General → Features**: uncheck Wiki / Projects / Discussions
  if unused.

---

## Local development

1. Create `.envrc` at the repo root (gitignored):

   ```sh
   export DATABRICKS_HOST=https://dbc-xxxx.cloud.databricks.com
   export BUNDLE_VAR_prod_sp_id=<sp-application-id>
   export BUNDLE_VAR_alerts_email=you@example.com
   export BUNDLE_VAR_bundle_owner_email=you@example.com
   ```

2. `direnv allow` to activate.

3. Authenticate to Databricks (as your own user, not the SP):

   ```sh
   databricks auth login --host "$DATABRICKS_HOST"
   ```

4. Sync the Python environment:

   ```bash
   make sync
   ```

   This creates `.venv/` and installs the project plus the `dev` and `test` groups.

## Common tasks

```bash
make lint          # ruff check
make format        # ruff format (in place)
make format-check  # ruff format --check
make test          # pytest with coverage
make run           # python main.py
make clean         # remove .venv and caches
```
