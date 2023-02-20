#!/bin/bash

[[ -e lib/sing.pid ]] && pkill -F lib/sing.pid
[[ -e subs/$1/tested.txt ]] && rm subs/$1/tested.txt

ls subs/"$1" | while read line
do
    #echo $line
    jq -s ".[0].outbounds[0] = .[1].outbounds[0] | .[0]" conf/test_base.json subs/"$1"/"$line" > conf/test_conf.json
    lib/run-sing.sh conf/test_conf.json lib/sing.pid &
    st=$[$(date +%s%N)/1000000]
    env http_proxy='http://127.0.0.1:20175' https_proxy='http://127.0.0.1:20175' curl -s http://cp.cloudflare.com/
    et=$[$(date +%s%N)/1000000]
    t=$((et-st))
    pkill -F lib/sing.pid
    echo "$t subs/$1/$line"
    echo "$t subs/$1/$line" >> subs/$1/tested.txt
done

rm lib/sing.pid 

echo "------------------------------------------------------"

cat subs/$1/tested.txt | sort -r -k1 -n
