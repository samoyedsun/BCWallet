local skynet = require "skynet"
require "luaext"
require "print_r"
require "functions"

log4 = require "log4"
log4.configure(require "etc.log4")

IS_DEBUG = skynet.getenv("run_mode")