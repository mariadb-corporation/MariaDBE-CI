#!/usr/bin/env bash
#
set -x
#
NCPU=$(grep -c processor /proc/cpuinfo)
export DEB_BUILD_OPTIONS="parallel=${NCPU}"
#
BUILDDIR=MariaDBEnterprise
mkdir ${BUILDDIR}
#
tar xzf mariadb-*.tar.gz --strip-components=1 -C ${BUILDDIR}
rm -vf mariadb-*.tar.gz
#
cd ${BUILDDIR}
#
# AUTHPROXY PLUGIN. see https://jira.mariadb.org/browse/MENT-1013
# TODO add additional check for release tasks IF this script will be used for making releases
#if [[ ${SHORT_VERSION} = "10.5" ]]; then
#  AUTOBAKE_OPTS="--with-authproxy"
#fi
#
debian/autobake-deb.sh ${AUTOBAKE_OPTS:-}
#
echo REPOSITORY="https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/${SHORT_VERSION}/${GIT_BRANCH}/${GIT_COMMIT}/DEB" >> ${WORKSPACE}/build.properties
#
#
cd ${WORKSPACE}
#
PACKAGES=$(find . -type f -name 'mariadb*.deb' ! -name '*dbgsym*')
#
for __pkg in ${PACKAGES}; do
  echo $(basename ${__pkg}) | gawk -F '_' '{print $1}'
done | sort | uniq | gawk '{ printf "%s ", $1}' > pkglist.txt
