#!/usr/bin/env bash

AWS_PROFILE=${AWS_PROFILE:-coreos-cluster}
AWS_REGION=${AWS_REGION:-us-west-2}
ASG=${1:-worker}

EC2_IDS=$(aws --profile $AWS_PROFILE --region $AWS_REGION autoscaling describe-auto-scaling-groups \
	--auto-scaling-group-name $ASG 2> /dev/null | jq .AutoScalingGroups[0].Instances[].InstanceId | xargs)

if [ ! -z "${EC2_IDS}" ]; then
	for i in ${EC2_IDS}
	do
		aws --profile $AWS_PROFILE --region $AWS_REGION ec2 modify-instance-attribute \
  			--instance-id $i --no-source-dest-check
  	done
else
	echo "Cannot get instance ids for autoscaling group $ASG."
fi

