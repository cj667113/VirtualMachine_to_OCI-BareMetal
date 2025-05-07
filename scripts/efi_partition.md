###Instructions to configure an efi partition if it does not exist
Run parted /dev/sda (Your boot disk)
	print free
	mkpart primary fat32 XXGB YYGB (start, end)
	set 3 esp on
	quit
dnf install dosfstools -y
mkfs.fat -F32 /dev/sda3
dnf install mtools -y
mlabel -i /dev/sda3 ::BOOTUEFI
echo "LABEL=BOOTUEFI  /boot/efi  vfat  umask=0077  0  1" >> /etc/fstab
systemctl daemon-reload
mount -a
