#!/bin/bash
# Request Kubernetes certificates.
export VAULT_ADDR=https://vault.${CLUSTER_INTERNAL_ZONE}
export VAULT_CACERT=/opt/etc/vault/ca/ca.pem # cert to communicate with vault server.
export PATH=/opt/bin/:$PATH
cert_paths="/var/lib/kubernetes /etc/etcd/certs"
/opt/bin/s3sync.sh > /dev/null 2>&1

# Wait for vault service
retry=5
until vault status || [[ $retry -eq 0 ]];
do
  sleep 3
  let "retry--"
done
if [ $retry -eq 0 ];
  then
  echo "Vault service is not ready."
  exit 1
fi

# Vault PKI Token. We store them in both /etc/etcd/certs and /var/lib/kubernetes directories
for i in $*
do
    token_name=$i
    export VAULT_TOKEN=$(cat /opt/etc/pki-tokens/$token_name)
    vault write -format=json \
      ${CLUSTER_NAME}/pki/$token_name/issue/$token_name common_name=$(hostname --fqdn) \
      alt_names="kube-$private_ipv4.cluster.local,kubernetes.default,*.cluster.local,*.${CLUSTER_INTERNAL_ZONE},${KUBE_API_SERVICE},${KUBE_API_DNSNAME}" \
      ttl=43800h0m0s \
      ip_sans="127.0.0.1,$private_ipv4" >  /tmp/ca-bundle.certs
    if [ ! -s /tmp/ca-bundle.certs ]; then
      echo "/tmp/ca-bundle.certs doesn't exist or has zero size."
      exit 1
    fi
    for p in $cert_paths
    do
      mkdir -p $p
      cat /tmp/ca-bundle.certs | jq -r ".data.certificate" > $p/$token_name.pem
      cat /tmp/ca-bundle.certs | jq -r ".data.private_key" > $p/$token_name-key.pem
      cat /tmp/ca-bundle.certs | jq -r ".data.issuing_ca" > $p/$token_name-ca.pem
    done
done