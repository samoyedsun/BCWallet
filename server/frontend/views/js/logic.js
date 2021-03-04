console.log("document.domain:", document.domain)

var uid = 10000000
var token = "76491a8d530c11f397789e45bb7c5237a67f185e"

function userLogin(reqData){
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if ( xhr.readyState == 4 ){
            if ( ( xhr.status >= 200 && xhr.status < 300 ) || xhr.status == 304 ) {
                var resData = JSON.parse(xhr.responseText);
                if (resData.code == 20000) {
                    console.log("成功!");
                } else {
                    console.log(resData.err);
                }
            } else {
                alert("请求失败!" + xhr.status)
            }
        }
    }
    xhr.open('POST', "http://" + document.domain + ":8203" + "/user/login", true );
    var data = JSON.stringify(reqData);
    xhr.send(data);
}

function userRegister(reqData){
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if ( xhr.readyState == 4 ){
            if ( ( xhr.status >= 200 && xhr.status < 300 ) || xhr.status == 304 ) {
                var resData = JSON.parse(xhr.responseText);
                if (resData.code == 20000) {
                    console.log("成功!");
                } else {
                    console.log(resData.err);
                }
            } else {
                alert("请求失败!" + xhr.status)
            }
        }
    }
    xhr.open('POST', "http://" + document.domain + ":8203" + "/user/register", true );
    var data = JSON.stringify(reqData);
    xhr.send(data);
}

function user_info(){
    var socket = new Socket();
    socket.connect("ws://" + document.domain + ":9948" + "/ws");
    socket.on("onopen", function () {
        socket.request("user_auth", {
            uid : uid,
            token : token,
            platform : "website"
        }, function (args) {
            console.log(args)
            socket.request("user_info", {
                uid : uid
            }, function (args) {
                document.getElementById("field_recv").value = JSON.stringify(args)
                socket.close()
            });
        });
    });
}