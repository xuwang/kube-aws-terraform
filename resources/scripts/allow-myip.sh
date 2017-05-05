#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_PROFILE=${AWS_PROFILE:-NODEFAULT}
AWS_REGION=${AWS_REGION:-us-west-2}
ACTION=${1:DONOTHING}
MODULE_NAME=${2:-master}
PORT=${3:-22}

SGNAME=${MODULE_NAME}_security_group
myip=$(curl -s ipecho.net/plain)

if [ $MODULE_NAME == 'master' ];
then
  SGNAME=kube-lab-kubernetes
fi
security_group_id=$(aws --region ${AWS_REGION} --profile ${AWS_PROFILE} ec2 describe-security-groups | \
    jq -r --arg SGNAME ${SGNAME} ".SecurityGroups[] | select(.GroupName==\"${SGNAME}\") | .GroupId" )
if [ -z "$security_group_id" ];
then
  echo "Security group for $SGNAME doesn't exist."
  exit 1
fi

# Revoke existing rules if any; add allow rule. Revoke after it's done.
revoke() {
    aws ec2 --region ${AWS_REGION} --profile ${AWS_PROFILE} revoke-security-group-ingress \
        --group-id $security_group_id --protocol tcp --port $PORT --cidr $myip/32 > /dev/null 2>&1
    [ $OPTION != "a" ] && echo Revoked $PORT from $myip/32 to $MODULE_NAME...
}
allow() {
    aws ec2 --region ${AWS_REGION} --profile ${AWS_PROFILE} \
        authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port $PORT --cidr $myip/32
    echo Permitted $PORT from $myip/32 to $MODULE_NAME...
}

# Get options from the command line
while getopts ":a:r:" OPTION
do
  case $OPTION in
    a)
      revoke
      allow
      ;;
    r)
      revoke
      ;;
    *)
      echo "Usage: $(basename $0) <-a|-r> <machine> <port>"
      exit 0
      ;;
  esac
done
