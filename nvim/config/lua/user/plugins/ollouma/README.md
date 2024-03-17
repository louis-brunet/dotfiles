## Installation

### with lazy.nvim

```lua
---@type LazySpec
{
    'louis-brunet/ollouma.nvim'

    dependencies = {
        -- TODO: document dependencies
    },

    opts = {
        -- see [Setup](#setup)
    },

    config = function(_, opts)
        local ollouma = require 'ollouma'

        ollouma.setup(opts)
    end
}
```

## Configuration options

```lua
---@type OlloumaConfig
{
-- TODO: document config
}
```

