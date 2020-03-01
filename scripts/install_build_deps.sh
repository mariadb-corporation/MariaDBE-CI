#!/bin/bash
#
set -x
#

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
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  sudo locale-gen en_US.UTF-8
  sudo dpkg-reconfigure --frontend=noninteractive locales 
  sudo update-locale LANG=en_US.UTF-8
  export DEBIAN_FRONTEND=noninteractive
  export apt_opt="-E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes"
  sudo ${apt_opt} \
       install git build-essential make cmake libaio-dev libssl-dev \
       libncurses5-dev devscripts \
       libcurl3-dev libnuma-dev libsnappy-dev uuid-dev
  sudo ${apt_opt} \
       install dh-systemd libaio-dev  \
       perl-modules libmhash-dev libxml-simple-perl patch \
       apt-utils build-essential sudo git \
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
       net-tools wget
  sudo ${apt_opt} \
       install libzstd-dev
  sudo ${apt_opt} \
       build-dep mariadb-server
  sudo ${apt_opt} \
       install dh-apparmor libjemalloc-dev libkrb5-dev \
       libreadline-gplv2-dev libsystemd-dev
  sudo ${apt_opt} \
       install libbison-dev
  sudo ${apt_opt} \
       install chrpath
  sudo ${apt_opt} \
       install libpcre3-dev
  sudo ${apt_opt} \
       install python-dev
  sudo ${apt_opt} \
       install python2-dev

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

  # columnstore
  sudo ${apt_opt} \
       install libboost-all-dev libsnappy-dev flex expect 
  sudo ${apt_opt} \
       install net-tools autoconf automake libtool
  sudo ${apt_opt} \
       install pkg-config
  sudo ${apt_opt} \
       install libjemalloc1
  sudo ${apt_opt} \
       install libjemalloc2
  #sudo apt-get remove -y --force-yes cmake
fi

if [[ ${packager_type} == "yum" ]]
then
    # YUM!
    sudo yum clean all
    sudo yum update -y
    if [ "${platform_version}" == "6" ]; then
      sudo subscription-manager repos --enable=rhel-6-server-optional-rpms
    fi

    if [ "${platform_version}" == "7" ]; then
      #sudo subscription-manager release --set=7.5
      sudo subscription-manager repos --enable=rhel-7-server-optional-rpms
    fi

    if [ "${platform_version}" == "8" ]; then
      #sudo subscription-manager release --set=8
      sudo subscription-manager repos --enable=codeready-builder-for-rhel-8-x86_64-rpms
    fi

    unset enable_power_tools
    yum repolist all | grep PowerTools
    if [ $? == 0 ]
    then
        enable_power_tools="--enablerepo=PowerTools"
    fi
    sudo yum -y install yum-utils
    sudo yum -y groupinstall 'Development Tools'
    sudo yum install -y --nogpgcheck ${enable_power_tools} \
         gcc gcc-c++ make yum-utils libaio-devel \
         openssl-devel gnutls-devel libgcrypt-devel pam-devel \
         ncurses-devel bison zlib-devel libevent-devel wget
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
    sudo yum install -y --nogpgcheck ${enable_power_tools} devtoolset-3-gcc-c++ devtoolset-3-valgrind-devel devtoolset-3-libasan-devel clang
    sudo yum install -y --nogpgcheck ${enable_power_tools} perl-Time-HiRes
    sudo yum install -y --nogpgcheck ${enable_power_tools} perl-Memoize

    sudo yum install -y --nogpgcheck ${enable_power_tools} ccache
    sudo yum install -y --nogpgcheck ${enable_power_tools} libffi-devel
    sudo yum install -y --nogpgcheck ${enable_power_tools} python-devel
    sudo yum install -y --nogpgcheck ${enable_power_tools} python2-pip

#    if [ "${platform_version}" == "6" ]; then
#      # boost update
#      sudo yum remove -y boost-*
#      BOOST_VER="1.61.0"
#      wget https://sourceforge.net/projects/boost/files/boost/${BOOST_VER}/boost_${BOOST_VER//./_}.tar.gz
#      tar xzf boost_${BOOST_VER//./_}.tar.gz
#      cd boost_${BOOST_VER//./_}
#      ./bootstrap.sh
#      sudo ./b2 install
#      cd ..
#    fi

    sudo yum -y erase cmake || true
fi

if [[ ${packager_type} == "zypper" ]]
then
    # We need zypper here
    sudo zypper -n refresh
    sudo zypper -n update
    sudo zypper -n install \
        make gcc wget \
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
    sudo zypper -n remove cmake
    #columnstore
    sudo zypper -n install snappy-devel expect jemalloc net-tools flex libboost_*-devel autoconf automake libtool
fi


