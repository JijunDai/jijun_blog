#!/usr/bin/env bash
set -xe

# use can boot hugo server sh command as below
# sh bootlocal_win.sh [optional:-D or -F]

# -D(draft / default) or -F(Feature)
development=${1:-"-D"}

# extract local ip addr / mac only
#local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2)
local_ip=$(ip a | grep "inet " | grep -v 127.0.0.1 | grep -v docker|grep -v br-|cut -d/ -f1|awk '{print $NF}')
echo ""
echo "Use this Addr"
echo "http://${local_ip}:1313/"
echo ""

# boot hugo
hugo server "${development}" --bind "${local_ip}" --baseURL http://${local_ip} --gc