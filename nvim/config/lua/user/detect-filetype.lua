vim.filetype.add({
    filename = {
        ['docker-compose.yml'] = 'yaml.docker-compose',
        ['docker-compose.yaml'] = 'yaml.docker-compose',
    },
    extension = {
        tfvars = 'terraform',
        http = 'http', -- TODO: why is this sometimes necessary ?
    },
    pattern = {
        ['.*%.component%.html'] = "angular.html",
    },
})

