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
	@echo "make [ help | all | controller | etcd | iam | pki | route53 | s3 | vault | vpc | worker ]"
	@echo "make show-<controller | etcd |i am | s3 | pki | route53 | vault | vpc | worker>" 
	@echo "make destroy-<controller | etcd | iam | s3 | pki | route53 | vault | vpc |worker >"

cluster: core controller worker

core: vpc s3 route53 iam pki vault etcd

controller: etcd
	cd resources/controller; make
show-controller:
	cd resources/controller; make show
destroy-controller:
	cd resources/controller; make destroy

etcd: iam vault vpc
	cd resources/etcd; make
plan-etcd:
	cd resources/etcd; make plan
show-etcd:
	cd resources/etcd; make show
destroy-etcd: destroy-worker
	cd resources/etcd; make destroy

iam: s3
	cd resources/iam; make
destroy-iam: destroy-etcd 
	cd resources/iam; make destroy

pki: s3 
	cd resources/pki; make
destroy-pki: 
	cd resources/pki; make destroy

route53: vpc
	cd resources/route53; make
show-route53:
	cd resources/route53; make show
destroy-route53:
	cd resources/route53; make destroy

s3: 
	cd resources/s3; make
destroy-s3:
	cd resources/s3; make destroy

vault: iam pki route53 vpc
	cd resources/vault; make
plan-vault:
	cd resources/vault; make plan
show-vault:
	cd resources/vault; make show
destroy-vault:
	cd resources/vault; make destroy

vpc: 
	cd resources/vpc; make
plan-vpc:
	cd resources/vpc; make plan
show-vpc:
	cd resources/vpc; make show
destroy-vpc: destroy-s3
	cd resources/vpc; make destroy

worker: etcd
	cd resources/worker; make
show-worker:
	cd resources/worker; make show
plan-worker:
	cd resources/worker; make plan
destroy-worker: 
	cd resources/worker; make destroy

plan-destroy-all:
	@rm -rf ${ROOT_DIR}/tmp; mkdir -p ${ROOT_DIR}/tmp
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy-plan  2> /tmp/destroy.err;)

confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
    fi

destroy-all: | plan-destroy-all
	for i in ${ROOT_DIR}tmp/*.plan; do terraform show $$i; done | grep -- -
	@$(eval total=$(shell for i in ${ROOT_DIR}/tmp/*.plan; do terraform show $$i; done | grep -- - | wc -l))
	@echo ""
	@echo "Will destroy $$total resources"
	@$(MAKE) confirm
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) destroy 2> /tmp/destroy.err;)
	@$(MAKE) destroy-remote
	rm -rf ${ROOT_DIR}tmp/*.plan

# ToDo: Need to delete all versions of remote state to actually delete the bucket. This target now just empty the bucket.
destroy-remote:
	@echo "Destroy Terraform remote state?"
	@echo "This will destroy remote state for each module, all remote state versions, and delete the bucket"
	@$(MAKE) confirm	
	@cd resources/vpc; $(MAKE) force-destroy-remote

show-all:
	@$(foreach resource,$(ALL_RESOURCES),cd $(ROOT_DIR)/resources/$(resource) && $(MAKE) show  2> /tmp/destroy.err;)

# Extras
add-ons:
	cd resources/kubectl; make add-ons
smoke-test:
	cd resources/worker; make smoke-test

get-apiserver-elb:
	cd resources/controller; make get-apiserver-elb
	
kube-cleanup:
	cd resources/kubectl; make kube-cleanup

.PHONY: provider.tf all help vpc s3 iam etcd worker 
.PHONY: destroy destroy-vpc destroy-s3 destroy-iam destroy-etcd destroy-worker smoke-test
