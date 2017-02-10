To check status of kubernetes services, for example, kubelet:

```
$ cd resources/worker
$ ssh-add $HOME/.ssh/kube-cluster-worker.pem
$ make get-ops
$ ssh core@52.27.156.202 "cd /etc/systemd/system; systemctl status kubelet"
```

# Cluster Run Book

- [Login to instances](#login-to-instance)
- [Update cloud-config](#update-cloud-config)
- [Upgrade Kubernetes binaries](upgrade-kubernetes-binaries)
- [Add a new Terraform modules, such as elb, efs, rds](#add-modules)
- [Verify controller, etcd, worker service status](#service-verification)
- [How to run a test pod](#smoke-test)
- [How to upgrade vault binary](#upgrade-vault)
- [Upgrade etcd cluster](#upgrade-etcd)


## Login to intance

To login to controller:

```
$ cd resources/controller
$ make get-ips
$ ssh-add ~/.ssh/<cluster-name>-controller.pem
$ ssh core@<controller-ip>
```

Same for worker, etcd nodes.

## Update Cloud Config

All machines use the same script ('user-data') to bootstrap. The bootstrap will use role-based IAM policy to download the
machine's own cloud-config.yaml and run cloud-init to setup the machine. This second stage bootstrapping gives us the flexibilty of changing cloud-config without having to re-provisioned the machine. All you need to do is to reboot the machine. 

To update cloud-config for worker (same for etcd, controller):

```
$ edit resources/worker/artifacts/cloud-config/cloud-config.yaml.tmpl
$ cd resources/worker
$ make update-user-data
```
Then reboot each worker node.

In HA mode, when you reboot etcd, controllers, wait the cluster has elected new leaders before rebooting another one. 

## Upgrade Kubernetes binaries

Read Kubernetes release notes to make necessary configuration changes. Ideally use a test environment to test out the new releases.

First, hange TF_VAR_kube_versoin in envs.sh, e.g. to v1.5.2, then run:
```
$ cd resources/worker
$ make update-user-data
```
Reboot worker one at a time.

## Add modules

- mkdir -p resource/\<module\>
- cd resource/\<module\>; ln -sf ../common/common.tf common.tf
- cd resource/\<module\>; ln -sf ../common/common.mk Makefile, or include ../common/common.mk in module's customized Makefile
- Add envs.sh to define module name, override auto-configuration parameters
- Add a target and its dependencies in top level Makefile
- Add "terraform_remote_state" in common.tf if the module output will be referened by other modules



