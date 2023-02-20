#!/bin/bash

function update_all {
    NAMES=($(jq -r 'map(.name) | @sh' conf/subs.json | tr -d \'))

    for i in "${NAMES[@]}"
    do
	update $i
    done
    
}

function help {
    echo "zhaose's sing-box tools"
}

function update {
    url=$(jq "map(select(.name == \"$1\")) | .[0].url" conf/subs.json -r)
    echo "更新訂閱 $url 中"
    mkdir -p subs/$1
    rm subs/$1/*.json
    curl -s $url | base64 -d | while read line
    do
	echo $line
	name=$(deserver $line | jq .name -j | sed 's/\r//g')
	deserver $line > subs/$1/"$name".json
	echo "更新$name"
    done
}

function deserver {
    
    if [[ $1 =~ "vmess://" ]]; then
	devmess $1
    elif [[ $1 =~ "ss://" ]]; then
	dessr $1
    elif [[ $1 =~ "trojan://" ]]; then
	detrojan $1
    fi
	
}

function devmess {

    b='{"alter_id":0,"domain_strategy":"","security":"auto","server":"","server_port": 0,"tag":"proxy","transport":{"type":""},"type":"vmess","uuid":""}'
    
    j=$(echo $1 | sed 's|vmess://||g' | base64 -d)
    b=$(echo $b $j | jq -s ".[0].alter_id = .[1].aid | .[0].server = .[1].add | .[0].server_port = .[1].port | .[0].uuid = .[1].id | .[0]")

    [ $(echo $j | jq .net -r) ] && b=$(echo $b $j | jq -s ".[0].transport.type = .[1].net | .[0]")
    [ $(echo $j | jq .scy -r) ] && b=$(echo $b $j | jq -s ".[0].security = .[1].scy | .[0]")

    echo '{"name": "","outbounds":[]}' $b $j | jq -s ".[0].name = .[2].ps | .[0].outbounds[0] = .[1] | .[0]"
  
}

function dessr {

    b='{"domain_strategy":"","method":"","password":"","server":"","server_port":0,"tag":"proxy","type":"shadowsocks"}'
    
    # extract the protocol
    proto=$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')
    # remove the protocol
    url=$(echo ${1/$proto/})
    # extract the user (if any)
    user=$(echo $url | grep @ | cut -d@ -f1)
    # extract the host and port
    hostport=$(echo ${url/$user@/} | cut -d/ -f1)
    # by request host without port    
    host=$(echo $hostport | sed -e 's,:.*,,g')
    # by request - try to extract the port
    port=$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')
    # extract the path (if any)
    path=$(echo $url | grep / | cut -d/ -f2-)

    m=$(echo $user | base64 -d | awk -F: '{print $1}')
    p=$(echo $user | base64 -d | awk -F: '{print $2}')

    b=$(echo $b | jq -s ".[0].method = \"$m\" | .[0].server = \"$host\"  | .[0].server_port = $port  | .[0].password = \"$p\"  | .[0]")

    name=$(echo -e ${1//%/\\x} | awk -F# '{print $2}')

    echo '{"name": "","outbounds":[]}' $b | jq -s ".[0].name = \"$name\" | .[0].outbounds[0] = .[1] | .[0]"
    
}

function detrojan {

    b='{"domain_strategy":"","password":"","server":"","server_port":0,"tag":"proxy","tls":{"enabled":true},"type":"trojan"}'

    # extract the protocol
    proto=$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')
    # remove the protocol
    url=$(echo ${1/$proto/})
    # extract the user (if any)
    user=$(echo $url | grep @ | cut -d@ -f1)
    # extract the host and port
    hostport=$(echo ${url/$user@/} | cut -d/ -f1)
    # by request host without port    
    host=$(echo $hostport | sed -e 's,:.*,,g')
    # by request - try to extract the port
    port=$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')
    # extract the path (if any)
    path=$(echo $url | grep / | cut -d/ -f2-)

    j=$(echo $hostport | sed -e 's|^.*?||g' -e 's|#.*$||g')

    b=$(echo $b | jq -s " .[0].server = \"$host\"  | .[0].server_port = $port  | .[0].password = \"$user\"  | .[0]")

    i=1
    while [ $(echo $j | awk -F\& "{print \$${i}}") ]
    do
	line=$(echo $j | awk -F\& "{print \$${i}}")
	if [ $(echo $line | awk -F= '{print $1}') = "security" ] || [ $(echo $line | awk -F= '{print $2}') = "tls" ]; then
	    b=$(echo $b | jq " .tls.enabled = true ")
	elif [ $(echo $line | awk -F= '{print $1}') = "allowInsecure" ]; then
	    allow=$(echo $line | awk -F= '{print $2}')
	    b=$(echo $b $allow | jq -s '.[0].tls.insecure = (.[1] == 1) | .[0]')
	elif [ $(echo $line | awk -F= '{print $1}') = "sni" ]; then
	    sni=$(echo $line | awk -F= '{print $2}')
	    b=$(echo $b | jq " .tls.server_name = \"$sni\" ")
	fi
	i=$((i+1))
    done

    name=$(echo -e ${1//%/\\x} | awk -F# '{print $2}')

    echo '{"name": "","outbounds":[]}' $b | jq -s ".[0].name = \"$name\" | .[0].outbounds[0] = .[1] | .[0]"
    
}

case ${1:-help} in
    help)
	help
	exit 0
	;;
    all)
	update_all
	exit 0
	;;
    *)
	echo 1
	update $1
	exit 0
	;;
esac

