#!/bin/bash
set -x

export script_dir="$(dirname $(readlink -f $0))"
export PASSPHRASE=`cat $HOME/.config/passphrase`
${script_dir}/keygrip.sh

target=$1
box=$2

if [ "$target" == "" ] ;
then
  echo "target is not defined, exiting"
  exit 1
fi


if [ "$box" == "" ] ;
then
  echo "box is not defined, exiting"
  exit 1
fi

mkdir -p rpm
cd rpm

rm -rf ${target}/$box
mkdir -p ${target}/$box

if [ "${direct_in_path}" != "" ] ;
then
  in_path=${direct_in_path}/$box
else
  in_path=/srv/ci-repos/${target}/packages/$box
fi

scp -r timofey_turenko_mariadb_com@mdbe-ci-repo:${in_path}/* ${target}/$box/

curr=`pwd`
cd ${target}/$box/
rpm --resign *.rpm
createrepo -d -s sha .
gpg2 --output repomd.xml.key --sign repodata/repomd.xml
gpg2 -a --detach-sign repodata/repomd.xml
cd $curr

if [ "${direct_out_path}" != "" ] ;
then
  out_path=${direct_out_path}/$box
else
  out_path=/srv/ci-repos/${target}/yum/$box
fi
ssh timofey_turenko_mariadb_com@mdbe-ci-repo "sudo rm -rf ${out_path}"
ssh timofey_turenko_mariadb_com@mdbe-ci-repo "sudo mkdir -p ${out_path}; sudo chmod 777  ${out_path}"
rsync -avz --progress -e ssh ${target}/$box/ timofey_turenko_mariadb_com@mdbe-ci-repo:${out_path}/

rm -rf ${target}/$box

cd ..

