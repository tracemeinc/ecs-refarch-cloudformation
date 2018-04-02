#!/bin/bash -eo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

    stack_name=$stage-secondary-datacenter
    template_url=https://s3-us-west-2.amazonaws.com/codepipeline.traceme.com/$stack_name/infrastructure/secondary.yaml
    aws s3 sync $script_dir/.. s3://codepipeline.traceme.com/$stack_name/infrastructure --exclude ".git/*" --exclude "*.swp"
    params=`aws s3 cp s3://codepipeline.traceme.com/$stack_name/infrastructure/conf/$stage-$region.yaml -`
    aws --region=$region cloudformation update-stack --stack-name $stack_name --template-url $template_url --parameters "$params"
}

function usage() {
    echo "usage: $0 <stage> <region>" 1>&2
}

main $1 $2
