#!/bin/bash -e

# vault script
cp -r ./scripts /opt/etc/vault
chmod 755 /opt/etc/vault/scripts/*.sh

GET=/opt/bin/s3get.sh

# install vault binary
$GET ${CONFIG_BUCKET} vault/envvars /opt/etc/vault/envvars
source /opt/etc/vault/envvars /etc/environment
docker run --rm -v /opt/bin:/tmp ${VAULT_IMAGE} cp /bin/vault /tmp/vault

# downlaod vault configuration files
$GET ${CONFIG_BUCKET} vault/vault.sh  /etc/profile.d/vault.sh
$GET ${CONFIG_BUCKET} vault/vault.hcl /opt/etc/vault/vault.hcl
$GET ${CONFIG_BUCKET} vault/vault.cnf /opt/etc/vault/certs/vault.cnf.tmpl

# download vault root ca/key
$GET  ${CONFIG_BUCKET} pki/ca-key.pem /opt/etc/vault/ca/ca-key.pem
$GET  ${CONFIG_BUCKET} pki/ca.pem /opt/etc/vault/ca/ca.pem

# generate vault certs
cd /opt/etc/vault/certs
cat vault.cnf.tmp | envsubst > vault.cnf
/opt/etc/vault/scripts/gen-vault-cert.sh
