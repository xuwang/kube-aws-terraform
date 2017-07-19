include envs.sh

AWS_ACCOUNT := $(shell aws --profile ${AWS_PROFILE} sts get-caller-identity --output text --query 'Account')
ROUTE53_ZONE_ID := $(shell aws --profile ${AWS_PROFILE} route53 list-hosted-zones --output json | \
		jq -r --arg ROUTE53_ZONE_NAME "${ROUTE53_ZONE_NAME}" '.HostedZones[] | \
		select(.Name=="${ROUTE53_ZONE_NAME}.") | .Id ' | cut -d'/' -f 3)

ALLOWED_ACCOUNT_IDS := "$(AWS_ACCOUNT)"
ifdef AWS_ROLE_NAME
	AWS_ROLE_ARN := arn:aws:iam::${AWS_ACCOUNT}:role/${AWS_ROLE_NAME}
endif

TF_REMOTE_STATE_BUCKET := ${AWS_ACCOUNT}-${CLUSTER_NAME}-terraform-public
TF_REMOTE_STATE_PATH := "route53.tfstate"

BUILD_DIR := ${PWD}/build

# Timestamp for tagging resources
TF_VAR_timestamp := $(shell date +%Y-%m-%d-%H%M)
# Terraform dir referenced in container
TF_VAR_build_dir := /build

TF_VERSION := light
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

export

help: ## this info
	@# adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo '_________________'
	@echo '| Make targets: |'
	@echo '-----------------'
	@cat Makefile | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort -k1,1

update-build: check-profile ## create or update build dir for terraform
	@mkdir -p ${BUILD_DIR}
# copy local tf files to build dir
	@cp -rf tf/* ${BUILD_DIR}
# generate docker env-file for tf vars and aws profile
	@env | grep 'TF_VAR\|AWS_' | grep -v 'TF_CMD' > ${BUILD_DIR}/tf.env
# generate tf provider file
	@scripts/gen-provider.sh > ${BUILD_DIR}/provider.tf

check-profile: ## validate AWS profile
	@if ! aws --profile ${AWS_PROFILE} sts get-caller-identity --output text --query 'Account'> /dev/null 2>&1 ; then \
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

destroy: init ## terraform destroy
	@aws --profile ${AWS_PROFILE} route53 list-resource-record-sets --hosted-zone-id=${ROUTE53_ZONE_ID} | jq '.ResourceRecordSets[]'
	@echo Destroy ${ROUTE53_ZONE_NAME} with these records?
	@$(MAKE) confirm
	@${TF_APPLY} -var route53_zone_force_destroy="true"
	@${TF_DESTROY}
	$(MAKE) clean

clean: ## delete build dir
	rm -rf ${BUILD_DIR}

init: sync-docker-time update-build ## setup terraform remote state
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

force-destroy-remote: update-build  ## destroy terraform remote state bucket
	@if aws s3 --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} ls s3://${TF_REMOTE_STATE_BUCKET}  &> /dev/null; \
	then \
		echo destroy bucket for remote state ... ; \
		aws s3 --profile ${AWS_PROFILE} rb s3://${TF_REMOTE_STATE_BUCKET} \
			--region ${TF_REMOTE_STATE_REGION} \
			--force ; \
	fi

# see https://github.com/docker/for-mac/issues/17#issuecomment-236517032
sync-docker-time: ## sync docker vm time with hardware clock
	@docker run --rm --privileged alpine hwclock -s

confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
	fi

.PHONY: init plan apply show output destroy sync-docker-time help force-destroy-remote
