# Cluster Run Book

- [How to login to instances](#login)
- [How to update cloud-config](#update-cloud-config)
- [How to verify services status](#service-verification)
- [How to upgrade kubernetes binaries](#upgrade-kubernetes)
- [How to add more Terraform modules, such as elb, efs, rds](#add-modules)
- [How to upgrade vault binary](#upgrade-vault)
- [How to upgrade cluster operating system](#upgrade-instances-operating-system)

## Login

For trouble-shooting, you can login to etcd, controller, and workers. First make sure the AWS instance key pairs are already added to ssh agent:
```
$ ssh-add -l
2048 SHA256:h9ps0iAK8QeptEzNcvLEQRIZVl7kam7gTD5InP2Sqbk /Users/xxxxx/.ssh/kubev1-vault.pem (RSA)
2048 SHA256:7rzk7bd6AZU7cW+vkfi0Nr79FIZfb7O0jRxfLXCmXUM /Users/xxxxx/.ssh/kubev1-etcd.pem (RSA)
2048 SHA256:FLveXZTsgOrmCp9iwJiNVK6suYeN/ARkk5snY4We/q8 /Users/xxxxx/.ssh/kubev1-controller.pem (RSA)
2048 SHA256:z6YWKb75hb3BLaxtVWQFAXg3Lgfm1kqg/KBSCitAJpk /Users/xxxxx/.ssh/kubev1-worker.pem (RSA)
```

If not, add necessary key to ssh agent:

```
$ ssh-add /Users/xxxxx/.ssh/kubev1-controller.pem
$ cd resources/controller
$ make get-ips
controller; public ips:  <aws-profile-name> 52.36.180.132
$ ssh core@52.36.180.132
core@ip-10-240-10-80-kubev1-controller ~ $
```

Same for worker, etcd nodes.

## Update Cloud Config

All machines use the same script ('user-data') to bootstrap. The bootstrap uses role-based IAM policy to download the
machine's own cloud-config.yaml and run cloud-init to setup the machine. This second stage bootstrapping gives us the flexibilty of changing cloud-config without having to re-provisioned the machine. All you need to do is to reboot the machine. 

Cloud config contains system units and post-installation scripts. Per resource **cloud-config.yaml.tmpl** file is located at resources/\<controller|worker|etcd|vault\>/artifacts/cloug-config.yaml.tmpl. The generated cloud-config.yaml file is uploaded to the resource's specific s3 bucket and will be picked up at each reboot. 

To upload a new file after modifying the **cloud-config.yaml.tmpl**:

```
$ cd resources/<controller|worker|etcd|vault>
$ make update-user-data
```
When you reboot etcd, controllers, wait the cluster has elected new leaders before rebooting another one.

## Service Verification

This verifies controller installation status.
```
$ cd resources/controller
$ make get-ips
$ ssh core@52.36.180.132 "cd /etc/systemd/system; systemctl status kube-*" | less
```
This verifies worker's installation status.
```
$ cd resources/worker
$ make get-ips
$ ssh core@52.36.180.132 "cd /etc/systemd/system; systemctl status kube*" | less
```

## Upgrade Kubernetes binaries

Read Kubernetes release notes to make necessary configuration changes. Ideally use a test environment to test out the new releases.

* Edit envs.sh file to change the version of Kubernetes, as shown in bellow example:

```
export TF_VAR_kube_version="v1.5.3"
```

* Update systemd install-kubernetes unit

```
$ make upgrade-kube
```

* Reboot each controller and workers to pickup new configurations. To validate:

```
$ /opt/bin/kubectl version
```

## Add modules

- mkdir -p resource/\<module\>
- cd resource/\<module\>; ln -sf ../common/common.tf common.tf
- cd resource/\<module\>; ln -sf ../common/common.mk Makefile, or include ../common/common.mk in module's customized Makefile
- Add envs.sh to define module name, override auto-configuration parameters
- Add a target and its dependencies in top level Makefile
- Add "terraform_remote_state" in common.tf if the module output will be referened by other modules

## Upgrade-Vault

* Find TF_VAR_vault_release in envs.sh, and change it like so:

```
# Vault release: restart vault service if changed
export TF_VAR_vault_release=0.6.4
```

* Change vault's configuration and restart vault

```
$ cd resources/vault
$ make
$ make get-ips
$ ssh core@<vault-ip>
$ sudo reboot
```

## Upgrade Instances Operating System

All machines are running CoreOS image. With auto-update enabled, CoreOS and etcd binaries will be upgraded automatically when CoreOS has new release. 


