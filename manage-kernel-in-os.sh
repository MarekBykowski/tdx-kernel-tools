#!/bin/bash

if [[ $1 == remove ]]; then
	version="6.6.0-v35.2-tony-custom-g73218750293b-dirty"
	version="6.6.0-marek-crash-g50dbeda4185c"
	version="6.6.0-marek-gac4882cfd43f"
	if [[ $1 == list ]]; then
		sudo grubby --info ALL | grep ^kernel=.*${version}
		ls /boot/vmlinuz-${version}
		ls /boot/initramfs-${version}.img
		ls /boot/System.map-${version}
	elif [[ $1 == remove ]]; then
		sudo grubby --remove-kernel=/boot/vmlinuz-${version}
		sudo rm -f /boot/vmlinuz-${version}
		sudo rm -f /boot/initramfs-${version}.img
		sudo rm -f /boot/System.map-${version}
	fi
else 
cat <<- 'EOF'
echo "List kernel menu entries"
sudo grubby --info ALL

echo "Update cmdline"
version=$(cat include/config/kernel.release)
kernel="/boot/vmlinuz-${version}"
sudo grubby --update-kernel=${kernel} --args="$tuned_params ro resume=/dev/mapper/cs_gnr--jf04--5350-swap rd.lvm.lv=cs_gnr-jf04-5350/root rd.lvm.lv=cs_gnr-jf04-5350/swap rhgb quiet selinux=0 console=tty0 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 intel_iommu=on,sm_on numa_balancing=disable tsc=recalibrate tdxio crashkernel=6G panic=30"

echo "Set default kernel"
sudo ls -1 /boot/loader/entries/
sudo grub2-set-default <entry> without .conf
sudo grub2-editenv list
EOF
fi
