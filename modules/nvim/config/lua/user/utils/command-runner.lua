local function create_output_stream_to_buffer(bufnr)
    local window = nil
    return function(error, data)
        if data then
            vim.schedule(function()
                -- Append data to buffer (splitting by lines)
                local lines = vim.split(data, "\n")
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)

                if window == nil then
                    window = vim.api.nvim_open_win(bufnr, true,
                        { vertical = true })
                end
            end)
        end
    end
end

-- Function to set a unique buffer name
-- If the initial name is taken, appends _1, _2, etc. until finding a unique name
---@param bufnr integer
---@param name string
---@return string|nil
local function set_unique_buffer_name(bufnr, name)
  -- Base case: try setting the name directly
  local success = pcall(vim.api.nvim_buf_set_name, bufnr, name)

  if success then
    -- Name set successfully
    return name
  else
    -- Name already exists, try with numbered suffixes
    local counter = 1
    local new_name

    while true do
      new_name = name .. "_" .. counter
      success = pcall(vim.api.nvim_buf_set_name, bufnr, new_name)

      if success then
        -- Found an available name
        return new_name
      end

      -- Try next number
      counter = counter + 1

      -- Safety check to prevent infinite loops
      if counter > 100 then
        print("Failed to set buffer name after 100 attempts")
        return nil
      end
    end
  end
end

---@class UserUtilsCommandRunner
local CommandRunner = {}

---@class UserUtilsCommandRunnerRunOptions
---@field text? boolean (default: true)

---@param command string[]
---@param opts? UserUtilsCommandRunnerRunOptions
function CommandRunner.run(command, opts)
    opts = opts or {}
    if opts.text == nil then
        opts.text = true
    end

    local cmd_str = table.concat(command, " ")

    local stdout_bufnr = vim.api.nvim_create_buf(false, true)
    set_unique_buffer_name(stdout_bufnr, cmd_str .. " [STDOUT]")

    local stderr_bufnr = vim.api.nvim_create_buf(false, true)
    set_unique_buffer_name(stderr_bufnr, cmd_str .. " [STDERR]")

    ---@type vim.SystemOpts
    local system_opts = {
        text = opts.text,
        stderr = create_output_stream_to_buffer(stderr_bufnr),
        stdout = create_output_stream_to_buffer(stdout_bufnr),
    }
    local ok, system_obj = pcall(vim.system, command, system_opts,
        function(result)
            vim.notify("DONE - exit code " .. result.code)
        end)

    if ok then
        vim.notify(
            "started command `" .. cmd_str .. "` with pid " .. system_obj.pid,
            vim.log.levels.DEBUG, { title = "Command runner" })
    else
        vim.notify("could not run command `" .. cmd_str .. "`")
    end
end

return CommandRunner
