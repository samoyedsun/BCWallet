local skynet = require "skynet"
require "skynet.manager"
local hotfix = require "hotfix"

skynet.start(function ()
    skynet.uniqueservice("mylogger")
    skynet.newservice("debug_console", 8903)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end

    skynet.newservice("mongo", 1)
    skynet.newservice("request3rd", 1)
    skynet.newservice("lottery", 1)
    hotfix.start_hotfix_service("skynet", "http_portal", skynet.getenv("frontend_http_port"), 65536)
    hotfix.start_hotfix_service("skynet", "ws_portal", skynet.getenv("frontend_ws_port"), "ws")
    
    skynet.exit()
end)
