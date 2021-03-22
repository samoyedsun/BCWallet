#!/bin/sh

export ROOT=$(pwd)

export DAEMON=false
export LOG_PATH='"./logs/"'
export ENV='"dev"'
while getopts "DKU:l:v:" arg
do
    case $arg in
        D)
            export DAEMON=true
            ;;
        K)
            kill `cat $ROOT/run/skynet-test.pid`
            exit 0;
            ;;
        l) 
            export LOG_PATH='"'$OPTARG'"'
            ;;
        v)  
            export ENV='"'$OPTARG'"'
            ;;
        U)
            echo 'start srv_hotfix update' | nc 127.0.0.1 8903
            exit 0;
            ;;

    esac
done

$ROOT/skynet/skynet $ROOT/etc/config.lua
