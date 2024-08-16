#!/bin/bash

## Script to compile a Droidian kernel with clang
#
# Version: 0.0.2
#
# Upstream-Name: compile-droidian-kernel-clang
# Source: https://github.com/droidian-berb/compile-droidian-kernel-clang
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


START_DIR="/buildd/sources"
ROOTDIR="/opt"

fn_install_prereqs() {
 apt-get install linux-packaging-snippets bc bison build-essential ccache curl flex git git-lfs gnupg gperf imagemagick libelf-dev  libncurses5-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3
# libsdl1.2-dev
}

fn_install_toolchains() {
    cd /opt
    ## If kernel is not previously downloaded.
    # git clone https://github.com/LineageOS/android_kernel_device
    #
    # gcc
    git clone -b lineage-18.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git
    #
    # clang
#    git clone https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git
    #
    # wireguard kernel module
    # git clone https://github.com/WireGuard/wireguard-linux-compat.git
    #
    # built-tools

# android-11.0.0_r0.100
# android-13.0.0_r0.117
    git clone -b android-11.0.0_r0.100 https://android.googlesource.com/kernel/prebuilts/build-tools
    git clone -b lineage-18.1 https://github.com/LineageOS/android_prebuilts_tools-lineage.git
}

fn_invert_PATH_kernel_snippet() {
    ## Patch releng kernel-snippet.mk
    ## To use the lineage toolchain, the FULL_PATH var needs to be defined with the PATH var at the beguin
    sed -i 's|FULL_PATH = $(BUILD_PATH):$(CURDIR)/debian/path-override:${PATH}|FULL_PATH = ${PATH}:$(BUILD_PATH):$(CURDIR)/debian/path-override|g' /usr/share/linux-packaging-snippets/kernel-snippet.mk
}

fn_build_kernel_droidian_releng() {
    ## Reconf PATH in kernel snippet (if using custom gcc)
    fn_invert_PATH_kernel_snippet
    ## Pre compile configs
    chmod +x /buildd/sources/debian/rules
    cd /buildd/sources
    rm -f debian/control
    debian/rules debian/control
    ## Call releng
    RELENG_HOST_ARCH=arm64 releng-build-package
}

fn_install_prereqs

## CUSTOM TOOLCHAIN
fn_install_toolchains
   ## Paths are defined in kernel-info.mk
fn_build_kernel_droidian_releng
