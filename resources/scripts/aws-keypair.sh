#!/bin/bash

AWS_PROFILE=${AWS_PROFILE:-NODEFAULT}
CLUSTER_NAME=${CLUSTER_NAME:-NODEFAULT}
AWS_ACCOUNT=${AWS_ACCOUNT:-}
AWS_REGION=${AWS_REGION:-us-west-2}
SSHKEY_DIR=${SSHKEY_DIR:-keypairs}

# Default keypair name
key="${CLUSTER_NAME}-default"

if [ "X${AWS_ACCOUNT}" = "X" ];
then
  echo "Getting AWS account number..."
  AWS_ACCOUNT=$(aws --profile ${AWS_PROFILE} sts get-caller-identity --output text --query 'Account')
fi

create(){
  if  aws --profile ${AWS_PROFILE} --region ${AWS_REGION} ec2 describe-key-pairs --key-name ${key} > /dev/null 2>&1 ;
  then
    echo "keypair ${key} already exists."
  else
    mkdir -p ${SSHKEY_DIR}
    chmod 700 ${SSHKEY_DIR}
    echo "Creating keypair ${key}"
    # Todo: consider to generate keypairs and import into AWS
    aws --profile ${AWS_PROFILE} --region ${AWS_REGION} ec2 create-key-pair --key-name ${key} --query 'KeyMaterial' --output text > ${SSHKEY_DIR}/${key}.pem
    chmod 600 ${SSHKEY_DIR}/${key}.pem
  fi
}

exist(){
  if aws --profile ${AWS_PROFILE} --region ${AWS_REGION} ec2 describe-key-pairs --key-name ${key} > /dev/null 2>&1 ;
  then
    return 0
  else
    return 1
  fi
}
destroy(){
  if  ! aws --profile ${AWS_PROFILE} --region ${AWS_REGION} ec2 describe-key-pairs --key-name ${key} > /dev/null 2>&1 ;
  then
    echo "keypair ${key} does not exists."
  else
    if [ -f ${SSHKEY_DIR}/${key}.pem ];
    then
      echo "Remove from ssh agent"
      ssh-add -L |grep "${SSHKEY_DIR}/${key}.pem" > ${SSHKEY_DIR}/${key}.pub
      [ -s ${SSHKEY_DIR}/${key}.pub ] && ssh-add -d ${SSHKEY_DIR}/${key}.pub
      rm -rf ${SSHKEY_DIR}/${key}.pem
      rm -rf ${SSHKEY_DIR}/${key}.pub
    fi
    echo "Delete AWS keypair ${key}"
    #aws --profile ${AWS_PROFILE} --region ${AWS_REGION}  s3 rm s3://${AWS_ACCOUNT}-${CLUSTER_NAME}-config/keypairs/${key}.pem
    aws --profile ${AWS_PROFILE} --region ${AWS_REGION} ec2 delete-key-pair --key-name ${key}
  fi
}

while getopts ":c:d:e:h" OPTION
do
  key=$OPTARG
  case $OPTION in
    c)
      create
      ;;
    d)
      destroy
      ;;
    e)
      exist
      ;;
    *)
      echo "Usage: $(basename $0) -c|-d|-e keyname"
      exit 1
      ;;
  esac
done
