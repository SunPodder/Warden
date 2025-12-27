#!/bin/bash
set -e

source "$(dirname "$0")/../scripts/utils.sh"

ROOT_DIR=$(get_root_dir)
KERNEL_VERSION="$(cd "$ROOT_DIR/linux" && make -s kernelrelease)"
SYSTEM_IMAGE="$(dirname "$0")/debian-amd64-xfce.img"
INITRD="$(dirname "$0")/initrd.img"
SIZE_MB=${DEBIAN_IMAGE_SIZE_MB:-4096}						# image size in MB (4GB)
DIST=forky													# Debian distribution to use
ARCH=amd64
MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
MOUNTDIR=/mnt/warden-debian

print_info "Using Debian mirror: $MIRROR"
print_info "Image size: ${SIZE_MB}MB"
echo ""

if [ -f "$SYSTEM_IMAGE" ]; then
	print_warn "$SYSTEM_IMAGE already exists. Do you want to overwrite it? (y/N)"
	read -r answer
	if [[ ! "$answer" =~ ^[Yy]$ ]]; then
		exit 1
	else
		rm -f "$SYSTEM_IMAGE" "$INITRD"
	fi
fi

if [[ $EUID -ne 0 ]]; then
	print_err "Root privileges are required (to create and mount disk image)."
	exec sudo bash "$0" "$@"
	exit 0
fi

if ! command -v debootstrap >/dev/null 2>&1; then
	echo "debootstrap not found, installing..."
	apt install -y debootstrap
fi

print_info "Creating disk image: $SYSTEM_IMAGE"
dd if=/dev/zero of="$SYSTEM_IMAGE" bs=1M count="$SIZE_MB" status=progress > /dev/null
mkfs.ext4 -F "$SYSTEM_IMAGE"

mkdir -p "$MOUNTDIR"
if ! mount "$SYSTEM_IMAGE" "$MOUNTDIR"; then
	print_err "Failed to mount ${SYSTEM_IMAGE} to ${MOUNTDIR}"
	exit 1
fi

print_info "Bootstrapping Debian $DIST"
debootstrap --arch="$ARCH" "$DIST" "$MOUNTDIR" "$MIRROR"

print_info "Installing kernel modules to $MOUNTDIR"
(cd "$ROOT_DIR/linux" && make INSTALL_MOD_PATH="$MOUNTDIR" modules_install)

print_info "Configuring system"
mount --bind /dev	"$MOUNTDIR/dev"
mount --bind /proc "$MOUNTDIR/proc"
mount --bind /sys	"$MOUNTDIR/sys"

cleanup(){
	print_info "Cleaning up..."
	umount -R "$MOUNTDIR"
	rmdir "$MOUNTDIR"
}
trap cleanup EXIT

cat > "$MOUNTDIR/etc/fstab" <<FSTAB
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/vda        /               ext4    errors=remount-ro 0       1
FSTAB

cp /etc/resolv.conf "$MOUNTDIR/etc/resolv.conf"

chroot "$MOUNTDIR" /usr/bin/env KERNEL_VERSION="$KERNEL_VERSION" /bin/bash <<EOF
set -e

export DEBIAN_FRONTEND=noninteractive

apt update > /dev/null 2>&1
apt install -y \
	xfce4 xfce4-terminal \
	lightdm \
	xorg dbus-x11 \
	sudo \
	network-manager \
	ca-certificates \
	mesa-utils \
	vim \
	fonts-dejavu \
	initramfs-tools busybox-static

# Enable basic services
systemctl enable lightdm
systemctl enable NetworkManager

# Root password (root/root for dev VM)
echo "root:root" | chpasswd

# Auto-login root (dev VM only)
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/10-autologin.conf <<CONF
[Seat:*]
autologin-user=root
autologin-session=xfce
CONF

# Faster boot, less noise
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Generate initramfs using initramfs-tools
update-initramfs -c -k "$KERNEL_VERSION"

apt clean

EOF

# Change ownership of the image back to the invoking user
OWNER="${SUDO_USER:-$USER}"
if [ -n "$OWNER" ]; then
	chown "$OWNER":"$OWNER" "$SYSTEM_IMAGE"
fi

print_info "Copying initramfs to host: $INITRD"
cp "$MOUNTDIR/boot/initrd.img-$KERNEL_VERSION" "$INITRD"
if [ -n "$OWNER" ]; then
	chown "$OWNER":"$OWNER" "$INITRD"
fi

cleanup

echo
print_success "Debian image built successfully: $SYSTEM_IMAGE"
print_success "Root login: root / root"
