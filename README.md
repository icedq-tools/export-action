# icedq-tools/export-action

GitHub composite Action that exports iceDQ rules, workflows, or folders to a bundle file by invoking [`@icedq/cli`](https://www.npmjs.com/package/@icedq/cli).

Pairs with [`icedq-tools/import-action`](https://github.com/icedq-tools/import-action) for promotion pipelines.

## Usage

### Export a single workflow

```yaml
- uses: actions/checkout@v4

- uses: icedq-tools/export-action@v1
  with:
    icedq-url:     ${{ secrets.ICEDQ_URL }}
    keycloak-url:  ${{ secrets.ICEDQ_KEYCLOAK_URL }}
    client-id:     ${{ secrets.ICEDQ_CLIENT_ID }}
    client-secret: ${{ secrets.ICEDQ_CLIENT_SECRET }}
    org-id:        ${{ secrets.ICEDQ_ORG_ID }}
    account-id:    ${{ secrets.ICEDQ_ACCOUNT_ID }}
    workspace-id:  ${{ vars.DEV_WORKSPACE_ID }}
    resource:      workflow
    id:            wkfl-abc123
    output-file:   ./exports/finance.zip
```

### Export a folder recursively

```yaml
- uses: icedq-tools/export-action@v1
  with:
    # ...auth inputs...
    resource:      folder
    id:            fldr-xyz789
    include-child: 'true'
    output-file:   ./exports/finance.zip
```

### Chain export → import (Dev → QA promotion)

```yaml
jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: icedq-tools/export-action@v1
        with:
          # ...DEV auth...
          workspace-id: ${{ vars.DEV_WORKSPACE_ID }}
          resource:     folder
          id:           ${{ vars.FINANCE_FOLDER_ID }}
          include-child: 'true'
          output-file:  ./bundle.zip

      - uses: icedq-tools/import-action@v1
        with:
          # ...QA auth...
          workspace-id: ${{ vars.QA_WORKSPACE_ID }}
          bundle:       ./bundle.zip
          kind:         workflows
          mapping-file: ./mappings/qa.json
          strict:       'true'
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `icedq-url` | yes | — | iceDQ instance base URL |
| `keycloak-url` | yes | — | Keycloak token endpoint base |
| `client-id` | yes | — | OAuth client ID |
| `client-secret` | yes | — | OAuth client secret |
| `org-id` | yes | — | Org ID |
| `account-id` | yes | — | Account ID |
| `workspace-id` | yes | — | Source workspace ID |
| `resource` | yes | — | `rule`, `workflow`, or `folder` |
| `id` | yes | — | Resource UUID |
| `include-child` | no | `false` | Recurse folder children (folder only) |
| `output-file` | yes | — | Path to write the bundle ZIP |
| `timeout` | no | `1800` | Polling timeout in seconds |
| `cli-version` | no | `latest` | Pin a specific `@icedq/cli` version |
| `verify-ssl` | no | `true` | Verify TLS |
| `upload-artifact` | no | `true` | Upload the bundle as a workflow artifact |
| `artifact-name` | no | `icedq-bundle` | Name of the uploaded artifact |

## Outputs

| Output | Description |
|---|---|
| `task-id` | iceDQ `taskInstanceId` |
| `status` | Terminal status (`Completed`, `Terminated`, `Error`) |
| `bundle-path` | Path to the downloaded bundle ZIP |

## Versioning

- `@v1` — recommended. Tracks the latest `v1.x.y` release; you automatically get bug fixes and non-breaking improvements.
- `@v1.0.0` — pins to an exact release. No automatic updates; upgrade by changing this yourself.
- `@<commit-sha>` — pins to an exact commit. Most reproducible/secure option.

Breaking changes are released under a new major tag (`@v2`, etc.) — existing `@v1` users are never moved onto breaking changes automatically.

## Self-hosted runners

For iceDQ instances on private networks, set `runs-on: [self-hosted, icedq]` (or your runner's labels). The Action is runner-agnostic.

## Companion repos

- [`icedq-tools/cli`](https://github.com/icedq-tools/cli) — the CLI this Action wraps
- [`icedq-tools/import-action`](https://github.com/icedq-tools/import-action) — companion import Action
