local function is_wsl()
    return not not vim.env.WSL_INTEROP
end

local function init_wsl()
    if not is_wsl() then
        return
    end

    vim.g.clipboard = {
        name = "WslClipboard",
        copy = { ["+"] = "clip.exe", ["*"] = "clip.exe", },
        paste = {
            ["+"] =
            'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            ["*"] =
            'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        },
        cache_enabled = 0,
    }
end

init_wsl()
