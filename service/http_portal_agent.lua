local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local error_code_config = require "config.error_code_config"
local urllib = require "http.url"
local logger = log4.get_logger(SERVICE_NAME)

local modules = {}
modules.user        = require "user.user_impl"
modules.lottery     = require "lottery.lottery_impl"


body_size_limit, update_count = ...

--------------------
local BEFORE_PROCESS = {}
local AFTER_PROCESS = {}
local PROCESS = {}              -- 处理模式
local INIT_PROCESS  = false     -- 是否已初始化
local SORT_PROCESS = {}         -- 排序后处理器

local function init_process()
    if INIT_PROCESS then
        return
    end
    INIT_PROCESS = true
    SORT_PROCESS = {}
    for _, v in ipairs(BEFORE_PROCESS) do 
        table.insert(SORT_PROCESS, v) 
    end
    for _, v in ipairs(PROCESS) do 
        table.insert(SORT_PROCESS, v)
    end 
    for _, v in ipairs(AFTER_PROCESS) do 
        table.insert(SORT_PROCESS, v) 
    end 
end

local function not_found_process(req, res)
    res.code = 404
    res.body = "<html><head><title>404 Not Found</title></head><body> <p>404 Not Found</p></body></html>"
    res.headers["Content-Type"]="text/html"
end

local function internal_server_error(req, res, errmsg)
    res.code = 500
    if IS_DEBUG then
        local body = "<html><head><title>Internal Server Error</title></head><body><p>500 Internal Server Error</p><p>%s</p></body></html>"
        res.body = string.format(body, errmsg)
    else
        res.body = "<html><head><title>Internal Server Error</title></head><body><p>500 Internal Server Error</p></body></html>"
    end
    res.headers["Content-Type"]="text/html"
    return res.code, res.body, res.headers
end

local function pre_pattern(path)
    local keys = {}
    for k in string.gmatch(path, "/:([%w_]+)") do
        table.insert(keys, k)
    end
    if #keys == 0 then
        return path
    end
    local pattern = string.gsub(path, "/:(%w+)", "/([%%w_]+)")
    return pattern, keys
end


