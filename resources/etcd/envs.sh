# Env for VPC

export MODULE=etcd
export TF_VAR_module_name=${MODULE}

# Override default values to make sure we have odd number of etcd servers
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=${TF_VAR_cluster_min_size}
export TF_VAR_cluster_desired_capacity=${TF_VAR_cluster_min_size}
export TF_VAR_coreos_update_channel=${COREOS_UPDATE_CHANNEL}
export TF_VAR_instance_type=t2.medium
