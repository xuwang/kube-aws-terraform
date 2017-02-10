include ../common/common.mk

# Kubelete token used by kubelet
TF_VAR_kubelet_token := $(shell grep kubelet  ../../artifacts/secrets/api-server/token.csv | cut -f1 -d',')
export

# Start nginx pop, expose nodePort, open firewall to  myip, and connect to the service
smoke-test:
	@-kubectl run nginx --image=nginx --port=80 --replicas=2 && kubectl expose deployment nginx --type LoadBalancer
	@sleep 60
	@elb_name=$(shell kubectl get svc nginx -o json | jq '.status.loadBalancer.ingress[0].hostname') ; \
          open http://$$elb_name

destroy-smoke:
	kubectl delete deployment,svc nginx

init: create-key
destroy: destroy-key
.PHONY: destroy-key create-key smoke-test
