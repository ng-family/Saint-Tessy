#!/bin/bash

HOSTSVR=<hostname>
HOSTIP=<mgmtIP>
CACRT=<pathToCRT>
CAKEY=<pathToKEY>

cat > $HOSTSVR.conf << EOF
[ req ]
default_md = sha256
distinguished_name = req_distinguished_name
req_extensions = v3_ext
x509_extensions = v3_ext
prompt = no

[ req_distinguished_name ]
C = US
ST = NM
L = ABQ
O = NG Family
OU = ngfamilyservice
CN = $HOSTSVR.ngfamily.lan

[ v3_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = $HOSTSVR
DNS.2 = $HOSTSVR.ngfamily.lan
IP.1 = $HOSTIP
EOF

#Generate Key and CSR
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout $HOSTSVR.key -out $HOSTSVR.csr -config $HOSTSVR.conf

#Sign CSR
openssl x509 -req -in $HOSTSVR.csr -CA $CACRT -CAkey $CAKEY -CAcreateserial -out $HOSTSVR.crt -days 365 -sha256 -extfile $HOSTSVR.conf -extensions v3_ext

#Combine to create pem file
cat $HOSTSVR.key $HOSTSVR.crt | tee $HOSTSVR.pem
