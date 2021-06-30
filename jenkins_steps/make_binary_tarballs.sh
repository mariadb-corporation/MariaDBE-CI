#!/usr/bin/env bash
#
set -x
#
if ! tar xzf mariadb-*.tar.gz --strip-components=1; then
  echo "Error unpacking mariadb-enterprise sourcetar!"
  exit 1
fi
#
rm -vf mariadb-*.tar.gz
#
# to avoid pkg upgrades during the build
if [[ -x /usr/bin/apt-get ]]; then
  for _try in {0..20}; do
    sleep ${_try}
    sudo apt-get update && sudo apt-get -y dist-upgrade && break
  done
fi

if [[ -x /usr/bin/yum ]]; then
  for _try in {0..20}; do
    sleep ${_try}
    sudo yum -y update && break
  done
fi
#
[[ -f /opt/rh/devtoolset-3/enable ]] && source /opt/rh/devtoolset-3/enable
#
NCPU=$(grep -c processor /proc/cpuinfo)

# AUTHPROXY PLUGIN. see https://jira.mariadb.org/browse/MENT-1013
#if [[ ${SHORT_VERSION} = "10.5" ]]; then
#  CMAKEOPTS="-DPLUGIN_AUTH_PROXY=DYNAMIC"
#fi
#
cmake . -DBUILD_CONFIG=enterprise ${CMAKEOPTS:-}
make -j${NCPU} package
