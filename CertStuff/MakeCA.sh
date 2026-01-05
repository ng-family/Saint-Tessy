#!/bin/bash

CAname=<DomainName>
#Maybe in the future I should include a conf file to automate the prompts but I only run this once every 5 years.

openssl genrsa -aes256 -out $CAname.key 4096

openssl req -x509 -new -nodes -key $CANAME.key -sha256 -days 1826 -out $CANAME.crt
