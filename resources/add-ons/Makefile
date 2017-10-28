include ../../envs.sh
include envs.sh

KUBERNETES_WORKDIR := /tmp/kubernetes_workdir_${CLUSTER_NAME}
KUBERNETES_DASHBOARD := https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

.PHONY: help
help:
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat $(shell pwd)/Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort -k1,1

.PHONY: add-ons
add-ons: kubedns monitor dashboard ## bundled addsons kubedns,monitor,dashboard

.PHONY: kube-config
kube-config: ## If kubeconfig is not configured the this cluster, configure it
	@if kubectl config get-contexts -o name | grep ^${CLUSTER_NAME}$$ &> /dev/null ; \
	then \
		echo ${CLUSTER_NAME} is configured. Skip configuration. ; \
		echo Run "kubectl config delete-context ${CLUSTER_NAME} if you want to re-configure." ; \
		$(MAKE) switch-context ; \
	else \
		$(MAKE) kube-reconfig ; \
	fi

.PHONY: kube-reconfig
kube-reconfig: ## Create or reconfigure kubeconfig for kubectl
	@rm -rf ${KUBERNETES_WORKDIR}
	@mkdir -p ${KUBERNETES_WORKDIR}
	@echo Download vault generated ca cert from the api server. Clean out ssh-agent memory cache
	@ssh-add -D
	@ssh-add ${SSHKEY_DIR}/${CLUSTER_NAME}-master.pem
	@${SCRIPTS}/allow-myip.sh -a master 22
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		core@${KUBE_API_DNSNAME} "tar -C /var/lib/kubernetes -cf - admin.pem admin-key.pem kube-apiserver-ca.pem" | \
		  tar -C ${KUBERNETES_WORKDIR}/ -xf - 
	@${SCRIPTS}/allow-myip.sh -r master 22
	@echo kubectl config set-cluster kubernetes...
	@kubectl config set-cluster ${CLUSTER_NAME} \
  		--certificate-authority=${KUBERNETES_WORKDIR}/kube-apiserver-ca.pem \
  		--embed-certs=true \
  		--server=https://${KUBE_API_DNSNAME}:6443

	@echo kubectl config set-credentials ${CLUSTER_NAME}-admin...
	@kubectl config set-credentials ${CLUSTER_NAME}-admin \
		--embed-certs=true \
		--client-certificate=${KUBERNETES_WORKDIR}/admin.pem \
		--client-key=${KUBERNETES_WORKDIR}/admin-key.pem
	@-gshred ${KUBERNETES_WORKDIR}/*
	@-rm -rf ${KUBERNETES_WORKDIR}
	$(MAKE) switch-context

.PHONY: switch-context
switch-context: ## Switch context to this cluster
	@echo kubectl config set-context  ${CLUSTER_NAME} ...
	@kubectl config set-context ${CLUSTER_NAME} \
  		--cluster=${CLUSTER_NAME} \
  		--user=${CLUSTER_NAME}-admin
	kubectl config use-context ${CLUSTER_NAME}

.PHONY: kube-system-admin-role-binding
kube-system-admin-role-binding: kube-config ## Create Service account admin binding
	@if ! kubectl get clusterrolebinding kube-system-admin-role-binding &> /dev/null ; \
	then \
		kubectl create -f rbac-policies/kube-system-admin-role-binding.yaml ; \
	fi

.PHONY: kubernetes-dashboard-admin-role-binding
kubernetes-dashboard-admin-role-binding: kube-config ## Create Service account admin binding
	@if ! kubectl get clusterrolebinding kubernetes-dashboard &> /dev/null ; \
	then \
		kubectl create -f rbac-policies/kubernetes-dashboard-admin.yaml ; \
	fi

.PHONY: kubedns
kubedns: kube-config ## Deploy kube-dns
	@if ! kubectl get svc -n kube-system kube-dns &> /dev/null ; \
	then \
		kubectl create -f kubedns/ ; \
	else \
		kubectl get svc,pods -n kube-system -l k8s-app=kube-dns ; \
	fi

.PHONY: delete-kubedns
delete-kubedns: kube-config ## Delete kube-dns
	kubectl delete -f kubedns/;

.PHONY: dashboard
dashboard: kube-config kubernetes-dashboard-admin-role-binding ## Start dashboard
	@if ! kubectl get pods -n kube-system |grep kubernetes-dashboard |grep Running &> /dev/null ; \
	then \
		kubectl apply -f ${KUBERNETES_DASHBOARD} ; \
	else \
		kubectl get svc,pods -n kube-system -l k8s-app=kubernetes-dashboard ; \
	fi

.PHONY: ui
ui: kill-ui dashboard ## kubectl proxy and open dashboard ui
	kubectl proxy -p 8001 &> /dev/null &
	@while ! kubectl get pods -n kube-system -o json -l k8s-app=kubernetes-dashboard | jq .items'[]'.status.containerStatuses'[]'.ready | grep -q true; \
	do \
		echo Waitting for UI ; \
		sleep 10 ; \
	done
	@echo
	@echo To access endpoint of dashboard local proxy, go to:
	@echo http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
	@echo
	@echo "Please 'make kill-ui' to close kube proxy connection"

.PHONY: kill-ui
kill-ui:  kill-metrics ## Close Kube console connection
	@if pgrep -f 8001 &> /dev/null ; \
	then \
	  echo Killed Proxy on port 8001 ; \
		kill $(shell pgrep -f 8001) ; \
	fi

.PHONY: metrics
metrics: kube-config monitor ## Open metrics ui
	kubectl proxy -p 8002 &> /dev/null &
	@while ! kubectl get pods -n kube-system -o json -l k8s-app=grafana | grep ready | grep -q true ; \
	do \
		echo Waitting for granfana ; \
		sleep 10 ; \
	done
	echo "Connecting to Grafana"
	open "http://127.0.0.1:8002/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/dashboard/db/pods"
	echo "Please 'make kill-metrics' to close kube proxy connection"

.PHONY: kill-metrics
kill-metrics:  ## Close monitor console connection
	@if pgrep -f 8002 &> /dev/null ; \
	then \
	  echo Killed proxy on port 8002 ; \
		kill $(shell pgrep -f 8002) ; \
	fi

.PHONY: delete-dashboard
delete-dashboard: kube-config kill-ui ## Delete dashboard
	kubectl delete -f ${KUBERNETES_DASHBOARD}

.PHONY: monitor
monitor: kube-system-admin-role-binding ## Deploy heapster, infuluxdb and grafana
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

.PHONY: delete-monitor
delete-monitor: kube-config ## Delete monitor
	kubectl delete -f monitor/

.PHONY: kube-cleanup
kube-cleanup: ## Delete all add-ons and delete the default-context
	@-$(MAKE) delete-dashboard
	@-$(MAKE) delete-monitor
	@-$(MAKE) delete-kubedns
	@if kubectl config get-contexts | grep default-context | grep ${CLUSTER_NAME} &> /dev/null ; \
	then \
		kubectl config delete-context default-context ; \
	fi
