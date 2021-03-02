return {
    OMNICORE_HOST = "http://testtesttest.huanyingplay.com:8332",
    OMNICORE_SENDHEADER = {
        ["Content-Type"] = "application/json",
        ["Accept-Charset"] = "utf-8",
        ["Authorization"] = "Basic " .. "dGVzdDoxMjM0NTY="
    },
    OMNICORE_GENERATION_PARAMS = function(method, params)
        return {
            id = "1",
            jsonrpc = "2.0",
            method = method,
            params = params
        }
    end
}