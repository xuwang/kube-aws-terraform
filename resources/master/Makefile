include ../common/common.mk

init: create-key upload-config
get-apiserver-elb:
	@elb_name=`make output | jq -r  '.elb_kube_apiserver_public_dns_name.value'`; \
	elb_ip=`host $$elb_name | awk 'END {print $$NF}'`; \
  echo Please add $$elb_ip $${KUBE_API_DNSNAME} to /etc/hosts file.
destroy: destroy-key
