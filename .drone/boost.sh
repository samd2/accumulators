#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

BOOST_BRANCH=develop && [ "$TRAVIS_BRANCH" == "master" ] && BOOST_BRANCH=master || true
cd ..
git clone -b $TRAVIS_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update --init tools/boost_install
git submodule update --init libs/headers
git submodule update --init tools/build
git submodule update --init libs/config
git submodule update --init tools/boostdep
cp -r $TRAVIS_BUILD_DIR/* libs/accumulators
python tools/boostdep/depinst/depinst.py accumulators
./bootstrap.sh
./b2 headers

echo '==================================> COMPILE'

echo "using $TOOLSET : : $COMPILER ;" > ~/user-config.jam
./b2 --verbose-test libs/config/test//config_info toolset=$TOOLSET cxxstd=$CXXSTD || true
cd libs/accumulators/test
../../../b2 -j`(nproc || sysctl -n hw.ncpu) 2> /dev/null` toolset=$TOOLSET cxxstd=$CXXSTD $CXXSTD_DIALECT
cd ../../..

echo '==================================> AFTER_SUCCESS'

cd $DRONE_CURRENT_BUILD_DIR
. .drone/after-success.sh
