## Manage individual platform resources

Using Terraform to manage AWS resources means you can do incremental changes safely. 
You can plan, show, apply, destroy resources. For example, you wan to change node's instance type or re-size the 
autoscaling group, or update cloud-configurtaion to add systemd units etc.

In general you can manage resources like this:

```
$ cd resources/<resourcename>
$ make plan
$ make
$ make output
$ make show
```

If you no longer need the resource:

```
$ make plan-destroy
$ make destroy
```
