#!/bin/bash

if ! which -s kubectl; then
  echo "kubectl command not installed"
  exit 1
fi

while ! kubectl get pods -o json -l name=gitlab   |grep ready | grep -q true ;
do
  echo "Waiting for GitLab to be ready..."
  sleep 2
done
elb_dns=""
while [ "X$elb_dns" = "X" ];
do
  echo "Waiting for loadBanlancer..."
  elb_dns=$(kubectl get svc gitlab  -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
  sleep 10
done
echo "Conntect to demo GitLab at: http://$elb_dns"
open "http://$elb_dns"
