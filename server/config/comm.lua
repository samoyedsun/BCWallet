local httpc = require "http.httpc"
local logger = log4.get_logger("server_config_comm")

local root = {}

function root.http_request(method, host, path, param, sendheader)
    local recvheader = {}
    local sendheader = sendheader or {
        ["Content-Type"] = "application/json",
        ["Accept-Charset"] = "utf-8"
    }
    
    if method == "GET" then
        local i = 0
        for k, v in pairs(param) do 
            path = string.format("%s%s%s=%s", path, i == 0 and "?" or "&", k, v)
            i = i + 1
        end
        param = nil
    elseif type(param) == "table" then
        param = cjson_encode(param)
    end

    local req = param
    local status, content = httpc.request(method, host, path, recvheader, sendheader, req)
    local debug_info = {status, method, host, path, tostring(recvheader), tostring(sendheader), tostring(req), content}
    logger.debug("http_request, status:%s, method:%s, host:%s, path:%s, recvheader:%s, sendheader:%s, req:%s, res:%s", table.unpack(debug_info))

    local ok, res = pcall(cjson_decode, content)
    if not ok then
        return content
    end
    return res
end

return root