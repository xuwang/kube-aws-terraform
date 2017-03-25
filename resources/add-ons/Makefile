include ../common/common.mk

KUBE_APISERVER_CA := /tmp/kube-apiserver-ca.pem

add-ons: kube-config kubedns monitor dashboard

kube-config:
	@if kubectl config get-contexts | grep default-context | grep ${CLUSTER_NAME} &> /dev/null ; \
	then \
		echo ${CLUSTER_NAME} is current context. Skip configuration. ; \
	else \
		$(MAKE) do-config ; \
	fi

do-config:
	@echo Download vault generated ca cert from the api server
	@ssh-add -D
	@ssh-add ${SSHKEY_DIR}/${CLUSTER_NAME}-controller.pem
	@scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		core@${KUBE_API_DNSNAME}:/var/lib/kubernetes/kube-apiserver-ca.pem ${KUBE_APISERVER_CA}
	@echo kubectl config set-cluster kubernetes...
	@kubectl config set-cluster ${CLUSTER_NAME} \
  		--certificate-authority=${KUBE_APISERVER_CA} \
  		--embed-certs=true \
  		--server=https://${KUBE_API_DNSNAME}:6443
	@echo kubectl config set-credentials admin...
	@kubectl config set-credentials admin \
		--token `cat ../${SEC_PATH}/api-server/token.csv|grep kubelet | grep kubelet | cut -d, -f1`
	@echo kubectl config set-context default-context ...
	@kubectl config set-context default-context \
  		--cluster=${CLUSTER_NAME} \
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

dashboard: kube-config ## Start dashboard
	@if ! kubectl get pods -n kube-system | grep kubernetes-dashboard &> /dev/null ; \
	then \
		kubectl create -f dashboard/ ; \
	else \
		kubectl get svc,pods -n kube-system -l app=kubernetes-dashboard ; \
	fi

ui: dashboard ## kubectl proxy and open dashboard ui
	kubectl proxy -p 8001 &> /dev/null &
	open "http://127.0.0.1:8001/ui/#/workload?namespace=kube-system"
	echo "Please 'make kill-ui' to close kube proxy connection"

kill-ui:  ## close Kube console connection
	kill $(shell ps | grep '[kubectl] proxy -p 8001' | cut -f 1 -d' ')

metrics: monitor ## open metrics ui
	kubectl proxy -p 8002 &> /dev/null &
	open "http://127.0.0.1:8002/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/dashboard/db/pods"
	echo "Please 'make kill-merics' to close kube proxy connection"

kill-metrics:  ## Close monitor console connection
	kill $(shell ps | grep '[kubectl] proxy -p 8002' | cut -f 1 -d' ')

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

.PHONY: add-ons kube-config kubedns delete-kubedns dashboard delete-dashboard kill-ui monitor delete-monitor
