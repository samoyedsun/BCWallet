local crypt = require "skynet.crypt"
local uid = 12132
local timestamp = skynet_time()
local password = "helloworld"
local secret = "uwmr8HU1"
print(uid)
print(timestamp)
print(password)
print(secret)   -- 玩家登陆时，记录登陆时间timestamp
local token = token_create(uid, timestamp, password, secret)
print(token)
print("====================")
-- 用户请求数据时携带token,uid; 通过uid得到secret,然后解析token
local uid, timestamp, password = token_parse(token, secret)
print(uid)
print(timestamp)
print(password)
print(secret, "        ", secret[1]:byte())
-- 解析报错抛异常验证失败，非法token
-- 时间戳和密码，首先验证密码是否正确，然后验证时间戳是否过期，ok则通过, 否则验证失败需要重新登陆
-- 时间戳 + 7200 < 当前时间 验证失败 说明过期
-- 登出时间为空，或 时间戳 > 登出时间 验证失败 没登出直接登陆 说明在其他设备登陆

-- 玩家手动登出 标记登出
-- 时间未到更新token
-- 时间到了标记登出
