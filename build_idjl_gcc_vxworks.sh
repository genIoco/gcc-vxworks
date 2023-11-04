#! /bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will download packages for, configure, build and install a GCC cross-compiler.
# Customize the variables (INSTALL_PATH, TARGET, etc.) to your liking before running.
# If you get an error and need to resume the script from some point in the middle,
# just delete/comment the preceding lines before running it again.
#
# Based on http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
#-------------------------------------------------------------------------------------------

export SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export INSTALL_PATH=${SCRIPTPATH}/install
export TARGET=i586-wrs-vxworks
export CONFIGURATION_OPTIONS="--enable-threads=posix --disable-multilib --disable-libssp --disable-libquadmath --disable-libquadmath-support --enable-libstdcxx --disable-libstdcxx-pch --disable-libitm --disable-libcc1 --with-native-system-header-dir=${SCRIPTPATH}/wrs-vxworks-headers/sys-include"
export PARALLEL_MAKE=-j20
BINUTILS_VERSION=binutils-2.30
export GCC_VERSION=gcc-7.3.0
MPFR_VERSION=mpfr-4.0.1
GMP_VERSION=gmp-6.1.2
MPC_VERSION=mpc-1.1.0
ISL_VERSION=isl-0.18
CLOOG_VERSION=cloog-0.18.1
export PATH=$INSTALL_PATH/bin:$PATH


# Download packages
export http_proxy=$HTTP_PROXY https_proxy=$HTTP_PROXY ftp_proxy=$HTTP_PROXY
wget -nc https://ftp.gnu.org/gnu/binutils/$BINUTILS_VERSION.tar.gz
wget -nc https://ftp.gnu.org/gnu/gcc/$GCC_VERSION/$GCC_VERSION.tar.gz
wget -nc https://ftp.gnu.org/gnu/mpfr/$MPFR_VERSION.tar.xz
wget -nc https://ftp.gnu.org/gnu/gmp/$GMP_VERSION.tar.xz
wget -nc https://ftp.gnu.org/gnu/mpc/$MPC_VERSION.tar.gz
wget -nc ftp://gcc.gnu.org/pub/gcc/infrastructure/$ISL_VERSION.tar.bz2
wget -nc ftp://gcc.gnu.org/pub/gcc/infrastructure/$CLOOG_VERSION.tar.gz

# Download VxWorks headers 
# See https://aur.archlinux.org/packages/wrs-vxworks-headers/
# See https://github.com/rbmj/wrs-headers-installer 
wget -nc http://ftp.ni.com/pub/devzone/tut/updated_vxworks63gccdist.zip

# Extract VxWorks headers 
unzip -o updated_vxworks63gccdist.zip
mkdir -p wrs-vxworks-headers/{wind_base/target,share/ldscripts}
cp -dpr --no-preserve=ownership gccdist/WindRiver/vxworks-6.3/host wrs-vxworks-headers/wind_base
cp -dpr --no-preserve=ownership gccdist/WindRiver/vxworks-6.3/target/h/. wrs-vxworks-headers/sys-include
cp -dpr --no-preserve=ownership gccdist/WindRiver/vxworks-6.3/target/h/wrn/coreip/. wrs-vxworks-headers/include
cp -dpr --no-preserve=ownership gccdist/WindRiver/vxworks-6.3/target/h/wrn/coreip/. wrs-vxworks-headers/wind_base/target/h
export WIND_BASE=${SCRIPTPATH}/wrs-vxworks-headers/wind_base
export VSB_DIR=""

mkdir -p install
cp -dpr --no-preserve=ownership  wrs-vxworks-headers/sys-include install/i586-wrs-vxworks

# Cleanup possible leftovers before extracting everything
rm -rf ./$BINUTILS_VERSION
rm -rf ./$GMP_VERSION
rm -rf ./$MPC_VERSION
rm -rf ./$MPFR_VERSION
rm -rf ./$ISL_VERSION
rm -rf ./$CLOOG_VERSION
rm -rf ./$BINUTILS_VERSION
rm -rf ./$GCC_VERSION

# Extract everything
for f in *.tar*; do tar -xvf $f; done

# Make symbolic links
cd $GCC_VERSION
ln -sf `ls -1d ../mpfr-*/` mpfr
ln -sf `ls -1d ../gmp-*/` gmp
ln -sf `ls -1d ../mpc-*/` mpc
ln -sf `ls -1d ../isl-*/` isl
ln -sf `ls -1d ../cloog-*/` cloog
cd ..

# Build Binutils
mkdir -p build-binutils
cd build-binutils
../$BINUTILS_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET $CONFIGURATION_OPTIONS
make $PARALLEL_MAKE
make install
cd ..

# Apply GCC patch (see https://aur.archlinux.org/cgit/aur.git/tree/pointer-cast.patch?h=powerpc-wrs-vxworks-gcc)
cd $GCC_VERSION 
patch -p1 < ../pointer-cast.patch 
cd ..

# Apply GCC patch to enable posix thread support 
cd $GCC_VERSION 
patch -p1 < ../patches/vxworks-pthread.patch 
cd ..

# Build C/C++ Compilers
mkdir -p build-gcc
cd build-gcc
../$GCC_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET --enable-languages=c,c++ $CONFIGURATION_OPTIONS 
make $PARALLEL_MAKE all-gcc
make install-gcc
cd ..

# Compiler Support Library
cd build-gcc
make $PARALLEL_MAKE all-target-libgcc
make install-target-libgcc
cd ..

# Standard C++ Library
cd build-gcc
make $PARALLEL_MAKE all-target-libstdc++-v3
make install
cd ..

# the rest of GCC
cd build-gcc
make $PARALLEL_MAKE all
make install
cd ..

# The VxWorks headers distributed by National Instruments target VxWorks 6.3, 
# but we are actually targeting VxWorks 6.9 in IDJL builds 
# For this reason we actually create a sys/time.h header and install it, just containing
# the definition of the gettimeofday function
mkdir -p $INSTALL_PATH/include/i586-wrs-vxworks/idjl-include/sys
cp ${SCRIPTPATH}/sys_time.h $INSTALL_PATH/include/i586-wrs-vxworks/idjl-include/sys/time.h
# We also add a dummy select.h that just includes VxWorks's selectLib.h 
cp ${SCRIPTPATH}/sys_select.h $INSTALL_PATH/include/i586-wrs-vxworks/idjl-include/sys/select.h

# Also the poll.h and the uio.h header are not in the correct location, we copy it there 
cp ${SCRIPTPATH}/wrs-vxworks-headers/sys-include/wrn/coreip/poll.h $INSTALL_PATH/include/i586-wrs-vxworks/idjl-include/sys/poll.h
cp ${SCRIPTPATH}/wrs-vxworks-headers/include/net/uio.h $INSTALL_PATH/include/i586-wrs-vxworks/idjl-include/sys/uio.h


# Copy the custom CMake toolchain file 
cp ./idjl_vxworks_toolchain.cmake.in $INSTALL_PATH/idjl_vxworks_toolchain.cmake
cp -r ./Platform $INSTALL_PATH/Platform

cp ./setup.sh.in $INSTALL_PATH/setup.sh

# Copy the directory for then defining the WIND_BASE env variable 
cp -r ./wrs-vxworks-headers $INSTALL_PATH/wrs-vxworks-headers

trap - EXIT
echo 'Success!'
