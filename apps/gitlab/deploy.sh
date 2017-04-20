#!/bin/bash

if ! which -s kubectl; then
  echo "kubectl command not installed"
  exit 1
fi

# create the services
for svc in *-svc.yml
do
  echo -n "Creating $svc... "
  kubectl -f $svc create
done

# create the replication controllers
for rc in *-rc.yml
do
  echo -n "Creating $rc... "
  kubectl -f $rc create
done

# list pod,rc,svc
echo "Pod:"
kubectl get pod

echo "RC:"
kubectl get rc

echo "Service:"
kubectl get svc

# Wait for the Pods to be ready
while ! kubectl get pods -o json -l name=gitlab   |grep ready | grep -q true ;
do
  echo "Waiting for GitLab to be ready..."
  sleep 10
done

elb_dns=$(kubectl get svc gitlab  -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
while ! echo $elb_dns | grep -q 'elb.amazonaws.com'
do
  echo "Getting loadBanlancer dns name..."
  elb_dns=$(kubectl get svc gitlab  -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
  sleep 15
done

while ! curl -L -I $elb_dns | grep -v "200 OK" ;
do
   echo "Waiting for loadBanlancer 200 OK"
   sleep 15
done
echo "Conntect to demo GitLab at: http://$elb_dns"
open "http://$elb_dns"
