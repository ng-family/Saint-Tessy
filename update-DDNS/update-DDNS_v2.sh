#!/bin/bash
#
# Check for need, build dynu update url, build cloudflare url, and update
# syntax update-DDNS.sh \
# {dynu_domain} {dynu_md5password} \
# {cloudflare_domain} {cloudflare_api} {cloudflare_zoneid}

LOGFILE="/var/log/update-ddns.log"
DNSSERVER="a.b.c.d"

DYNUDOMAIN=$1
DYNUPASS=$2
CLOUDFLAREDOMAIN=$3
CLOUDFLAREPASS=$4
CLOUDFLAREZONEID=$5

#Get IP State
LOCAL_IP=`curl -4 --max-time 2 -s https://ipv4.whatismyip.akamai.com/`
if test -z "$LOCAL_IP"
then
	echo "`date "+%m-%d-%Y %T"`: Couldn't retrieve public ipv4 address!" | tee -a $LOGFILE
	exit
fi
LOCAL_IP6=`curl -6 --max-time 2 -s https://ipv6.whatismyip.akamai.com/`
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

#Check if CLOUDFLARE IP addresses have changed
#Test API key
# refer to https://developers.cloudflare.com/api/
#APITEST=`curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CLOUDFLAREAPI"`

CLOUDFLARERECORDS=`curl -s "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONEID/dns_records" -H "Authorization: Bearer $CLOUDFLAREAPI"`
if echo "$CLOUDFLARERECORDS" | jq -r '.success' | grep -q 'true'; then
	#echo $CLOUDFLARERECORDS | tee -a $LOGFILE
	RECORDS=`echo $CLOUDFLARERECORDS | jq -r '.result'`
	#echo $RECORDS | tee -a $LOGFILE
	IFS=$'\n'
	echo $RECORDS | jq -c -r '.[]' | while read item; do
		#echo "$item" | tee -a $LOGFILE
		if echo $item | jq -r '.name' | grep -q $CLOUDFLAREDOMAIN; then
			#Record domain name matches
			if echo $item | jq -r '.type' | grep -q 'AAAA'; then
				if echo $item | jq -r '.content' | grep -q $LOCAL_IP6; then
					echo "`date "+%m-%d-%Y %T"`: IPv6 address match, No update required for cloudflare" | tee -a $LOGFILE
				else
					echo "`date "+%m-%d-%Y %T"`: Update required for cloudflare IPv6 address" | tee -a $LOGFILE
				fi
			else
				if echo $item | jq -r '.content' | grep -q $LOCAL_IP; then
					echo "`date "+%m-%d-%Y %T"`: IPv4 address match, No update required for cloudflare" | tee -a $LOGFILE
				else
					echo "`date "+%m-%d-%Y %T"`: Update required for cloudflare IP address" | tee -a $LOGFILE
				fi
			fi
		fi
	done
	unset IFS
else
	echo "`date "+%m-%d-%Y %T"`: Could not retrieve Cloudflare Records"
fi
RECORDARRAY=`echo "$CLOUDFLARERECORDS" | jq -c -r '.result.[]'`
echo "$RECORDARRAY" | tee -a $LOGFILE
for item in ${RECORDARRAY[@]}; do
    echo "!" | tee -a $LOGFILE
    echo "$item" | tee -a $LOGFILE
done

#trunc log
#tail -n 50001 $LOGFILE > $LOGFILE
TEMP=$(tail -n 555 $LOGFILE)
echo "$TEMP" > $LOGFILE
