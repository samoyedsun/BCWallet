local skynet = require "skynet"
require "skynet.manager"
local hotfix = require "hotfix"

skynet.start(function ()
    skynet.uniqueservice("srv_logger_sup")
    skynet.newservice("debug_console", 8903)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end

    skynet.newservice("mongo", 1)
    skynet.newservice("third_api", 1)
    hotfix.start_hotfix_service("skynet", "http_portal", skynet.getenv("frontend_http_port"), 65536)
    hotfix.start_hotfix_service("skynet", "ws_portal", skynet.getenv("frontend_ws_port"), "ws")
    --hotfix.start_hotfix_service("skynet", "srv_websocket", skynet.getenv("frontend_ws_port"), "frontend.wsapp", "ws")
    
    skynet.exit()
end)
