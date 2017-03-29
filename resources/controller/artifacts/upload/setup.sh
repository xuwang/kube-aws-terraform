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

# generate certs for etcd and kube-apiserver 
bash get-kube-certs.sh kube-apiserver etcd-member
