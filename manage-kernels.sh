#!/bin/bash


list_kernels() {
    current=$(uname -r)
    #default=$(sudo grubby --default-kernel | sed 's|.*/vmlinuz-||; s|"||g')

    #kernel="/boot/vmlinuz-6.6.0-tdx-io-test-ready" -> /boot/vmlinuz-6.6.0-tdx-io-test-ready
    default=$(sudo grubby --default-kernel | sed 's|^kernel=||; s|"||g')

    for k in $(sudo grubby --info=ALL | grep '^kernel=' | sed 's|^kernel=||; s|"||g'); do
        marker=""
        if [[ "$k" =~ "$current" ]]; then
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

build_kernel() {
    local do_install="$1"
    local SUFFIX=-tdx-io-remote-rootport
    local use_git_sha=false

    scripts/config --disable LOCALVERSION_AUTO
    make olddefconfig

    if [[ "$use_git_sha" == "true" ]]; then
        SHA=$(git rev-parse --short HEAD)
        SUFFIX="${SUFFIX}-${SHA}"
    fi

    fakeroot make -j10 LOCALVERSION="$SUFFIX"

    if [[ "$do_install" == "install" ]]; then
        sudo make modules_install
        sudo make install
    fi

    local KERNEL_RELEASE
    KERNEL_RELEASE=$(cat include/config/kernel.release)
    echo "Kernel release is: $KERNEL_RELEASE"
    if [[ "$do_install" == "install" ]]; then
        echo "Kernel installed in grub and populated to /boot"
    else
        echo "Kernel only built but not installed"
    fi
}

check_grubby() {
    if ! command -v grubby &>/dev/null; then
        echo "grubby not found"
        return 1
    fi
}

set_default_kernel() {
    check_grubby || return 1

    local version
    version=$(cat include/config/kernel.release)

    sudo grubby --set-default /boot/vmlinuz-"${version}" 1>/dev/null 2>&1
    echo "Default kernel set to: $(sudo grubby --default-kernel)"
}

set_cmdline() {
    check_grubby || return 1

    local version
    version=$(cat include/config/kernel.release)

    local kernel="/boot/vmlinuz-${version}"
    local cmdline="ro resume=/dev/mapper/cs_gnr--jf04--5350-swap rd.lvm.lv=cs_gnr-jf04-5350/root rd.lvm.lv=cs_gnr-jf04-5350/swap rhgb quiet selinux=0 console=tty0 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 intel_iommu=on,sm_on numa_balancing=disable tsc=recalibrate tdxio ${tuned_params} crashkernel=6G panic=30"

    sudo grubby --update-kernel="$kernel" --args="$cmdline" 1>/dev/null 2>&1
    echo "Cmdline set for: $kernel"
    echo "$cmdline"
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
    build)
        build_kernel "$2"
        ;;
    set-default)
        set_default_kernel
        ;;
    set-cmdline)
        set_cmdline
        ;;
    misc)
        misc
        ;;
    *)
        echo "Usage:"
        echo "  $0 list-all"
        echo "  $0 list <version>"
        echo "  $0 remove <version>"
        echo "  $0 set-default    # set default to kernel from include/config/kernel.release"
        echo "  $0 set-cmdline    # set kernel cmdline for kernel from include/config/kernel.release"
        echo "  $0 build          # build only"
        echo "  $0 build install  # build and install"
        echo "  $0 misc"
        ;;
esac
