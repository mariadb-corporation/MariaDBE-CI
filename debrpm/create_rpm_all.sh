#!/bin/bash

set -x

export script_dir="$(dirname $(readlink -f $0))"

${script_dir}/create_rpm_repos.sh $1 rhel_6_gcp
${script_dir}/create_rpm_repos.sh $1 rhel_7_gcp
${script_dir}/create_rpm_repos.sh $1 rhel_8_gcp
${script_dir}/create_rpm_repos.sh $1 sles_12_gcp
${script_dir}/create_rpm_repos.sh $1 sles_15_gcp
