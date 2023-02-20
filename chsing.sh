#! /usr/bin/bash

jq -s ".[0].outbounds[0] = .[1].outbounds[0] | .[0]" /etc/sing-box/config_base.json - > /etc/sing-box/config.json

jq ".outbounds[0]" /etc/sing-box/config.json
