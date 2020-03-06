#!/bin/bash

set -x

export script_dir="$(dirname $(readlink -f $0))"

${script_dir}/create_rpm_repos.sh $1 "rhel/6"
${script_dir}/create_rpm_repos.sh $1 "rhel/7"
${script_dir}/create_rpm_repos.sh $1 "rhel/8"
${script_dir}/create_rpm_repos.sh $1 "sles/12"
${script_dir}/create_rpm_repos.sh $1 "sles/15"
