#!/bin/bash
set -e
# References: 
# http://cuddletech.com/?p=959
# https://www.digitalocean.com/company/blog/vault-and-kubernetes/

# Create a CA

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/utils/functions
. $DIR/utils/env_defaults
. /etc/profile.d/vault.sh

# Need at least one argument
[[ $# -lt 1 ]] && exit1 "${0##*/} [-i ] my_root_ca"

# Default to create root ca
interm_ca="false"

# Default CA valid until
rootCAttl="87600h"
intermCAttl="26280h"
keyBits=4096

while getopts ":i:h" OPTION
do
  case $OPTION in
    i)
	interm_ca="true"
        shift
 	;;
    *)
        usage "${0##*/} [-i ] my_root_ca"
        ;;
   esac
done

create_root_ca() {
    # Generate root ca
    vault write $pki_path/root/generate/internal \
        common_name="$pki_path" ttl=$ttl key_bits=$keyBits exclude_cn_from_sans=true

    # Create CA url and CRL
    vault write $pki_path/config/urls \
      issuing_certificates="https://vault.$CLUSTER_INTERNAL_ZONE/v1/$pki_path/ca,https://$VAULT_ROOTCA_CN" \
      crl_distribution_points="https://vault.$CLUSTER_INTERNAL_ZONE/v1/$pki_path/crl,https://$VAULT_ROOTCA_CN"

    echo "The $pki_path CA is ready."
}

create_interm_ca() {
    vault write -format=json $pki_path/intermediate/generate/internal \
       common_name="$description" ttl=$ttl key_bits=$keyBits exclude_cn_from_sans=true \
       | jq -r '.data.csr' > /tmp/$pki_path.csr

    # Sign the cert with root ca
    vault write -format=json $root_ca_path/root/sign-intermediate csr=@/tmp/$pki_path.csr \
       common_name="$description" \
       ttl=$itermCAttl | jq -r '.data.certificate' > /tmp/$pki_path.crt

    # Import back to the intermediate CA backend
    vault write -format=json $pki_path/intermediate/set-signed certificate=@/tmp/$pki_path.crt

    # Create Intermediate CA url and CRL
    vault write -format=json $pki_path/config/urls \
	     issuing_certificates="https://vault.$CLUSTER_INTERNAL_ZONE/v1/$pki_path/ca" \
	     crl_distribution_points="https://vault.$CLUSTER_INTERNAL_ZONE/v1/$pki_path/crl"

    echo "The Intermidate CA is ready!"
}

## MAIN

# Private IP, used for vault service endpoint on localhost
private_ip=$(hostname -i|awk '{print $1}')

# PKI mount path
pki_path=$1
if [ -z "$pki_path" ]; then
  exit1 "pki path is required."
else
  description=$pki_path
fi
if [ "$interm_ca" = "true" ]; then
  description="$description Intermdediate CA"
  ttl=$intermCAttl
else
  description="$description Root CA"
  ttl=$rootCAttl
fi

root_token=$(get_root_token)
vault auth $root_token

# Mount pki path
if vault mounts | grep ^$pki_path | grep pki; then
    echo "$pki_path PKI backend already mounted. Skipping re-mount"
else
    vault mount -path=$pki_path -description="$description" -max-lease-ttl=$ttl pki
    vault mount-tune -max-lease-ttl=87600h $pki_path
fi

# Check if it already exist.
if curl -s http://localhost:8200/v1/$pki_path/ca/pem \
    | openssl x509 -text > /dev/null 2>&1; then
    echo "$pki_path CA exists. Skipping."
elif [ $interm_ca = "true" ]; then
    create_interm_ca
else
    create_root_ca
fi

