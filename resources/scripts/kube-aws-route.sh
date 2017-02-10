#!/bin/bash

AWS_PROFILE=${AWS_PROFILE:-NODEFAULT}
CLUSTER_NAME=${CLUSTER_NAME:-NODEFAULT}
kubectl get nodes \
 --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}' > /tmp/nodesCidr

#10.240.5.49 10.200.1.0/24
#10.240.5.78 10.200.0.0/24

AWSCMD="aws --profile ${AWS_PROFILE}"
ROUTE_TABLE_ID=$($AWSCMD ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=${CLUSTER_NAME}" | \
  jq -r '.RouteTables[].RouteTableId')

cat /tmp/nodesCidr | \
while read node; do
  privateIP=$(echo $node | awk '{print $1}')
  subnet=$(echo $node | awk '{print $2}')
  WORKER_INSTANCE_ID=$($AWSCMD ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$privateIP" | \
  jq -r '.Reservations[].Instances[].InstanceId')
  echo "Creating route $privateIP, $WORKER_INSTANCE_ID, $subnet"
  $AWSCMD ec2 delete-route \
  --route-table-id ${ROUTE_TABLE_ID} \
  --destination-cidr-block $subnet
  $AWSCMD ec2 create-route \
  --route-table-id ${ROUTE_TABLE_ID} \
  --destination-cidr-block $subnet \
  --instance-id ${WORKER_INSTANCE_ID}
done
