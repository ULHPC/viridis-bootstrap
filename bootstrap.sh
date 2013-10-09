#!/bin/bash

set -x

DISTRIB=ubuntu

# Config

IMAGE=/home/users/hcartiaux/viridis-ref.img
INITRD=/home/users/hcartiaux/viridis-initrd
KERNEL=/home/users/hcartiaux/viridis-kernel

PASSWORD=changeme

IMAGE_SIZE=4000 # in MB

CHROOT_PATH=/mnt/chroot

PACKAGES="debootstrap vim screen tmux strace rsync iperf ethtool host build-essential less git subversion stress parallel aptitude"
MODULES="highbank_cpufreq"

if [ "$DISTRIB" = "debian" ] ; then
    VERSION=wheezy
    LINUX_IMAGE_URL=http://ppa.launchpad.net/calxeda/kernel-ppa/ubuntu/pool/main/l/linux/linux-image-3.5.0-1000-highbank_3.5.0-1000.167_armhf.deb
    MIRROR=http://debian.mirror.root.lu/debian/
    LINUX_VERSION=3.5.0-1000-highbank
elif [ "$DISTRIB" = "ubuntu" ] ; then
    VERSION=quantal
    MIRROR=http://ports.ubuntu.com/
    LINUX_VERSION=3.5.0-17-highbank
fi

NFS_MOUNTPOINT=/home/users
NFS_EXPORT=10.226.251.13:/export/users

TARGET="chroot ${CHROOT_PATH} "
INSTALL="apt-get install -y --allow-unauthenticated "

# Image creation

dd if=/dev/zero of=$IMAGE bs=1M count=$IMAGE_SIZE
mkfs.ext4 -F $IMAGE

# Mount

mkdir -p $CHROOT_PATH
mount -o loop $IMAGE $CHROOT_PATH


$INSTALL debootstrap
debootstrap --no-check-gpg --arch=armhf $VERSION $CHROOT_PATH $MIRROR

if [ "$DISTRIB" = "ubuntu" ] ; then
  $TARGET mv /sbin/initctl /sbin/initctl.orig
  $TARGET ln -s /bin/true /sbin/initctl
  echo "" > $CHROOT_PATH/etc/apt/sources.list
fi

# Modules
echo $MODULES > $CHROOT_PATH/etc/modules

# NFS mount point
mkdir -p ${NFS_MOUNTPOINT}
echo "${NFS_EXPORT} ${NFS_MOUNTPOINT} nfs async,defaults,auto,nfsvers=3,tcp 0 0" >> $CHROOT_PATH/etc/fstab

# Preseed

$TARGET $INSTALL debconf-utils
echo "localepurge     localepurge/nopurge     multiselect     en_US, en_US.ISO-8859-15, en_US.UTF-8" | $TARGET debconf-set-selections

# Install packages

$TARGET apt-get update
$TARGET $INSTALL localepurge
$TARGET $INSTALL openssh-server open-iscsi ntp nfs-common
$TARGET $INSTALL uboot-mkimage initramfs-tools module-init-tools
$TARGET $INSTALL $PACKAGES

# KERNEL

if [ "$DISTRIB" = "debian" ] ; then
    $TARGET wget $LINUX_IMAGE_URL   -O /root/linux-image.deb
    $TARGET dpkg -i --force-depends    /root/linux-image.deb
elif [ "$DISTRIB" = "ubuntu" ] ; then
    $TARGET $INSTALL linux-highbank
fi

$TARGET ln -s /boot/vmlinuz-$LINUX_VERSION    /boot/vmlinuz
$TARGET ln -s /boot/initrd.img-$LINUX_VERSION /boot/initrd.img

cp $CHROOT_PATH/boot/vmlinuz-$LINUX_VERSION    $KERNEL
cp $CHROOT_PATH/boot/initrd.img-$LINUX_VERSION $INITRD

# Clean

if [ "$DISTRIB" = "ubuntu" ] ; then
    $TARGET rm /sbin/initctl
    $TARGET mv /sbin/initctl.orig /sbin/initctl
fi

$TARGET aptitude clean
$TARGET rm -f /root/linux-image.deb

# Copy config files
cp files/ttyAMA0.conf    $CHROOT_PATH/etc/init/
cp files/ntp.conf        $CHROOT_PATH/etc/ntp.conf
cp files/resolv.conf     $CHROOT_PATH/etc/resolv.conf
mkdir -p $CHROOT_PATH/root/.ssh
cp files/authorized_keys $CHROOT_PATH/root/.ssh/
cp files/rc.local        $CHROOT_PATH/etc/rc.local
chmod +x $CHROOT_PATH/etc/rc.local

# Remove getty on tty*
sed -i '/getty 38400/d' $CHROOT_PATH/etc/inittab

# Set password
$TARGET chpasswd << EOF
root:${PASSWORD}
EOF

umount $CHROOT_PATH

echo "== OUTPUT =="
echo "Image : ${IMAGE}"
echo "Initrd: ${INITRD}"
echo "Kernel: ${KERNEL}"

