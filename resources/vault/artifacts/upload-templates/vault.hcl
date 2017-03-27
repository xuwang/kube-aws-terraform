backend "s3" {
  bucket = "${AWS_ACCOUNT}-${CLUSTER_NAME}-vault-s3-backend"
  region = "${AWS_DEFAULT_REGION}"
}
/* If use etcd backend
backend "etcd" {
  address = "http://127.0.0.1:2379"
   advertise_addr = "https://$public_ipv4:8200"
   path = "vault"
   sync = "yes"
  ha_enabled = "true"
}
*/
# Vault runs in container. See vault.service unit
listener "tcp" {
  address = "0.0.0.0:8201"
  tls_disable = 1
}
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_cert_file = "/vault/config/certs/vault.crt"
  tls_key_file = "/vault/config/certs/vault.key"
}
# if mlock is not supported
# disable_mlock = true
/* Need to install statesite for this to work
telemetry {
  statsite_address = "0.0.0.0:8125"
  disable_hostname = true
}
*/
