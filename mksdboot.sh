#! /bin/sh
# Script to create SD card for DM368 plaform.
#
# Author: jiangjinxiong, tongfangcloud Inc.
#

VERSION="0.4"
#filesysdir="/home/jiangjx/UbuntuShare/filesys"

execute ()
{
    $* >/dev/null
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: executing $*"
        echo
        exit 1
    fi
}

version ()
{
  echo
  echo "`basename $1` version $VERSION"
  echo "Script to create bootable SD card for DM368 IPNC"
  echo

  exit 0
}

usage ()
{
  echo "
Usage: `basename $1` [options] <device>

Mandatory options:
  --device              SD block device node (e.g /dev/sdd)

Optional options:
  --version             Print version.
  --help                Print this help message.
"
  exit 1
}

# Process command line...
while [ $# -gt 0 ]; do
  case $1 in
    --help | -h)
      usage $0
      ;;
    --device) shift; device=$1; shift; ;;
    --version) version $0;;
    *) copy="$copy $1"; shift;;
  esac
done

test -z $device && usage $0

if [ ! -d $filesysdir ]; then
   echo "ERROR: $filesysdir does not exist,failed to find rootfs"
   exit 1;
fi
 
if [ ! -b $device ]; then
   echo "ERROR: $device is not a block device file"
   exit 1;
fi

echo "************************************************************"
echo "*         THIS WILL DELETE ALL THE DATA ON $device        *"
echo "*                                                          *"
echo "*         WARNING! Make sure your computer does not go     *"
echo "*                  in to idle mode while this script is    *"
echo "*                  running. The script will complete,      *"
echo "*                  but your SD card may be corrupted.      *"
echo "*                                                          *"
echo "*         Press <ENTER> to confirm....                     *"
echo "************************************************************"
read junk

source ./dm3xx_sd.config

for i in `ls -1 $device?`; do
 echo "unmounting device '$i'"
 umount $i 2>/dev/null
done

execute "dd if=/dev/zero of=$device bs=1024 count=1024"

# get the partition information.
echo "get the partition information."
total_size=`fdisk -l $device | grep Disk | awk '{print $5}'`
total_cyln=`echo $total_size/255/63/512 | bc`

# start from cylinder 20, this should give enough space for flashing utility
# to write u-boot binary.
pc1_start=50
pc1_end=$((($total_cyln - $pc1_start) / 100 *99 ))

# start of rootfs partition
pc2_start=$(($pc1_start + $pc1_end))

# calculate number of cylinder for the second parition
if [ "$copy" != "" ]; then
  pc2_end=$((($total_cyln - $pc1_end) / 2))
  pc3_start=$(($pc2_start + $pc2_end))
fi

{
if [ "$copy" != "" ]; then
  echo $pc1_start,$pc1_end,0x0B,-
  echo $pc2_start,$pc2_end,,-
  echo $pc3_start,,-
else
  echo $pc1_start,$pc1_end,0x0B,-
  echo $pc2_start,,-
fi
} | sfdisk -D -H 255 -S 63 -C $total_cyln $device

if [ $? -ne 0 ]; then
    echo ERROR
    exit 1;
fi

echo "Formating ${device}1 ..."
execute "mkfs.vfat -n "BOOT" ${device}1"
echo "Formating ${device}2 ..."
execute "mke2fs -j -L "ROOTFS" ${device}2"
if [ "$copy" != "" ]; then
  echo "Formating ${device}3 ..."
  execute "mke2fs -j -L  "USER" ${device}3"
fi

# creating boot.scr
echo "creating boot.scr...*******************************************************"
execute "mkdir -p .tmp/sdk"
cat <<EOF >.tmp/sdk/boot.cmd
mmc rescan 0
setenv bootargs 'console=ttyS0,115200n8  root=/dev/mmcblk0p2 rw ip=off mem=60M video=davincifb:vid0=OFF:vid1=OFF:osd0=480x272x16,4050K dm365_imp.oper_mode=0 vpfe_capture.interface=1 davinci_enc_mngr.ch0_output=LCD davinci_enc_mngr.ch0_mode=480x272 rootwait'
fatload mmc 0 80700000 uImage
bootm 80700000
EOF

echo "Executing mkimage utilty to create a boot.scr file"
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'Execute uImage' -d .tmp/sdk/boot.cmd .tmp/sdk/boot.scr

if [ $? -ne 0 ]; then
  echo "Failed to execute mkimage to create boot.scr"
  echo "Execute 'sudo apt-get install uboot-mkimage' to install the package"
  exit 1
fi

echo "Copying uImage/boot.scr on ${device}1"
execute "mkdir -p .tmp/sdk/$$"
execute "mount ${device}1 .tmp/sdk/$$"
execute "cp .tmp/sdk/boot.scr .tmp/sdk/$$/"
execute "cp .tmp/sdk/boot.cmd .tmp/sdk/$$/"

#execute "chmod 777 -R nand_blk/ubl/ubl_nand/"
#cat nand_blk/ubl/ubl_head/ubl_head_blk01 $ubl_nand > nand_blk/ubl/ubl_nand/ubl_blk01

#execute "chmod 777 -R nand_blk/uboot/uboot_nand/"
#cat nand_blk/uboot/uboot_head/uboot_head_blk25 $uboot_nand > nand_blk/uboot/uboot_nand/uboot_blk25

echo "mkfs.cramfs $rootfs_filesys original/rootfs.cramfs"
mkfs.cramfs $rootfs_filesys original/rootfs.cramfs

#execute "cp original/rootfs.cramfs $rootfs_filesys_flash/mnt/rootfs.cramfs"
#execute "cp -r $rootfs_filesys/mnt/nand/cfg $rootfs_filesys_flash/mnt/nand/"
#mkfs.cramfs $rootfs_filesys_flash original/rootfs.cramfs

echo "Copying ubl\uboot\uimage\rootfs on ${device}1"
mkdir .tmp/sdk/$$/sd
execute "cp -r nand_blk/ubl/ubl_nand/      .tmp/sdk/$$/sd/"
execute "cp -r nand_blk/uboot/uboot_nand/  .tmp/sdk/$$/sd/"
execute "cp $kernel_nand .tmp/sdk/$$/sd/uImage"
execute "cp original/rootfs.cramfs .tmp/sdk/$$/sd/rootfs.cramfs"

#echo "Copying YAHEI.TTF on ${device}1"
#execute "cp original/YAHEI.TTF .tmp/sdk/$$/"

sync
execute "umount .tmp/sdk/$$"

FILE=sdcard_flash/uflash
if [ -f $FILE ]; then
  echo "Executing uflash tool to write ubl and u-boot.bin"
  ./sdcard_flash/uflash -d ${device} -u $ubl_sdmmc -b $uboot_sdmmc -vv
else 
  echo "ERROR: uflash utility not found"
  exit 1
fi

if [ $? -ne 0 ]; then
  echo "Failed to execute uflash"
  exit 1
fi

execute "rm -rf .tmp"
echo -e "\033[43;36m completed! \033[0m" 

