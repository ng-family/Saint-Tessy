#!/bin/bash
# Check for need, build dynu update url, and update
# syntax update-DDNS.sh {domain} {md5password}

DOMAIN=$1
LOGFILE="/home/paul/update-ddns.log"
NETINTERFACE="eth0"        #manually select interface
PASSWORD=$2

##try a couple ip retrieve sites
LOCAL_IP=`curl -s --ipv4 ipecho.net | grep -o "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"`
if test -z "$LOCAL_IP"
then
    LOCAL_IP=`curl -s --ipv4 myexternalip.com/raw | grep -o "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"`
    if test -z "$LOCAL_IP"
    then
        echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve public ipv4 address!" >> $LOGFILE
        exit
    fi
fi
LOCAL_IP6=$(ip addr show $NETINTERFACE | awk '/inet6/ && ! /fe80|host/ && ! /deprecated/ { print $2 }' | awk -F"/" '{print $1}')

##check if IP has changed
DNS_IP_REPLY=`host $DOMAIN 1.1.1.1`
DNS_IP=`echo $DNS_IP_REPLY | grep -o "address [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" | awk '{print $2}'`
DNS_IP6=`echo $DNS_IP_REPLY | grep -o "IPv6 address .*" | awk '{print $3}'`

if test -z "$DNS_IP"
then
    echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve DNS A record" >> $LOGFILE
    exit
else
    if test -z "$DNS_IP6"
    then
        echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve DNS AAA record" >> $LOGFILE
        exit
    fi
fi
if [ "$DNS_IP" == "$LOCAL_IP" ]; then
    echo "IPv4 IPs match"
    if [[ "$LOCAL_IP6" =~ "$DNS_IP6" ]]; then
        echo "IPv6 IPs match"
        echo "`date "+%m-%d-%Y %T"`: IPs match, No update required!" >> $LOGFILE
        exit
    fi
fi

##Check failed, send update to dynu
DYNUAPIURL="https://api.dynu.com/nic/update?hostname=$DOMAIN&myip=$LOCAL_IP&myipv6=$LOCAL_IP6&password=$PASSWORD"

DYNU_UPDATE_REPLY=`wget $DYNUAPIURL -O - -q ; echo`
echo "`date "+%m-%d-%Y %T"`: IPs mismatched
                    [Previous IPs: $DNS_IP, $DNS_IP6]
                    [Current IPs: $LOCAL_IP, $LOCAL_IP6]" >> $LOGFILE
echo "`date "+%m-%d-%Y %T"`: Dynu Server reply
                    $DYNU_UPDATE_REPLY" >> $LOGFILE

#trunc log
##sed -i '50001,$ d' $LOGFILE
tail -n 50001 $LOGFILE > $LOGFILE
