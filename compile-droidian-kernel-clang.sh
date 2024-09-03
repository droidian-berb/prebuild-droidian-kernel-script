#!/bin/bash

## Script to compile a Droidian kernel with clang
#
# Version: 0.0.8
#
# Upstream-Name: prebuild-droidian-kernel-script
# Source: https://github.com/droidian-berb/prebuild-droidian-kernel-script
#
# Copyright (C) 2024 Berbascum <berbascum@ticv.cat>
# All rights reserved.
#
# BSD 3-Clause License
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the <organization> nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

abort() {
    echo; echo "$*"; exit 1
}

START_DIR="/buildd/sources"
KERNEL_DIR="${START_DIR}"
## Check for /buildd/sources dir
[ -d "${KERNEL_DIR}" ] || abort "The expected ${KERNEL_DIR} does not exist!"
## Check for a kernel tree root
[ -f "$(pwd)/Kconfig" ] || abort "Not in a kernel source dir!"

ROOTDIR="/opt"
## The arch var is used by clang-manual, but not by releng
export ARCH=arm64

fn_install_prereqs() {
 apt-get install linux-packaging-snippets bc bison build-essential ccache curl flex git git-lfs gnupg gperf imagemagick libelf-dev libncurses5-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3
# libsdl1.2-dev
}

fn_install_prereqs_droidian_kernel_info() {
    apt-get install binutils-aarch64-linux-gnu clang-android-${CLANG_VERSION} gcc-4.9-aarch64-linux-android g++-4.9-aarch64-linux-android libgcc-4.9-dev-aarch64-linux-android-cross
}

fn_enable_ccache() {
    ## Use ccache tu speedup the build
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    ccache -M 10G
    ccache -o compression=false
}

fn_install_lineage_toolchains() {
    cd /opt
    # gcc
    git clone -b lineage-18.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git
    #
    # clang
#    git clone https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git
    #
    # build-tools
    los_ver="lineage-18.1"
    los_branch="android-11.0.0_r0.100"
    # los_branch="android-13.0.0_r0.117"
    # los_ver="lineage-20.1"
    git clone -b ${los_branch} \
    https://android.googlesource.com/kernel/prebuilts/build-tools
    git clone -b ${los_branch} https://github.com/LineageOS/android_prebuilts_tools-lineage.git
}

fn_invert_PATH_kernel_snippet() {
    ## NOT USED
    ## Patch releng kernel-snippet.mk
    ## To use the lineage toolchain, the FULL_PATH var needs to be defined with the PATH var at the beguin
    sed -i 's|FULL_PATH = $(BUILD_PATH):$(CURDIR)/debian/path-override:${PATH}|FULL_PATH = ${PATH}:$(BUILD_PATH):$(CURDIR)/debian/path-override|g' /usr/share/linux-packaging-snippets/kernel-snippet.mk
}


######################################
## Clang manual lineage build tools ##
######################################
fn_clang_manual_droidian_gcc_vars() {
    ## TODO: review if still needed
    CLANG_PATH="/usr/lib/llvm-android-${CLANG_VERSION}/bin"
    export PATH="$PATH:${CLANG_PATH}"
}
fn_clang_manual_lineage_gcc_vars() {
    ## TODO: review if still needed
    #CLANG_PATH="$ROOTDIR/android_prebuilts_clang_kernel_linux-x86_clang-r416183b/bin"
    export PATH=$PATH:$ROOTDIR/build-tools/linux-x86/bin:$ROOTDIR/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/aarch64-linux-android/bin:$ROOTDIR/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/bin::$ROOTDIR/android_prebuilts_tools-lineage/linux-x86/bin
}

fn_releng_vars() {
    export ARCH=$(cat "${KERNEL_DIR}" | grep "KERNEL_ARCH" | awk '{print $3}')
    ## CLANG_VERSION requires a same name var in kernel-info.mk
    CLANG_VERSION="$(cat "${KERNEL_DIR}" | grep "^CLANG_VERSION = " | awk '{print $3}')"
}

fn_clang_manual_vars() {
    ## Clang version vars
    # CLANG_VERSION="9.0-r353983c"
    # CLANG_VERSION="10.0-r370808"
    # CLANG_VERSION="11.0-r383902" 
    CLANG_VERSION="12.0-r416183b"
    # CLANG_VERSION="14.0-r450784d"
    # CLANG_VERSION="17.0-r487747"
    ## defconfig files vars
    DEFCONFIG_SOC="vendor/sm8150_defconfig"
    DEFCONFIG_MODEL="vayu_user_defconfig"
    DEFCONFIG_MAIN="vayu_main_defconfig"
    KERNEL_RELEASE="4.14-290-xiaomi-vayu"
    CROSS_TYPE="android" # | gnu
    # COMPILER="aarch64-linux-android-gcc-4.9"
    COMPILER=clang
    CLANG_PATH="${CLANG_PATH}"
    # CLANG=$CLANG_PATH/clang
    #export PATH=${CLANG_PATH}:$PATH
    #export AS=aarch64-linux-${CROSS_TYPE}-as
    #export LD=aarch64-linux-${CROSS_TYPE}-ld
    #export AR=aarch64-linux-${CROSS_TYPE}-ar
    #export NM=aarch64-linux-${CROSS_TYPE}-nm
    # export OBJCOPY=aarch64-linux-${CROSS_TYPE}-objcopy
    # export OBJDUMP=aarch64-linux-${CROSS_TYPE}-objdump
    # export STRIP=aarch64-linux-${CROSS_TYPE}-strip
    export CROSS_COMPILE=aarch64-linux-${CROSS_TYPE}-
    export CROSS_COMPILE_ARM32=aarch64-linux-${CROSS_TYPE}-
    export CLANG_TRIPLE=aarch64-linux-gnu-

}


