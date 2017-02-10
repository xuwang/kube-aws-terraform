# Destroy the cluster

Sometimes during development phase, you might want to destroy some resources, but keep others. 
For example, you want to shutdown workers, but keep controller, etcd, vpc:

```
$ cd resources/worker
$ make plan-destroy
$ make destroy
```

To complete destroy everything, including the vault data, and terraform remote states:

```
$ make destroy-all
```



