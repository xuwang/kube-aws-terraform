#!/bin/bash -e

GET=/opt/bin/s3get.sh
# Get vault CA and PKI tokens
$GET ${CONFIG_BUCKET} pki/ca.pem /opt/etc/vault/ca/ca.pem
$GET ${CONFIG_BUCKET} pki-tokens/kube-apiserver /opt/etc/pki-tokens/kube-apiserver
$GET ${CONFIG_BUCKET} pki-tokens/etcd-server /opt/etc/pki-tokens/etcd-server
$GET ${CONFIG_BUCKET} etc/sysconfig/initial-cluster /etc/sysconfig/initial-cluster

$GET ${CONFIG_BUCKET} master/envvars /opt/etc/master/envvars
source /opt/etc/master/envvars

# Generate vault.sh needed by bootstraping certs
cat > /etc/profile.d/vault.sh <<EOF
# For vault client to connect server through TLS
export VAULT_CACERT=/opt/etc/vault/ca/ca.pem
export VAULT_ADDR=https://vault.${CLUSTER_INTERNAL_ZONE}
export PATH=$PATH:/opt/bin
export VAULT_TOKEN=$(cat /opt/etc/pki-tokens/kube-apiserver)
EOF

# Install vault binary
if [ ! -f /opt/etc/master/${VAULT_IMAGE} ]
then
  docker run --rm -v /opt/bin:/tmp ${VAULT_IMAGE} cp /bin/vault /tmp/vault
  touch  /opt/etc/master/${VAULT_IMAGE}
fi
# Install kubernetes
if [ ! -f /opt/etc/master/kube-${KUBE_VERSION} ]
then
  docker run --env VERSION="${KUBE_VERSION}" --rm -v /opt/bin:/shared xueshanf/install-kubernetes
  touch /opt/etc/master/kube-${KUBE_VERSION}
fi

# Generate certs from vualt pki for etcd and kube-apiserver
#  get-certs <issuer_name> <common_name> <auth_token> <install path>
bash get-certs.sh etcd-server etcd-server $(cat /opt/etc/pki-tokens/etcd-server) /etc/etcd/certs
bash get-certs.sh kube-apiserver admin $(cat /opt/etc/pki-tokens/kube-apiserver) /var/lib/kubernetes
bash get-certs.sh kube-apiserver kube-apiserver $(cat /opt/etc/pki-tokens/kube-apiserver) /var/lib/kubernetes
