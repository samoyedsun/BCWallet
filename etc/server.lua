local root = {
    backend = {
        ip = "0.0.0.0",
        type = "http",
        port = 8103,
    },
    frontend = {
        ip = "0.0.0.0",
        type = "http",
        wsport = 9948,
        port = 8203,
    }
}


return root