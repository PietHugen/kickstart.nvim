# YAML Editing Setup

Custom YAML editing configuration for Kubernetes platform engineering.

## Architecture

YAML schema detection uses a **three-layer approach** to avoid conflicts:

1. **SchemaStore** (via yamlls) — auto-detects schemas by file path for Ansible, GitHub Workflows, Docker Compose, Helm Charts, etc. This is the default and handles most non-K8s YAML files automatically.

2. **Custom content-based detection** (`yaml-companion.lua`) — scans the first 200 lines of a buffer for `apiVersion`/`kind` patterns. Detects core Kubernetes resources and CRDs (ArgoCD). Runs on `BufReadPost`/`BufWritePost` and dynamically applies schemas via `workspace/didChangeConfiguration`.

3. **Manual override** — `<leader>tyc` opens a schema picker (SchemaStore + CRDs), `<leader>tyk` forces the Kubernetes schema on the current buffer.

### Why not use yaml-companion's builtin kubernetes matcher?

The builtin matcher applies a monolithic `all.json` schema from `yannh/kubernetes-json-schema`. This file is too large for yamlls to parse effectively — completions and validation don't work. Instead, we use yamlls's **native `kubernetes` key** which handles per-resource schemas properly with full completion and validation support.

### Why not use `kubernetes = '*.yaml'` globally?

This applies the Kubernetes schema to ALL YAML files, conflicting with SchemaStore detections (Ansible, GitHub Workflows, etc.) and CRD schemas. Content-based detection only applies it when the file actually contains Kubernetes resources.

### Why is SchemaStore's kubernetes schema not used?

SchemaStore + yaml-companion's matcher both applying Kubernetes schemas caused "Matches multiple schemas when only one must validate" errors, especially on multi-document YAML files. Disabling the builtin matcher and using the native `kubernetes` key avoids this.

## Changed Files

| File | Purpose |
|------|---------|
| `lua/custom/plugins/yaml-companion.lua` | Schema detection, yamlls setup, keymaps |
| `lua/kickstart/plugins/lspconfig.lua` | Removed yamlls + non-LSP tools from servers table |
| `lua/kickstart/plugins/conform.lua` | prettier as YAML formatter |
| `lua/kickstart/plugins/lint.lua` | yamllint for YAML linting |
| `lua/kickstart/plugins/treesitter.lua` | yaml parser in ensure_installed |
| `lua/kickstart/plugins/mini.lua` | Schema name in statusline |
| `ftplugin/yaml.lua` | Buffer settings + indent navigation |

## Keymaps (YAML buffers only)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>tyc` | n | Schema picker (SchemaStore + CRDs) |
| `<leader>tyk` | n | Force Kubernetes schema on current buffer |
| `(` | n | Jump to start of current indent block |
| `)` | n | Jump to end of current indent block |
| `{` | n | Previous sibling (same indent level) |
| `}` | n | Next sibling (same indent level) |
| `<S-Tab>` | i | Dedent current line |

## Plugins

- **mosheavni/yaml-companion.nvim** — Neovim 0.11 compatible fork. Provides schema picker via `vim.ui.select` and CRD schema management. Does NOT manage the kubernetes schema (we handle that ourselves).
- **yaml-language-server** (yamlls) — LSP providing completion, validation, hover. Installed via Mason.
- **prettier** — YAML formatting via conform.nvim. Installed via Mason.
- **yamllint** — YAML linting via nvim-lint. Installed via Mason.

## Adding New CRD Schemas

Edit the `crd_schemas` table at the top of `lua/custom/plugins/yaml-companion.lua`:

```lua
{
  name = 'My CRD',
  uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/group/crd_version.json',
  match = { apiVersion = 'group.io/', kind = 'MyCRD' },
},
```

- `name` — displayed in picker and statusline
- `uri` — JSON schema URL (Datree CRDs-catalog has most popular CRDs)
- `match.apiVersion` — prefix match against the file's `apiVersion` field
- `match.kind` — exact match against the file's `kind` field

## Adding New Core K8s API Groups

If a new API group is added to Kubernetes, add its prefix to `k8s_api_versions` in `yaml-companion.lua`:

```lua
local k8s_api_versions = {
  'v1',
  'apps/',
  -- ...
  'my.new.group.io/',
}
```

## Known Limitations

- **Multi-document YAML** — Schema detection uses the first matching `apiVersion`/`kind` in the first 200 lines. If a file mixes K8s and non-K8s documents, the first match wins.
- **Per-buffer, not per-document** — yamlls applies one schema to the entire file. Different resource types in the same file share one schema.
- **Manual CRD selection** — CRDs that aren't in the `crd_schemas` table require manual selection via `<leader>tyc`.
- **Completion trigger** — Use `Ctrl+N` to trigger completions (not `Ctrl+Space` which may not work in all terminals).
