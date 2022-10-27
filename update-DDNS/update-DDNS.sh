#!/bin/bash
# Check for need, build dynu update url, and update
# syntax update-DDNS.sh {domain} {md5password}

NETINTERFACE="eth0"        #manually select interface
DOMAIN=$1
PASSWORD=$2

##try a couple ip retrieve sites
LOCAL_IP=`curl -s ipecho.net | grep -o "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"`
if test -z "$LOCAL_IP"
then
    LOCAL_IP=`curl -s myexternalip.com/raw | grep -o "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"`
    if test -z "$LOCAL_IP"
    then
        echo "Couldn't retrieve public ipv4 address!"
        exit
    fi
fi
LOCAL_IP6=$(ip addr show $NETINTERFACE | awk '/inet6/ && ! /fe80|host/ { print $2 }' | awk -F"/" '{print $1}')

##check if IP has changed
DNS_IP_REPLY=`host $DOMAIN 1.1.1.1`
DNS_IP=`echo $DNS_IP_REPLY | grep -o "address [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" | awk '{print $2}'`
DNS_IP6=`echo $DNS_IP_REPLY | grep -o "IPv6 address .*" | awk '{print $3}'`

if test -z "$DNS_IP"
then
    echo "Couldn't retrieve DNS A record"
    exit
else
    if test -z "$DNS_IP6"
    then
        echo "Couldn't retrieve DNS AAA record"
        exit
    fi
fi
if [ "$DNS_IP" == "$LOCAL_IP" ]; then
    echo "IPv4 IPs match"
    if [ "$DNS_IP6" == "$LOCAL_IP6" ]; then
        echo "IPv6 IPs match"
        echo "No update required!"
        exit
    fi
fi

##Check failed, send update to dynu
DYNUAPIURL="https://api.dynu.com/nic/update?hostname=$DOMAIN&myip=$LOCAL_IP&myipv6=$LOCAL_IP6&password=$PASSWORD"

DYNU_UPDATE_REPLY=`wget $DYNUAPIURL -O - -q ; echo`
echo "$DYNU_UPDATE_REPLY"