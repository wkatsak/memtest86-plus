#!/bin/bash

SYSLINUX_ROOT=/home/wkatsak/syslinux-6.03

if [[ $EUID -ne 0 ]]; then
	echo "$0: this script must be run as root..."
	exit
fi

# stop on errors
set -e

# Prepare partition
dd if=/dev/zero of=memtest-partition.img bs=1M count=7
mkfs.fat memtest-partition.img
$SYSLINUX_ROOT/bios/linux/syslinux -i memtest-partition.img
LOOP_DEV=$(losetup -f)
echo "Using loop device: $LOOP_DEV"
losetup $LOOP_DEV memtest-partition.img
mkdir -p tmp
mount $LOOP_DEV tmp
cp -v memtest.bin tmp/memtest
cp -v syslinux.cfg tmp/
sync
umount tmp
losetup --detach $LOOP_DEV

# prepare main image
dd if=/dev/zero of=memtest-usb.img bs=1M count=8

# create partitions
parted -s memtest-usb.img mklabel msdos
parted -s memtest-usb.img mkpart primary fat16 1M 8M
parted -s memtest-usb.img set 1 boot on

# install mbr
dd conv=notrunc bs=440 count=1 if=$SYSLINUX_ROOT/bios/mbr/mbr.bin of=memtest-usb.img

# copy partition into main image
dd if=memtest-partition.img of=memtest-usb.img seek=1M oflag=seek_bytes

# clean up
rm -f memtest-partition.img
rm -rf tmp

