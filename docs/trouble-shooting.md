# Common issues

* Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubev2/pki/kube-apiserver")

 Possibly there was an older kubeconfig for the same cluster name with different cert. Frequently occur during testing. To clear up previous confguration:

```console
$ kubectl config delete-context <clusername>
kubectl config delete-context <clustername>
warning: this removed your active context, use "kubectl config use-context" to select a different one
deleted context kubev2 from /Users/sfeng/.kube/configif you want to re-configure.
```
