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

scp -r timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/ci-repos/$target/packages/debian*/RelWithDebInfo/* $target/incoming/
scp -r timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/ci-repos/$target/packages/ubuntu*/RelWithDebInfo/* $target/incoming/
find $target/incoming/ -name "*.ddeb" -exec rename 's/.ddeb$/.deb/' {} \;
find $target/incoming/ -name "*.changes" -exec sed "s/\.ddeb/.deb/" -i {} \;
find $target/incoming/ -name "*.buildinfo" -exec sed "s/\.ddeb/.deb/" -i {} \;

reprepro -Vb $target processincoming default
reprepro -Vb $target export

ssh timofey_turenko_mariadb_com@mdbe-ci-repo rm -rf /srv/ci-repos/$target/apt
ssh timofey_turenko_mariadb_com@mdbe-ci-repo mkdir -p /srv/ci-repos/$target/apt
rsync -avz --progress -e ssh $target/ timofey_turenko_mariadb_com@mdbe-ci-repo:/srv/ci-repos/$target/apt/

rm -rf $target
cd ..
