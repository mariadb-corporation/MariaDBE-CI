#!/usr/bin/env bash
#
set -x
#
MYSQL_USER=mysql
MYSQL_GROUP=mysql
MYSQL_VARDIR=/var/tmp/mtr
MYSQL_DATADIR=/var/lib/mysql
PLATFORM=${IMAGE:-NO-DEFAULT-HERE}
PLATFORM=`echo $PLATFORM | sed "s/_/-/g" | sed "s/-gcp//" | sed "s/-aws//"`
#
MTR_DEFAULT_ARGS="--max-save-core=0 --max-save-datadir=1 --force --retry=3 --parallel=auto --vardir=${MYSQL_VARDIR}"
MTR_RUN_ARGS=${MTR_DEFAULT_ARGS}
PACKAGE=MariaDB-ES
unset WSREP_EXPORT
#
# specific ARGS for different TESTS
MTR_BIG_TEST_ARGS=" --max-test-fail=20 --big-test"
GALERA_TEST_ARGS=" --suite=galera,wsrep,galera_3nodes,galera_sr,galera_3nodes_sr --max-test-fail=0 --testcase-timeout=120 --big-test"
NORMAL_TEST_ARGS=""
PSPROTO_TEST_ARGS=" --ps-protocol"
EXTRA_TEST_ARGS=" --suite=funcs_1,funcs_2,stress,jp --testcase-timeout=120 --mysqld=--open-files-limit=0 --mysqld=--log-warnings=1"
ENGINES_TEST_ARGS=" --suite=spider,spider/bg,engines/funcs,engines/iuds --testcase-timeout=120 --mysqld=--open-files-limit=0 --mysqld=--log-warnings=1"
#
TARNAME=""
#
# here we should define proper options to run MTR
# normal test is the default one
#
while [[ ${#} -gt 0 ]]; do
  case ${1} in
    --junit-report)
      MTR_RUN_ARGS+=" --junit-output=/tmp/${PACKAGE}_${RANDOM}_${RANDOM}.xml --junit-package=${PACKAGE}"
      shift
      ;;
    --mtr-big-test)
      MTR_RUN_ARGS+=${MTR_BIG_TEST_ARGS}
      TARNAME=${1/--/}
      shift
      ;;
    --mtr-galera-test)
      MTR_RUN_ARGS+=${GALERA_TEST_ARGS}
      PACKAGE=Galera
      TARNAME=${1/--/}
      shift
      ;;
    --mtr-normal-test)
      MTR_RUN_ARGS+=${NORMAL_TEST_ARGS}
      TARNAME=${1/--/}
      shift
      ;;
    --mtr-psproto-test)
      MTR_RUN_ARGS+=${PSPROTO_TEST_ARGS}
      TARNAME=${1/--/}
      shift
      ;;
    --mtr-extra-test)
      MTR_RUN_ARGS+=${EXTRA_TEST_ARGS}
      TARNAME=${1/--/}
      shift
      ;;
    --mtr-engines-test)
      MTR_RUN_ARGS+=${ENGINES_TEST_ARGS}
      TARNAME=${1/--/}
      shift
      ;;
    *)
      echo "No such option: ${1}"
      exit 1
      ;;
  esac
done

unset packager_type

if [[ ${distro_id} =~ "suse" ]]
then
   packager_type="zypper"
fi

if [[ ${distro_id} =~ "rhel" ]]
then
   packager_type="yum"
fi

if [[ ${distro_id} =~ "debian" ]]
then
   packager_type="apt"
fi

if [[ ${packager_type} == "" ]]
then
    command -v apt-get

    if [ $? == 0 ]
    then
        packager_type="apt"
    fi

    command -v yum

    if [ $? == 0 ]
    then
        packager_type="yum"
    fi

    command -v zypper

    if [ $? == 0 ]
    then
        packager_type="zypper"
    fi
fi

if [[ ${packager_type} == "" ]]
then
    echo "Can not determine package manager type, exiting"
    exit 1
fi

