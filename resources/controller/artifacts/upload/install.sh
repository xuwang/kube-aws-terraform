DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
mkdir -p /var/lib/kubernetes/
cp $DIR/policy.jsonl $DIR/token.csv /var/lib/kubernetes/

