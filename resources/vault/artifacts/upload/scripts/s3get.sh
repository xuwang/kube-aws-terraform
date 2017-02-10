#!/bin/bash -e
# Written by sfeng@stanford.edu
# s3get.sh <bucket> <key> <path/to/file>

# Get instance auth token from meta-data
get_value() {
  echo -n $(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$roleProfile | jq -r ".$1")
}
# Headers for curl
create_string_to_sign() {
  contentType="application/x-compressed-tar"
  contentType=""
  dateValue="`date +'%a, %d %b %Y %H:%M:%S %z'`"

  # stringToSign
  stringToSign="GET

${contentType}
${dateValue}
x-amz-security-token:${s3Token}
${resource}"
}

# Log curl call
debug_log () {
    echo ""  >> /tmp/s3-bootstrap.log
    echo "curl -s -O -H \"Host: ${bucket}.s3.amazonaws.com\"
  -H \"Content-Type: ${contentType}\"
  -H \"Authorization: AWS ${s3Key}:${signature}\"
  -H \"x-amz-security-token:${s3Token}\"
  -H \"Date: ${dateValue}\"
        https://${bucket}.s3.amazonaws.com/${key} " >> /tmp/s3get.log
}

# Curl options
opts="-L --fail --retry 5 --retry-delay 3 --silent --show-error"

# Instance profile
instanceProfile=$(curl -s http://169.254.169.254/latest/meta-data/iam/info \
        | jq -r '.InstanceProfileArn' \
        | sed  's#.*instance-profile/##')

bucket=$1
key=$2
destination=$3
if [[ -z $bucket ]] || [[ -z $key ]] || [[ -z $destination ]];
then
  echo "Missing parameters."
  exit 1
fi
path=$(dirname $destination)
[ -s "$path" ] && mkdir -p $path
roleProfile=${instanceProfile}
# Find token, AccessKeyId,  line, remove leading space, quote, commas
s3Token=$(get_value "Token")
s3Key=$(get_value "AccessKeyId")
s3Secret=$(get_value "SecretAccessKey")

resource="/${bucket}/${key}"
create_string_to_sign
signature=$(/bin/echo -n "$stringToSign" | openssl sha1 -hmac ${s3Secret} -binary | base64)
debug_log
curl $opts -H "Host: ${bucket}.s3.amazonaws.com" \
  -H "Content-Type: ${contentType}" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  -H "x-amz-security-token:${s3Token}" \
  -H "Date: ${dateValue}" \
  https://${bucket}.s3.amazonaws.com/${key} > ${destination}
