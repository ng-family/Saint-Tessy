#!/bin/bash
#
# Check for need, build dynu update url, build cloudflare url, and update
# syntax update-DDNS.sh {dynu_domain} {dynu_md5password} {cloudflare_domain} {cloudflare_api}

LOGFILE="/var/log/update-ddns.log"
DNSSERVER="a.b.c.d"

DYNUDOMAIN=$1
DYNUPASS=$2
CLOUDFLAREDOMAIN=$3
CLOUDFLAREPASS=$4

#Get IP State
LOCAL_IP=`curl -4 --max-time 2 -s https://ipv4.whatismyip.akamai.com/`
if test -z "$LOCAL_IP"
then
	echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve public ipv4 address!" | tee -a $LOGFILE
	exit
fi
LOCAL_IPV6=`curl -6 --max-time 2 -s https://ipv6.whatismyip.akamai.com/`
if test -z "$LOCAL_IP"
then
	echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve public ipv6 address!" | tee -a $LOGFILE
	exit
fi

#Check if DYNU IP addresses have changed
DNS_IP_REPLY=`host $DYNUDOMAIN $DNSSERVER`
DNS_IP=`echo $DNS_IP_REPLY | grep -o "address [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" | awk '{print $2}'`
DNS_IP6=`echo $DNS_IP_REPLY | grep -o "IPv6 address .*" | awk '{print $3}'`
UPDATEREQ=1


if test -z "$DNS_IP"
then
    echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve DNS A record" | tee -a $LOGFILE
    UPDATEREQ=0
else
    if test -z "$DNS_IP6"
    then
        echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve DNS AAA record" | tee -a $LOGFILE
        UPDATEREQ=0
    fi
fi

if [ "$UPDATEREQ" -eq 1 ]; then
    echo "`date "+%m-%d-%Y %T"`: VERBOSE IP Varibales 
        [Previous IPs: $DNS_IP, $DNS_IP6]
        [Current IPs: $LOCAL_IP, $LOCAL_IP6]"

    if [ "$DNS_IP" == "$LOCAL_IP" ]; then
        echo "IPv4 IPs match"
        if [[ "$LOCAL_IP6" =~ "$DNS_IP6" ]]; then
            echo "IPv6 IPs match"
            echo "`date "+%m-%d-%Y %T"`: IPs match, No update required for dynu!" | tee -a $LOGFILE
            UPDATEREQ=0
        fi
    fi
fi

if [ "$UPDATEREQ" -eq 1 ]; then
    #Update DYNU
	echo "`date "+%m-%d-%Y %T"`: IPs mismatched
    	[Previous IPs: $DNS_IP, $DNS_IP6]
    	[Current IPs: $LOCAL_IP, $LOCAL_IP6]" | tee -a $LOGFILE
	DYNUAPIURL="https://api.dynu.com/nic/update?hostname=$DYNUDOMAIN&myip=$LOCAL_IP&myipv6=$LOCAL_IP6&password=$DYNUPASS"
	DYNU_UPDATE_REPLY=`wget $DYNUAPIURL -O - -q ; echo`
	echo "`date "+%m-%d-%Y %T"`: Dynu Server reply
    $DYNU_UPDATE_REPLY" | tee -a $LOGFILE
fi

# TODO#Check if CLOUDFLARE IP addresses have changed
# DNS_IP_REPLY=`host $CLOUDFLAREDOMAIN $DNSSERVER`
# DNS_IP=`echo $DNS_IP_REPLY | grep -o "address [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" | awk '{print $2}'`
# DNS_IP6=`echo $DNS_IP_REPLY | grep -o "IPv6 address .*" | awk '{print $3}'`
# UPDATEREQ=1


# if test -z "$DNS_IP"
# then
#     echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve DNS A record" | tee -a $LOGFILE
#     UPDATEREQ=0
# else
#     if test -z "$DNS_IP6"
#     then
#         echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve DNS AAA record" | tee -a $LOGFILE
#         UPDATEREQ=0
#     fi
# fi

# if [ "$UPDATEREQ" -eq 1 ]; then
#     echo "`date "+%m-%d-%Y %T"`: VERBOSE IP Varibales 
#         [Previous IPs: $DNS_IP, $DNS_IP6]
#         [Current IPs: $LOCAL_IP, $LOCAL_IP6]"

#     if [ "$DNS_IP" == "$LOCAL_IP" ]; then
#         echo "IPv4 IPs match"
#         if [[ "$LOCAL_IP6" =~ "$DNS_IP6" ]]; then
#             echo "IPv6 IPs match"
#             echo "`date "+%m-%d-%Y %T"`: IPs match, No update required for dynu!" | tee -a $LOGFILE
#             UPDATEREQ=0
#         fi
#     fi
# fi

# if [ "$UPDATEREQ" -eq 1 ]; then
#     #Update DYNU
# 	echo "`date "+%m-%d-%Y %T"`: IPs mismatched
#     	[Previous IPs: $DNS_IP, $DNS_IP6]
#     	[Current IPs: $LOCAL_IP, $LOCAL_IP6]" | tee -a $LOGFILE
# 	DYNUAPIURL="https://api.dynu.com/nic/update?hostname=$DYNUDOMAIN&myip=$LOCAL_IP&myipv6=$LOCAL_IP6&password=$DYNUPASS"
# 	DYNU_UPDATE_REPLY=`wget $DYNUAPIURL -O - -q ; echo`
# 	echo "`date "+%m-%d-%Y %T"`: Dynu Server reply
#     $DYNU_UPDATE_REPLY" | tee -a $LOGFILE
# fi

#trunc log
tail -n 50001 $LOGFILE > $LOGFILE
