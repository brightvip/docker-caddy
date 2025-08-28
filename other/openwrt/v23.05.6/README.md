## Set the EMMC root filesystem size to 59392 for the CMCC RAX3000M.
`Use this configuration file to compile openwrt to only support CMCC RAX3000M EMMC version`

## Instructions
[https://blog.codee.top/rax3000m%E6%90%9E%E6%9C%BA%E7%9B%AE%E5%BD%95/#%E5%BC%80%E5%90%AFssh%E6%B5%81%E7%A8%8B%E5%9B%BE](https://blog.codee.top/rax3000m%E6%90%9E%E6%9C%BA%E7%9B%AE%E5%BD%95/#%E5%BC%80%E5%90%AFssh%E6%B5%81%E7%A8%8B%E5%9B%BE)
```
1 Configuration Management->Export Configuration File
2 Decrypt and unzip the configuration file or Unzip the configuration file
   openssl aes-256-cbc -d -pbkdf2 -k $CmDc#RaX30O0M@\!$ -in cfg_export_config_file.conf -out - | tar -zxvf -
   OR
   tar -xvzf cfg_export_config_file.conf
3 Modify the configuration file
   Edit 'etc/config/dropbear', set 'enable' to '1'.
   Edit 'etc/shadow', update (remove) root password:
      'root::19523:0:99999:7:::'
4 Packaging Configuration File
   tar -zcvf - etc | openssl aes-256-cbc -pbkdf2 -k $CmDc#RaX30O0M@\!$ -out cfg_export_config_file_new.conf
   OR
   tar -zcvf  cfg_export_config_file_new.conf etc
5 Importing the configuration file
```

[https://git.openwrt.org/?p=openwrt/openwrt.git;a=commit;h=423186d7d8b4f23aee91fca4f1774a195eba00d8](https://git.openwrt.org/?p=openwrt/openwrt.git;a=commit;h=423186d7d8b4f23aee91fca4f1774a195eba00d8)
```
Gain SSH access:
1. Login into web interface, and download the configuration.
2. Enter fakeroot, decompress the configuration:
   tar -zxf cfg_export_config_file.conf
3. Edit 'etc/config/dropbear', set 'enable' to '1'.
4. Edit 'etc/shadow', update (remove) root password:
   'root::19523:0:99999:7:::'
5. Repack 'etc' directory:
   tar -zcf cfg_export_config_file.conf etc/
   * If you find an error about 'etc/wireless/mediatek/DBDC_card0.dat',
     just ignore it.
6. Upload new configuration via web interface, now you can SSH to RAX3000M.

Check stroage type:
Check the label on the back of the device:
"CH EC CMIIT ID: xxxx" is eMMC version
"CH    CMIIT ID: xxxx" is NAND version

eMMC Flash instructions:
1. SSH to RAX3000M, and backup everything, especially 'factory' part.
   ('data' partition can be ignored, it's useless.)
2. Write new GPT table:
   dd if=openwrt-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync
3. Erase and write new BL2:
   echo 0 > /sys/block/mmcblk0boot0/force_ro
   dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync
   dd if=openwrt-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync
4. Erase and write new FIP:
   dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync
   dd if=openwrt-mediatek-filogic-cmcc_rax3000m-emmc-bl31-uboot.fip of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync
5. Set static IP on your PC:
   IP 192.168.1.254, GW 192.168.1.1
6. Serve OpenWrt initramfs image using TFTP server.
7. Cut off the power and re-engage, wait for TFTP recovery to complete.
8. After OpenWrt has booted, perform sysupgrade.
9. Additionally, if you want to have eMMC recovery boot feature:
     (Don't worry! You will always have TFTP recovery boot feature.)
   dd if=openwrt-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb of=/dev/mmcblk0p4 bs=512 conv=fsync

NAND Flash instructions:
1. SSH to RAX3000M, and backup everything, especially 'Factory' part.
2. Erase and write new BL2:
   mtd erase BL2
   mtd write openwrt-mediatek-filogic-cmcc_rax3000m-nand-preloader.bin BL2
3. Erase and write new FIP:
   mtd erase FIP
   mtd write openwrt-mediatek-filogic-cmcc_rax3000m-nand-bl31-uboot.fip FIP
4. Set static IP on your PC:
   IP 192.168.1.254, GW 192.168.1.1
5. Serve OpenWrt initramfs image using TFTP server.
6. Cut off the power and re-engage, wait for TFTP recovery to complete.
7. After OpenWrt has booted, erase UBI volumes:
   ubidetach -p /dev/mtd0
   ubiformat -y /dev/mtd0
   ubiattach -p /dev/mtd0
8. Create new ubootenv volumes:
   ubimkvol /dev/ubi0 -n 0 -N ubootenv -s 128KiB
   ubimkvol /dev/ubi0 -n 1 -N ubootenv2 -s 128KiB
9. Additionally, if you want to have NAND recovery boot feature:
     (Don't worry! You will always have TFTP recovery boot feature.)
   ubimkvol /dev/ubi0 -n 2 -N recovery -s 20MiB
   ubiupdatevol /dev/ubi0_2 openwrt-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb
10. Perform sysupgrade.
```
