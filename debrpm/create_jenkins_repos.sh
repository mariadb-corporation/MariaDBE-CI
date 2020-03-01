#!/bin/bash
set -x

export script_dir="$(dirname $(readlink -f $0))"

#jenkins_target=$1
jenkns_target="10.3/origin/10.3e-abychko/83d402a6a9c0967606508e48894478728cd57fe0"

export direct_in_path=${jenkins_target}/DEB/*
export direct_out_path=${jenkins_target}/apt

${script_dir}/create_deb_repos.sh x

export direct_in_path=${jenkins_target}/RPMS
export direct_out_path=${jenkins_target}/yum

${script_dir}/create_rpm_all.sh x
