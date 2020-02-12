#!/usr/bin/env bash
#
set -x
#
CODETREE=${PWD}/MariaDBEnterprise
GIT_RESET=no
IMAGE_PREFIX=es-build
SCRIPT=es-build.sh
SCRIPT_ARGS=${SCRIPT_ARGS:-}
#
function show_help {
cat <<-EOF
    Parameters are:
       ????
EOF
}
#
while [ ${#} -gt 0 ]; do
    case ${1} in
        --code-tree)
            CODETREE=${2}
            shift 2
            ;;
        --make-sourcetar)
            SCRIPT_ARGS+=" ${1}"
            shift
            ;;
        --build-type)
            SCRIPT_ARGS+=" ${1}"
            SCRIPT_ARGS+=" ${2}"
            shift 2
            ;;
        --make-rpm)
            SCRIPT_ARGS+=" ${1}"
            MOUNTDIR="${MOUNTDIR}/_padding_for_CPACK_RPM_BUILD_SOURCE_DIRS_PREFIX"
            shift
            ;;
        --make-deb)
            SCRIPT_ARGS+=" ${1}"
            shift
            ;;
        *)
            echo "Wrong parameter: ${1}"
            show_help
            exit 1
            ;;
    esac
done

distro_id=`cat /etc/*-release | grep "^ID_LIKE=" | sed "s/ID=//"`

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
       install git build-essential cmake make libaio-dev libssl-dev \
       libncurses5-dev devscripts \
       libcurl3-dev libnuma-dev libsnappy-dev uuid-dev
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       install dh-systemd libaio-dev  \
       perl-modules libmhash-dev libxml-simple-perl patch \
       apt-utils build-essential python-dev sudo git \
       devscripts equivs libcurl4-openssl-dev \
       ccache python3 python3-pip curl libssl-dev \
       libevent-dev dpatch gawk gdb \
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
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       install libzstd-dev
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       build-dep mariadb-server
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       install dh-apparmor libjemalloc-dev libkrb5-dev \
       libreadline-gplv2-dev libsystemd-dev
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       install libbison-dev
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       install chrpath

  cat /etc/*release | grep -E "Trusty|wheezy"
  if [ $? == 0 ]
  then
     sudo apt-get install -y --force-yes libgnutls-dev libgcrypt11-dev
  else
     sudo apt-get install -y --force-yes libgnutls30 libgnutls-dev
     if [ $? != 0 ]
     then
         sudo apt-get install -y --force-yes libgnutls28-dev
     fi
     sudo apt-get install -y --force-yes libgcrypt20-dev
     if [ $? != 0 ]
     then
         sudo apt-get install -y --force-yes libgcrypt11-dev
     fi
  fi
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
         gcc gcc-c++ make cmake yum-utils libaio-devel \
         openssl-devel gnutls-devel libgcrypt-devel pam-devel \
         ncurses-devel bison zlib-devel libevent-devel
    sudo yum install -y --nogpgcheck ${enable_power_tools} rpm-build
    sudo yum install -y --nogpgcheck ${enable_power_tools} rpmbuild
    sudo yum install -y --nogpgcheck ${enable_power_tools} rpmdevtools
    sudo yum install -y --nogpgcheck ${enable_power_tools} \
         libaio-devel libxml2-devel perl-Data-Dumper \
         perl-XML-LibXML curl-devel libxml2-devel gnutls-devel perl-XML-Simple \
         boost-devel check-devel which systemd-devel \
         cracklib-devel rsync socat lsof patch valgrind-devel \
         snappy-devel expect net-tools
    sudo yum install -y --nogpgcheck ${enable_power_tools} mhash-devel
    sudo yum install -y --nogpgcheck ${enable_power_tools} scons
    sudo yum install -y --nogpgcheck ${enable_power_tools} Judy-devel
    sudo yum install -y --nogpgcheck ${enable_power_tools} jemalloc
    sudo yum install -y --nogpgcheck devtoolset-3-gcc-c++ devtoolset-3-valgrind-devel devtoolset-3-libasan-devel clang
fi

if [[ ${packager_type} == "zypper" ]]
then
    # We need zypper here
    sudo zypper -n refresh
    sudo zypper -n update
    sudo zypper -n install \
        cmake make gcc \
        gcc-c++ libaio-devel perl-XML-Simple \
        bison libopenssl-devel \
        ncurses-devel \
        rsync socat lsof tar gzip bzip2 rpm-build \
        checkpolicy policycoreutils curl perl \
        wget sudo git-core \
        expect net-tools flex autoconf automake libtool \
        perl-XML-LibXML patch zlib-devel \
        libgcrypt-devel  libxml2-devel libcurl-devel  \
        boost-devel snappy-devel valgrind-devel check-devel \
        libevent-devel libgnutls-devel pam-devel \
        systemd-devel libgnutls-devel
    sudo zypper -n install rpmbuild
    sudo zypper -n install rpm-build
    sudo zypper -n install scons
    sudo zypper -n install perl-Data-Dump
    sudo zypper -n source-install -d mariadb
fi

# cmake
wget -q https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.tar.gz --no-check-certificate
sudo tar xzf cmake-3.16.4-Linux-x86_64.tar.gz -C /usr/ --strip-components=1

cmake_version=`cmake --version | grep "cmake version" | awk '{ print $3 }'`
if [ "`echo -e "3.16.4\n$cmake_version"|sort -V|head -n 1`" != "3.16.4" ] ; then
    echo "cmake does not work! Trying to build from source"
    wget -q https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4.tar.gz --no-check-certificate
    tar xzf cmake-3.16.4.tar.gz
    cd cmake-3.16.4

    ./bootstrap
    gmake
    sudo make install
    cd ..
fi

export PLATFORM=${Image}

${CODETREE}/scripts/${SCRIPT} ${SCRIPT_ARGS:-}
