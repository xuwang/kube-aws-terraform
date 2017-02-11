# Env for Worker

export MODULE=worker

# Workers ASG override
export TF_VAR_instance_type="t2.medium"
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=5
export TF_VAR_cluster_desired_capacity=2
