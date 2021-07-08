#!/usr/bin/env bash
#
set -x
#

for _try in {0..60}; do
  sleep ${_try}
  sudo apt-get update && \
  sudo apt-get -y dist-upgrade && break
done
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
debian/autobake-deb.sh ${AUTOBAKE_OPTS:-} || exit 1
#
# TODO fix the path if we need more locations
if [[ ${JOB_NAME%\/*} = 10.[2-9]e-DEB-ENTERPRISE ]]; then
  REPOSITORY="https://${REPO_CRED}@es-repo.mariadb.net/jenkins/ENTERPRISE/${GIT_BRANCH}/${GIT_COMMIT}/DEB"
else
  REPOSITORY="https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/${SHORT_VERSION}/${GIT_BRANCH}/${GIT_COMMIT}/DEB"
fi
#
echo REPOSITORY="${REPOSITORY}" >> ${WORKSPACE}/build.properties
#
#
cd ${WORKSPACE}
#
PACKAGES=$(find . -type f -name 'mariadb*.deb' ! -name '*dbgsym*')
#
for __pkg in ${PACKAGES}; do
  echo $(basename ${__pkg}) | gawk -F '_' '{print $1}'
done | sort | uniq | gawk '{ printf "%s ", $1}' > pkglist.txt
