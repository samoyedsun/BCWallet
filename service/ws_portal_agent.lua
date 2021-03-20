local skynet = require "skynet"
local socket = require "skynet.socket"
local service = require "skynet.service"
local websocket = require "http.websocket"
local sproto = require "sproto"
local jproto = require "jproto"
local code = require "config.code"
local session_class = require "session"
local logger = log4.get_logger(SERVICE_NAME)

update_count = ...

local COMMAND = {}

function add_web_agent_cmd(cmd, process)      -- 这样合适吗？
    COMMAND[cmd] = process
end

--------------------------------------------------------

------------------------------------------------------------------
-- 协议事件处理
local PROTO_PROCESS = { 
    C2S = {},
    S2C = {},
}

local C2S_PROCESS = {}
local S2C_PROCESS = {}

local C2S_AFTER_PROCESS = {}
local S2C_AFTER_PROCESS = {}

local C2S_BEFORE_PROCESS = {}
local S2C_BEFORE_PROCESS = {}
local IS_INIT_PROCESS = false

local HOST 
local HOST_REQUEST 

local socketproto = {}

local function init_process()
    if IS_INIT_PROCESS then
        return
    end
    
    C2S_PROCESS = {}
    S2C_PROCESS = {}
    for _, v in ipairs(C2S_BEFORE_PROCESS) do 
        table.insert(C2S_PROCESS, v)
    end
    for _, v in ipairs(S2C_BEFORE_PROCESS) do 
        table.insert(S2C_PROCESS, v)
    end

    for _, v in ipairs(PROTO_PROCESS.C2S) do 
        table.insert(C2S_PROCESS, v)
    end
    for _, v in ipairs(PROTO_PROCESS.S2C) do 
        table.insert(S2C_PROCESS, v)
    end

    for _, v in ipairs(C2S_AFTER_PROCESS) do 
        table.insert(C2S_PROCESS, v)
    end
    for _, v in ipairs(S2C_AFTER_PROCESS) do 
        table.insert(S2C_PROCESS, v)
    end
end


function socketproto.configure(host, host_request)
    HOST = host
    HOST_REQUEST = host_request
end

function socketproto.c2s_use(name, process)
    IS_INIT_PROCESS = false
    PROTO_PROCESS.C2S[name] = process
    table.insert(PROTO_PROCESS.C2S, {name, process})
end

function socketproto.s2c_use(name, process)
    IS_INIT_PROCESS = false
    table.insert(PROTO_PROCESS.S2C, {name, process})
end
function socketproto.c2s_after( name, process)
    IS_INIT_PROCESS = false
    table.insert(C2S_AFTER_PROCESS, {name, process})
end

function socketproto.c2s_before( name, process )
    IS_INIT_PROCESS = false
    table.insert(C2S_BEFORE_PROCESS, {name, process})
end

function socketproto.s2c_after( name, process )
    IS_INIT_PROCESS = false
    table.insert(S2C_AFTER_PROCESS, {name, process})
end

function socketproto.s2c_before( name, process )
    IS_INIT_PROCESS = false
    table.insert(S2C_BEFORE_PROCESS, {name, process})
end

-- 默认c2s处理器
local function not_found_c2s_process(self, name, args, res)
    return self:emit("error", "c2s", name, args, res, "c2s process not found")
end

local function c2s_process(self, name, req, res) 
    local found = false
    for _, v in ipairs(C2S_PROCESS) do
        local pattern, f = table.unpack(v) 
        if string.match(name, pattern) then
            found = true
            local ok = f(self, name, req, res)
            if not ok then
                return
            end
        end
    end

    return found or not_found_c2s_process(self, name, req, res)
end

local function s2c_process(self, name, args)
    for _, v in ipairs(S2C_PROCESS) do
        local pattern, f = table.unpack(v) 
        if string.match(name, pattern) then
            local ok = f(self, name, args)
            if not ok then
                return
            end
        end
    end
    return
