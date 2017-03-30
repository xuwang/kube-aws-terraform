# Destroy the cluster

During development phase, you might want to destroy some resources, but keep others. 
For example, you want to shutdown nodes, but keep master, etcd, vpc:

```
$ cd resources/node
$ make plan-destroy
$ make destroy
```

To complete destroy everything, including the vault data, and Terraform remote states, run this at
the repo's top level:

```
$ make teardown
```



