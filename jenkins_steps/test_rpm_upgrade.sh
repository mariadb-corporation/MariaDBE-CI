#!/usr/bin/env bash
#
# upgrade is possible starting from 10.3
#
# PREVIOUS_VERSION can be passed externally as ENV variable
[[ -z "${PREVIOUS_VERSION}" ]] && PREVIOUS_VERSION=$(echo ${SHORT_VERSION} - 0.1 | bc)
#
case ${PREVIOUS_VERSION} in
  "10.2" | "10.3")
    old_CLIENT_CMD="mysql"
  ;;
  "10.4" | "10.5")
    old_CLIENT_CMD="mariadb"
  ;;
  *)
    echo "Error! PREVIOUS_VERSION is \"${PREVIOUS_VERSION}\""
    exit 1
  ;;
esac
#
case ${SHORT_VERSION} in
  "10.3")
    new_CLIENT_CMD="mysql"
    new_UPGRADE_CMD="mysql_upgrade"
    GALERA_VERSION=3
  ;;
  "10.4" | "10.5" | "10.6")
    new_CLIENT_CMD="mariadb"
    new_UPGRADE_CMD="mariadb-upgrade"
    GALERA_VERSION=4
  ;;
  *)
    echo "Error! SHORT_VERSION is \"${SHORT_VERSION}\""
    exit 1
  ;;
esac
#
if [[ $label =~ rhel ]]; then
  pkg_mng="yum -y"
fi
#
if [[ $label =~ sles ]]; then
  pkg_mng="zypper -n"
fi
#
if [[ ${label} = rhel-8 ]]; then
  RHEL8FIX='module_hotfixes=true'
fi
# Workaround for MENT-1229
# TODO: remove when 10.2.39-13 is released
if [[ ${label} =~ rhel-8 ]] && [[ ${PREVIOUS_VERSION} =~ 10.2 ]]; then
  sudo ${pkg_mng} remove mariadb-connector-c
fi
#
wget https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup
chmod +x mariadb_es_repo_setup
sudo ./mariadb_es_repo_setup --token="${ESTOKEN}" --apply --mariadb-server-version="${PREVIOUS_VERSION}" --skip-maxscale
#
sudo ${pkg_mng} install MariaDB-server MariaDB-client MariaDB-backup ||:
sudo sudo systemctl restart mariadb
#
# Ensuring that server is up and running
echo 'SELECT VERSION()' | sudo ${old_CLIENT_CMD}
#
# Performing mariabackup
mkdir -p /var/tmp/backup/preupgrade_backup
sudo mariabackup --backup \
      --user=root \
      --target-dir=/var/tmp/backup/preupgrade_backup
#
sudo mariabackup --prepare --target-dir=/var/tmp/backup/preupgrade_backup
#
sudo systemctl stop mariadb
sudo ${pkg_mng} remove MariaDB-server MariaDB-client MariaDB-backup
sudo rm -fv /etc/yum.repos.d/mariadb*.repo
#

if [[ ${label} =~ rhel ]]; then
cat << EOF > enterprise.repo
[es-galera]
name=galera
baseurl=https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/rpm/${label}/
gpgcheck=0
enable=1
${RHEL8FIX:-}

[es-server-${SHORT_VERSION}]
name=MariaDB-ES
baseurl=${REPOSITORY}
gpgcheck=0
enable=1
${RHEL8FIX:-}
EOF
#
  cat enterprise.repo
  sudo mv -vf enterprise.repo /etc/yum.repos.d/
  sudo yum -y clean all
  sudo ${pkg_mng} --nogpgcheck install MariaDB-server MariaDB-backup MariaDB-client
fi
#
#
if [[ ${label} =~ sles ]]; then
  # cleanup
  sudo zypper rr Galera-Enterprise
  sudo zypper rr MariaDB-Enterprise
  #
  set +e

  sudo rm -fv /etc/SUSEConnect
  sudo rm -fv /etc/zypp/{repos,services,credentials}.d/*
  sudo rm -fv /usr/lib/zypp/plugins/services/*
  sudo sed -i '/^# Added by SMT reg/,+1d' /etc/hosts
  sudo SUSEConnect --cleanup

  sudo zypper ar -f -p 10 -g https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/rpm/${label} Galera-Enterprise
  sudo zypper ar -f -p 10 ${REPOSITORY} MariaDB-Enterprise
  sudo zypper --no-gpg-checks refresh ||:
  sudo ${pkg_mng} --no-gpg-checks install MariaDB-server MariaDB-backup MariaDB-client
fi
#

if ! sudo systemctl restart mariadb; then
  ps afxw
  exit 1
fi

if ! sudo ${new_UPGRADE_CMD}; then
  ps afxw
  exit 1
fi

# Ensuring that server is up and running
echo 'SELECT VERSION()' | sudo ${new_CLIENT_CMD}
