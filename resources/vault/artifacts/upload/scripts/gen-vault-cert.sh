#!/bin/sh
# Need to fix "unable to write r'andom state'" error
export HOME=/root
echo "creating the vault.key and vault.csr...."
openssl req -new -out vault.csr -config vault.cnf
echo "signing vault.csr..."
openssl x509 -req -days 9999 -in vault.csr -CA ../ca/ca.pem -CAkey ../ca/ca-key.pem \
        -CAcreateserial -extensions v3_req -out vault.crt -extfile vault.cnf
