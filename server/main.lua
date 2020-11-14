local skynet = require "skynet"
require "skynet.manager"
local hotfix = require "hotfix"

skynet.start(function ()
    skynet.uniqueservice("srv_logger_sup")
    skynet.newservice("debug_console", 8903)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end

    hotfix.start_hotfix_service("skynet", "srv_web", skynet.getenv("backend_http_port"), "server.backend.webapp", 65536)
    hotfix.start_hotfix_service("skynet", "srv_websocket", skynet.getenv("backend_ws_port"), "server.backend.wsapp", "ws")
    hotfix.start_hotfix_service("skynet", "srv_web", skynet.getenv("frontend_http_port"), "server.frontend.webapp", 65536)
    hotfix.start_hotfix_service("skynet", "srv_websocket", skynet.getenv("frontend_ws_port"), "server.frontend.wsapp", "ws")
    skynet.exit()
end)
