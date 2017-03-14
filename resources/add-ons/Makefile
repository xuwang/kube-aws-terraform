include ../common/common.mk

KUBE_APISERVER_CA := /tmp/kube-apiserver-ca.pem

add-ons: kube-config kubedns dashboard monitor

kube-config:
	@echo Download vault generated ca cert from the api server
	@ssh-add -D
	@ssh-add ${SSHKEY_DIR}/${CLUSTER_NAME}-controller.pem
	@scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		core@${KUBE_API_DNSNAME}:/var/lib/kubernetes/kube-apiserver-ca.pem ${KUBE_APISERVER_CA}
	@echo kubectl config set-cluster kubernetes...
	@kubectl config set-cluster kubernetes \
  		--certificate-authority=${KUBE_APISERVER_CA} \
  		--embed-certs=true \
  		--server=https://${KUBE_API_DNSNAME}:6443
	@echo kubectl config set-credentials admin...
	@kubectl config set-credentials admin \
		--token `cat ../${SEC_PATH}/api-server/token.csv|grep kubelet | grep kubelet | cut -d, -f1`
	@echo kubectl config set-context default-context ...
	@kubectl config set-context default-context \
  		--cluster=kubernetes \
  		--user=admin
	kubectl config use-context default-context
	@kubectl get nodes

kubedns:
	@if ! kubectl get svc -n kube-system | grep kube-dns &> /dev/null ; \
	then \
		kubectl create -f kubedns/ ; \
	else \
		kubectl get svc,pods -n kube-system -l k8s-app=kube-dns ; \
	fi

delete-kubedns:
	kubectl delete -f kubedns/

dashboard:
	@if ! kubectl get pods -n kube-system | grep kubernetes-dashboard &> /dev/null ; \
	then \
		kubectl create -f dashboard/ ; \
	else \
		kubectl get svc,pods -n kube-system -l app=kubernetes-dashboard ; \
	fi

delete-dashboard:
	kubectl delete -f dashboard/

monitor:
	@if ! kubectl get pods -n kube-system | grep monitoring-grafana &> /dev/null ; \
	then \
		kubectl create -f monitor/ ; \
	else \
		kubectl get svc,pods -n kube-system -l task=monitoring ; \
	fi

delete-monitor:
	kubectl delete -f monitor/

kube-cleanup:
	$(MAKE) delete-dashboard
	$(MAKE) delete-monitor
	$(MAKE) delete-kubedns

.PHONY: add-ons kube-config kubedns delete-kubedns dashboard delete-dashboard monitor delete-monitor
