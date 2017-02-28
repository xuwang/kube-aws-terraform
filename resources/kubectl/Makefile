include ../common/common.mk

KUBE_APISERVER_CA := /tmp/kube-apiserver-ca.pem
KUBEDNS_DEPLOYMENT := ../artifacts/kubedns-deployment.yaml
KUBEDNS_SERVICE := ../artifacts/kubedns-service.yaml
KUBE_UI := ../artifacts/kubernetes-dashboard.yaml

add-ons: kube-config kube-dns kube-ui
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

kube-dns:
	@if ! kubectl get svc -n kube-system | grep kube-dns &> /dev/null ; \
	then \
		kubectl apply -f ${KUBEDNS_SERVICE} ; \
		kubectl apply -f ${KUBEDNS_DEPLOYMENT} ; \
	else \
		kubectl get pods -n kube-system -l k8s-app=kube-dns ; \
	fi

kube-dns-delete:
	kubectl delete -f ${KUBEDNS_DEPLOYMENT} 
	kubectl delete -f ${KUBEDNS_SERVICE}

kube-ui-delete:
	kubectl delete -f ${KUBE_UI}
kube-ui:
	@if ! kubectl get pods -n kube-system | grep kubernetes-dashboard &> /dev/null ; \
	then \
		kubectl create -f ${KUBE_UI} ; \
	else \
		kubectl get pods -n kube-system -l app=kubernetes-dashboard ; \
	fi
kube-cleanup:
	$(MAKE) kube-dns-delete
	$(MAKE) kube-ui-delete

.PHONY: kube-config kube-route kube-dns kube-route add-ons kube-config turn-off-source-dest-check

