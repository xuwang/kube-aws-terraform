#!/bin/bash
#
# sfeng@stanford.edu 2016
#
# Modified https://github.com/hashicorp/best-practices/blob/master/packer/config/vault/scripts/setup_vault.sh
# to use S3 backend.
set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. $DIR/utils/env_defaults
. $DIR/utils/functions


### MAIN

if [ "X$interactive" = 'X-i' ]; then
    read -p $'Running this script will initialize & unseal Vault, \nthen put your unseal keys and root token into S3. \n\nIf you are sure you want to continue, type \'yes\': \n' ANSWER
  if [ "$ANSWER" != "yes" ]; then
     echo
     echo "Exiting without intializing & unsealing Vault, no keys or tokens were stored."
     echo
     exit 1
   fi
fi

if [ -z "$BUCKET" ]; then
  exit1 "S3 Bucket is not defined in $DIR/utils/env_defaults."
elif ! bucket_exist ; then
  exit1 "$BUCKET doesn't exist. Create it first."
fi

if ! s3ls root-token ; then
  init_vault
else
  echo "Vault has already been initialized, skipping."
fi

if vault status | grep Sealed | grep true ; then
  unseal_vault
else
 echo "Vault is already unsealed."
fi

instructions
