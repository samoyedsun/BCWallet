- 使用方式:
    1. 运行 a_exceltolua.exe 可以将当前目录下的配置文件生成到config目录

- 配置格式要求:
    - 第一行必须是描述行
    - 第二行必须是字段名(若不填则当前列都不会导出)
    - 第三行必须是字段类型 支持(1~9)
    - 第四行必须是导出方式(0~2)
    - 第一列必须是key(4~5)

- 导出方式:
    - 0-导出客户端.服务端配置
    - 1-只导出客户端配置
    - 2-只导出服务端配置
    - 若第一列导出方式为1 那么只会导出客户端配置

- 字段类型:
    - 1-数字(若不填则默认0)
    - 2-字符(若不填则默认"")
    - 3-表(若不填则默认{})
    - 4-数字key(若不填则整行都不导出)
    - 5-字符串key(若不填则整行都不导出)
    - 6-不识别导出(填什么导出什么 不填则字段不导出)
    - 7-数字(若不填则字段不导出)
    - 8-字符(若不填则字段不导出)
    - 9-表(若不填则字段不导出)