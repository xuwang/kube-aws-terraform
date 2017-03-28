#!/bin/bash -e


# Initilize variables
init_vars() {
	# utilities
	bash_s3_repo="https://github.com/xuwang/bash-s3.git"
	work_dir=/root
	install_dir=/opt/bin
	
	# config bucket and file path
	export AWS_ACCOUNT=${AWS_ACCOUNT}
	export CLUSTER_NAME=${CLUSTER_NAME}
	export MODULE_NAME=${MODULE_NAME}
	export CONFIG_BUCKET=${CONFIG_BUCKET}
}

install_bash_s3() {
	cd $work_dir
	git clone --depth 1 $bash-s3-repo bash-s3
	install -m 0755 bash-s3/s3get.sh bash-s3/s3put.sh $install_dir

	GET=/opt/bin/s3get.sh
	PUT=/opt/bin/s3put.sh

	# cleanup
	# rm -rf bash-s3
}

do_setup() {
  	config_tarball=config.tar.gz
  	setup_cmd=setup.sh

	# get config and do setup
	cd $work_dir
	mkdir -p setup
	cd setup
	$GET ${CONFIG_BUCKET} ${MODULE_NAME}/$config_tarball $config_tarball

	if [ -s "$config_tarball" ]; then
		tar zxvf $config_tarball
		if [ -s "$setup_cmd" ]; then
			bash $setup_cmd
		fi
	fi
	# cleanup
	cd $work_dir
	# rm -rf setup

}

do_cloudinit() {
	mkdir -p $work_dir/config
	cd $work_dir/config

	$GET ${CONFIG_BUCKET} ${MODULE_NAME}/cloud-config.yaml cloud-config.yaml

	if [ -s "cloud-config.yaml" ]; then
		# Create /etc/environment file so the cloud-init can get IP addresses
		coreos_env='/etc/environment'
		if [ ! -f $coreos_env ];
		then
		    echo "COREOS_PRIVATE_IPV4=$private_ipv4" > /etc/environment
		    echo "COREOS_PUBLIC_IPV4=$public_ipv4" >> /etc/environment
		    echo "INSTANCE_PROFILE=$instanceProfile" >> /etc/environment
		fi

		# Run cloud-init
		coreos-cloudinit --from-file=cloud-config.yaml
	fi
	# cleanup
	cd $work_dir
	# rm -rf config
}

init_vars
install_bash_s3
do_setup
do_cloudinit
