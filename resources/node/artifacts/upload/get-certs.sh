#!/bin/bash
# Get ca/certs/key from vault pki backend

usage() {
  echo "Get ca/certs/key from vault pki backend"
  echo
  echo "Usage: $0 <issuer_name> <vault_token> <install_dir>"
  echo "cert will be in <install_dir>/<issuer_name>.pem"
  echo "key will be in <install_pathdir>/<issuer_name>-key.pem"
  echo "ca cert will be in <install_dir>/<issuer_name>-ca.pem"
}

if [ "$#" -ne 3 ]; then
  usage
  exit
fi

# Request Kubernetes certificates.
source /etc/profile.d/vault.sh
source /etc/environment
source /opt/etc/master/envvars

export PATH=/opt/bin/:$PATH
issuer_name=$1
token=$2
install_path=$3
work_idr=certs
mkdir -p certs
cd certs

# Wait for vault service
retry=5
until vault status || [[ $retry -eq 0 ]];
do
  sleep 3
  let "retry--"
done
if [ $retry -eq 0 ]; then
  echo "Vault service is not ready."
  exit 1
fi

# Vault PKI Token. We store them in both /etc/etcd/certs and /var/lib/kubernetes directories
export VAULT_TOKEN=$token
vault write -format=json \
  ${CLUSTER_NAME}/pki/$issuer_name/issue/$issuer_name common_name=kubelet \
  alt_names="kubernetes.default,*.cluster.local" \
  ttl=43800h0m0s \
  ip_sans="127.0.0.1,$COREOS_PRIVATE_IPV4" >  $issuer_name-bundle.certs

if [ ! -s $issuer_name-bundle.certs ]; then
  echo "$issuer_name-bundle.certs doesn't exist or has zero size."
  exit 1
fi

mkdir -p $install_path
cat $issuer_name-bundle.certs | jq -r ".data.certificate" > $install_path/$issuer_name.pem
cat $issuer_name-bundle.certs | jq -r ".data.private_key" > $install_path/$issuer_name-key.pem
cat $issuer_name-bundle.certs | jq -r ".data.issuing_ca" > $install_path/$issuer_name-ca.pem
