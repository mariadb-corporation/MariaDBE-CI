#!/usr/bin/env bash
#
set -xe
#
# GIT_BRANCH and GIT_COMMIT are runtime variables
echo "GIT_BRANCH=${GIT_BRANCH}" >  build.properties
echo "GIT_COMMIT=${GIT_COMMIT}" >> build.properties
cat build.properties
#
cmake . -DBUILD_CONFIG=enterprise
make dist
#
. VERSION
#
echo "SHORT_VERSION=${MYSQL_VERSION_MAJOR}.${MYSQL_VERSION_MINOR}" >> build.properties
echo "FULL_VERSION=${MYSQL_VERSION_MAJOR}.${MYSQL_VERSION_MINOR}.${MYSQL_VERSION_PATCH}${MYSQL_VERSION_EXTRA}" >> build.properties
