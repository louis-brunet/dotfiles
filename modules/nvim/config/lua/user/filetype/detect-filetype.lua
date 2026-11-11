vim.filetype.add({
    filename = {
        ['docker-compose.yml'] = 'yaml.docker-compose',
        ['docker-compose.yaml'] = 'yaml.docker-compose',
    },
    extension = {
        -- tfvars = 'terraform-vars',
        tf = 'terraform',
        http = 'http',

        -- https://alphatab.net/docs/alphatex/lsp
        atex = 'alphatex',
        alphatex = "alphatex"
    },
    pattern = {
        ['.*%.component%.html'] = 'angular.html',

        ['%.env'] = 'sh',
        ['%.env%..*'] = 'sh',
        ['.*%.env%.example'] = 'sh',
        ['.*%.env%.template'] = 'sh',
    },
})

