skynetroot = "./skynet/"
cloudroot="./"
thread = 8
harbor = 0
start = "server/main"  -- main script
bootstrap = "snlua bootstrap"   -- The service for bootstrap

gameservice = cloudroot.."service/?.lua;" .. "./test/?.lua;" .. "./?.lua"
luaservice = skynetroot.."service/?.lua;" .. gameservice

lualoader = skynetroot .. "lualib/loader.lua"
preload = "./etc/preload.lua"   -- run preload.lua before every lua service run
snax = gameservice
cpath = skynetroot.."cservice/?.so;".. "" ..cloudroot.."cservice/?.so" 

lua_path = skynetroot .. "lualib/?.lua;" ..
            -- skynetroot .. "lualib/compat10/?.lua;" ..
            cloudroot .. "lualib/?.lua;"..
            cloudroot .. "lualib/rpc/?.lua;".. 
            "./test/?.lua;" ..
            "./lualib/?.lua;" ..
            "./?.lua" 
            
lua_cpath = skynetroot .. "luaclib/?.so;" .. cloudroot .."luaclib/?.so" 


logpath = $LOG_PATH
env = $ENV or "dev"

if $DAEMON then
      daemon = "./run/skynet-test.pid"
      logger = logpath .. "skynet-error.log"
end

debug_mode = true
backend_http_port = 8103
backend_ws_port = 9848
frontend_http_port = 8203
frontend_ws_port = 9948

mongo_host = "127.0.0.1"
mongo_port = 27017
mongo_db_name = "bcwallet"
mongo_username = "bcwallet"
mongo_password = "2habYaVFQFKmuji5"
mongo_auth_mod = "scram_sha1"