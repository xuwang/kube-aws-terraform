## File tree

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
├── artifacts
│   └── secrets
│       └── api-server
│           ├── policy.jsonl
│           ├── token.csv
│           └── token.csv.sample
├── docs
│   ├── 00-run-book.md
│   ├── 01-aws-resources.md
│   ├── 02-vault-pki.md
│   ├── 03-configuration.md
│   ├── 04-files.md
│   ├── 05-manage-resources.md
│   └── 07-cleanup.md
├── envs.sh
├── envs.sh.sample
├── images
│   ├── dashboard.png
│   ├── ec2-instances.png
│   └── kube-monitor.png
├── resources
│   ├── add-ons
│   │   ├── Makefile
│   │   ├── dashboard
│   │   │   └── kubernetes-dashboard.yaml
│   │   ├── envs.sh
│   │   ├── kubedns
│   │   │   ├── kubedns-deployment.yaml
│   │   │   └── kubedns-service.yaml
│   │   └── monitor
│   │       ├── grafana-deployment.yaml
│   │       ├── grafana-service.yaml
│   │       ├── heapster-deployment.yaml
│   │       ├── heapster-service.yaml
│   │       ├── influxdb-deployment.yaml
│   │       └── influxdb-service.yaml
│   ├── artifacts
│   │   ├── cloud-config
│   │   │   ├── common-files.yaml.tmpl
│   │   │   ├── files-vault.yaml
│   │   │   ├── s3-cloudconfig-bootstrap.sh
│   │   │   ├── s3-cloudconfig-bootstrap.sh.tmpl
│   │   │   ├── systemd-units-flannel.yaml
│   │   │   └── systemd-units.yaml
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
│   ├── modules
│   │   ├── cloudtrail
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   ├── cluster
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   └── subnet
│   │       └── subnet.tf
│   ├── pki
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
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
│   │   ├── session-lock.sh
│   │   └── tf-apply-confirm.sh
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

40 directories, 141 files
```
