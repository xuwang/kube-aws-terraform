include ../common/common.mk

init: create-key upload-config

destroy: destroy-key empty-vault-bucket
empty-vault-bucket:
	@if aws s3 --profile ${AWS_PROFILE} ls s3://${AWS_ACCOUNT}-${CLUSTER_NAME}-vault-s3-backend  &> /dev/null; \
	then \
		aws s3 --profile ${AWS_PROFILE}  rm s3://${AWS_ACCOUNT}-${CLUSTER_NAME}-vault-s3-backend --recursive; \
	fi
