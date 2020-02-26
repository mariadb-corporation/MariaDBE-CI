#!/bin/bash
set -x

export script_dir="$(dirname $(readlink -f $0))"
export PASSPHRASE=`cat $HOME/.config/passphrase`
${script_dir}/keygrip.sh

target=$1

if [ "$target" == "" ] ;
then
  echo "target is not defined, exiting"
  exit 1
fi

mkdir -p deb
cd deb

rm -rf $target
key=`gpg --list-keys --keyid-format LONG "MariaDB Platform QA" | grep pub | awk -F'/' '{print $2}' | awk -F' ' '{print $1}'`
${script_dir}/../apt-repository --initrepo --repopath $target --gpgkey $key

scp -r timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/repository/logs/$target/DEBRPM/debian*//RelWithDebInfo/* $target/incoming/
scp -r timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/repository/logs/$target/DEBRPM/ubuntu*//RelWithDebInfo/* $target/incoming/

reprepro -Vb $target processincoming default
reprepro -Vb $target export

ssh timofey_turenko_mariadb_com@mdbe-ci-repo mkdir -p /srv/repository/logs/$target/DEB
rsync -avz --progress -e ssh $target/ timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/repository/logs/$target/DEB/

rm -rf $target
cd ..