########################################
## Clang manual compilation functions ##
########################################
fn_mrproper() {
    make -C /buildd/sources ARCH=${ARCH} \
	O=/buildd/sources/out/KERNEL_OBJ \
	CC=$COMPILER \
	mrproper
}

fn_gen_main_defconfig() {
    ## Load soc_defconfig as base
    fn_set_defconfig "${DEFCONFIG_SOC}"
    echo "" && echo "soc_defconfig loaded" && echo ""
    ## Merge model_defconfig into .config
    /buildd/sources/scripts/kconfig/merge_config.sh \
	-O /buildd/sources/out/KERNEL_OBJ \
	-m /buildd/sources/out/KERNEL_OBJ/.config \
	 /buildd/sources/arch/${ARCH}/configs/"${DEFCONFIG_MODEL}"
    echo "" && echo "device_defconfig merged" && echo ""
    ## regenerate .config
    fn_olddefconfig
    echo "" &&  echo ".config regenerated" && echo ""
    ## copy .config to arch configs base dir
    cp -v  out/KERNEL_OBJ/.config \
        /buildd/sources/arch/${ARCH}/configs/${DEFCONFIG_MAIN}
}

fn_set_defconfig() {
    [ -z "${DEFCONFIG_MAIN}" ] && DEFCONFIG_MAIN=$1
    make -C /buildd/sources ARCH=${ARCH} \
	O=/buildd/sources/out/KERNEL_OBJ \
	CC=$COMPILER \
        ${DEFCONFIG_MAIN}
}

fn_merge_fragments() {
    /buildd/sources/scripts/kconfig/merge_config.sh \
	-O /buildd/sources/out/KERNEL_OBJ \
	-m /buildd/sources/out/KERNEL_OBJ/.config \
	/buildd/sources/droidian/vayu.config \
	/buildd/sources/droidian/common_fragments/droidian.config \
	/buildd/sources/droidian/common_fragments/halium.config
}

fn_menuconfig() {
    make -C /buildd/sources ARCH=${ARCH} \
	O=/buildd/sources/out/KERNEL_OBJ \
	CC=$COMPILER \
	menuconfig
}

fn_olddefconfig() {
    make -C /buildd/sources ARCH=${ARCH} \
	O=/buildd/sources/out/KERNEL_OBJ \
	CC=$COMPILER \
	KCONFIG_CONFIG=/buildd/sources/out/KERNEL_OBJ/.config olddefconfig
}

fn_build_kernel_clang_manual() {
    make -C /buildd/sources ARCH=${ARCH} \
     KERNELRELEASE=${KERNEL_RELEASE} \
     LLVM=1 LLVM_IAS=1 \
     -j8 \
     O=/buildd/sources/out/KERNEL_OBJ \
     CC=$COMPILER
     # CXX=clang++ \
}

###########################################
## Droidian releng compilation functions ##
###########################################
fn_build_kernel_droidian_releng() {
    ## Reconf PATH in kernel snippet (if using custom gcc)
    ## Pre compile configs
    chmod +x /buildd/sources/debian/rules
    cd /buildd/sources
    rm -f debian/control
    debian/rules debian/control
    ## Call releng
    RELENG_HOST_ARCH=${ARCH} releng-build-package
}

fn_install_prereqs
fn_enable_ccache

## Custom lineage build tools
# fn_install_lineage_toolchains
   ## Need to define paths in kernel-info.mk

if [ "$1" == "releng" ]; then
    #
    #
#   fn_install_prereqs_droidian_kernel_info
    fn_releng_vars
    fn_build_kernel_droidian_releng
    #
    #
elif [ "$1" == "clang" ]; then
    #
    #
#   fn_install_prereqs_droidian_kernel_info
    fn_clang_manual_droidian_gcc_vars
#   fn_clang_manual_lineage_gcc_vars
    fn_clang_manual_vars
#   fn_menuconfig
#   fn_mrproper
#   fn_gen_main_defconfig
#   fn_set_defconfig
    #fn_merge_fragments
#   fn_olddefconfig
    #### fn_build_kernel_clang_manual
else
    echo
    echo "Please type \"releng\" or \"clang\""
fi
