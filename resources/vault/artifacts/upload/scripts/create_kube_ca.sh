#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export PATH=/opt/bin:/opt/etc/vault/scripts:$PATH

. $DIR/utils/functions
. $DIR/utils/env_defaults
. /etc/profile.d/vault.sh

export PATH=/opt/bin:/opt/etc/vault/scripts:$PATH

CLUSTER_ID=$1
COMPONENTS="etcd-member kube-apiserver"

if [ -z "$CLUSTER_ID" ];
then
  exit1 "A unique Kubernetes cluster id is required."
fi

# Etcd CA. Etcd and apiserver's cert should be signed by the same CA.
create_pki() {
    pki_name=$1
    $DIR/create_ca.sh $CLUSTER_ID/pki/$pki_name
}
create_pki_role_etcd_member() {
    vault write $CLUSTER_ID/pki/etcd-member/roles/etcd-member \
        allow_domains="cluster.local,$ROUTE53_ZONE_NAME,$CLUSTER_INTERNAL_ZONE" \
        allow_subdomains=true \
        allow_any_name=true \
        ttl=87600h0m0s
    vault read $CLUSTER_ID/pki/etcd-member/roles/etcd-member
}

create_pki_role_kube_apiserver() {
    vault write $CLUSTER_ID/pki/kube-apiserver/roles/kube-apiserver \
        allowed_domains="kubelet,kubernetes.default,cluster.local,$ROUTE53_ZONE_NAME,$CLUSTER_INTERNAL_ZONE" \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_any_name=true \
        allow_ip_sans="true" \
        allow_localhost="true" \
        ttl=87600h0m0s
    vault read $CLUSTER_ID/pki/kube-apiserver/roles/kube-apiserver
}

# Cert role's issue police
create_role_policy() {
    pki_name=$1
    role_name=$2
    cat <<EOT | vault policy-write $CLUSTER_ID/pki/$pki_name/$role_name -
path "$CLUSTER_ID/pki/$pki_name/issue/$role_name" {
policy = "write"
}
EOT
}

# Provided each machine with a Vault token that can be renewed indefinitely.
# This token is only granted the policies that it requires.
create_auth_role() {
  vault write auth/token/roles/kube-$CLUSTER_ID \
  period="4200h" \
  orphan=true \
  allowed_policies="$CLUSTER_ID/pki/etcd-member/etcd-member,$CLUSTER_ID/pki/kube-apiserver/kube-apiserver"
}
create_auth_token() {
  token_path=$1
  token_name=$2
  # check if the token already created and uploaded to the bucket
  echo "s3get.sh ${VAULT_TOKEN_BUCKET} pki-tokens/$token_name $TMPDIR/$token_name"
  s3get.sh ${VAULT_TOKEN_BUCKET} pki-tokens/$token_name $TMPDIR/$token_name
  if [[ -s "$TMPDIR/$token_name" ]] && vault token-lookup $(cat $TMPDIR/$token_name) > /dev/null 2>&1 ; then
    echo "Token $token already exist. Renew token"
    vault token-renew $(cat $TMPDIR/$token_name)
  else
    token=$(vault token-create \
      -policy="$CLUSTER_ID/$token_path" \
      -role="kube-$CLUSTER_ID" | egrep -o -E "token(\s+.*)" | cut -f2 | tee $TMPDIR/$token_name)
    if [ -n "$token" ]; then
        s3put.sh ${VAULT_TOKEN_BUCKET} pki-tokens $TMPDIR/$token_name
    fi
  fi
  #shred -z $TMPDIR/token
}

create_pki etcd-member
create_pki_role_etcd_member
create_role_policy etcd-member etcd-member
create_pki kube-apiserver
create_pki_role_kube_apiserver
create_role_policy kube-apiserver kube-apiserver

# Create role and associated polices
create_auth_role
create_auth_token pki/etcd-member/etcd-member etcd-member
create_auth_token pki/kube-apiserver/kube-apiserver kube-apiserver
