#!/bin/bash -eo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

KEY_PAIR_NAME=production
PUBLIC_KEY_PATH=file://$script_dir/../conf/production.pub

function main() {
    stage=$1
    region=$2

    if [ -z "$stage" ]; then
        echo "<stage> is a required field" 1>&2
        usage
        exit 1
    fi

    if [ -z "$region" ]; then
        echo "<region> is a required field" 1>&2
        usage
        exit 1
    fi

    aws --region us-west-1 ec2 describe-key-pairs --filters Name=key-name,Values=$KEY_PAIR_NAME | jq -e '.KeyPairs[0]'
    if [ $? -eq 1 ]; then
        echo "setting up key pair in region: $region" 1>&2
        aws ec2 import-key-pair --key-name $KEY_PAIR_NAME --public-key-material $PUBLIC_KEY_PATH --region $region
    else
        echo "found existing key-pair named $KEY_PAIR_NAME, using that" 1>&2
    fi

    echo "creating initial cloudfront stack" 1>&2
    stack_name=$stage-secondary-datacenter
    template_url=https://s3-us-west-2.amazonaws.com/codepipeline.traceme.com/$stack_name/infrastructure/secondary.yaml
    aws s3 sync . s3://codepipeline.traceme.com/$stack_name/infrastructure --exclude ".git/*" --exclude "*.swp"
    params=`aws s3 cp s3://codepipeline.traceme.com/$stack_name/infrastructure/conf/$stage-$region.yaml -`
    aws --region=$region cloudformation create-stack --stack-name $stack_name --template-url $template_url --parameters "$params"
}

function usage() {
    echo "usage: $0 <stage> <region>" 1>&2
}

main $1 $2
