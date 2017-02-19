## Code Structure

File tree resource/module:

```
.
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── README.md
├── Vagrantfile
├── artifacts
│   └── secrets
│       └── api-server
│           ├── policy.jsonl
│           ├── token.csv
│           └── token.csv.sample
├── envs.sh
├── envs.sh.sample
├── resources
│   ├── artifacts
│   │   ├── cloud-config
│   │   │   ├── common-files.yaml.tmpl
│   │   │   ├── controller.yaml.tmpl
│   │   │   ├── files-vault.yaml
│   │   │   ├── s3-cloudconfig-bootstrap.sh
│   │   │   ├── s3-cloudconfig-bootstrap.sh.tmpl
│   │   │   ├── systemd-units-flannel.yaml
│   │   │   └── systemd-units.yaml
│   │   ├── kubedns-deployment.yaml
│   │   ├── kubedns-service.yaml
│   │   ├── kubernetes-dashboard.yaml
│   │   └── policies
│   │       ├── assume_role_policy.json
│   │       ├── deployment_policy.json
│   │       ├── kubernetes_policy.json
│   │       └── s3_remote_policy.json
│   ├── cloudtrail
│   │   └── cloudtrail.tf
│   ├── common
│   │   ├── common.mk
│   │   └── common.tf
│   ├── controller
│   │   ├── Makefile
│   │   ├── artifacts
│   │   │   ├── cloud-config.yaml.tmpl
│   │   │   ├── policy.json
│   │   │   └── upload
│   │   │       ├── install.sh
│   │   │       ├── policy.jsonl -> ../../../../artifacts/secrets/api-server/policy.jsonl
│   │   │       └── token.csv -> ../../../../artifacts/secrets/api-server/token.csv
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── elb.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   └── security-group.tf
│   ├── etcd
│   │   ├── Makefile
│   │   ├── artifacts
│   │   │   ├── cloud-config.yaml.tmpl
│   │   │   └── policy.json
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── iam
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── kubernetes.tf
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── kubectl
│   │   ├── Makefile
│   │   ├── envs.sh
│   │   └── provider.tf
│   ├── modules
│   │   ├── cloudtrail
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   ├── cluster
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   ├── efs-target
│   │   │   └── efs-target.tf
│   │   └── subnet
│   │       └── subnet.tf
│   ├── pki
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── pki.tf
│   │   └── provider.tf
│   ├── route53
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── s3
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── scripts
│   │   ├── allow-myip.sh
│   │   ├── aws-keypair.sh
│   │   ├── delete-all-object-versions.sh
│   │   ├── gen-provider.sh
│   │   ├── gen-rds-password.sh
│   │   ├── get-ami.sh
│   │   ├── get-dns-name.sh
│   │   ├── get-ec2-public-id.sh
│   │   ├── get-vpc-id.sh
│   │   ├── kube-aws-route.sh
│   │   ├── session-lock.sh
│   │   ├── tf-apply-confirm.sh
│   │   └── turn-off-source-dest-check.sh
│   ├── vault
│   │   ├── Makefile
│   │   ├── artifacts
│   │   │   ├── cloud-config.yaml.tmpl
│   │   │   ├── policy.json
│   │   │   └── upload
│   │   │       ├── install.sh
│   │   │       └── scripts
│   │   │           ├── create_ca.sh
│   │   │           ├── create_kube_ca.sh
│   │   │           ├── init-unseal.sh
│   │   │           ├── s3get.sh
│   │   │           ├── s3put.sh
│   │   │           └── utils
│   │   │               ├── env_defaults
│   │   │               └── functions
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── elb.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   └── variables.tf
│   ├── vpc
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── provider.tf
│   │   ├── vpc-subnet-controller.tf
│   │   ├── vpc-subnet-elb.tf
│   │   ├── vpc-subnet-etcd.tf
│   │   ├── vpc-subnet-vault.tf
│   │   ├── vpc-subnet-worker.tf
│   │   └── vpc.tf
│   └── worker
│       ├── Makefile
│       ├── artifacts
│       │   ├── cloud-config.yaml.tmpl
│       │   └── policy.json
│       ├── common.tf -> ../common/common.tf
│       ├── envs.sh
│       ├── main.tf
│       └── provider.tf
└── tmp

```
## Add a new module

    - mkdir -p resource/\<module\>
    - cd resource/\<module\>; ln -sf ../common/common.tf common.tf
    - cd resource/\<module\>; ln -sf ../common/common.mk Makefile, or include ../common/common.mk in module's customized Makefile
    - Add envs.sh to define module name, override auto-configuration parameters
    - Add a target and its dependencies in top level Makefile
    - Add "terraform_remote_state" in common.tf if the module output will be referened by other modules
