#!/usr/bin/env bash
#
rpm -qa | grep -iE 'galera|mariadb|mysql' || true
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
if [[ ${label} =~ rhel-8 ]]; then
  RHEL8FIX='module_hotfixes=true'
fi
#
if [[ ${label} =~ rhel ]]; then
cat << EOF > enterprise.repo
[galera]
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

  sudo zypper ar -f -g https://${REPO_CRED}@es-repo.mariadb.net/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/rpm/${label} Galera-Enterprise
  sudo zypper ar -f ${REPOSITORY} MariaDB-Enterprise
  sudo zypper --no-gpg-checks refresh ||:

fi
#
set -e
#
PKGS=$(cat pkglist.txt)
#
if [[ ${label} =~ rhel ]]; then sudo yum -y --nogpgcheck install ${PKGS}; fi
#
if [[ ${label} =~ sles ]]; then
  sudo zypper --no-gpg-checks -n install --repo Galera-Enterprise galera-enterprise-${GALERA_VERSION}
  sudo zypper --no-gpg-checks -n install --repo MariaDB-Enterprise ${PKGS}
fi
#
















