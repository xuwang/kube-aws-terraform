#!/bin/bash
# Get ca/certs/key from vault pki backend

usage() {
  echo "Get ca/certs/key from vault pki backend"
  echo
  echo "Usage: $0 <issuer_name>  <common_name> <vault_token> <install_dir>"
  echo "cert will be in <install_dir>/<issuer_name>-<common_name>.pem"
  echo "key will be in <install_dir>/<issuer_name>-<common_name>-key.pem"
  echo "ca cert will be in <install_dir>/<issuer_name>-ca.pem"
}

pkg=$(basename $0)
if [ "$#" -ne 4 ]; then
  usage
  exit
fi

# Request Kubernetes certificates.
source /etc/profile.d/vault.sh
source /etc/environment
source /opt/etc/master/envvars

export PATH=/opt/bin/:$PATH
issuer_name=$1
common_name=$2
token=$3
install_path=$4
work_idr=certs
mkdir -p certs
cd certs

# Wait for vault service
retry=5
until vault status || [[ $retry -eq 0 ]];
do
  sleep 10
  let "retry--"
done
if [ $retry -eq 0 ]; then
  echo "$pkg: Vault service is not ready."
  exit 1
fi

# Vault PKI Token. We store them in both /etc/etcd/certs and /var/lib/kubernetes directories
export VAULT_TOKEN=$token
ca_bundle=${issuer_name}-${common_name}-bundle.pem
vault write -format=json \
  ${CLUSTER_NAME}/pki/$issuer_name/issue/$issuer_name common_name=$common_name \
  alt_names="kube-$COREOS_PRIVATE_IPV4.cluster.local,kubernetes.default,*.cluster.local,*.${CLUSTER_INTERNAL_ZONE},${KUBE_API_DNSNAME}" \
  ttl=43800h0m0s \
  ip_sans="127.0.0.1,$COREOS_PRIVATE_IPV4,${KUBE_API_SERVICE}" > $ca_bundle

  if [ ! -s $ca_bundle ]; then
    echo "$pkg: $ca_bundle doesn't exist or has zero size."
    exit 1
  fi

  mkdir -p $install_path
  cat $ca_bundle | jq -r ".data.certificate" > $install_path/$common_name.pem
  cat $ca_bundle | jq -r ".data.private_key" > $install_path/$common_name-key.pem
  cat $ca_bundle | jq -r ".data.issuing_ca" > $install_path/$issuer_name-ca.pem
