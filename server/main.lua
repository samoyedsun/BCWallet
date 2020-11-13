local skynet = require "skynet"
require "skynet.manager"
local hotfix = require "hotfix"

skynet.start(function ()
    skynet.uniqueservice("srv_logger_sup")
    skynet.newservice("debug_console", 8903)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end

    local config = require('etc.' .. skynet.getenv("env") .. ".server")
    hotfix.start_hotfix_service("skynet", "srv_web", config.backend.port, "server.backend.webapp", 65536)
    hotfix.start_hotfix_service("skynet", "srv_web", config.frontend.port, "server.frontend.webapp", 65536 * 2)
    hotfix.start_hotfix_service("skynet", "srv_websocket", config.frontend.wsport, "server.frontend.wsapp", "ws")
    skynet.exit()
end)
