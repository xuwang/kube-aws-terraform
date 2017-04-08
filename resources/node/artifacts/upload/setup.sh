#!/bin/bash -e

GET=/opt/bin/s3get.sh
# Get vault CA and PKI tokens
$GET ${CONFIG_BUCKET} pki/ca.pem /opt/etc/vault/ca/ca.pem
$GET ${CONFIG_BUCKET} pki-tokens/kube-apiserver /opt/etc/pki-tokens/kube-apiserver

$GET ${CONFIG_BUCKET} ${MODULE_NAME}/envvars /opt/etc/${MODULE_NAME}/envvars
source /opt/etc/${MODULE_NAME}/envvars

# Install vault binary
if [ ! -f /opt/etc/${MODULE_NAME}/${VAULT_IMAGE} ]
then
  docker run --rm -v /opt/bin:/tmp ${VAULT_IMAGE} cp /bin/vault /tmp/vault
  touch  /opt/etc/${MODULE_NAME}/${VAULT_IMAGE}
fi
s
# Install CNI plugin and kubernetes
if [ ! -f /opt/etc/${MODULE_NAME}/${CNI_PLUGIN_URL} ];
then
  mkdir -p /opt/cni
  wget ${CNI_PLUGIN_URL}
  tar -xvf $(basename ${CNI_PLUGIN_URL}) -C /opt/cni
fi
if [ ! -f /opt/etc/${MODULE_NAME}/kube-${KUBE_VERSION} ]
then
  docker run --env VERSION="${KUBE_VERSION}" --net=host --env COMPONENTS='kube-proxy kubelet kubectl' --rm -v /opt/bin:/shared xueshanf/install-kubernetes
  touch /opt/etc/${MODULE_NAME}/kube-${KUBE_VERSION}
fi

$GET ${CONFIG_BUCKET} ${MODULE_NAME}/kubelet-kubeconfig /var/lib/kubelet/kubeconfig
#echo "export KUBECONFIG=/var/lib/kubelet/kubeconfig" > /etc/profile.d/kubeconfig.sh
$GET ${CONFIG_BUCKET} ${MODULE_NAME}/kube-proxy-kubeconfig /var/lib/kube-proxy/kubeconfig

# Generate certs from vualt pki: <issuer endpoint> <auth token> <install path>
bash get-certs.sh kube-apiserver $(cat /opt/etc/pki-tokens/kube-apiserver) /var/lib/kubernetes
