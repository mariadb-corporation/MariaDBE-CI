#!/bin/bash
#
set -x
#
export script_dir="$(dirname $(readlink -f $0))"
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

${script_dir}/install_build_deps.sh

sudo wget https://cmake.org/files/v3.15/cmake-3.15.3-Linux-x86_64.sh -O /tmp/cmake.sh
sudo /bin/bash /tmp/cmake.sh --prefix=/usr --exclude-subdir --skip-license
sudo rm -f /tmp/cmake.sh
cmake --version

# cmake
#CMAKE_VER="3.15.3"
#wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-Linux-x86_64.tar.gz --no-check-certificate
#sudo tar xzf cmake-${CMAKE_VER}-Linux-x86_64.tar.gz -C /usr/ --strip-components=1
#rm cmake-${CMAKE_VER}-Linux-x86_64.tar.gz

#cmake_version=`cmake --version | grep "cmake version" | awk '{ print $3 }'`
#if [ "`echo -e "${CMAKE_VER}\n$cmake_version"|sort -V|head -n 1`" != "${CMAKE_VER}" ] ; then
#    echo "cmake does not work! Trying to build from source"
#    wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}.tar.gz --no-check-certificate
#    tar xzf cmake-${CMAKE_VER}.tar.gz
#    cd cmake-${CMAKE_VER}
#
#    ./bootstrap
#    gmake
#    sudo make install
#    cd ..
#    rm -rf cmake-${CMAKE_VER}.tar.gz
#    rm -rf cmake-${CMAKE_VER}
#fi

export PLATFORM=${Image}

${CODETREE}/scripts/${SCRIPT} ${SCRIPT_ARGS:-}
