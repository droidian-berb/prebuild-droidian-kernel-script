#!/bin/bash

## This script is only a launcher that automates some steps from the official Droidian porting guide.
#
# Guide URL: https://github.com/droidian/porting-guide/blob/master/kernel-compilation.md#kernel-adaptation

chmod +x /buildd/sources/debian/rules
cd /buildd/sources
rm -f debian/control
debian/rules debian/control

RELENG_HOST_ARCH=arm64 releng-build-package
