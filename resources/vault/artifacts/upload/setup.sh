#!/bin/bash -e

# vault script
cp -r /root/upload/scripts /opt/etc/vault
chmod 755 /opt/etc/vault/scripts/*.sh

source /etc/aws/account.envvars
source /root/.aws/config
GET=/opt/bin/s3-get
pki_bucket=${AWS_ACCOUNT}-${CLUSTER_NAME}-config

# downlaod vault configuration files
$GET $pki_bucket vault/vault.sh /etc/profile.d/vault.sh
$GET $pki_bucket vault/vault.cnf /opt/etc/vault/vault.cnf
$GET $pki_bucket vault/vault.hcl /opt/etc/vault/vault.hcl
$GET $pki_bucket vault/vault.hcl /opt/etc/vault/envvars

# download vault root ca/key
$GET  $pki_bucket pki/ca-key.pem /opt/etc/vault/ca/ca-key.pem
$GET  $pki_bucket pki/ca.pem /opt/etc/vault/ca/ca.pem

# generate vault certs
mkdir -p /opt/etc/vault/certs
cd /opt/etc/vault/certs
/opt/etc/vault/scripts/gen-vault-cert.sh

# install vault binary
source /opt/etc/vault/envvars
docker run --rm -v /opt/bin:/tmp ${VAULT_IMAGE} 
cp /bin/vault /tmp/vault
