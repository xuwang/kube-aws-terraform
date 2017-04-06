#!/bin/bash -e

# vault script
mkdir -p /opt/etc/vault
cp -r ./scripts /opt/etc/vault
chmod 755 /opt/etc/vault/scripts/*.sh

# Get instance private and public IPs
export COREOS_PRIVATE_IPV4=$(curl -s 169.254.169.254/latest/meta-data/local-ipv4)
export COREOS_PUBLIC_IPV4=$(curl -s 169.254.169.254/latest/meta-data/public-ipv4)

GET=/opt/bin/s3get.sh

# install vault binary
$GET ${CONFIG_BUCKET} vault/envvars /opt/etc/vault/envvars
source /opt/etc/vault/envvars
docker run --rm -v /opt/bin:/tmp ${VAULT_IMAGE} cp /bin/vault /tmp/vault

# downlaod vault configuration files
$GET ${CONFIG_BUCKET} vault/vault.sh  /etc/profile.d/vault.sh
$GET ${CONFIG_BUCKET} vault/vault.hcl /opt/etc/vault/vault.hcl.tmpl;
cat /opt/etc/vault/vault.hcl.tmpl | envsubst > /opt/etc/vault/vault.hcl

# download vault root ca/key
$GET ${CONFIG_BUCKET} pki/ca-key.pem /opt/etc/vault/ca/ca-key.pem
$GET ${CONFIG_BUCKET} pki/ca.pem /opt/etc/vault/ca/ca.pem

# generate vault certs
mkdir -p /opt/etc/vault/certs
cd /opt/etc/vault/certs
$GET ${CONFIG_BUCKET} vault/vault.cnf vault.cnf.tmpl
cat vault.cnf.tmpl | envsubst > vault.cnf
/opt/etc/vault/scripts/gen-vault-cert.sh
