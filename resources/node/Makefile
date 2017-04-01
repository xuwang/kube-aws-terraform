include ../common/common.mk

# Kubelete token used by kubelet
TF_VAR_kubelet_token := $(shell grep kubelet  ../../artifacts/secrets/api-server/token.csv | cut -f1 -d',')
export

init: create-key copy-token upload-config

copy-token:
	@cp ../${SEC_PATH}/api-server/token.csv ./artifacts/upload/token.csv

init: create-key
destroy: destroy-key
.PHONY: destroy-key create-key copy-token upload-config