if [[ ${packager_type} == "apt" ]]
then
  # DEB-based distro
  export DEBIAN_FRONTEND=noninteractive
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       install libaio-dev  \
       perl-modules libmhash-dev libxml-simple-perl patch \
       apt-utils build-essential python-dev sudo git \
       devscripts equivs libcurl4-openssl-dev \
       ccache python3 python3-pip curl libssl-dev \
       libzstd-dev libevent-dev dpatch gawk gdb \
       libboost-dev libcrack2-dev libjudy-dev libnuma-dev \
       libsnappy-dev libxml2-dev unixodbc-dev uuid-dev \
       fakeroot iputils-ping \
       libmhash-dev libxml-simple-perl \
       gnutls-dev libaio-dev libpam-dev \
       scons libboost-program-options-dev \
       libboost-system-dev libboost-filesystem-dev check \
       socat lsof valgrind apt-transport-https \
       software-properties-common dirmngr rsync netcat \
       libboost-all-dev libsnappy-dev flex expect \
       net-tools  
fi

if [[ ${packager_type} == "yum" ]]
then
    # YUM!
    sudo yum clean all
    sudo yum update -y
    unset enable_power_tools
    yum repolist all | grep PowerTools
    if [ $? == 0 ]
    then
        enable_power_tools="--enablerepo=PowerTools"
    fi
    sudo yum -y insrall yum-utils
    sudo yum -y groupinstall 'Development Tools'
    sudo yum install -y --nogpgcheck ${enable_power_tools} \
         libaio-devel libxml2-devel perl-Data-Dumper \
         perl-XML-LibXML curl-devel mhash-devel libxml2-devel gnutls-devel perl-XML-Simple \
         scons boost-devel check-devel which systemd-devel \
         cracklib-devel Judy-devel rsync socat lsof patch valgrind-devel \
         snappy-devel expect jemalloc net-tools
fi

if [[ ${packager_type} == "zypper" ]]
then
    # We need zypper here
    sudo zypper -n refresh
    sudo zypper -n update
    sudo zypper -n install \
        gcc-c++ libaio-devel pam-devel perl-XML-Simple \
        libgnutls-devel bison openssl-devel systemd-devel \
        ncurses-devel libxml2-devel libcurl-devel \
        rsync socat lsof tar gzip bzip2 rpm-build \
        checkpolicy policycoreutils curl perl check-devel \
        valgrind-devel wget sudo git scons boost-devel \
        snappy-devel expect net-tools flex autoconf automake libtool \
        perl-Data-Dumper perl-XML-LibXML patch
fi




#
# here we are going to install Galera library

#
# here we are going to create unprivileged mysql user if doesn't exist
if [[ ! $(getent passwd ${MYSQL_USER} > /dev/null 2>&1) ]]; then
  case ${PLATFORM} in
    centos* | rhel* | sles* | suse* )
      sudo groupadd -r ${MYSQL_GROUP} 2> /dev/null || true
      sudo useradd -M -r --home ${MYSQL_DATADIR} --shell /sbin/nologin \
        --comment "MySQL server" --gid ${MYSQL_GROUP} ${MYSQL_USER} 2> /dev/null || true
      ;;
    debian* | ubuntu* )
      sudo addgroup --system ${MYSQL_GROUP} > /dev/null 2>&1
      sudo adduser --system --disabled-login --ingroup ${MYSQL_GROUP} --no-create-home \
    --home /nonexistent --gecos "MySQL Server" --shell /bin/false ${MYSQL_USER} > /dev/null 2>&1
      ;;
      *)
        echo "Testing on \"${PLATFORM}\" is not implemented!"
        exit 1
      ;;
  esac
