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

help:
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat $(shell pwd)/Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

cluster: core master node  ## Create or update a kubernetes cluster (include core, masters and nodes)

core: vpc s3 route53 iam pki vault etcd  ## Create or update vpc, s3, route 53, iam, pki, vault, and etcd.

master: etcd  ## Create or update masters
	cd resources/master; make apply
show-master: ## Show master resources
	cd resources/master; make show
destroy-master:  ## Destroy masters
	cd resources/master; make destroy

etcd: iam vault vpc ## Create or update etcd cluster
	cd resources/etcd; make apply
plan-etcd: ## Generate etcd cluster Terraform plan (dry-run)
	cd resources/etcd; make plan
show-etcd: ## Show etcd cluster resources
	cd resources/etcd; make show
destroy-etcd: destroy-node ## Destroy node and etcd cluster
	cd resources/etcd; make destroy

iam: s3 ## Create or update IAM and S3 buckets
	cd resources/iam; make apply
destroy-iam: destroy-etcd ## Destroy IAM and its dependencies
	cd resources/iam; make destroy

pki: s3 ## Create or update Vault PKI backend
	cd resources/pki; make apply
destroy-pki: ## Destroy Vault PKI backend.
	cd resources/pki; make destroy

route53: vpc ## Create or update Route53 zone
	cd resources/route53; make apply
show-route53: ## Show Route53 resource
	cd resources/route53; make show
destroy-route53: ## Destroy Route53 Zone
	cd resources/route53; make destroy

s3: ## Create or update S3 buckets
	cd resources/s3; make apply
destroy-s3: ## Destroy S3 buckets
	cd resources/s3; make destroy

vault: vpc iam pki route53 ## Create or updat Vault server
	cd resources/vault; make apply
plan-vault: ## Generate Vault Terraform plan
	cd resources/vault; make plan
show-vault: ## Show Vault resource
	cd resources/vault; make show
destroy-vault: ## Destroy Vault
	cd resources/vault; make destroy

vpc: 		## Create or upate VPC, gateways, routing tables, subnets
	cd resources/vpc; make apply
plan-vpc:	## Generate VPC Terraform plan
	cd resources/vpc; make plan
show-vpc:	## Show VPC and subnets resources
	cd resources/vpc; make show
destroy-vpc: destroy-s3	## Destroy VPC
	cd resources/vpc; make destroy

node: etcd   	## Create or udpate nodes
	cd resources/node; make apply
show-node:	## Show node resource
	cd resources/node; make show
plan-node:	## Generate node Terraform plan
	cd resources/node; make plan
destroy-node: ## Destroy node
	cd resources/node; make destroy

plan-destroy-all:	## Generate destroy plan of all resources
	@rm /tmp/destroy.err
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy-plan 2> /tmp/destroy.err;)

confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
    fi

teardown:
	@-cd ${ROOT_DIR}/apps/gitlab; ./teardown.sh
	@-cd ${ROOT_DIR}/apps/nginx-test; ./teardown.sh
	$(MAKE) destroy-add-ons
	$(MAKE) destroy-all

destroy-all: plan-destroy-all	## Destroy all resources
	@rm -f /tmp/destroy_plan
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) show-destroy-plan >> /tmp/destroy_plan;)
	@cat /tmp/destroy_plan
	@$(eval total=$(shell cat /tmp/destroy_plan | grep -v data.terraform | wc -l))
	@echo ""
	@echo "Will destroy $$total resources"
	@$(MAKE) confirm
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy 2> /tmp/destroy.err;)
	@$(MAKE) destroy-remote

destroy-remote:		# Destroy Terraform remote state, as final cleanup
	@echo "Destroy Terraform remote state?"
	@echo "This will destroy remote state for each module, all remote state versions, and delete the bucket"
	@$(MAKE) confirm
	@cd resources/vpc; $(MAKE) force-destroy-remote

show-all:	## Show all resources
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) show 2> /tmp/destroy.err;)

upgrade-kube:	## Upgrade Kubernetes version
	@cd resources/node; make upgrade-kube
	@cd resources/master; make upgrade-kube

# Extras
add-ons:	## Kubernetes add-ons, e.g. dns, dashboard
	cd resources/add-ons; make add-ons

ui: ## Open dashboard UI in browser
	cd resources/add-ons; make ui

metrics: ## Open Granfana UI in browser
	cd resources/add-ons; make metrics

kill-ui: ## Close dashboard UI connection
	cd resources/add-ons; make kill-ui

kill-metrics: ## Close Granfana UI connection
	cd resources/add-ons; make kill-metrics

smoke-test: ## Run smoke test
	cd ${ROOT_DIR}/apps/nodeapp; ./deploy.sh

get-apiserver-elb: ## Get API server ELB address
	cd resources/master; make get-apiserver-elb

destroy-add-ons: ## Delete all add-ons, ie. kubedns, dashboard, and monitor
	cd resources/add-ons; make kube-cleanup

# see https://github.com/docker/for-mac/issues/17#issuecomment-236517032
sync-docker-time: ## sync docker vm time with hardware clock
		@docker run --rm --privileged alpine hwclock -s

.PHONY: help vpc s3 iam etcd node add-ons destroy-add-ons sync-docker-time
.PHONY: destroy destroy-vpc destroy-s3 destroy-iam destroy-etcd destroy-node smoke-test
