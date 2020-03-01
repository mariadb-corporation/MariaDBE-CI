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

scp -r timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/ci-repos/${target}/packages/$box/RelWithDebInfo/* ${target}/$box/

cd ${target}/$box/
rpm --resign *.rpm
createrepo -d -s sha .
gpg2 --output repomd.xml.key --sign repodata/repomd.xml
gpg2 -a --detach-sign repodata/repomd.xml
cd ../..

ssh timofey_turenko_mariadb_com@mdbe-ci-repo rm -rf /srv/ci-repos/${target}/yum/$box
ssh timofey_turenko_mariadb_com@mdbe-ci-repo mkdir -p /srv/ci-repos/${target}/yum/$box
rsync -avz --progress -e ssh ${target}/$box/ timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/ci-repos/${target}/yum/$box/

rm -rf ${target}/$box

cd ..

