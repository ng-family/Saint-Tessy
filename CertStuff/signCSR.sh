#!/bin/bash

HOSTSVR=<hostname>
HOSTCSR=<pathToCSR>
CACRT=<pathToCAcert>
CAKEY=<pathToCAkey>

openssl x509 -req -days 365 -in $HOSTCSR -CA $CACRT -CAkey $CAKEY -CAcreateserial -out $HOSTSVR.crt
