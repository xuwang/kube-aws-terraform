# Etcd2 to Etcd3 Migration notes

WARNING: These are just  working notes to provide some high level migration steps. You need througly understand etcd backup, restore process and do your own research on etcd2->etcd3 cluster migration kubernetes data store etcd2->etcd3 migration.

## Upgrade references

Here is a collection of migration references. Please read them carefully before upgrade.

* [Migrating applications, clusters, and Kubernetes to etcd v3](https://coreos.com/blog/migrating-applications-etcd-v3.html)

* [etcd2 to etcd 3 rolling upgrade](https://github.com/coreos/etcd/tree/master/Documentation/upgrades)


## Prerequisite

* Have a test system

* If you only has one etcd instance, it's better to make it a 3 etcd cluster so you can perform rolling upgrade without service outage. You can change the capacity in `resources/etcd/envs.sh` file.

* Make sure the cluster is healthy

```
$ etcdctl cluster-health
```

## High Level Upgrade steps

* Update to the latest repo, which replaces CoreOS build-in etcd2 service with  `etcd-member.service` in cloud-config. The following will update the etcd cluster cloud-config to install etcd-member configuration drop-in:

```
$ git pull
$ cd resources/etcd
$ make plan
$ make apply
```

* Rolling upgrade: carefully follow [etcd2 to etcd 3 rolling upgrade](https://github.com/coreos/etcd/tree/master/Documentation/upgrades) guide. In particularly, make a backup; do one server at a time until success; You may need to change ETCD_IMAGE_TAG to go through etcd2.3.7 to etcd 3.0.x, 3.1.x, 3.2.x. Make sure the cluster is at the same version before upgrade to the next.

* To verify etcd version:

```console
endpoints="10.240.2.4:2379,10.240.2.20:2379,10.240.2.23:2379"
core@ip-10-240-2-20-kube-lab-etcd ~ $ ETCDCTL_API=3 etcdctl --endpoints $endpoints --insecure-skip-tls-verify --cert=/etc/etcd/certs/etcd-server.pem  --key=/etc/etcd/certs/etcd-server-key.pem -w table endpoint status
+------------------+------------------+---------+---------+-----------+-----------+------------+
|     ENDPOINT     |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+------------------+------------------+---------+---------+-----------+-----------+------------+
|  10.240.2.4:2379 | 6bcdbddce03fec3d |  3.1.10 |   25 kB |      true |      2418 |   49022235 |
| 10.240.2.20:2379 | 97f7eb3e9d4e858c |  3.1.10 |   25 kB |     false |      2418 |   49022235 |
| 10.240.2.23:2379 | 9d30b834fdfd2ffa |  3.1.10 |   25 kB |     false |      2418 |   49022235 |
+------------------+------------------+---------+---------+-----------+-----------+------------+

```

or:

```consolecore@ip-10-240-2-20-kube-lab-etcd ~ $ rkt list
UUID		APP	IMAGE NAME			STATE	CREATED		STARTED		NETWORKS
77d53649	etcd	quay.io/coreos/etcd:v3.1.10	running	6 hours ago	6 hours ago
```

## Migerate Kubernetes etcd2 data store to etcd3 data store

The previous KAT's kube-apiserver has etcd2 storage-backend. Since etcd3 image supports both etcd2 and etcd3 protocol, you can
delay data migration to another time, but the latest KAT repo uses etcd3 storage backend by default, you might want to migrate before you do next api server upgrade. Please verify your etcd2 backend kube-apiserver still works before you upgrade kube-apiserver. 

Stop all etcd services so no data change during the etcd2 data converstion:

```console

# systemctl stop etcd-member

ETCDCTL_API=3 etcdctl migrate --data-dir /var/lib/etcd
using default transformer
2017-10-12 00:47:05.301760 I | etcdserver/membership: added member c612d8cf8b3c0efd [https://10.240.2.20:2380] to cluster 0
2017-10-12 00:47:05.301978 N | etcdserver/membership: set the initial cluster version to 3.2
2017-10-12 00:47:05.302002 I | etcdserver/api: enabled capabilities for version 3.2
finished transforming keys

```
Start all etcd services.

Verify:

```console
$ ETCDCTL_API=3 etcdctl --endpoints=10.240.2.20:2379 get /registry --prefix --keys-only --insecure-skip-tls-verify --cert=/etc/etcd/certs/etcd-server.pem  --key=/etc/etcd/certs/etcd-server-key.pem
registry/apiregistration.k8s.io/apiservices/v1.

/registry/apiregistration.k8s.io/apiservices/v1.authentication.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.authorization.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.autoscaling

/registry/apiregistration.k8s.io/apiservices/v1.batch

/registry/apiregistration.k8s.io/apiservices/v1.networking.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.storage.k8s.io

...

```

* Upgrade kube-master in the similar way:

```
$ cd resources/master
$ make plan
$ make apply
```

Reboot master.