fi
#
if [[ ${PACKAGE} = Galera ]]; then
  # Galera installation
  export GALERA_PACKAGE="galera-enterprise-4"
  export GALERA_PACKAGE_DEB="galera-enterprise-4"
  export GALERA_REPO="repo4"
  minor_version=`cat $(dirname ${0})/VERSION | grep "MYSQL_VERSION_MINOR" | sed "s/MYSQL_VERSION_MINOR=//"`
  if [[ "${minor_version}" == "2" || "${minor_version}" == "3" ]]; then
    export GALERA_PACKAGE="galera"
    export GALERA_PACKAGE_DEB="galera-3"
    export GALERA_REPO="repo3"
  fi 
  if [[ -e /usr/bin/apt-get ]]; then
    sudo apt update
    sudo apt install -y dirmngr lsb-release
    DEBIAN_VERSION=$(lsb_release -sc)
    sudo bash -c "echo deb http://downloads.mariadb.com/galera-test/${GALERA_REPO}/deb ${DEBIAN_VERSION} main > /etc/apt/sources.list.d/galera.list"
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xCE1A3DD5E3C94F49
    sudo apt update
    DEBIAN_FRONTEND=noninteractive sudo apt install -y ${GALERA_PACKAGE_DEB} rsync netcat socat
  fi

  if [[ -e /usr/bin/yum ]]; then
    sudo sh -c "echo '[galera]' > /etc/yum.repos.d/galera.repo"
    sudo sh -c "echo 'name=galera' >> /etc/yum.repos.d/galera.repo"
    sudo sh -c "echo 'baseurl=http://downloads.mariadb.com/galera-test/${GALERA_REPO}/rpm/rhel/\$releasever/\$basearch/' >> /etc/yum.repos.d/galera.repo"
    sudo sh -c "echo 'gpgkey=https://downloads.mariadb.com/MariaDB/RPM-GPG-KEY-MariaDB-Ent' >> /etc/yum.repos.d/galera.repo"
    sudo sh -c "echo 'gpgcheck=1' >> /etc/yum.repos.d/galera.repo"
    sudo cat /etc/yum.repos.d/galera.repo
    sudo yum -y clean all
    sudo yum install -y ${GALERA_PACKAGE} rsync socat lsof
  fi

  if [[ -e /usr/bin/zypper ]]; then
    sudo zypper -n in wget || true
    source /etc/os-release
    RELEASE=${VERSION_ID%.*}
    wget https://downloads.mariadb.com/MariaDB/RPM-GPG-KEY-MariaDB-Ent -O /tmp/rpm.key
    sudo rpm --import /tmp/rpm.key && rm -f /tmp/rpm.key
    sudo zypper rr Galera-Enterprise || true
    sudo zypper ar -f -g http://downloads.mariadb.com/galera-test/${GALERA_REPO}/rpm/sles/${RELEASE}/x86_64/ Galera-Enterprise
    sudo zypper refresh
    sudo zypper -n in ${GALERA_PACKAGE} rsync socat lsof
  fi
#
  export WSREP_PROVIDER=$(sudo find /usr -type f -name 'libgalera*smm.so')
  export WSREP_EXPORT="export WSREP_PROVIDER=${WSREP_PROVIDER}; "
#  [[ -n "${WSREP_PROVIDER}" ]] && export WSREP_PROVIDER
#else
   # remove all disabled.def if it is not galera run
  # sudo find . -type f -name "disabled.def" -exec rm -f {} \;
fi
#
# Run MTR with parameters
cd $(dirname ${0})/../mysql-test/

RUNDIR=$(pwd)
sudo chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${RUNDIR}
sudo chmod a+rx .
sudo chmod a+rx /home -R
sudo mkdir -p ${MYSQL_VARDIR}
sudo mkdir -p ${MYSQL_DATADIR}
sudo chown ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_VARDIR}
sudo chown ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_DATADIR}
sudo su - ${MYSQL_USER} -s /bin/bash -c "${WSREP_EXPORT} cd ${RUNDIR} && perl mysql-test-run.pl ${MTR_RUN_ARGS}"
MTR_RETCODE=${?}
[[ ${MTR_RETCODE} -ne 0 ]] && tar czf ${TARNAME}.tar.gz ${MYSQL_VARDIR}
sudo mv -vf /tmp/${PACKAGE}_*.xml ${TARNAME}.tar.gz ${RUNDIR}/../ ||:
exit ${MTR_RETCODE}
