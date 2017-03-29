#!/bin/bash -e

# Initilize variables
init_vars() {
	# utilities
	BASH_S3_REPO=https://github.com/xuwang/bash-s3.git
	# aws ec2 meta_data
	META_DATA=169.254.169.254/latest/meta-data

	export OPT_BIN=/opt/bin
	mkdir -p $OPT_BIN

	export WORK_DIR=/root/bootstrap
	rm -rf $WORK_DIR
	mkdir $WORK_DIR
	cd $WORK_DIR

	# config bucket,file path, and ips
	echo export AWS_ACCOUNT=${AWS_ACCOUNT}		> envs.sh
	echo export CLUSTER_NAME=${CLUSTER_NAME}	>> envs.sh
	echo export MODULE_NAME=${MODULE_NAME}		>> envs.sh
	echo export CONFIG_BUCKET=${CONFIG_BUCKET}	>> envs.sh
	echo export COREOS_PRIVATE_IPV4=$(curl -s $META_DATA/local-ipv4) >> envs.sh
	echo export COREOS_PUBLIC_IPV4=$(curl -s $META_DATA/public-ipv4) >> envs.sh
	
	source envs.sh
}

install_bash_s3() {
	cd $WORK_DIR
	git clone --depth 1 $BASH_S3_REPO bash_s3
	install -m 0755 bash_s3/s3get.sh bash_s3/s3put.sh $OPT_BIN

	GET=/opt/bin/s3get.sh
	PUT=/opt/bin/s3put.sh
}

do_setup() {
	config_tarball=config.tar.gz
	setup_cmd=setup.sh

	# get config and do setup
	mkdir -p $WORK_DIR/setup
	cd $WORK_DIR/setup
	$GET ${CONFIG_BUCKET} ${MODULE_NAME}/$config_tarball $config_tarball

	if [ -s "$config_tarball" ]; then
		tar zxvf $config_tarball
		if [ -s "$setup_cmd" ]; then
			bash $setup_cmd
		fi
	fi
}

get_cloudinit() {
	mkdir -p $WORK_DIR/config
	cd $WORK_DIR/config

	$GET ${CONFIG_BUCKET} ${MODULE_NAME}/cloud-config.yaml cloud-config.yaml

	if [ -s "cloud-config.yaml" ]; then
		# Run cloud-init
		coreos-cloudinit --from-file=cloud-config.yaml
	fi
}

do_cloudinit() {
	cd $WORK_DIR/config
	if [ -s "cloud-config.yaml" ]; then
		# Run cloud-init
		coreos-cloudinit --from-file=cloud-config.yaml
	fi
}

# Main
init_vars
install_bash_s3
get_cloudinit
do_setup
do_cloudinit
