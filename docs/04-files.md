```
.
├── LICENSE
├── Makefile
├── README.md
├── apps
│   └── gitlab
│       ├── deploy.sh
│       ├── get-load-balancer.sh
│       ├── gitlab-rc.yml
│       ├── gitlab-svc.yml
│       ├── postgresql-rc.yml
│       ├── postgresql-svc.yml
│       ├── redis-rc.yml
│       ├── redis-svc.yml
│       └── teardown.sh
├── docs
│   ├── 00-run-book.md
│   ├── 01-aws-resources.md
│   ├── 02-vault-pki.md
│   ├── 03-configuration.md
│   ├── 04-files.md
│   ├── 05-manage-resources.md
│   └── 07-cleanup.md
├── envs.sh.sample
├── images
│   ├── dashboard.png
│   ├── ec2-instances.png
│   └── kube-monitor.png
└── resources
    ├── add-ons
    │   ├── Makefile
    │   ├── envs.sh
    │   ├── kube-system-admin-role-bindings.yaml
    │   ├── kubedns
    │   │   ├── kubedns-cm.yaml
    │   │   ├── kubedns-deployment.yaml
    │   │   ├── kubedns-sa.yaml
    │   │   └── kubedns-svc.yaml
    │   └── monitor
    │       ├── grafana-deployment.yaml
    │       ├── grafana-service.yaml
    │       ├── heapster-deployment.yaml
    │       ├── heapster-service.yaml
    │       ├── influxdb-deployment.yaml
    │       └── influxdb-service.yaml
    ├── artifacts
    │   ├── policies
    │   │   ├── assume_role_policy.json
    │   │   ├── deployment_policy.json
    │   │   ├── kubernetes_policy.json
    │   │   └── s3_remote_policy.json
    │   └── user-data-s3-bootstrap.sh
    ├── cloudtrail
    │   └── cloudtrail.tf
    ├── common
    │   ├── common.mk
    │   └── common.tf
    ├── etcd
    │   ├── Makefile
    │   ├── artifacts
    │   │   ├── cloud-config.yaml.tmpl
    │   │   └── policy.json
    │   ├── envs.sh
    │   └── tf
    │       ├── main.tf
    │       └── upload.tf
    ├── iam
    │   ├── Makefile
    │   ├── envs.sh
    │   └── tf
    │       ├── kubernetes.tf
    │       └── main.tf
    ├── master
    │   ├── Makefile
    │   ├── artifacts
    │   │   ├── cloud-config.yaml.tmpl
    │   │   ├── policy.json
    │   │   ├── upload
    │   │   │   ├── get-certs.sh
    │   │   │   └── setup.sh
    │   │   └── upload-templates
    │   │       └── envvars
    │   ├── envs.sh
    │   └── tf
    │       ├── elb.tf
    │       ├── main.tf
    │       ├── security-group.tf
    │       └── upload.tf
    ├── modules
    │   ├── cloudtrail
    │   │   ├── main.tf
    │   │   └── variables.tf
    │   ├── cluster
    │   │   ├── main.tf
    │   │   └── variables.tf
    │   └── cluster-no-opt-data
    │       ├── main.tf
    │       └── variables.tf
    ├── node
    │   ├── Makefile
    │   ├── artifacts
    │   │   ├── cloud-config.yaml.tmpl
    │   │   ├── policy.json
    │   │   ├── upload
    │   │   │   ├── get-certs.sh
    │   │   │   └── setup.sh
    │   │   └── upload-templates
    │   │       ├── envvars
    │   │       ├── kube-proxy-kubeconfig
    │   │       └── kubelet-kubeconfig
    │   ├── envs.sh
    │   └── tf
    │       ├── main.tf
    │       └── upload.tf
    ├── pki
    │   ├── Makefile -> ../common/common.mk
    │   ├── envs.sh
    │   └── tf
    │       └── main.tf
    ├── route53
    │   ├── Makefile -> ../common/common.mk
    │   ├── envs.sh
    │   └── tf
    │       └── main.tf
    ├── s3
    │   ├── Makefile -> ../common/common.mk
    │   ├── envs.sh
    │   └── tf
    │       └── main.tf
    ├── scripts
    │   ├── allow-myip.sh
    │   ├── aws-keypair.sh
    │   ├── delete-all-object-versions.sh
    │   ├── gen-provider.sh
    │   ├── gen-rds-password.sh
    │   ├── get-ami.sh
    │   ├── get-dns-name.sh
    │   ├── get-ec2-public-id.sh
    │   ├── get-vpc-id.sh
    │   ├── session-lock.sh
    │   └── tf-apply-confirm.sh
    ├── vault
    │   ├── Makefile
    │   ├── artifacts
    │   │   ├── cloud-config.yaml.tmpl
    │   │   ├── policy.json
    │   │   ├── upload
    │   │   │   ├── scripts
    │   │   │   │   ├── create_ca.sh
    │   │   │   │   ├── create_kube_ca.sh
    │   │   │   │   ├── create_kube_config.sh
    │   │   │   │   ├── gen-vault-cert.sh
    │   │   │   │   ├── init-unseal.sh
    │   │   │   │   └── utils
    │   │   │   │       ├── env_defaults
    │   │   │   │       └── functions
    │   │   │   └── setup.sh
    │   │   └── upload-templates
    │   │       ├── envvars
    │   │       ├── vault.cnf
    │   │       ├── vault.hcl
    │   │       └── vault.sh
    │   ├── envs.sh
    │   └── tf
    │       ├── elb.tf
    │       ├── main.tf
    │       ├── upload.tf
    │       └── variables.tf
    └── vpc
        ├── Makefile
        ├── envs.sh
        └── tf
            ├── vpc-subnet-elb.tf
            ├── vpc-subnet-etcd.tf
            ├── vpc-subnet-master.tf
            ├── vpc-subnet-node.tf
            ├── vpc-subnet-vault.tf
            └── vpc.tf

47 directories, 130 files

```
