#!/bin/bash

if ! which -s kubectl; then
  echo "kubectl command not installed"
  exit 1
fi

kubectl apply -f deployment.yml
kubectl apply -f svc.yml

echo "Get loadBanlancer dns name"
elb_dns=$(kubectl get svc nodeapp  -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
while ! echo $elb_dns | grep -q 'elb.amazonaws.com'
do
  elb_dns=$(kubectl get svc nodeapp  -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
  sleep 15
done

while ! curl -L -I $elb_dns | grep -v "200 OK" ;
do
   echo "Waiting for $elb_dns to be ready"
   sleep 15
done
echo "Conntect to demo Nginx at: http://$elb_dns"
open "http://$elb_dns"
