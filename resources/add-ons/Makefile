include ../../envs.sh
include envs.sh

KUBERNETES_WORKDIR := /tmp/kubernetes_workdir
KUBERNETES_DASHBOARD := https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml

help:
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat $(shell pwd)/Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

add-ons: kube-config kubedns monitor dashboard ## buncled addsons kubedns,monitor,dashboard

kube-config: ## If kubeconfig is not configured the this cluster, configure it
	@if kubectl config get-contexts | grep default-context | grep ${CLUSTER_NAME} &> /dev/null ; \
	then \
		echo ${CLUSTER_NAME} is current context. Skip configuration. ; \
		echo Run "kubectl config delete-context default-context" if you want to re-configure. ; \
	else \
		$(MAKE) do-config ; \
	fi

do-config: ## Create kubeconfig for kubectl
	@rm -rf ${KUBERNETES_WORKDIR}
	@mkdir -p ${KUBERNETES_WORKDIR}
	@echo Download vault generated ca cert from the api server
	@ssh-add ${SSHKEY_DIR}/${CLUSTER_NAME}-master.pem
	@../scripts/allow-myip.sh -a master 22
	@scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		core@${KUBE_API_DNSNAME}:/var/lib/kubernetes/admin.pem \
		core@${KUBE_API_DNSNAME}:/var/lib/kubernetes/admin-key.pem \
		core@${KUBE_API_DNSNAME}:/var/lib/kubernetes/kube-apiserver-ca.pem \
		 ${KUBERNETES_WORKDIR}/
	@../scripts/allow-myip.sh -r master 22

	@echo kubectl config set-cluster kubernetes...
	@kubectl config set-cluster ${CLUSTER_NAME} \
  		--certificate-authority=${KUBERNETES_WORKDIR}/kube-apiserver-ca.pem \
  		--embed-certs=true \
  		--server=https://${KUBE_API_DNSNAME}:6443

	@echo kubectl config set-credentials admin...
	@kubectl config set-credentials admin \
		--embed-certs=true \
		--client-certificate=${KUBERNETES_WORKDIR}/admin.pem \
		--client-key=${KUBERNETES_WORKDIR}/admin-key.pem
	@echo kubectl config set-context default-context ...
	@kubectl config set-context default-context \
  		--cluster=${CLUSTER_NAME} \
  		--user=admin
	kubectl config use-context default-context
	@echo rm -rf ${KUBERNETES_WORKDIR}

kube-system-admin-role-binding: kube-config ## Create Service account admin binding
	@if ! kubectl get clusterrolebinding kube-system-admin-role-binding &> /dev/null ; \
	then \
		kubectl create -f kube-system-admin-role-binding.yaml ; \
	fi

kubedns: ## Deploy kube-dns
	@if ! kubectl get svc -n kube-system kube-dns &> /dev/null ; \
	then \
		kubectl create -f kubedns/ ; \
	else \
		kubectl get svc,pods -n kube-system -l k8s-app=kube-dns ; \
	fi

delete-kubedns: ## Delete kube-dns
	kubectl delete -f kubedns/;

dashboard: kube-system-admin-role-binding ## Start dashboard
	@if ! kubectl get pods -n kube-system |grep kubernetes-dashboard |grep Running &> /dev/null ; \
	then \
		kubectl create -f ${KUBERNETES_DASHBOARD} ; \
	else \
		kubectl get svc,pods -n kube-system -l k8s-app=kubernetes-dashboard ; \
	fi

ui: dashboard ## kubectl proxy and open dashboard ui
	kubectl proxy -p 8001 &> /dev/null &
	@while ! kubectl get pods -n kube-system -o json -l k8s-app=kubernetes-dashboard | jq .items'[]'.status.containerStatuses'[]'.ready | grep -q true; \
	do \
		echo Waitting for UI ; \
		sleep 10 ; \
	done
	echo "Connecting to ui..."
	open "http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/workload?namespace=kube-system"
	echo "Please 'make kill-ui' to close kube proxy connection"

kill-ui:  kill-metrics ## Close Kube console connection
	@if pgrep -f 8001 &> /dev/null ; \
	then \
	  echo Killed Proxy on port 8001 ; \
		kill $(shell pgrep -f 8001) ; \
	fi

metrics: monitor ## Open metrics ui
	kubectl proxy -p 8002 &> /dev/null &
	@while ! kubectl get pods -n kube-system -o json -l k8s-app=grafana | grep ready | grep -q true ; \
	do \
		echo Waitting for granfana ; \
		sleep 10 ; \
	done
	echo "Connecting to Grafana"
	open "http://127.0.0.1:8002/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/dashboard/db/pods"
	echo "Please 'make kill-metrics' to close kube proxy connection"

kill-metrics:  ## Close monitor console connection
	@if pgrep -f 8002 &> /dev/null ; \
	then \
	  echo Killed proxy on port 8002 ; \
		kill $(shell pgrep -f 8002) ; \
	fi

delete-dashboard: kill-ui ## Delete dashboard
	kubectl delete -f ${KUBERNETES_DASHBOARD}

monitor: ## Deploy heapster, infuluxdb and grafana
	@if ! kubectl get pods -n kube-system | grep monitoring-grafana &> /dev/null ; \
	then \
		while ! kubectl get pods -n kube-system -o json -l k8s-app=kube-dns | grep ready | grep -q true  ; \
		do \
			echo Waitting for kube-dns ; \
			sleep 5 ; \
		done ; \
		kubectl create -f monitor/ ; \
	else \
		kubectl get svc,pods -n kube-system -l task=monitoring ; \
	fi

delete-monitor: ## Delete monitor
	kubectl delete -f monitor/

kube-cleanup: ## Delete all add-ons and delete the default-context
	@-$(MAKE) delete-dashboard
	@-$(MAKE) delete-monitor
	@-$(MAKE) delete-kubedns
	@if kubectl config get-contexts | grep default-context | grep ${CLUSTER_NAME} &> /dev/null ; \
	then \
		kubectl config delete-context default-context ; \
	fi

.PHONY: add-ons dashboard delete-dashboard delete-monitor delete-kubedns do-config helpme kill-metrics
.PHONY: kill-ui kube-cleanup kube-config kubedns metrics monitor kube-system-admin-role-binding ui
