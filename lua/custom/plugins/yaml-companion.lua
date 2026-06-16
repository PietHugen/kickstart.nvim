-- CRD schemas for manual selection via <leader>tyc and content-based auto-detection
local crd_schemas = {
  {
    name = 'Argo CD Application',
    uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json',
    match = { apiVersion = 'argoproj.io/', kind = 'Application' },
  },
  {
    name = 'Argo CD ApplicationSet',
    uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/applicationset_v1alpha1.json',
    match = { apiVersion = 'argoproj.io/', kind = 'ApplicationSet' },
  },
  {
    name = 'Argo CD AppProject',
    uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/appproject_v1alpha1.json',
    match = { apiVersion = 'argoproj.io/', kind = 'AppProject' },
  },
}

-- Core K8s apiVersion prefixes (resources that should use native kubernetes schema)
local k8s_api_versions = {
  'v1',
  'apps/',
  'batch/',
  'networking.k8s.io/',
  'rbac.authorization.k8s.io/',
  'policy/',
  'storage.k8s.io/',
  'autoscaling/',
  'admissionregistration.k8s.io/',
  'apiextensions.k8s.io/',
  'coordination.k8s.io/',
  'discovery.k8s.io/',
  'events.k8s.io/',
  'flowcontrol.apiserver.k8s.io/',
  'node.k8s.io/',
  'scheduling.k8s.io/',
  'certificates.k8s.io/',
}

--- Scan buffer content and return the detected schema type.
--- Returns: { type = 'kubernetes' } or { type = 'crd', schema = <crd_entry> } or nil
local function detect_schema(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
  local api_version, kind

  for _, line in ipairs(lines) do
    local av = line:match '^apiVersion:%s*(.+)'
    if av then
      api_version = vim.trim(av)
    end
    local k = line:match '^kind:%s*(.+)'
    if k then
      kind = vim.trim(k)
    end

    -- Check CRDs first (more specific match)
    if api_version and kind then
      for _, crd in ipairs(crd_schemas) do
        if api_version:find(crd.match.apiVersion, 1, true) and kind == crd.match.kind then
          return { type = 'crd', schema = crd }
        end
      end
    end

    -- Check core K8s
    if api_version then
      for _, prefix in ipairs(k8s_api_versions) do
        if api_version == prefix or api_version:find(prefix, 1, true) == 1 then
          return { type = 'kubernetes' }
        end
      end
    end

    -- Reset on document separator for multi-doc files
    if line:match '^---' then
      api_version, kind = nil, nil
    end
  end

  return nil
end

--- Apply detected schema to yamlls for the given buffer
local function apply_schema(bufnr)
  local result = detect_schema(bufnr)
  if not result then
    return
  end

  local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'yamlls' }
  if #clients == 0 then
    return
  end
  local client = clients[1]

  local fname = vim.api.nvim_buf_get_name(bufnr)

  -- Inject schema directly into client.settings so yamlls sees it
  -- alongside yaml-companion's own { result = {} } structure
  client.settings.yaml = client.settings.yaml or {}
  client.settings.yaml.schemas = client.settings.yaml.schemas or {}

  if result.type == 'kubernetes' then
    client.settings.yaml.schemas['kubernetes'] = fname
    vim.b[bufnr].yaml_schema_name = 'Kubernetes'
  elseif result.type == 'crd' then
    client.settings.yaml.schemas[result.schema.uri] = fname
    vim.b[bufnr].yaml_schema_name = result.schema.name
  end

  client:notify('workspace/didChangeConfiguration', { settings = client.settings })
end

-- Build schemas list for yaml-companion picker (without match metadata)
local picker_schemas = {}
for _, crd in ipairs(crd_schemas) do
  table.insert(picker_schemas, { name = crd.name, uri = crd.uri })
end

return {
  {
    'mosheavni/yaml-companion.nvim',
    ft = { 'yaml' },
    opts = {
      builtin_matchers = {
        kubernetes = { enabled = false },
        cloud_init = { enabled = true },
      },
      schemas = picker_schemas,
      lspconfig = {
        settings = {
          yaml = {
            validate = true,
            completion = true,
            hover = true,
            schemaStore = {
              enable = true,
              url = 'https://www.schemastore.org/api/json/catalog.json',
            },
            schemas = {},
            format = {
              enable = false,
            },
          },
        },
      },
    },
    config = function(_, opts)
      local cfg = require('yaml-companion').setup(opts)

      -- Merge cmp-nvim-lsp capabilities since we bypass mason-lspconfig handler
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})

      vim.lsp.config('yamlls', cfg)
      vim.lsp.enable('yamlls')

      -- Auto-detect K8s/CRD schemas on file open and save
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
        group = vim.api.nvim_create_augroup('yaml-schema-detect', { clear = true }),
        pattern = { '*.yaml', '*.yml' },
        callback = function(ev)
          -- Delay slightly to ensure yamlls is attached
          vim.defer_fn(function()
            apply_schema(ev.buf)
          end, 500)
        end,
      })

      vim.keymap.set('n', '<leader>tyc', function()
        require('yaml-companion').open_ui_select()
      end, { desc = '[T]oggle [Y]aml [C]ompanion schema picker' })

      vim.keymap.set('n', '<leader>tyk', function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'yamlls' }
        if #clients == 0 then
          vim.notify('yamlls not attached', vim.log.levels.WARN)
          return
        end
        local client = clients[1]
        local fname = vim.api.nvim_buf_get_name(bufnr)
        client.settings.yaml = client.settings.yaml or {}
        client.settings.yaml.schemas = client.settings.yaml.schemas or {}
        client.settings.yaml.schemas['kubernetes'] = fname
        client:notify('workspace/didChangeConfiguration', { settings = client.settings })
        vim.b[bufnr].yaml_schema_name = 'Kubernetes'
        vim.notify('Set Kubernetes schema')
      end, { desc = 'Set [Y]aml [K]ubernetes schema' })
    end,
  },
}