end

function socketproto.send_package(fd, pack)
    if not fd then
        return false, "socket close"
    end
    local package = string.pack(">s2", pack)
    return socket.write(fd, package)
end

local function s2c_request(self, name, args)
    local trace_err = ""
    local trace = function (e)
        trace_err = tostring(e) .. debug.traceback()
    end
    local ok = xpcall(s2c_process, trace, self, name, args)
    if not ok then
        self:emit("error", "s2c",  name, args, nil, "s2c process " .. trace_err)
    end

    local ok, data = pcall(HOST_REQUEST, name, args)
    if not ok then
        self:emit("error", "s2c",  name, args, nil, "s2c proto " .. data)
        ok, data = pcall(HOST_REQUEST, name, args)
    end

    if self.session then
        local ok, err = root.send_package(self.session.fd, data)
        if not ok then
            self:emit("error", "socket", err, name, args)
        end
    end
end

-- 处理proto 请求协议入口
local function proto_request(self, msg, sz)
    local ok, type, name, args, response = pcall(HOST.dispatch, HOST, msg, sz)
    if not ok then
        self:emit("error", "proto", name, nil, nil, "proto unpack error ".. type)
        return
    end

    if type == "RESPONSE" then
        local session = name
        local s2c = self.session.s2c 
        if not s2c then
            self:emit("error", "proto", name, args, nil, "response not found wakeup co")
            return
        end
        local req = s2c.req
        local co = req[session]
        if co and type(co) == "thread" then
            req[session] = args
            skynet.wakeup(co)
            return
        end
        self:emit("error", "proto", name, args, nil, "response not found wakeup co")
    end
    if type ~= "REQUEST" then
        self:emit("error", "proto", name, args, nil, "unknow type ".. type)
        return
    end
    
    local trace_err = ""
    local trace = function (e)
        trace_err = tostring(e) .. debug.traceback()
    end
    local res = {}          -- 也许应该包含更多信息, 记录整个处理过程路径，方便debug
    local ok = xpcall(c2s_process, trace, self, name, args, res)
    if not ok then
        self:emit("error", "c2s", name, args, res, "c2s process ".. trace_err)
    end
    if not response or not self.session then
        return
    end
    local ok, data = pcall(response, res)
    if not ok then
        self:emit("error", "c2s", name, args, res, "c2s proto " .. data)
        ok, data = pcall(response, res)
    end
    local ok, err = root.send_package(self.session.fd, data)
    if not ok then
        self:emit("error", "socket", err, name, args, res)
    end
end

function socketproto.c2s_process(self, _ , ...)
    init_process()
    proto_request(self, ...)
    return true
end

function socketproto.s2c_process(self, _ , ...)
    init_process()
    s2c_request(self, ...)
    return true
end
------------------------------------------------------------------

-----------------------------------------------------------

-- local host = sproto.parse(gate_proto.c2s):host "package"
-- local host_request = host:attach(sproto.parse(gate_proto.s2c))
-- proto.configure(host, host_request)

-- 设置客户端消息序列化和反序列化方法
socketproto.configure(jproto.host, jproto.host_request)

socketproto.c2s_before(".*", function (self, name, args, res)
    if (name == "user_auth") or self.session.auth then
        return true
    end
    create_timeout(3 * 100, function(s) self:emit("kick") end)
    table.merge(res, {code = code.ERROR_USER_UNAUTH, err = code.ERROR_USER_UNAUTH_MSG})
    return false
end)

