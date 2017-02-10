#!/bin/bash -e
# Modified version of https://gist.github.com/weavenet/f40b09847ac17dd99d16
#
# xueshan.feng@gmail.com

AWS_PROFILE=${AWS_PROFILE:-NODEFAULT}
AWS_REGION=${AWS_REGION:-us-west-2}
bucket=$1

abort(){
    echo $*
    exit 1
}

delete_objects(){
    for i in $(seq 0 $count); do
        key=`echo $objects | jq .[$i].Key |sed -e 's/\"//g'`
        versionId=`echo $objects | jq .[$i].VersionId |sed -e 's/\"//g'`
        cmd="aws s3api delete-object --bucket $bucket --version-id $versionId --key"
        echo $cmd "$key"
        $cmd "$key"
    done
}

# Error checking
if [ -z "$bucket" ]; then
 abort "Bucket name is required. Example: mybucket"
fi
if ! aws s3 ls s3://$bucket ; then
  abort "bucket doesn't exist or permission is denied."
fi

versions=$(aws s3api list-object-versions --bucket $bucket |jq '.Versions')
markers=$(aws s3api list-object-versions --bucket $bucket |jq '.DeleteMarkers')

# Have to delete delete markers first - this will put the object back to the bucket. 
let count=$(echo $markers |jq 'length')-1
if [ $count -gt -1 ]; then
    echo "Removing delete markers"
    objects=$markers
    delete_objects
fi

# Then delete the object with versionId and obejct key. When they match, AWS will not insert a delete marker, and keept
# it as latest version. This way the bucket is emptied without the version and the delete marker objects. 
let count=$(echo $versions |jq 'length')-1
if [ $count -gt -1 ]; then
    echo "Removing files"
    objects=$versions
    delete_objects
fi
