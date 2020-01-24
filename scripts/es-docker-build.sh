#!/usr/bin/env bash
#
set -x
#
CODETREE=${PWD}/MariaDBEnterprise
GIT_RESET=no
REGISTRY=registry.abychko.expert:5000
IMAGE_PREFIX=es-build
MOUNTDIR=/tmp/${IMAGE_PREFIX}
DOCKER_IMAGE=${DOCKER_IMAGE:-ubuntu-2004}
SCRIPT=es-build.sh
SCRIPT_ARGS=${SCRIPT_ARGS:-}
#
function show_help {
cat <<-EOF
    Parameters are:
        --code-tree    | default ${PWD}/MariaDBEnterprise
        --git-branch   | default 10.2-enterprise
        --image-prefix | default es-build
        --mount-dir    | default /tmp/es-build
        --docker-image | default ubuntu-2004
EOF
}
#
while [ ${#} -gt 0 ]; do
    case ${1} in
        --code-tree)
            CODETREE=${2}
            shift 2
            ;;
        --run-script)
            SCRIPT=${2}
            shift 2
            ;;
        --git-branch)
            GIT_BRANCH=${2#*/}
            GIT_BRANCH=${GIT_BRANCH//+/p}
            shift 2
            ;;
        --git-reset)
            GIT_RESET=yes
            shift
            ;;
        --registry)
            REGISTRY=${2}
            shift 2
            ;;
        --image-prefix)
            IMAGE_PREFIX=${2}
            shift 2
            ;;
        --mount-dir)
            MOUNTDIR=${2}
            shift 2
            ;;
        --docker-image)
            DOCKER_IMAGE=${2}
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
#
# run options
DOCKER_PARAMS="-dit"

# container name
DOCKER_NAME+="${GIT_BRANCH}_${DOCKER_IMAGE}"

# setting the name
DOCKER_PARAMS+=" --name ${DOCKER_NAME}"

# bind mount options
DOCKER_PARAMS+=" --mount type=bind,source=${CODETREE},target=${MOUNTDIR}"

# image to run
DOCKER_PARAMS+=" ${REGISTRY}/${IMAGE_PREFIX}/${DOCKER_IMAGE}"

# finally
[[ ${GIT_RESET} = yes ]] && (cd ${CODETREE} && git reset --hard)

docker run ${DOCKER_PARAMS} /bin/bash -c "IMAGE=${DOCKER_IMAGE} ${MOUNTDIR}/scripts/${SCRIPT} ${SCRIPT_ARGS:-}"
docker logs --follow ${DOCKER_NAME} | tee ${DOCKER_NAME}_build.log
DOCKER_RETCODE=$(docker wait ${DOCKER_NAME})
docker rm ${DOCKER_NAME}
exit ${DOCKER_RETCODE}
