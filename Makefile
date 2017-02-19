###################
## Customization ##
###################
# Change here or use environment variables, e.g. export AWS_PROFILE=<aws profile name>.

# Default SHELL for make for consistency on different platforms
SHELL := /bin/bash
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# When destroy-all runs, the resources on this list will be destroyed, in this order. 
ALL_RESOURCES := worker controller etcd iam pki vault route53 s3 vpc

export 

help:
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat $(shell pwd)/Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

cluster: core controller worker  ## Create or update a kubernetes cluster (include core, controllers and workers)

core: vpc s3 route53 iam pki vault etcd  ## Create or update vpc, s3, route 53, iam, pki, vault, and etcd.

controller: etcd  ## Create or update controllers
	cd resources/controller; make
show-controller: ## Show controller resources
	cd resources/controller; make show
destroy-controller:  ## Destroy controllers
	cd resources/controller; make destroy

etcd: iam vault vpc ## Create or update etcd cluster
	cd resources/etcd; make
plan-etcd: ## Generate etcd cluster Terraform plan (dry-run)
	cd resources/etcd; make plan
show-etcd: ## Show etcd cluster resources
	cd resources/etcd; make show
destroy-etcd: destroy-worker ## Destroy worker and etcd cluster
	cd resources/etcd; make destroy

iam: s3 ## Create or update IAM and S3 buckets
	cd resources/iam; make
destroy-iam: destroy-etcd ## Destroy IAM and its dependencies
	cd resources/iam; make destroy

pki: s3 ## Create or update Vault PKI backend
	cd resources/pki; make
destroy-pki: ## Destroy Vault PKI backend.
	cd resources/pki; make destroy

route53: vpc ## Create or update Route53 zone
	cd resources/route53; make
show-route53: ## Show Route53 resource
	cd resources/route53; make show
destroy-route53: ## Destroy Route53 Zone
	cd resources/route53; make destroy

s3: ## Create or update S3 buckets
	cd resources/s3; make
destroy-s3: ## Destroy S3 buckets
	cd resources/s3; make destroy

vault: iam pki route53 vpc ## Create or updat Vault server
	cd resources/vault; make
plan-vault: ## Generate Vault Terraform plan
	cd resources/vault; make plan
show-vault: ## Show Vault resource
	cd resources/vault; make show
destroy-vault: ## Destroy Vault 
	cd resources/vault; make destroy

vpc: 		## Create or upate VPC, gateways, routing tables, subnets
	cd resources/vpc; make
plan-vpc:	## Generate VPC Terraform plan
	cd resources/vpc; make plan
show-vpc:	## Show VPC and subnets resources
	cd resources/vpc; make show
destroy-vpc: destroy-s3	## Destroy VPC
	cd resources/vpc; make destroy

worker: etcd   	## Create or udpate workers
	cd resources/worker; make
show-worker:	## Show worker resource
	cd resources/worker; make show
plan-worker:	## Generate worker Terraform plan
	cd resources/worker; make plan
destroy-worker: ## Destroy worker
	cd resources/worker; make destroy

plan-destroy-all:	## Generate destroy plan of all resources
	@rm -rf ${ROOT_DIR}/tmp; mkdir -p ${ROOT_DIR}/tmp
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy-plan  2> /tmp/destroy.err;)

confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
    fi

teardown:
	@-cd ${ROOT_DIR}/apps/gitlab; ./teardown.sh
	@cd resources/kubectl; make kube-cleanup
	$(MAKE) destroy-all

destroy-all: | plan-destroy-all		## Destroy all resources
	for i in ${ROOT_DIR}tmp/*.plan; do terraform show $$i; done | grep -- -
	@$(eval total=$(shell for i in ${ROOT_DIR}/tmp/*.plan; do terraform show $$i; done | grep -- - | wc -l))
	@echo ""
	@echo "Will destroy $$total resources"
	@$(MAKE) confirm
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy 2> /tmp/destroy.err;)
	@$(MAKE) destroy-remote
	rm -rf ${ROOT_DIR}tmp/*.plan

destroy-remote:		# Destroy Terraform remote state, as final cleanup
	@echo "Destroy Terraform remote state?"
	@echo "This will destroy remote state for each module, all remote state versions, and delete the bucket"
	@$(MAKE) confirm	
	@cd resources/vpc; $(MAKE) force-destroy-remote

show-all:	## Show all resources
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) show 2> /tmp/destroy.err;)

upgrade-kube:	## Upgrade Kubernetes version
	@cd resources/worker; make upgrade-kube
	@cd resources/controller; make upgrade-kube

# Extras
add-ons:	## Kubernetes add-ons, e.g. dns, dashboard
	cd resources/kubectl; make add-ons
smoke-test:
	cd resources/worker; make smoke-test

get-apiserver-elb: ## Get API server ELB address
	cd resources/controller; make get-apiserver-elb
	
kube-cleanup: ## Delete all kubernetes deployments
	cd resources/kubectl; make kube-cleanup

.PHONY: all help vpc s3 iam etcd worker 
.PHONY: destroy destroy-vpc destroy-s3 destroy-iam destroy-etcd destroy-worker smoke-test
