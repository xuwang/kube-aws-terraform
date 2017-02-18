
# Cluster Run Book

- [How to login to instances](#login)
- [How to update cloud-config](#update-cloud-config)
- [How to add more Terraform modules, such as elb, efs, rds](#add-modules)
- [How to verify controller, etcd, worker service status](#service-verification)
- [How to run a test pod](#smoke-test)
- [How to upgrade vault binary](#upgrade-vault)
- [How to upgrade kubernetes binaries](#upgrade-kubernetes)
- [How to upgrade cluster operating system](#upgrade-instances-operating-system)

## Login

For trouble-shooting, you can login to etcd, controller, and workers. First make sure the AWS instance key pairs are already
added to ssh agent:
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

## Upgrade Kubernetes

* Edit envs.sh file to change the version of Kubernetes, as show in bellow example:
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
## Upgrade Instances Operating System

All machines are running CoreOS image. With auto-update enabled, CoreOS and etcd binaries will be upgraded automatically when CoreOS has new release. 
