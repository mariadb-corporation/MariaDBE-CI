#!/usr/bin/env bash
#
MYSQL_PASSWORD='tESt123%_password'
PKGS=$(cat pkglist.txt)
#
case ${SHORT_VERSION} in
  "10.2" | "10.3")
    GALERA_VERSION=3
  ;;
  "10.4" | "10.5" | "10.6")
    GALERA_VERSION=4
   ;;
   *)
    echo "Unable to determine Galera version for installation!"
    exit 1
    ;;
esac
#
echo "deb [trusted=yes] https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/apt ${label}/" > enterprise-server.list
echo "deb [trusted=yes] ${REPOSITORY} ${label}/" >> enterprise-server.list
sudo mv -vf enterprise-server.list /etc/apt/sources.list.d/
#
for _count in {0..20}; do
  sleep ${_count}
  sudo apt-get update && sudo apt-get -y -f install debconf-utils && break
done
#
echo mariadb-server-${SHORT_VERSION}  mariadb-server-${SHORT_VERSION}/postrm_remove_databases  boolean false   | sudo debconf-set-selections
echo mariadb-server-${SHORT_VERSION}  mysql-server/root_password  password ${MYSQL_PASSWORD}       | sudo debconf-set-selections
echo mariadb-server-${SHORT_VERSION}  mysql-server/root_password_again  password ${MYSQL_PASSWORD} | sudo debconf-set-selections
#
for _try in {0..10}; do
  sleep 1
  sudo apt-get -y install ${PKGS}
done
