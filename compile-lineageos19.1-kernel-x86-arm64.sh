#!/bin/bash

## Script to compile a lineageos 19.1 kernel with clang
#
# REFERENCES: To do this script, the next link was consulted:
# https://thedoc.eu.org/blog/lineage-os-20-kernel-wireguard-module/
#
# Version: 0.0.1
#
# Upstream-Name: prebuild-droidian-kernel-script
# Source: https://github.com/droidian-berb/prebuild-droidian-kernel-script
#
# Copyright (C) 2024 Berbascum <berbascum@ticv.cat>
# All rights reserved.
#
# BSD 3-Clause License
#
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

## Download lineage build tools
START_DIR="/buildd/sources"
ROOTDIR="/opt"

fn_install_prereqs() {
 apt-get install bc bison build-essential ccache curl flex git git-lfs gnupg gperf imagemagick libelf-dev  libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3
}

fn_enable_ccache() {
    ## Use ccache tu speedup the build
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    ccache -M 10G
    ccache -o compression=true
}

fn_install_toolchains() {
    cd /opt

    ## If kernel is not previously downloaded.
    # git clone https://github.com/LineageOS/android_kernel_device
    #
    # gcc
    git clone -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git
    #
    # clang
    git clone https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git
    #
    # wireguard kernel module
    # git clone https://github.com/WireGuard/wireguard-linux-compat.git
    #
    # built-tools
    git clone -b android-13.0.0_r0.117 https://android.googlesource.com/kernel/prebuilts/build-tools
    git clone https://github.com/LineageOS/android_prebuilts_tools-lineage.git
}


fn_build_kernel() {
    #rm -rf build
    #mkdir build
    #cd android_kernel_oneplus_sm8150
    cd /buildd/sources


    BINARIES=$PATH:$ROOTDIR/build-tools/linux-x86/bin:$ROOTDIR/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/aarch64-linux-android/bin:$ROOTDIR/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/bin:$ROOTDIR/android_prebuilts_clang_kernel_linux-x86_clang-r416183b/bin:$ROOTDIR/android_prebuilts_tools-lineage/linux-x86/bin

    ## clean
    # make O=/buildd/sources/out/KERNEL_OBJ \
    #	ARCH=arm64 clean

    ## mrproper
    make O=/buildd/sources/out/KERNEL_OBJ \
	ARCH=arm64 mrproper

    ## Create .config
    make  O=/buildd/sources/out/KERNEL_OBJ \
	ARCH=arm64 PATH=$BINARIES CC=clang \
	CROSS_COMPILE=aarch64-linux-android- \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	vayu_user_defconfig
        #BRAND_SHOW_FLAG=vayu TARGET_PRODUCT=vayu

    ## Compile kernel
    #make KCFLAGS="-Wall -Wextra -g" V=1 \
    make \
	-j4 O=/buildd/sources/out/KERNEL_OBJ \
        ARCH=arm64 PATH=$BINARIES CC=clang \
	CROSS_COMPILE=aarch64-linux-android- \
	CLANG_TRIPLE=aarch64-linux-gnu-
}

# fn_install_prereqs
fn_install_toolchains
# fn_enable_ccache
# fn_build_kernel
