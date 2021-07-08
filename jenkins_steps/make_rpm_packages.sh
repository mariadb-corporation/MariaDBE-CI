#!/usr/bin/env bash
#
set -x
#
BUILDDIR="padding_for_CPACK_RPM_BUILD_SOURCE_DIRS_PREFIX_ON_ES_BACKUP_DEBUGSOURCE"
mkdir ${BUILDDIR}
tar xzf mariadb-*.tar.gz --strip-components=1 -C ${BUILDDIR}
rm -vf mariadb-*.tar.gz
#
cd ${BUILDDIR}
#
if [[ ${label} = "rhel-7-arm" ]] || [[ ${label} = "rhel-8-arm" ]]; then
  curl -o ../MariaDB-shared-5.3.x.rpm \
    https://es-repo.mariadb.net/es-ci-files/MariaDB-shared-5.3.12-1.el7.centos.aarch64.rpm
  curl -o ../MariaDB-shared-10.1.x.rpm \
    https://es-repo.mariadb.net/es-ci-files/MariaDB-shared-10.1.48-1.el7.centos.aarch64.rpm
else
  curl -o ../MariaDB-shared-5.3.x.rpm http://yum.mariadb.org/5.3/centos5-amd64/rpms/MariaDB-shared-5.3.12-122.el5.x86_64.rpm
#
  if [[ ${label} = rhel-7 ]] || [[ ${label} = rhel-8 ]] ; then
      curl -o ../MariaDB-shared-10.1.x.rpm \
    http://yum.mariadb.org/10.1/centos7-amd64/rpms/MariaDB-shared-10.1.48-1.el7.centos.x86_64.rpm
  fi
#
  if [[ ${label} = sles-12 ]]; then
    curl -o ../MariaDB-shared-10.1.x.rpm \
    http://yum.mariadb.org/10.1/sles12-amd64/rpms/MariaDB-shared-10.1.48-1.x86_64.rpm
  fi
fi
#
NCPU=$(grep -c processor /proc/cpuinfo)
[[ -f /opt/rh/devtoolset-3/enable ]] && source /opt/rh/devtoolset-3/enable
#
cmake . -DBUILD_CONFIG=enterprise -DRPM=${label/-/}
make -j${NCPU} package || exit 1
#
rm -fv ../MariaDB-shared-*.rpm
mv -fv *.rpm ${WORKSPACE}
# TODO fix the path if we need more locations
if [[ ${JOB_NAME%\/*} = 10.[2-9]e-RPM-ENTERPRISE ]]; then
  REPOSITORY="https://${REPO_CRED}@es-repo.mariadb.net/jenkins/ENTERPRISE/${GIT_BRANCH}/${GIT_COMMIT}/RPMS/${label}"
else
  REPOSITORY="https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/${SHORT_VERSION}/${GIT_BRANCH}/${GIT_COMMIT}/RPMS/${label}"
fi
#
echo REPOSITORY="${REPOSITORY}" >> ${WORKSPACE}/build.properties
#
cd ${WORKSPACE}
#
PACKAGES=$(find . -type f -name '*.rpm' ! -name '*debuginfo*')
#
for __pkg in ${PACKAGES}; do
  echo $(basename ${__pkg}) | gawk -F '-[[:digit:]][[:digit:]].[[:digit:]]+.[[:digit:]]+' '{print $1}'
done | sort | uniq | gawk '{ printf "%s ", $1}' > pkglist.txt
