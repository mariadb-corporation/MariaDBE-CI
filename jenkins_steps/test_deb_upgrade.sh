#!/usr/bin/env bash
#
# upgrade is possible starting from 10.3
#
# Need to install `bc` if missing
for _count in {0..20}; do
  sleep ${_count}
  sudo apt-get update && sudo apt-get -y install bc wget && break
done

# PREVIOUS_VERSION can be passed externally as ENV variable
[[ -z "${PREVIOUS_VERSION}" ]] && PREVIOUS_VERSION=$(echo ${SHORT_VERSION} - 0.1 | bc)
#
old_BACKUP_PKG="mariadb-backup"
[[ "${PREVIOUS_VERSION}" = "10.2" ]] && old_BACKUP_PKG="mariadb-backup-10.2"
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
export DEBIAN_FRONTEND=noninteractive
export MYSQL_PASSWORD='tESt123%_password'
#
wget https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup
chmod +x mariadb_es_repo_setup
sudo ./mariadb_es_repo_setup --token="${ESTOKEN}" --apply --mariadb-server-version="${PREVIOUS_VERSION}" --skip-maxscale

#
for _count in {0..20}; do
  sleep ${_count}
  sudo apt-get update && sudo apt-get -y -f install debconf-utils && break
done
#
echo mariadb-server-${SHORT_VERSION}  mariadb-server-${SHORT_VERSION}/postrm_remove_databases  boolean false   | sudo debconf-set-selections
#
echo mariadb-server-${PREVIOUS_VERSION}  mariadb-server-${PREVIOUS_VERSION}/postrm_remove_databases  boolean false   | sudo debconf-set-selections
echo mariadb-server-${PREVIOUS_VERSION}  mysql-server/root_password  password ${MYSQL_PASSWORD}       | sudo debconf-set-selections
echo mariadb-server-${PREVIOUS_VERSION}  mysql-server/root_password_again  password ${MYSQL_PASSWORD} | sudo debconf-set-selections
#
sudo apt-get -y install mariadb-server ${old_BACKUP_PKG}
#
sudo systemctl restart mariadb
#
# Ensuring that server is up and running
echo 'SELECT VERSION()' | sudo ${old_CLIENT_CMD}

# Performing mariabackup
mkdir -p /var/tmp/backup/preupgrade_backup
sudo mariabackup --backup \
      --user=root \
      --target-dir=/var/tmp/backup/preupgrade_backup
#
sudo mariabackup --prepare --target-dir=/var/tmp/backup/preupgrade_backup

# go
sudo systemctl stop mariadb
#
sudo apt-get -y remove "mariadb-*"
sudo apt-get -y remove "galera-*"
#
[[ -x /usr/bin/apt ]] && sudo apt list --installed | egrep -i "mariadb|galera" ||:
#
sudo rm -f /etc/apt/sources.list.d/mariadb.list
echo "deb [trusted=yes] https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/apt ${label}/" > enterprise-server.list
echo "deb [trusted=yes] ${REPOSITORY} ${label}/" >> enterprise-server.list
cat enterprise-server.list
sudo mv -vf enterprise-server.list /etc/apt/sources.list.d/
#
for _count in {0..20}; do
  sleep ${_count}
  sudo apt-get update && sudo apt-get -y install mariadb-server mariadb-backup && break
done
#
if ! sudo systemctl restart mariadb; then
  ps afwx
  journalctl -xe | tail -n 100
  systemctl status mariadb.service
  exit 1
fi

# allow debian to finish startup (it runs DB upgrade on restart)
sleep 20
#
if ! sudo ${new_UPGRADE_CMD}; then
  # hm, dump some logs here?
  ps afwx
  exit 1
fi

# Ensuring that server is up and running
echo 'SELECT VERSION()' | sudo ${new_CLIENT_CMD}
