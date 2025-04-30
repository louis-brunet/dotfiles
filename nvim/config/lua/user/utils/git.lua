---@param git_cmd string[]
---@param opts? { wait_timeout_ms?: integer|nil }|nil
local function run_cmd(git_cmd, opts)
    opts = opts or {}
    opts.wait_timeout_ms = opts.wait_timeout_ms or 2000
    local child_process = vim.system(git_cmd)
    local child_result = child_process:wait(opts.wait_timeout_ms)
    return child_result
end

local M = {}

---@param file_path string
---@return boolean is_unmerged
function M.is_unmerged_file(file_path)
    local git_result = run_cmd({
        "git",
        "ls-files",
        "--unmerged",
        "--error-unmatch",
        file_path,
    })
    local is_unmerged = git_result.code == 0
    return is_unmerged
end

---@param file_path string
---@return boolean is_added
function M.add_file(file_path)
    local git_result = run_cmd({
        "git", "add", file_path
    })
    local is_added = git_result.code == 0
    return is_added
end

return M
