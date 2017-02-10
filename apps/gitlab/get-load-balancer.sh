#!/bin/bash

if ! which -s kubectl; then
  echo "kubectl command not installed"
  exit 1
fi

elb_dns=""
while [ "X$elb_dns" = "X" ];
do
  echo "Waiting for loadBanlancer..."
  elb_dns=$(kubectl get svc gitlab  -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
  sleep 10
done
echo "Conntect to GitLab at: http://$elb_dns"
