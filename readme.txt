---------------------����SD��������д˵����ע������----------------------------------
������һ��������SD����
һ�������linux�Զ����ظ��豸���豸����һ��Ϊ�� /dev/sdb��
<ע������>
��linux����ʶ��SD�����ֱ�������´���
1��windowsϵͳ�¸�ʽ��SD����
2������linuxϵͳ���ٲ���SD����
3����SD�����������г��ִ�����ʱ����Ҫ��linux�¸�ʽ��SD��,��� sudo fdisk /dev/sdb��


������������޸������ļ�dm3xx_sd.config��
1��ָ��UBL·����       export ubl_nand=original/ubl_DM36x_nand.bin

2��ָ��UBOOT·����     export uboot_nand=original/u-boot-1.3.4-dm368_ipnc.bin

3��ָ���ں�·����      
export kernel_nand=original/uImage
4��ָ�����ļ�ϵͳ·����export rootfs_filesys=/home/jiangjx/UbuntuShare/filesys


����������������SD����
sudo ./mksdboot.sh --device /dev/sdb


