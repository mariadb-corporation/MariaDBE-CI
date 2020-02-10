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
       install git build-essential cmake make libaio-dev
  sudo -E apt-get -q -o Dpkg::Options::=--force-confold \
       -o Dpkg::Options::=--force-confdef \
       -y --force-yes \
       build-dep mariadb-server
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
    sudo yum install -y --nogpgcheck ${enable_power_tools} \
         gcc gcc-c++ make cmake yum-utils libaio-devel
    sudo yum-builddep -y mariadb-server
fi

if [[ ${packager_type} == "zypper" ]]
then
    install_libdir=/usr/lib64
    # We need zypper here
    sudo zypper -n refresh
    sudo zypper -n update
    sudo zypper -n install gcc gcc-c++ make cmake libaio-devel
    sudo zypper -n source-install -d mariadb
fi


${CODETREE}/scripts/${SCRIPT} ${SCRIPT_ARGS:-}
