## Files 

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
│           └── token.csv.sample
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
    │   ├── dashboard
    │   │   └── kubernetes-dashboard.yaml
    │   ├── envs.sh
    │   ├── kubedns
    │   │   ├── kubedns-deployment.yaml
    │   │   └── kubedns-service.yaml
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
    │   ├── common.tf -> ../common/common.tf
    │   ├── envs.sh
    │   ├── main.tf
    │   └── upload.tf
    ├── iam
    │   ├── Makefile -> ../common/common.mk
    │   ├── common.tf -> ../common/common.tf
    │   ├── envs.sh
    │   ├── kubernetes.tf
    │   └── main.tf
    ├── master
    │   ├── Makefile
    │   ├── artifacts
    │   │   ├── cloud-config.yaml.tmpl
    │   │   ├── policy.json
    │   │   ├── upload
    │   │   │   ├── get-certs.sh
    │   │   │   ├── policy.jsonl -> ../../../../artifacts/secrets/api-server/policy.jsonl
    │   │   │   └── setup.sh
    │   │   └── upload-templates
    │   │       └── envvars
    │   ├── common.tf -> ../common/common.tf
    │   ├── elb.tf
    │   ├── envs.sh
    │   ├── main.tf
    │   ├── security-group.tf
    │   ├── service-account-token.tf
    │   └── upload.tf
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
    │   │   │   ├── policy.jsonl -> ../../../../artifacts/secrets/api-server/policy.jsonl
    │   │   │   └── setup.sh
    │   │   └── upload-templates
    │   │       ├── envvars
    │   │       └── kubeconfig
    │   ├── common.tf -> ../common/common.tf
    │   ├── envs.sh
    │   ├── main.tf
    │   └── upload.tf
    ├── pki
    │   ├── Makefile -> ../common/common.mk
    │   ├── common.tf -> ../common/common.tf
    │   ├── envs.sh
    │   └── main.tf
    ├── route53
    │   ├── Makefile -> ../common/common.mk
    │   ├── common.tf -> ../common/common.tf
    │   ├── envs.sh
    │   └── main.tf
    ├── s3
    │   ├── Makefile -> ../common/common.mk
    │   ├── common.tf -> ../common/common.tf
    │   ├── envs.sh
    │   └── main.tf
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
    │   ├── common.tf -> ../common/common.tf
    │   ├── elb.tf
    │   ├── envs.sh
    │   ├── main.tf
    │   ├── upload.tf
    │   └── variables.tf
    └── vpc
        ├── Makefile -> ../common/common.mk
        ├── common.tf -> ../common/common.tf
        ├── envs.sh
        ├── vpc-subnet-elb.tf
        ├── vpc-subnet-etcd.tf
        ├── vpc-subnet-master.tf
        ├── vpc-subnet-node.tf
        ├── vpc-subnet-vault.tf
        └── vpc.tf

42 directories, 140 files
```
