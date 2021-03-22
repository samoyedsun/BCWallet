作者信息
---
- 作者:LGC
- 时间:2017年 3月 4日 星期六 10时44分20秒 

- 作者:MRZ
- 时间:2019年 6月18日 星期二 17时28分40秒

学习资料
---
|标题|网址|
|-|-|
|服务端框架skynet|https://github.com/cloudwu/skynet/wiki|
|云风的blog|https://blog.codingnow.com/|

本框架解决的问题
---
- 服务器热更新
- log4日志服务功能
- web服务功能
- 基于http协议，消息序列化和反序列化基于json的rpc功能
- mysql和redis代理功能

集成库
---
- cjson

目录说明
---
```txt
├── bin                     启动脚本
├── cservice                skynet cservice
├── doc                     文档
├── etc                     skynet进程启动配置文件
├── server                  服务器逻辑代码示例
├── logs                    日志目录
├── luaclib                 lua c语言模块
├── lualib                  lua模块代码
├── lualib-src              lua c语言模块代码
├── run                     进程运行时存放文件目录，比如说进程pid
├── service                 skynet服务目录
├── service-src             skynet c语言服务代码
├── skynet                  skynet
└── test                    测试目录
```

编译前安装依赖库:
- macosx
    ```sh
    brew install openssl
    ```
- ubuntu
    ```sh
    sudo apt-get install libcurl4-gnutls-dev libreadline-dev autoconf libssl-dev
    ```
- centos
    ```sh
    sudo yum install libcurl-devel readline-devel autoconf openssl-devel
    ```

编译:
- Linux
    ```sh
    make linux
    ```
- Mac
    ```sh
    make macosx
    ```

启动命令：
```sh
./bin/start.sh
```
后台运行
```sh
./bin/start.sh -D
```
热更新命令：
```sh
./bin/start.sh -U
```

启动MONGODB服务
```sh
docker run -it -d -p 27017:27017 -v ${PWD}/data:/root/data -e MONGO_INITDB_ROOT_USERNAME=bcwallet -e MONGO_INITDB_ROOT_PASSWORD=2habYaVFQFKmuji5 --name mongo mongo
```
登陆MONGODB服务
```sh
docker exec -it mongo mongo -u bcwallet -p 2habYaVFQFKmuji5
```

常见问答A&Q：
- MAC下编译如果遇到的问题:
    - 以下报错
        ```txt
        ld: library not found for -lgcc_s.10.4
        ```
    - 需要做以下操作解决
        ```sh
        cd /usr/local/lib && sudo ln -s ../../lib/libSystem.B.dylib libgcc_s.10.4.dylib
        ```
    - 解决方法来自[这里](http://bugsfixes.blogspot.com/2016/02/mac-ld-library-not-found-for-lgccs104.html)

lua静态检测工具安装
```sh
brew install luarocks
luarocks install luacheck

#测试
luacheck test.lua
```
---

创建钱包
```
PROTO:  POST
URL:    localhost:8203/wallet/createwallet
PARAM:  {
            "wallet_name":"abc111"
        }
```
加密钱包
```
PROTO:  POST
URL:    localhost:8203/wallet/encryptwallet
PARAM:  {
            "wallet_name":"abc111",
            "passphrase":"qazwsx123"
        }
```
解密钱包 超时后自动锁定
```
PROTO:  POST
URL:    localhost:8203/wallet/walletpassphrase
PARAM:  {
            "wallet_name":"abc111",
            "passphrase":"qazwsx123",
            "timeout":60
        }
```
获取钱包信息
```
PROTO:  POST
URL:    localhost:8203/wallet/getwalletinfo
PARAM:  {
            "wallet_name":"abc111"
        }
```
新建钱包地址
```
PROTO:  POST
URL:    localhost:8203/wallet/getnewaddress
PARAM:  {
            "wallet_name":"abc111",
            "lable":"MYUSDT"
        }
```
获取钱包地址
```
PROTO:  POST
URL:    localhost:8203/wallet/getaddressesbylabel
PARAM:  {
            "wallet_name":"abc111",
            "lable":"MYUSDT"
        }
```
获取钱包地址信息
```
PROTO:  POST
URL:    localhost:8203/wallet/getaddressinfo
PARAM:  {
            "wallet_name":"abc111",
            "address":"xxxxxxxxxxx"
        }
```
获取USDT数量
```
PROTO:  POST
URL:    localhost:8203/wallet/omni_getbalance
PARAM:  {
            "address":"xxxxxxxxxxx"
        }
```
获取USDT数量
```
PROTO:  POST
URL:    localhost:8203/wallet/getaddressbalance
PARAM:  {
            "addresses":{"xxxxxxxxxxx","xxxxxxxxxx"}
        }
```
转账
```
PROTO:  POST
URL:    localhost:8203/wallet/omni_funded_send
PARAM:  {
            "wallet_name":"abc111",
            "fromaddress":"xxxxxxxxxxxxxxxxxxxxxxx",
            "toaddress":"xxxxxxxxxxxxxxxxxxxxxxx",
            "amount":10,
            "feeaddress":"xxxxxxxxxxxxxxxxxxxxxxx",
        }
```
查询
```
PROTO:  POST
URL:    localhost:8203/wallet/omni_gettransaction
PARAM:  {
            "wallet_name":"abc111",
            "txid":"xxxxxxxxxxxxxxxxxxxxxxx",
        }
```