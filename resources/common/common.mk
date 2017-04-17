include ../../envs.sh
include envs.sh

AWS_USER := $(shell aws --profile ${AWS_PROFILE} iam get-user | jq -r ".User.UserName")
AWS_ACCOUNT := $(shell aws --profile ${AWS_PROFILE} iam get-user | jq -r ".User.Arn" | grep -Eo '[[:digit:]]{12}')
ALLOWED_ACCOUNT_IDS := "$(AWS_ACCOUNT)"

SCRIPTS := ../scripts
SEC_PATH := ../artifacts/secrets
SSHKEY_DIR := ${HOME}/.ssh
BUILD_DIR := ${PWD}/build
ARTIFACTS_DIR := ../artifacts
MODULES_PATH := ../modules

# Timestamp for tagging resources
TF_VAR_timestamp := $(shell date +%Y-%m-%d-%H%M)
# Terraform dir referenced in container
TF_VAR_build_dir := /build
TF_VAR_artifacts_dir := ${TF_VAR_build_dir}/artifacts
TF_VAR_secrets_path := ${TF_VAR_artifacts_dir}/secrets

TF_VERSION := 0.9.2
TF_IMAGE := hashicorp/terraform:${TF_VERSION}
TF_CMD := docker run -it --rm --env-file=${BUILD_DIR}/tf.env \
		-v=${HOME}/.aws:/root/.aws \
		-v=${BUILD_DIR}:${TF_VAR_build_dir} \
		-w=${TF_VAR_build_dir} ${TF_IMAGE}

# Terraform max retries and log level
TF_MAX_RETRIES := 10
#TF_LOG := debug

# Terraform commands
# Note: for production, set -refresh=true to be safe
TF_APPLY := ${TF_CMD} apply -refresh=true
# Note: for production, remove --force to confirm destroy.
TF_DESTROY := ${TF_CMD} destroy -force
TF_DESTROY_PLAN := ${TF_CMD} plan -destroy -refresh=true
TF_GET := ${TF_CMD} get
TF_GRAPH := ${TF_CMD} graph -module-depth=0
TF_PLAN := ${TF_CMD} plan -refresh=true
TF_SHOW := ${TF_CMD} show -no-color
TF_LIST := ${TF_CMD} state list
TF_REFRESH := ${TF_CMD} refresh
TF_TAINT := ${TF_CMD} taint -allow-missing
TF_OUTPUT := ${TF_CMD} output -json
TF_INIT := ${TF_CMD} init -input=false

# TF environments
TF_REMOTE_STATE_PATH := "${MODULE}.tfstate"
TF_REMOTE_STATE_BUCKET := ${AWS_ACCOUNT}-${CLUSTER_NAME}-terraform
TF_PROVIDER := provider.tf

export

help: ## this info
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat ../common/common.mk | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

update-build: check-profile ## create or update build dir for terraform
	@mkdir -p ${BUILD_DIR}
# copy modules to buid dir
	@cp -rf ${MODULES_PATH} ${BUILD_DIR}
