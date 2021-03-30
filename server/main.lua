local skynet = require "skynet"
require "skynet.manager"
local hotfix = require "hotfix"

skynet.start(function ()
    skynet.uniqueservice("srv_logger", 1)
    skynet.uniqueservice("debug_console", 8903)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end

    skynet.uniqueservice("srv_auth", 1)
    skynet.uniqueservice("srv_mongo", 1)
    skynet.uniqueservice("srv_request3rd", 1)
    skynet.uniqueservice("srv_lottery", 1)
    hotfix.start_hotfix_service("skynetunique", "http_portal", skynet.getenv("frontend_http_port"), 65536)
    hotfix.start_hotfix_service("skynetunique", "ws_portal", skynet.getenv("frontend_ws_port"), "ws")
    
    skynet.exit()
end)
