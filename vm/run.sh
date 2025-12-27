#!/bin/bash
set -e

source "$(dirname "$0")/../scripts/utils.sh"
DISK_IMG="$(dirname "$0")/debian-amd64-xfce.img"
KERNEL="$(get_root_dir)/linux/arch/x86/boot/bzImage"
INITRD="$(dirname "$0")/initrd.img"

print_info "Starting QEMU with kernel $KERNEL and disk image $DISK_IMG..."
qemu-system-x86_64 \
	-enable-kvm \
	-cpu host \
	-smp 2 \
	-m 4G \
	-usb \
	-device usb-tablet \
	-kernel "$KERNEL" \
	-initrd "$INITRD" \
	-append "root=/dev/vda rw loglevel=3 lsm=warden" \
	-drive file="$DISK_IMG",format=raw,if=virtio \
	-vga virtio \
	-display sdl,gl=on
