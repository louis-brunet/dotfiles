return {
    name = "alphatab-language-server",
    schema = "registry+v1",
    description = "alphaTex language server",
    homepage = "https://alphatab.net",
    categories = { "LSP" },
    languages = { "alphatex" },
    licenses = { "MPL-2.0" },
    source = { id = "pkg:npm/%40coderline/alphatab-language-server@1.8.1" },
    bin = { ["alphatab-language-server"] = "npm:alphatab-language-server" },
}
