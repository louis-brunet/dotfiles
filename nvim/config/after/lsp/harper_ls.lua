-- https://writewithharper.com/docs/integrations/neovim
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#harper_ls
---@type vim.lsp.Config
return {
    settings = {
        ["harper-ls"] = {
            -- userDictPath = vim.fs.joinpath(
            --     vim.fn.expand("$XDG_CONFIG_HOME"),
            --     "harper-ls"
            -- ),
            -- fileDictPath = vim.fs.joinpath(
            --     vim.fn.expand("$XDG_DATA_HOME"),
            --     "harper-ls",
            --     "file_dictionaries"
            -- ),
            linters = {
                -- https://writewithharper.com/docs/rules
                SpellCheck = false,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = false,
                UnclosedQuotes = true,
                WrongQuotes = false,
                LongSentences = false,
                RepeatedWords = true,
                Spaces = false,
                Matcher = true,
                CorrectNumberSuffix = true,
                ToDoHyphen = false,
            },
            codeActions = { ForceStable = false },
            markdown = { IgnoreLinkTitle = false },
            diagnosticSeverity = "hint",  -- Can also be "information", "warning", or "error"
            isolateEnglish = false,
        },
    },
}