local function web_use(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(PROCESS, {path= path, pattern = pattern, keys=keys, process = process})
end

--是否有意义？方便处理排序？
local function web_after(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(AFTER_PROCESS, {path= path, pattern = pattern, keys=keys, process = process})
end

--是否有意义？方便处理排序？
local function web_before(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(BEFORE_PROCESS, {path= path, pattern = pattern, keys=keys, process = process})
end

local function web_get(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(PROCESS, {path = path, pattern = pattern, keys=keys, process = process, method = "GET"})
end

local function web_post(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(PROCESS, {path = path, pattern = pattern, keys=keys, process = process, method = "POST"})
end

local function static(root, file)
    file = root..file
    local fd = io.open(file, "r")
    local allcontent = ""
    while true do
        local content = fd:read(1024 * 128)
        if content then
            if content ~= "" then
                allcontent = allcontent .. content
            end
        else
            break
        end
    end
    fd:close()
    return allcontent
end

-- 静态文件下载
local function web_static(path, root)
    web_get(path, function (req, res)
        local file = req.path
        if string.find(file, "%.%s.") then      -- 禁止相对路径
            res.code = 404
            res.body = "NOT FOUND"
            return true
        end
        res.body = static(root, file)
        local suffix = string.match(file, "%.(%w+)$")
        local file_content_type = {
            json = "application/json",
            js = "text/javascript",
            html = "text/html",
            css = "text/css",
            txt = "text/plain",
            png = "image/png",
            jpg = "image/jpeg",
            jpeg = "image/jpeg",
            mp4 = "video/mp4"
        }
        res.headers["Content-Type"] = file_content_type[suffix]
        return true
    end)
end
---------------------------


web_before(".*", function (req, res)
    res.headers["Access-Control-Allow-Origin"] = "http://localhost:8080"
    res.headers["Access-Control-Allow-Methods"] = "POST"
    res.headers["Access-Control-Allow-Headers"] = "Content-Type,XFILENAME,XFILECATEGORY,XFILESIZE"
    res.headers["Access-Control-Allow-Credentials"] = "true"
    return true
end)

web_before(".*", function(req, res)
    logger.debug("before web req %s body %s", tostring(req.url), tostring(req.body))
    return true
end)

web_use("^/:module/:command$", function (req, res)
    local module = req.params.module
    local command = req.params.command
    local REQUEST = modules[module]
    if not REQUEST or not REQUEST[command] then
        local result = {code = error_code_config.ERROR_NAME_UNFOUND.value, err = error_code_config.ERROR_NAME_UNFOUND.desc}
        res:json(result)
        return true
    end

    -- 登陆成功的访问做安全验证; 以后再看有没有必要分到一个单独的模块
    if module ~= "user" or command ~= "login" then
        local cookies = req:get_cookies()
        local cli_sid = cookies.sid
        local cli_session, cli_uid = skynet.call("srv_auth", "lua", "get_session_by_sid", cli_sid)
        if not cli_uid then
            local result = {code = error_code_config.ERROR_USER_AUTH_FAILED.value, err = error_code_config.ERROR_USER_AUTH_FAILED.desc}
            res:json(result)
            return true
        end
        local srv_session, srv_uid = skynet.call("srv_auth", "lua", "get_session_by_uid", cli_uid)
        if not cli_session and not srv_session then
            local result = {code = error_code_config.ERROR_VERSION_OLDER.value, err = error_code_config.ERROR_VERSION_OLDER.desc}
            res:json(result)
            return true
        end
        if not cli_session and srv_session then
            local result = {code = error_code_config.ERROR_USER_LOGIIN_OTHER_DEVICE.value, err = error_code_config.ERROR_USER_LOGIIN_OTHER_DEVICE.desc}
            res:json(result)
            return true
        end
        local cli_expired = cli_session.expired
        local now_time = skynet_time()
        if cli_expired < now_time then
            local result = {code = error_code_config.ERROR_USER_SESSION_EXPIRED.value, err = error_code_config.ERROR_USER_SESSION_EXPIRED.desc}
            res:json(result)
            return true
        end
        skynet.send("srv_auth", "lua", "renew_expired", cli_sid, now_time)
    end

    local msg = req.query
    if req.method == "POST" then
        msg = cjson_decode(req.body)
    end
    local trace_err = ""
    local trace = function (e)
        trace_err = tostring(e) .. debug.traceback()
    end
    local ok, res_data, extra = xpcall(REQUEST[command], trace, req, msg)
    if not ok then
        logger.error("%s %s %s", req.path, tostring(msg), trace_err)
        local result = {code = error_code_config.ERROR_INTERNAL_SERVER.value, err = error_code_config.ERROR_INTERNAL_SERVER.desc}
        res:json(result)
        return true
    end
    res:json(res_data)

    -- 登陆成功保存会话到cookie方便下次访问做安全验证
    if module == "user" and command == "login" then
        res:set_cookies({sid = extra})
    end

    return true
end)

web_after(".*", function(req, res)
    if req.params and req.params.module then
        logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), tostring(res.body))
    else
        logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), string.len(res.body))
    end
    return true
end)

web_static("^/*", "./server/views")

---------------------------
local REQ = {}
function REQ:get_cookies()
    local cookies_tmp = string.split(self.headers.cookie, ";")
    local cookies = {}
    for k, v in ipairs(cookies_tmp) do
        local cookie = string.split(string.trim(v), "=")
        cookies[cookie[1]] = cookie[2]
    end
    return cookies
end

local RES = {}
function RES:json(tbl)
    local ok, body = pcall(cjson_encode, tbl)
    self.headers["Content-Type"] = 'application/json'
    self.body = body
end

function RES:set_cookies(cookies)
    local cookie_str = ""
    local i = 0
    for k, v in pairs(cookies) do
        cookie_str = string.format("%s%s%s=%s", cookie_str, i == 0 and "" or ";", k, v)
        i = i + 1
    end
    self.headers["Set-Cookie"] = cookie_str
end

function RES:status(code)
    self.code = code
end

local function process(req, res)
    init_process()                              -- 延后初始化处理器
    -- 正则表达式匹配支持
    local found = false
    for _, match in ipairs(SORT_PROCESS) do 
        if match.method and req.method ~= match.method then
        elseif string.match(req.path, match.pattern) then
            found = true
            if match.keys then
                local args = table.pack(string.match(req.path, match.pattern))
                if #args == #match.keys then
                    local params = {}
                    for k,v in ipairs(args) do 
                        params[match.keys[k]] = v
                    end
                    req.params = params
                    if not match.process(req, res) then
                        break
                    end
                end
            elseif not match.process(req, res) then
                break
            end
        end
    end
    return found or not_found_process(req, res)
end

-- 处理http请求
local function http_request(addr, url, method, headers, path, query, body, fd)
    local ip, _ = addr:match("([^:]+):?(%d*)$")
    local req = {ip = ip, url = url, method = method, headers = headers, 
            path = path, query = query, body = body, fd = fd, addr = addr}
    local res = {code = 200, body = nil, headers = {}}
    setmetatable(req, REQ)
    REQ.__index = REQ
    setmetatable(res, RES)
    RES.__index = RES
    local trace_err = ""
    local trace = function (e)
        trace_err = tostring(e) .. debug.traceback()
    end
    local ok = xpcall(process, trace, req, res)
    if not ok then
        skynet.error(trace_err)
        return internal_server_error(req, res, trace_err)
    end
    if not res.body then
        res.code = 404
        res.body = 'not found'
    end
    return res.code, res.body, res.headers
end

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end


local SOCKET_NUMBER = 0
local CMD = {}

function CMD.exit()
    skynet.fork(function ()
        while true do
            skynet.sleep(60 * 100)           -- 60s
            if SOCKET_NUMBER == 0 then
                break
            end
        end
        logger.info("after update service exit %08x", skynet.self())
        skynet.exit()                        -- 没有连接存在了
    end)
end

function CMD.info()
    logger.info("socket connect number %s", SOCKET_NUMBER)
end

function CMD.socket( fd, addr)
    SOCKET_NUMBER = SOCKET_NUMBER + 1
    socket.start(fd)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), tonumber(body_size_limit))
    if code then
        if code ~= 200 then
            response(fd, code)
        else
            local path, query = urllib.parse(url)
            local q = {}
            if query then
                q = urllib.parse_query(query)
            end         
            response(fd, http_request(addr, url, method, header, path, q, body, fd))
        end
    else
        if url == sockethelper.socket_error then
            skynet.error("socket closed")
        else
            skynet.error(url)
        end
    end
    SOCKET_NUMBER = SOCKET_NUMBER - 1
    socket.close(fd)
end

skynet.start(function() 
    skynet.dispatch("lua", function(session, _, command, ...)
        local f = CMD[command]
        if not f then
            if session ~= 0 then
                skynet.ret(skynet.pack(nil))
            end
            return
        end
        if session == 0 then
            return f(...)
        end
        skynet.ret(skynet.pack(f(...)))
    end)
end)
