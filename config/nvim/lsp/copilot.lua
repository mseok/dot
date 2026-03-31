---@brief
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, bufnr) then
      -- Check if inline_completion API is available (Neovim 0.11+)
      if vim.lsp.inline_completion then
        vim.lsp.inline_completion.enable(true, { bufnr = bufnr })

        vim.keymap.set(
          'i',
          '<C-F>',
          vim.lsp.inline_completion.get,
          { desc = 'LSP: accept inline completion', buffer = bufnr }
        )
        vim.keymap.set(
          'i',
          '<C-G>',
          vim.lsp.inline_completion.select,
          { desc = 'LSP: switch inline completion', buffer = bufnr }
        )
      end
    end
  end
})

---@param bufnr integer,
---@param client vim.lsp.Client
local function sign_in(bufnr, client)
  ---@param value unknown
  ---@return string|nil
  local function as_string(value)
    if type(value) == 'string' then
      return value
    end
    if type(value) == 'number' then
      return tostring(value)
    end
    return nil
  end

  ---@param register string
  ---@param value string
  local function safe_setreg(register, value)
    local ok = pcall(vim.fn.setreg, register, value)
    return ok
  end

  client:request(
  ---@diagnostic disable-next-line: param-type-mismatch
    'signIn',
    vim.empty_dict(),
    function(err, result)
      if err then
        vim.notify(err.message, vim.log.levels.ERROR)
        return
      end

      result = result or {}

      local code = as_string(result.userCode)
      local verification_uri = as_string(result.verificationUri)
      local status = as_string(result.status)
      local command = type(result.command) == 'table' and result.command or nil

      if code then
        local copied = safe_setreg('+', code)
        copied = safe_setreg('*', code) or copied
        if not copied then
          vim.notify('Copilot sign-in code: ' .. code, vim.log.levels.INFO)
        end
      end

      if command then
        local continue = vim.fn.confirm(
          (code and 'Copied your one-time code to clipboard.\n' or '')
            .. 'Open the browser to complete the sign-in process?',
          '&Yes\n&No'
        )
        if continue == 1 then
          client:exec_cmd(command, { bufnr = bufnr }, function(cmd_err, cmd_result)
            if cmd_err then
              vim.notify(err.message, vim.log.levels.ERROR)
              return
            end
            if cmd_result.status == 'OK' then
              vim.notify('Signed in as ' .. cmd_result.user .. '.')
            end
          end)
        end
      end

      if status == 'PromptUserDeviceFlow' then
        if code and verification_uri then
          vim.notify('Enter your one-time code ' .. code .. ' in ' .. verification_uri)
        elseif code then
          vim.notify('Enter your one-time code ' .. code .. ' to complete Copilot sign-in.')
        else
          vim.notify('Complete Copilot sign-in in the browser prompt.', vim.log.levels.INFO)
        end
      elseif status == 'AlreadySignedIn' then
        vim.notify('Already signed in as ' .. (as_string(result.user) or 'your GitHub account') .. '.')
      elseif not command and not status then
        vim.notify('Copilot sign-in returned an unexpected response shape.', vim.log.levels.WARN)
      end
    end
  )
end

---@param client vim.lsp.Client
local function sign_out(_, client)
  client:request(
  ---@diagnostic disable-next-line: param-type-mismatch
    'signOut',
    vim.empty_dict(),
    function(err, result)
      if err then
        vim.notify(err.message, vim.log.levels.ERROR)
        return
      end
      if result.status == 'NotSignedIn' then
        vim.notify('Not signed in.')
      end
    end
  )
end

---@type vim.lsp.Config
return {
  cmd = {
    'copilot-language-server',
    '--stdio',
  },
  root_markers = { '.git' },
  init_options = {
    editorInfo = {
      name = 'Neovim',
      version = tostring(vim.version()),
    },
    editorPluginInfo = {
      name = 'Neovim',
      version = tostring(vim.version()),
    },
  },
  settings = {
    telemetry = {
      telemetryLevel = 'all',
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspCopilotSignIn', function()
      sign_in(bufnr, client)
    end, { desc = 'Sign in Copilot with GitHub' })
    vim.api.nvim_buf_create_user_command(bufnr, 'LspCopilotSignOut', function()
      sign_out(bufnr, client)
    end, { desc = 'Sign out Copilot with GitHub' })
  end,
}
