# Env for master
export MODULE=master
export TF_VAR_module_name=${MODULE}

# Override default values
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=3
export TF_VAR_cluster_desired_capacity=1
export TF_VAR_instance_type=t2.medium
