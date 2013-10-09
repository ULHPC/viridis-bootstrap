#!/bin/bash

set -x

# Config

IMAGE=/tmp/wheezy-ref.img
INITRD=/tmp/wheezy-initrd
KERNEL=/tmp/wheezy-kernel

PASSWORD=changeme

IMAGE_SIZE=700 # in MB

CHROOT_PATH=/mnt/chroot

PACKAGES="vim screen tmux strace rsync parallel iperf ethtool host build-essential less git subversion stress"
MODULES="highbank_cpufreq"

LINUX_IMAGE_URL=http://ppa.launchpad.net/calxeda/kernel-ppa/ubuntu/pool/main/l/linux/linux-image-3.5.0-1000-highbank_3.5.0-1000.167_armhf.deb
LINUX_VERSION=3.5.0-1000-highbank

DEBIAN_MIRROR=http://debian.mirror.root.lu/debian/

NFS_MOUNTPOINT=/home/users
NFS_EXPORT=10.226.251.13:/export/users

TARGET="chroot ${CHROOT_PATH} "

# Image creation

dd if=/dev/zero of=$IMAGE bs=1M count=$IMAGE_SIZE
mkfs.ext4 -F $IMAGE

# Mount

mkdir -p $CHROOT_PATH
mount -o loop $IMAGE $CHROOT_PATH


apt-get install -y debootstrap
debootstrap --no-check-gpg --arch=armhf wheezy $CHROOT_PATH $DEBIAN_MIRROR

# Modules
echo $MODULES > $CHROOT_PATH/etc/modules

# NFS mount point
mkdir -p ${MOUNT_POINT}
echo "${NFS_EXPORT} ${MOUNT_POINT} nfs async,defaults,auto,nfsvers=3,tcp 0 0" >> $CHROOT_PATH/etc/fstab

# Preseed

$TARGET apt-get install -y debconf-utils
echo "localepurge     localepurge/nopurge     multiselect     en_US, en_US.ISO-8859-15, en_US.UTF-8" | $TARGET debconf-set-selections

# Install packages

$TARGET apt-get update
$TARGET apt-get install -y localepurge
$TARGET apt-get install -y openssh-server open-iscsi ntp nfs-common
$TARGET apt-get install -y uboot-mkimage initramfs-tools module-init-tools
$TARGET apt-get install -y $PACKAGES

# KERNEL

$TARGET wget $LINUX_IMAGE_URL   -O /root/linux-image.deb
$TARGET dpkg -i --force-depends    /root/linux-image.deb

$TARGET ln -s /boot/vmlinuz-$LINUX_VERSION    /boot/vmlinuz
$TARGET ln -s /boot/initrd.img-$LINUX_VERSION /boot/initrd.img


# Clean

$TARGET aptitude clean
$TARGET rm /root/linux-image.deb

# Copy config files
cp files/ttyAMA0.conf    $CHROOT_PATH/etc/init/
cp files/ntp.conf        $CHROOT_PATH/etc/ntp.conf
cp files/resolv.conf     $CHROOT_PATH/etc/resolv.conf
cp files/authorized_keys $CHROOT_PATH/root/.ssh/
cp files/rc.local        $CHROOT_PATH/etc/rc.local
chmod +x $CHROOT_PATH/etc/rc.local

# Remove getty on tty*
sed -i '/getty 38400/d' $CHROOT_PATH/etc/inittab

cp $CHROOT_PATH/boot/vmlinuz-$LINUX_VERSION    $KERNEL
cp $CHROOT_PATH/boot/initrd.img-$LINUX_VERSION $INITRD

# Set password
$TARGET chpasswd << EOF
root:${PASSWORD}
EOF

umount $CHROOT_PATH

echo "== OUTPUT =="
echo "Image : ${IMAGE}"
echo "Initrd: ${INITRD}"
echo "Kernel: ${KERNEL}"

