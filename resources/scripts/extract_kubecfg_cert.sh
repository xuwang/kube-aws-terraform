#!/bin/bash
# Input:  ./extract_kubecfg_cert.sh my-cluster-name username
# Output: ./my-cluster-name-ca.crt ./username.crt ./username.key
# From: https://gist.github.com/xueshanf/71f188c58553c82bda16f80483e71918

# Exit on error
abort(){
  echo $1 && exit 1
}

match_cert_key(){
  echo ""
  echo "Checking if private and public key match."
  user_cert_modulus_md5=$(openssl x509 -noout -modulus -in ${user_cert} | openssl md5)
  user_key_modulus_md5=$(openssl rsa -noout -modulus -in ${user_key} | openssl md5)
  echo " Public key modulus md5: ${user_cert_modulus_md5}"
  echo "Private key modulus md5: ${user_key_modulus_md5}"
  if [ "${user_cert_modulus_md5}" = "${user_key_modulus_md5}" ];
  then
    echo "Private key and public key match."
  else
    echo "Private key and public key doesn't match".
  fi
}

# Prerequistes
for i in yq jq kubectl
do
 if ! which -s $i; then
  abort "$i is not instaled." 
 fi
done

cluster_name=$1
user=$2
if ! kubectl config get-clusters | grep -q "^$cluster_name$"; 
then
  abort "Usage: $0 <cluster-name> <username>"
fi
if [ -z "$user" ];
then
  abort "Usage: $0 <cluster-name> <username>"
fi

kube_path=$HOME/.kube
kube_config=$kube_path/config
workspace=$(mktemp -d /tmp/workspace.XXXX)
ca_cert=${workspace}/${cluster_name}-ca.crt
user_cert=${workspace}/${cluster_name}-user.crt
user_key=${workspace}/${cluster_name}-user.key

if [ ! -f $kube_config ];
then
  abort "No $kube_config file."
fi

TMPJSON=$workspace/kubecfg.json
# Convert yaml to json
cat $kube_config | yq "." > $TMPJSON

# Get CA cert
cat $TMPJSON | jq --arg x $cluster_name -r \
	'.clusters[] | select(.name==$x) | .cluster | ."certificate-authority-data" ' | \
	 base64 -D > ${ca_cert}
if [ ! -s ${ca_cert} ];
then
  abort "Cannot find ${ca_cert}."
fi
# Get user client cert
cat $TMPJSON | jq --arg x $user -r \
	'.users[] | select(.name==$x) | .user | ."client-certificate-data" ' | base64 -D > ${user_cert}
if [ ! -s ${user_cert} ]; 
then
  abort "Cannot find ${user_cert}."
fi
# Get user client key
cat $TMPJSON | jq --arg x $user -r \
	'.users[] | select(.name==$x) | .user | ."client-key-data" ' | base64 -D > ${user_key}
if [ ! -s ${user_key} ]; 
then
  abort "Cannot find ${user_key}."
fi

match_cert_key

echo "${cluster_name}-ca.crt, $user.crt, and $user key are generated in the ${workspace} directory." 
echo "Please destroy them after use."

# Clean up
rm -rf $TMPJSON

