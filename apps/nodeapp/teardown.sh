#!/bin/bash

if ! which -s kubectl; then
  echo "kubectl command not installed"
  exit 1
fi

kubectl delete -f deployment.yml
kubectl delete -f svc.yml
