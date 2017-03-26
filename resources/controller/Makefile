include ../common/common.mk

init: create-key copy-token upload-artifacts
copy-token:
	@cp ../${SEC_PATH}/api-server/token.csv ./artifacts/upload/token.csv
get-apiserver-elb:
	@elb_name=`make output | jq -r  '.elb_kube_apiserver_public_dns_name.value'`; \
	elb_ip=`host $$elb_name | awk 'END {print $$NF}'`; \
  echo Please add $$elb_ip $${KUBE_API_DNSNAME} to /etc/hosts file.
destroy: destroy-key
