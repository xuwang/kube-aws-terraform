#!/bin/bash -e

# Get vault CA and PKI tokens
$GET ${CONFIG_BUCKET} pki/ca.pem /opt/etc/vault/ca/ca.pem
$GET ${CONFIG_BUCKET} pki-tokens/ca.pem /opt/etc/pki-tokens/etcd-member
$GET ${CONFIG_BUCKET} pki-tokens/kube-apiserver /opt/etc/pki-tokens/kube-apiserver

$GET ${CONFIG_BUCKET} controller/envvars /opt/etc/controller/envvars
source /opt/etc/controller/envvars

# Install vault binary
docker run --rm -v /opt/bin:/tmp ${VAULT_IMAGE} cp /bin/vault /tmp/vault

# Install kubernetes
docker run --env VERSION="${KUBE_VERSION}" --rm -v /opt/bin:/shared xueshanf/install-kubernetes

# Generate certs for etcd and kube-apiserver 
mkdir -p /var/lib/kubernetes/
bash get-kube-certs.sh kube-apiserver etcd-member

# Copy kube policy.jsonl and token.csv to /var/lib/kubernetes/
# Note: token.csv will be copied to upload by "make upload-config"
cp policy.jsonl token.csv /var/lib/kubernetes/

# TODO: after install cp ${VAULT_RELEASE} and ${KUBE_VERSION} to local disk.
# On rebooting compare ${VAULT_RELEASE} and ${KUBE_VERSION} with local copy
# if matches do NOT install again