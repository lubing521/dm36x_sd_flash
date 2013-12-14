---------------------制作SD卡启动烧写说明及注意事项----------------------------------
【步骤一】：插入SD卡。
一般情况下linux自动挂载该设备，设备名称一般为： /dev/sdb。
<注意事项>
若linux不能识别SD卡，分别进行以下处理：
1、windows系统下格式化SD卡；
2、重启linux系统，再插入SD卡；
3、若SD卡制作过程中出现错误，有时候需要在linux下格式化SD卡,命令： sudo fdisk /dev/sdb。


【步骤二】：修改配置文件dm3xx_sd.config。
1、指定UBL路径：       export ubl_nand=original/ubl_DM36x_nand.bin

2、指定UBOOT路径：     export uboot_nand=original/u-boot-1.3.4-dm368_ipnc.bin

3、指定内核路径：      
export kernel_nand=original/uImage
4、指定根文件系统路径：export rootfs_filesys=/home/jiangjx/UbuntuShare/filesys


【步骤三】：制作SD卡。
sudo ./mksdboot.sh --device /dev/sdb


