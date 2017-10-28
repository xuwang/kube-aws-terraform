# Common issues

* For all certificate related errors, first extract admin cert/key/ca from kube_config using this script like so:

    ```console
    $ resources/scripts/extract_kubecfg_cert.sh kube-lab kube-lab-admin <cluster-name> <cluster-name>-admin
    Checking if private and public key match.
     Public key modulus md5: ....
    Private key modulus md5: ....
    Private key and public key match.
    kube-lab-ca.crt, kube-lab-admin.crt, and kube-lab-admin key are generated in the /tmp/workspace.aPrr directory.
    Please destroy them after use.
    ```
    If any errors from the above output, you can troubleshoot further by examining certs with openssl command in the outpit directory.
    
* Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubev2/pki/kube-apiserver")

    Possibly there was an older kubeconfig for the same cluster name with different cert. Frequently occur during testing. To clear up previous confguration:

    ```console
    $ kubectl config delete-context <clusername>
    kubectl config delete-context <clustername>
    warning: this removed your active context, use "kubectl config use-context" to select a different one
    ```

* ssh_exchange_identification: Connection closed by remote host

    The API server is not ready. Please validate its status:

    ```console
    $ make validate-master
    ● kube-apiserver.service - Kubernetes API Server
    Loaded: loaded (/etc/systemd/system/kube-apiserver.service; static; vendor preset: disabled)
    Active: active (running) since Thu 2017-10-26 03:19:03 UTC; 28min ago
    --
    ● kube-controller-manager.service - Kubernetes master Manager
    Loaded: loaded (/etc/systemd/system/kube-controller-manager.service; disabled; vendor preset: disabled)
    Active: active (running) since Thu 2017-10-26 03:19:01 UTC; 28min ago
    --
    ● kube-scheduler.service - Kubernetes Scheduler
    Loaded: loaded (/etc/systemd/system/kube-scheduler.service; disabled; vendor preset: disabled)
    Active: active (running) since Thu 2017-10-26 03:19:01 UTC; 28min ago
    ```
