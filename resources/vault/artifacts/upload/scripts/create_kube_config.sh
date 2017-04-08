#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export PATH=/opt/bin:/opt/etc/vault/scripts:$PATH

. $DIR/utils/functions
. $DIR/utils/env_defaults
. /etc/profile.d/vault.sh

export PATH=/opt/bin:/opt/etc/vault/scripts:$PATH

CLUSTER_ID=$1

if [ -z "$CLUSTER_ID" ];
then
  exit1 "A unique Kubernetes cluster id is required."
fi

write_kubelet_bootstrap_token() {
  BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
  TOKEN_CSV="$BOOTSTRAP_TOKEN,kubelet-bootstrap,10001,\"system:kubelet-bootstrap\""
  if ! vault read -field=value secret/$CLUSTER_ID/config/kubelet-bootstrap-token
  then
    vault write secret/$CLUSTER_ID/config/kubelet-bootstrap-token value=$TOKEN_CSV
  fi
}

write_service_account_key() {
  if ! vault read -field=key secret/$CLUSTER_ID/config/service-account-key
  then
    openssl genrsa 4096 > token-key
    vault write secret/$CLUSTER_ID/config/service-account-key key=@token-key
    rm token-key
  fi
}

write_kubelet_bootstrap_token
write_service_account_key
