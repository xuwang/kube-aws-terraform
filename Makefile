###################
## Customization ##
###################
# Change here or use environment variables, e.g. export AWS_PROFILE=<aws profile name>.

# Default SHELL for make for consistency on different platforms
SHELL := /bin/bash
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# When destroy-all runs, the resources on this list will be destroyed, in this order.
ALL_RESOURCES := node master etcd iam pki vault route53 s3 vpc

export

.PHONY: help
help:
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat $(shell pwd)/Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort -k1,1

.PHONY: core master node
cluster: core master node  ## Create or update a kubernetes cluster (include core, masters and nodes)

.PHONY: vpc s3 route53 iam pki vault etcd
core: vpc s3 route53 iam pki vault etcd  ## Create or update vpc, s3, route 53, iam, pki, vault, and etcd.

.PHONY: master plan-master show-master destory-master
master: etcd  ## Create or update masters
	cd resources/master; make apply
plan-master: ## plan master resources
	cd resources/master; make plan
show-master: ## Show master resources
	cd resources/master; make show
destroy-master:  ## Destroy masters
	cd resources/master; make destroy

.PHONY: etcd plan-etcd show-etcd destroy-etcd
etcd: iam vault vpc ## Create or update etcd cluster
	cd resources/etcd; make apply
plan-etcd: ## Generate etcd cluster Terraform plan (dry-run)
	cd resources/etcd; make plan
show-etcd: ## Show etcd cluster resources
	cd resources/etcd; make show
destroy-etcd: destroy-node ## Destroy node and etcd cluster
	cd resources/etcd; make destroy

.PHONY: iam destroy-iam
iam: s3 ## Create or update IAM and S3 buckets
	cd resources/iam; make apply
destroy-iam: destroy-etcd ## Destroy IAM and its dependencies
	cd resources/iam; make destroy

.PHONY: pki s3
pki: s3 ## Create or update Vault PKI backend
	cd resources/pki; make apply
destroy-pki: ## Destroy Vault PKI backend.
	cd resources/pki; make destroy

.PHONY: route53 show-route53 destroy-route53
route53: vpc ## Create or update Route53 zone
	cd resources/route53; make apply
show-route53: ## Show Route53 resource
	cd resources/route53; make show
destroy-route53: ## Destroy Route53 Zone
	cd resources/route53; make destroy

.PHONY: s3 destroy-s3
s3: ## Create or update S3 buckets
	cd resources/s3; make apply
destroy-s3: ## Destroy S3 buckets
	cd resources/s3; make destroy

.PHONY: vault plan-vault show-vault destroy-vault
vault: vpc iam pki route53 ## Create or updat Vault server
	cd resources/vault; make apply
plan-vault: ## Generate Vault Terraform plan
	cd resources/vault; make plan
show-vault: ## Show Vault resource
	cd resources/vault; make show
destroy-vault: ## Destroy Vault
	cd resources/vault; make destroy

.PHONY: vpc plan-vpc show-vpc destory-vpc
vpc: 		## Create or upate VPC, gateways, routing tables, subnets
	cd resources/vpc; make apply
plan-vpc:	## Generate VPC Terraform plan
	cd resources/vpc; make plan
show-vpc:	## Show VPC and subnets resources
	cd resources/vpc; make show
destroy-vpc: destroy-s3	## Destroy VPC
	cd resources/vpc; make destroy

.PHONY: node show-node plan-node destroy-node
node: etcd   	## Create or udpate nodes
	cd resources/node; make apply
show-node:	## Show node resource
	cd resources/node; make show
plan-node:	## Generate node Terraform plan
	cd resources/node; make plan
destroy-node: ## Destroy node
	cd resources/node; make destroy

.PHONY: plan-destroy-all
plan-destroy-all:	## Generate destroy plan of all resources
	@rm -rf /tmp/destroy.err
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy-plan 2> /tmp/destroy.err;)

.PHONY: confirm
confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
    fi

.PHONY: teardown
teardown:
	@-cd ${ROOT_DIR}/apps/gitlab; ./teardown.sh
	@-cd ${ROOT_DIR}/apps/nginx-test; ./teardown.sh
	$(MAKE) destroy-add-ons
	$(MAKE) destroy-all

.PHONY: destroy-all
destroy-all: plan-destroy-all	## Destroy all resources
	@rm -f /tmp/destroy_plan
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) show-destroy-plan >> /tmp/destroy_plan;)
	@cat /tmp/destroy_plan | grep -v data.terraform | grep -v data.aws
	@echo ""
	@echo "Will destroy these resources. Please confirm."
	@$(MAKE) confirm
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy 2> /tmp/destroy.err;)
	@$(MAKE) destroy-remote

.PHONY: destroy-remote
destroy-remote:		# Destroy Terraform remote state, as final cleanup
	@echo "Destroy Terraform remote state?"
	@echo "This will destroy remote state for each module, all remote state versions, and delete the bucket"
	@$(MAKE) confirm
	@cd resources/vpc; $(MAKE) force-destroy-remote

.PHONY: show-all
show-all:	## Show all resources
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) show 2> /tmp/destroy.err;)

.PHONY: update-kube
update-kube:	## Update Kubernetes cluster
	@cd resources/master; make update
	@cd resources/node; make update

.PHONY: update-vault
update-vault:	## Upgrade vault
	@cd resources/vault; make update

# Extras
.PHONY: add-ons
add-ons:	## Kubernetes add-ons, e.g. dns, dashboard
	cd resources/add-ons; make add-ons

.PHONY: ui
ui: ## Open dashboard UI in browser
	cd resources/add-ons; make ui

.PHONY: metrics
metrics: ## Open Granfana UI in browser
	cd resources/add-ons; make metrics

.PHONY: kill-ui
kill-ui: ## Close dashboard UI connection
	cd resources/add-ons; make kill-ui

.PHONY: kill-metrics
kill-metrics: ## Close Granfana UI connection
	cd resources/add-ons; make kill-metrics

.PHONY: get-apiserver-elb
get-apiserver-elb: ## Get API server ELB address
	cd resources/master; make get-apiserver-elb

.PHONY: destroy-add-ons
destroy-add-ons: ## Delete all add-ons, ie. kubedns, dashboard, and monitor
	cd resources/add-ons; make kube-cleanup

.PHONY: sync-docker-time
# see https://github.com/docker/for-mac/issues/17#issuecomment-236517032
sync-docker-time: ## sync docker vm time with hardware clock
	@docker run --rm --privileged alpine hwclock -s

.PHONY: kube-config
kube-config: ## config kubectl
	cd resources/add-ons; make kube-config
