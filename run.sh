#!/bin/bash

set -x
use_git_sha=false

scripts/config --disable LOCALVERSION_AUTO
# Fixes .config internal state
make olddefconfig

if [[ "$use_git_sha" == "true" ]]; then
	# Does show SHA but without dirty/not dirty
	# Typically we do not want that as this pollutes the grubby and /boot
	SHA=$(git rev-parse --short HEAD)
	SUFFIX="-tdx-io-g${SHA}"
else
	# Only shows the string.
	# With subsequent commits no pollution for grubby, and /boot
	# This is what we typically want
	SUFFIX="-tdx-io"
fi

fakeroot make -j10 LOCALVERSION="$SUFFIX"

if [[ $1 == install ]]; then
	sudo make modules_install
	sudo make install
fi

KERNEL_RELEASE=$(cat include/config/kernel.release)
echo "Kernel release is: $KERNEL_RELEASE"
if [[ $f == install ]]; then
	echo "Kernel installed in grub and populated to /boot"
else
	echo "Kernel only built but not installed"
fi
