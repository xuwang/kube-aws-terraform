include ../../envs.sh
include envs.sh

AWS_USER := $(shell aws --profile ${AWS_PROFILE} iam get-user | jq -r ".User.UserName")
AWS_ACCOUNT := $(shell aws --profile ${AWS_PROFILE} iam get-user | jq -r ".User.Arn" | grep -Eo '[[:digit:]]{12}')
ALLOWED_ACCOUNT_IDS := "$(AWS_ACCOUNT)"

# Terraform commands
# Note: for production, set -refresh=true to be safe
TF_APPLY := terraform apply -refresh=true
# Note: for production, remove --force to confirm destroy.
TF_DESTROY := terraform destroy -force
TF_DESTROY_PLAN := terraform plan -destroy -refresh=true
TF_GET := terraform get
TF_GRAPH := terraform graph -module-depth=0
TF_PLAN := terraform plan -refresh=true
TF_SHOW := terraform show
TF_LIST := terraform state list
TF_REFRESH := terraform refresh
TF_TAINT := terraform taint -allow-missing
TF_OUTPUT := terraform output -json
#TF_LOG := debug

# TF environments
TF_REMOTE_STATE_PATH := "${MODULE}.tfstate"
TF_REMOTE_STATE_BUCKET := ${AWS_ACCOUNT}-${CLUSTER_NAME}-terraform

# tf files
TF_PROVIDER := provider.tf

# Timestamp for tagging resources
TF_VAR_timestamp := $(shell date +%Y-%m-%d-%H%M)
# Terraform state files
TF_VAR_secrets_path := ../../${SEC_PATH}
TF_VAR_artifacts_dir := ../artifacts
TF_VAR_app_repository := "git@example.com:user/app-repo.git"
TF_VAR_git_ssh_command := "ssh -i /root/.ssh/git-sync-rsa.pem -o 'StrictHostKeyChecking no'"
export

all: apply

init: | ${TF_PROVIDER} remote
	${TF_GET}

plan: init
	${TF_PLAN}

apply: init
	${TF_APPLY}

list: ${TF_PROVIDER} remote
	${TF_LIST}
show: ${TF_PROVIDER} remote
	${TF_SHOW}

output:
	@${TF_OUTPUT}

destroy-plan: ${TF_PROVIDER} remote
	@-${TF_DESTROY_PLAN} -out ${ROOT_DIR}/tmp/destroy-${MODULE}.plan
	
destroy: ${TF_PROVIDER} remote
	${TF_DESTROY}
	$(MAKE) clean

refresh: init
	${TF_REFRESH}

clean:
	rm -rf .terraform

remote-push: init
	terraform remote push

remote-pull: init
	terraform remote pull

help:
	@echo "make [ apply | init | remote | destroy | destroy-plan| help | show | output | refresh | remote-push | remote -pull | clean | update-user-data | upload-artifacts | force-destroy-remote ]"

${TF_PROVIDER}: 
	../scripts/gen-provider.sh > ${TF_PROVIDER}

update-profile:
	../scripts/gen-provider.sh > ${TF_PROVIDER}

create-key:
	../scripts/aws-keypair.sh -c $(CLUSTER_NAME)-${MODULE};

destroy-key:
	../scripts/aws-keypair.sh -d $(CLUSTER_NAME)-${MODULE};

get-ips:
	@echo "${MODULE}; public ips: " `$(SCRIPTS)/get-ec2-public-id.sh $(CLUSTER_NAME)-${MODULE}`

# Call this explicitly to re-load user_data
update-user-data:
	${TF_PLAN} -target=data.template_file.${MODULE}_cloud_config; \
	${TF_APPLY}
	
# Call this explicitly to upload scripts to s3 
upload-artifacts:
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

remote: ${TF_PROVIDER}
	@echo set remote state to s3://${TF_REMOTE_STATE_BUCKET}/${TF_REMOTE_STATE_PATH}

	@if ! aws s3 --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} ls s3://${TF_REMOTE_STATE_BUCKET}  &> /dev/null; \
	then \
		echo Creating bucket for remote state ... ; \
		aws s3 --profile ${AWS_PROFILE} \
			mb s3://${TF_REMOTE_STATE_BUCKET} --region ${TF_REMOTE_STATE_REGION}; \
		sleep 30; \
		if [ "${ENABLE_REMOTE_VERSIONING}" = "true" ]; \
		then \
			echo Enable versioning... ; \
			aws s3api --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} put-bucket-versioning \
				--bucket ${TF_REMOTE_STATE_BUCKET} --versioning-configuration Status="Enabled" ; \
    fi ; \
	fi
	# Terraform remote S3 backend init
	terraform init

force-destroy-remote:
	@if aws s3 --profile ${AWS_PROFILE} --region ${TF_REMOTE_STATE_REGION} ls s3://${TF_REMOTE_STATE_BUCKET}  &> /dev/null; \
	then \
		echo destroy bucket for remote state ... ; \
		aws s3 --profile ${AWS_PROFILE} rb s3://${TF_REMOTE_STATE_BUCKET} \
			--region ${TF_REMOTE_STATE_REGION} \
			--force ; \
	fi

upgrade-kube:
	@echo "Will upgrade ${MODULE}'s Kubernetes to ${TF_VAR_kube_version}."
	@$(MAKE) confirm
	@$(MAKE) 
	@echo "Don't forget to reboot ${MODULE}s."

confirm:
	@echo "CONTINUE? [Y/N]: "; read ANSWER; \
	if [ ! "$$ANSWER" = "Y" ]; then \
		echo "Exiting." ; exit 1 ; \
    fi

.PHONY: all remote plan apply show output destroy clean remote-push remote-pull help
.PHONY: update-profile update-ami update_user-data get-ips
.PHONY: create-key upload-key destroy-key force-destroy-remote
