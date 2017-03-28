#!/bin/bash -e

# Initilize variables
init_vars() {
	# utilities
	bash_s3_repo="https://github.com/xuwang/bash-s3.git"
	work_dir=/root/bootstrap
	rm -rf $work_dir
	mkdir $work_dir
	install_dir=/opt/bin
	mkdir -p $install_dir

	# config bucket and file path
	export AWS_ACCOUNT=${AWS_ACCOUNT}
	export CLUSTER_NAME=${CLUSTER_NAME}
	export MODULE_NAME=${MODULE_NAME}
	export CONFIG_BUCKET=${CONFIG_BUCKET}
}

install_bash_s3() {
	cd $work_dir
	git clone --depth 1 $bash_s3_repo bash_s3
	install -m 0755 bash_s3/s3get.sh bash_s3/s3put.sh $install_dir

	GET=/opt/bin/s3get.sh
	PUT=/opt/bin/s3put.sh
}

do_setup() {
	config_tarball=config.tar.gz
	setup_cmd=setup.sh

	# get config and do setup
	mkdir -p $work_dir/setup
	cd $work_dir/setup
	$GET ${CONFIG_BUCKET} ${MODULE_NAME}/$config_tarball $config_tarball

	if [ -s "$config_tarball" ]; then
		tar zxvf $config_tarball
		if [ -s "$setup_cmd" ]; then
			bash $setup_cmd
		fi
	fi
}

get_cloudinit() {
	mkdir -p $work_dir/config
	cd $work_dir/config

	$GET ${CONFIG_BUCKET} ${MODULE_NAME}/cloud-config.yaml cloud-config.yaml

	if [ -s "cloud-config.yaml" ]; then
		# Run cloud-init
		coreos-cloudinit --from-file=cloud-config.yaml
	fi
}

do_cloudinit() {
	cd $work_dir/config
	if [ -s "cloud-config.yaml" ]; then
		# Run cloud-init
		coreos-cloudinit --from-file=cloud-config.yaml
	fi
}

init_vars
install_bash_s3
get_cloudinit
do_setup
do_cloudinit