# copy shared tf files to buidl dir
	@cp -f ../common/*.tf ${BUILD_DIR}
# copy local tf files to build dir
	@cp -rf tf/* ${BUILD_DIR}
# copy shared artifacts to build dir
	@cp -rf ../artifacts ${BUILD_DIR}
# copy local artifacts to build dir if exist
	@if [ -d artifacts ] ; then cp -rf artifacts/* ${BUILD_DIR}/artifacts; fi
# generate docker env-file for tf vars and aws profile
	@env | grep 'TF_VAR\|AWS_' | grep -v 'TF_CMD' > ${BUILD_DIR}/tf.env
# generate tf provider file
	@../scripts/gen-provider.sh > ${BUILD_DIR}/${TF_PROVIDER}

check-profile: ## validate AWS profile
	@if ! aws --profile ${AWS_PROFILE} iam get-user > /dev/null 2>&1 ; then \
		echo "ERROR: AWS profile \"${AWS_PROFILE}\" is not setup!"; \
		exit 1 ; \
	fi

plan: init ## terraform plan
	@${TF_PLAN}

apply: init ## terraform apply
	@${TF_APPLY}

list: init ## terraform list
	@${TF_LIST}

show: init ## terraform show
	@${TF_SHOW}

output: ## terraform output
	@${TF_OUTPUT}

destroy-plan: init ## terraform destroy-plan
	@echo Plan destroy ${MODULE}...
	@-${TF_DESTROY_PLAN} -out ${TF_VAR_build_dir}/destroy-${MODULE}.plan

show-destroy-plan: ## show resources planed to be destroyed
	@-${TF_SHOW} ${TF_VAR_build_dir}/destroy-${MODULE}.plan | grep -- -

destroy: init ## terraform destroy
	@echo Destroy ${MODULE}...
	@${TF_DESTROY}
	$(MAKE) clean

refresh: init ## terraform refresh
	@${TF_REFRESH}

clean: ## delete build dir
	rm -rf ${BUILD_DIR}

create-key: ## create AWS keypair for this module
	../scripts/aws-keypair.sh -c $(CLUSTER_NAME)-${MODULE};

destroy-key: ## destroy AWS keypair for this module
	../scripts/aws-keypair.sh -d $(CLUSTER_NAME)-${MODULE};

get-ips: ## get ips of EC2 in this module
	@echo "${MODULE}; public ips: " `$(SCRIPTS)/get-ec2-public-id.sh $(CLUSTER_NAME)-${MODULE}`

# Call this explicitly to upload scripts to s3
upload-artifacts: check-profile ## upload artifacts to S3 bucket
	@if [ -d "$(PWD)/artifacts/upload" ]; \
	then \
		mkdir -p $(PWD)/tmp ; \
		COPYFILE_DISABLE=1 tar zcvhf tmp/${MODULE}.tar.gz -C $(PWD)/artifacts/upload . ; \
		aws s3 --profile ${AWS_PROFILE} cp tmp/${MODULE}.tar.gz \
			s3://${AWS_ACCOUNT}-${CLUSTER_NAME}-config/artifacts/${MODULE}/upload/${MODULE}.tar.gz; \
		rm -rf $(PWD)/tmp ; \
	else \
		@echo "$(PWD)/artifacts/upload doesn't exit. Nothing to upload"; \
	fi

# Call this explicitly to upload scripts to s3
upload-config: check-profile  ## upload files in artifacts/upload to S3
	@if [ -d "$(PWD)/artifacts/upload" ]; \
	then \
		mkdir -p $(PWD)/tmp ; \
		COPYFILE_DISABLE=1 tar zcvhf tmp/${MODULE}.tar.gz -C $(PWD)/artifacts/upload . ; \
		aws s3 --profile ${AWS_PROFILE} cp tmp/${MODULE}.tar.gz \
			s3://${AWS_ACCOUNT}-${CLUSTER_NAME}-config/${MODULE}/config.tar.gz; \
		rm -rf $(PWD)/tmp ; \
	else \
		@echo "$(PWD)/artifacts/upload doesn't exit. Nothing to upload"; \
	fi

init: update-build ## setup terraform remote state
	@echo set remote state to s3://${TF_REMOTE_STATE_BUCKET}/${TF_REMOTE_STATE_PATH}

	@if ! aws s3 --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} ls s3://${TF_REMOTE_STATE_BUCKET}  &> /dev/null; \
	then \
		echo Creating bucket for remote state ... ; \
		aws s3 --profile ${AWS_PROFILE} \
			mb s3://${TF_REMOTE_STATE_BUCKET} --region ${TF_REMOTE_STATE_REGION}; \
		sleep 30; \
	fi
	@if [ "${ENABLE_REMOTE_VERSIONING}" = "true" ]; \
	then \
		echo Enable versioning... ; \
		aws s3api --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} put-bucket-versioning \
			--bucket ${TF_REMOTE_STATE_BUCKET} --versioning-configuration Status="Enabled" ; \
	fi
# Terraform remote S3 backend init
	@${TF_INIT}

remote-push: init ## terraform remote push
	@${TF_CMD} remote push

remote-pull: init ## terraform remote pull
	@${TF_CMD} remote pull

force-destroy-remote: update-build  ## destroy terraform remote state bucket
	@if aws s3 --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} ls s3://${TF_REMOTE_STATE_BUCKET}  &> /dev/null; \
	then \
		echo destroy bucket for remote state ... ; \
		aws s3 --profile ${AWS_PROFILE} rb s3://${TF_REMOTE_STATE_BUCKET} \
			--region ${TF_REMOTE_STATE_REGION} \
			--force ; \
	fi

upgrade-kube: ## upgrade k8s to version defined in TF_VAR_kube_version
	@echo "Will upgrade ${MODULE}'s Kubernetes to ${TF_VAR_kube_version}."
	@$(MAKE) confirm
	@$(MAKE)
	@echo "Don't forget to reboot ${MODULE}s."

# see https://github.com/docker/for-mac/issues/17#issuecomment-236517032
sync-docker-time: ## sync docker vm time with hardware clock
		@docker run --rm --privileged alpine hwclock -s

confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
  fi


.PHONY: init plan apply show output destroy clean remote-push remote-pull help
.PHONY: update-build update-ami update_user-data get-ips sync-docker-time
.PHONY: create-key upload-key destroy-key force-destroy-remote
