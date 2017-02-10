#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_PROFILE=${AWS_PROFILE:-authnz-platform-dev}
AWS_REGION=${AWS_REGION:-us-west-2}
SGNAME=${1:-worker}
PORT=${2:-22}

myip=$(curl -s  --retry 5 --retry-delay 3 ipecho.net/plain)
security_group_id=$(make output | jq -r ".$SGNAME.value")
if [ ! -z "$security_group_id" ];
then
	aws ec2 --region ${AWS_REGION} --profile ${AWS_PROFILE} revoke-security-group-ingress \
		--group-id $security_group_id --protocol tcp --port $PORT --cidr $myip/32 > /dev/null 2>&1
	aws ec2 --region ${AWS_REGION} --profile ${AWS_PROFILE} \
		authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port $PORT --cidr $myip/32
else
	echo "Security group for $SGNAME doesn't exist."
	exit 1
fi
exit 0
