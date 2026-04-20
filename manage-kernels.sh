#!/bin/bash


list_kernels() {
    current=$(uname -r)
    default=$(sudo grubby --default-kernel | sed 's|.*/vmlinuz-||; s|"||')

    for k in $(sudo grubby --info=ALL | grep '^kernel=' | sed 's|.*/vmlinuz-||; s|"||'); do
        marker=""
        if [[ "$k" == "$current" ]]; then
		echo -e "  $k\t\t\t\t<- default"
	else 
		echo "  $k"
	fi
    done
}

remove_kernel() {
    local action="$1"
    local version="$2"

    if [[ -z "$version" ]]; then
        echo "Usage: $0 remove|list <kernel-version>"
        return 127
    fi

    local current
    current=$(uname -r)

    if [[ "$version" == "$current" ]]; then
        echo "Refusing to operate on currently running kernel!"
        return 1
    fi

    if [[ "$action" == "list" ]]; then
        echo "Checking kernel files for: $version"
	sudo grubby --info ALL | grep ^kernel=.*${version}
        ls -l /boot/vmlinuz-"${version}"
        ls -l /boot/initramfs-"${version}".img
        ls -l /boot/System.map-"${version}"
    elif [[ "$action" == "remove" ]]; then
        echo "Removing kernel: $version"
        sudo grubby --remove-kernel=/boot/vmlinuz-"${version}"
        sudo rm -f /boot/vmlinuz-"${version}"
        sudo rm -f /boot/initramfs-"${version}".img
        sudo rm -f /boot/System.map-"${version}"
    else
        echo "Unknown action: $action"
        return 1
    fi
}

misc() {
cat <<-'EOF'
echo "List kernel menu entries"
sudo grubby --info ALL

echo "Update cmdline"
version=$(cat include/config/kernel.release)
kernel="/boot/vmlinuz-${version}"
sudo grubby --update-kernel=${kernel} --args="$tuned_params ro resume=/dev/mapper/cs_gnr--jf04--5350-swap rd.lvm.lv=cs_gnr-jf04-5350/root rd.lvm.lv=cs_gnr-jf04-5350/swap rhgb quiet selinux=0 console=tty0 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 intel_iommu=on,sm_on numa_balancing=disable tsc=recalibrate tdxio crashkernel=6G panic=30"

echo "Set default kernel"
sudo ls -1 /boot/loader/entries/
sudo grub2-set-default <entry>
sudo grub2-editenv list
EOF
}


case "$1" in
    list-all)
        list_kernels
        ;;
    list|remove)
        remove_kernel "$1" "$2"
        ;;
    misc)
        misc
        ;;
    *)
        echo "Usage:"
        echo "  $0 list-all"
        echo "  $0 list <version>"
        echo "  $0 remove <version>"
        echo "  $0 misc"
        ;;
esac
