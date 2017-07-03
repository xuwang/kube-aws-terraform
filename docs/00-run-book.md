# Cluster Run Book

- [How to login to instances](#login)
- [How to update cloud-config](#update-cloud-config)
- [How to scale the cluster](#scaling-the-cluster)
- [How to verify services status](#service-verification)
- [How to upgrade kubernetes binaries](#upgrade-kubernetes)
- [How to add more Terraform modules, such as elb, efs, rds](#add-modules)
- [How to upgrade vault binary](#upgrade-vault)
- [How to upgrade cluster operating system](#upgrade-instances-operating-system)

## Login

For trouble-shooting, you can login to etcd, master, and nodes. First make sure the AWS instance key pairs are already added to ssh agent:
```
$ ssh-add -l
2048 SHA256:h9ps0iAK8QeptEzNcvLEQRIZVl7kam7gTD5InP2Sqbk /Users/xxxxx/.ssh/kubev1-vault.pem (RSA)
2048 SHA256:7rzk7bd6AZU7cW+vkfi0Nr79FIZfb7O0jRxfLXCmXUM /Users/xxxxx/.ssh/kubev1-etcd.pem (RSA)
2048 SHA256:FLveXZTsgOrmCp9iwJiNVK6suYeN/ARkk5snY4We/q8 /Users/xxxxx/.ssh/kubev1-master.pem (RSA)
2048 SHA256:z6YWKb75hb3BLaxtVWQFAXg3Lgfm1kqg/KBSCitAJpk /Users/xxxxx/.ssh/kubev1-node.pem (RSA)
```

If not, add necessary key to ssh agent:

```
$ ssh-add /Users/xxxxx/.ssh/kubev1-master.pem
$ cd resources/master
$ make get-ips
master; public ips:  <aws-profile-name> 52.36.180.132
$ ssh core@52.36.180.132
core@ip-10-240-10-80-kubev1-master ~ $
```

Same for node, etcd nodes.

## Update Cloud Config

All machines use the same script ('user-data') to bootstrap. The bootstrap uses role-based IAM policy to download the
machine's own cloud-config.yaml and run cloud-init to setup the machine. This second stage bootstrapping gives us the flexibilty of changing cloud-config without having to re-provisioned the machine. All you need to do is to reboot the machine.

Cloud config contains system units and post-installation scripts. Per resource **cloud-config.yaml.tmpl** file is located at resources/\<master|node|etcd|vault\>/artifacts/cloug-config.yaml.tmpl. The generated cloud-config.yaml file is uploaded to the resource's specific s3 bucket and will be picked up at each reboot.

To upload a new file after modifying the **cloud-config.yaml.tmpl**:

```
$ cd resources/<master|node|etcd|vault>
$ make update-user-data
```
When you reboot etcd, masters, wait the cluster has elected new leaders before rebooting another one.

## Scaling the Cluster

You re-size master, node, vault, and etcd autoscaling group by overriding the default vaules defined in **enva.sh**.

NOTE: For etcd autoscaling group, use 1,3,5,7.. odd number and make min=max=desired. For production, use at least 3 to begin with for high availability.

Here is an example of adding more nodes:

In **resources/node/envs.sh** file, change the capacity you want:

```
# Workers ASG override
export TF_VAR_instance_type="m3.large"
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=10
export TF_VAR_cluster_desired_capacity=5
```

Updating the autoscaling group

```
$ cd resources/node
$ make
```

## Service Verification

This verifies master installation status.
```
$ cd resources/master
$ make get-ips
$ ssh core@52.36.180.132 "cd /etc/systemd/system; systemctl status kube-*" | less
```
This verifies node's installation status.
```
$ cd resources/node
$ make get-ips
$ ssh core@52.36.180.132 "cd /etc/systemd/system; systemctl status kube*" | less
```

## Upgrade Kubernetes

Read Kubernetes release notes to make necessary configuration changes. Ideally use a test environment to test out the new releases.

* Edit envs.sh file to change the version of Kubernetes, as shown in bellow example:

```
export TF_VAR_kube_version="v1.6.6"
```

* Update systemd install-kubernetes unit

```
$ make upgrade-kube
```

* Reboot each master and nodes to pickup new configurations. To validate:

```
$ /opt/bin/kubectl version
```

## Add modules

- mkdir -p resource/\<module\>
- cd resource/\<module\>; ln -sf ../common/common.tf common.tf
- cd resource/\<module\>; ln -sf ../common/common.mk Makefile, or include ../common/common.mk in module's customized Makefile
- Add envs.sh to define module name, override auto-configuration parameters
- Add a target and its dependencies in top level Makefile
- Add "terraform_remote_state" in common.tf if the module output will be referenced by other modules

## Upgrade-Vault

* Find TF_VAR_vault_release in envs.sh, and change it like so:

```
# Vault release: restart vault service if changed
export TF_VAR_vault_release=0.7.0
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