socketproto.c2s_use("^user_*", function (self, name, args, res)
    -- local user = require "frontend.request.socket_user"
    -- table.merge(res, user.request(self, name, args))
    --[[
    local msg = args
    if not REQUEST[name] then
        return {code = code.ERROR_NAME_UNFOUND, err = code.ERROR_NAME_UNFOUND_MSG}
    end

    local trace_err = ""
    local trace = function (e)
        trace_err = e .. debug.traceback()
    end
    local ok, res_data = xpcall(REQUEST[name], trace, self, msg)
    if not ok then
        logger.error("%s %s %s", name, tostring(msg), trace_err)
        return {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
    end
    table.merge(res, res_data)
    --]]
    return true
end)

socketproto.c2s_after(".*", function (self, name, args, res)
    logger.debug("c2s after %s %s %s %s", "hello", name, tostring(args), "a lot data")
end)

------------------------------------------------------------------

-- 用户事件处理器
local PROCESS = {}
local socketapp = {}

-- 匹配事件
local function match_process(patterns, name, self, ...)
    for _, v in ipairs(patterns) do
        local pattern, f = table.unpack(v) 
        if string.match(name, pattern) then
            local ok = f(self, name, ...)
            if not ok then              -- 是否继续
                return
            end
        end
    end
end

-- 注册用户事件处理器
function socketapp.use(name, process)
    table.insert(PROCESS, {name, process})
end

-- session = {fd = fd, agent = agent, gate = gate}
function socketapp:new()
    local o = { session = {} }
    setmetatable(o, {__index = self})
    return o
end


-- 触发事件
function socketapp:emit(name, ...)
    local trace_err = ""
    local trace = function (e)
        trace_err = tostring(e) .. debug.traceback()
    end
    local ok = xpcall(match_process, trace, PROCESS, name, self, ...)
    if not ok then          
        if name == "error" then             -- 有死循环的风险 ...
            skynet.error("channel emit:('error') endless loop %s", trace_err)
            return
        end
        socketapp.emit(self, "error", "emit", name, string.format("%s %s %s", name, trace_err, tostring(...)))
        return false
    end
    return true
end

-- 不推荐使用，可能一点用处都没有，反而让系统变复杂, 连接关闭的时候，协程可能一直没办法唤醒
function socketapp:s2c_call(name,args)
    if not self.session.s2c then
        self.session.s2c = {req = {}, session = 0}
    end
    local s2c = self.session.s2c
    local session = s2c.session + 1
    s2c.session = session
    local co = coroutine.running()
    self:emit(name, args, session)
    s2c.req[session] = co
    skynet.wait()
    local res = s2c.req[session]
    s2c.req[session] = nil
    return res
end

------------------------------------------------------------------


socketapp.use("^c2s$", socketproto.c2s_process)
socketapp.use("^s2c$", socketproto.s2c_process)

socketapp.use("^error$", function (self, _name, _type, ...)
    if _type == "c2s" then
        logger.error("%s %s %s", _type, self.session:tostring(), tostring({...}))
        local name, args, res, err = ...
        if res and type(res) == "table" then
            table.merge(res, {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG})
        end
        return true
    end
    if _type == "socket" and not self.session then
        logger.debug("%s %s", _type, tostring({...}))
        return true
    end

    logger.error("%s %s %s", _type, self.session:tostring(), tostring({...}))
    if _type == "s2c" then
    elseif _type == "proto" then
    elseif _type == "emit" then
    end
    return true
end)

socketapp.use("^start$", function (self, _name, options)
    self.session = session_class:new(options)
    logger.debug("start session:%s", self.session:tostring())
    --[[
    skynet.fork(function ( ... )
        while self.session do
            -- self:emit("s2c", "on_user_heartbeat")                        -- TODO: 发送心跳
            skynet.sleep(1000)
        end
    end)
    --]]
end)

socketapp.use("^close$", function (self)
    local session = self.session
    if session.handle then
        local ret = skynet.call(session.handle, "lua", "offline", session.uid)
        logger.debug("player close code:%d, err:%s", ret.code, ret.err)
    end
    self.session = nil
    return true
end)

socketapp.use("^kick$", function (self)
    local session = self.session
    if not session then
        return
    end
    logger.debug("kick session:%s", tostring(session:totable()))
    if session.gate then
        skynet.call(session.gate, "lua", "kick", session.fd)
        return
    end
    self:close(session.fd, "kick")
end)







----------------------------------------------------------------------------------


local CMD = {}
local SOCKET_TO_CLIENT = {}

function CMD.close(fd, reason)
    local client = SOCKET_TO_CLIENT[fd]
    SOCKET_TO_CLIENT[fd] = nil
    if not client then
        return
    end
    client:emit("close", reason)        -- 清理工作
end

function CMD.emit(fd, ...)
    local client = SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    client:emit(...)
end

function CMD.info()
    for k, v in pairs(SOCKET_TO_CLIENT) do 
        skynet.error(string.format("fd %s to client session %s", k, tostring(v.session)))
    end
end


function CMD.exit()
    for k, v in pairs(SOCKET_TO_CLIENT) do 
        v:emit("kick")
    end
end

-- 注册 srv_web_agent CMD.xxx
for cmd, p in pairs(CMD) do 
   add_web_agent_cmd(cmd, p)
end

function socketapp:close(fd, reason)
    local client = SOCKET_TO_CLIENT[fd]
    SOCKET_TO_CLIENT[fd] = nil
    if not client then
        return
    end
    client:emit("close", reason)        -- 清理工作
end

--- overide 重载 send_package
function socketproto.send_package(fd, package)
    local client = SOCKET_TO_CLIENT[fd] 
    if not client then
        return false, "close"
    end
    websocket.write(fd, package)
    return true, "ok"
end


-- websocket回调方法
local handle = {}

function handle.connect(fd)
    skynet.error(string.format("ws connect from: %s", tostring(fd)))
end

function handle.handshake(fd, header, url)
    local addr = websocket.addrinfo(fd)
    skynet.error(string.format("ws handshake from: %s, url: %s, addr: %s", tostring(fd), url, addr))
    skynet.error("----header-----")
    for k,v in pairs(header) do
        skynet.error(string.format("k:%s, v:%s", tostring(k), tostring(v)))
    end
    skynet.error("--------------")
    local client = socketapp:new()
    SOCKET_TO_CLIENT[fd] = client
    local ip = addr:match("([^:]+):?(%d*)$")
    local session = {fd = fd, agent = skynet.self(), addr = addr, ip = ip}
    client:emit("start", session)
end

function handle.message(fd, msg, msg_type)
    assert(msg_type == "text")
    local client = SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    client:emit("c2s", msg, #msg)
end

function handle.ping(fd)
    skynet.error(string.format("ws ping from: %s", tostring(fd)))
end

function handle.pong(fd)
    skynet.error(string.format("ws pong from: %s", tostring(fd)))
end

function handle.close(fd, code, reason)
    skynet.error(string.format("ws close from: %s, code: %s, reason: %s", tostring(fd), tostring(code), tostring(reason)))
    local client = SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    CMD.close(fd, reason)
end

function handle.error(fd)
    skynet.error(string.format("ws error from: %s", tostring(fd)))
    local client = SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    CMD.close(fd, msg)
end
--------------------------------------------------------


local SOCKET_NUMBER = 0
function COMMAND.update()
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

function COMMAND.info()
    logger.info("socket connect number %s", SOCKET_NUMBER)
end

function COMMAND.socket(fd, protocol, addr)
    SOCKET_NUMBER = SOCKET_NUMBER + 1
    skynet.error("change socket number:", SOCKET_NUMBER, ", fd:", fd)
    local ok, err = websocket.accept(fd, handle, protocol, addr)
    if not ok then
        skynet.error("on websocket accept, error:", err, ", fd:", fd)
    end
    SOCKET_NUMBER = SOCKET_NUMBER - 1
    skynet.error("change socket number:", SOCKET_NUMBER, ", fd:", fd)
end

skynet.start(function ()
    skynet.dispatch("lua", function (session, _, command, ...)
        local f = COMMAND[command]
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
