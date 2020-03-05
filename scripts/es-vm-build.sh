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

${CODETREE}/scripts/${SCRIPT} ${SCRIPT_ARGS:-}
