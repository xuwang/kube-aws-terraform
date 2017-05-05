include ../common/common.mk

check-blackhole: ## Check blackhole routing tables
	@aws --region ${AWS_REGION} --profile ${AWS_PROFILE} ec2 describe-route-tables \
	 	--filters Name=route.state,Values=blackhole | \
		jq '.RouteTables[].Routes[] | select(.State == "blackhole")'

ssh-master: ## Login to a master
	@cd ../master; $(MAKE) ssh
ssh-etcd: ## Login to an etcd
	@cd ../etcd; $(MAKE) ssh
ssh-node: ## Login to a node
	@cd ../node; $(MAKE) ssh
ssh-vault: ## Login to a node
	@cd ../vault; $(MAKE) ssh
