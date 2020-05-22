#!/bin/bash

sudo ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX="crashkernel=auto ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,9600 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=5M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi iscsi_initiator=iqn.2015- 02.oracle.boot:instance"' >> /tmp/grub
cp /tmp/grub /etc/default/grub
grub2-mkconfig -o /etc/grub2-efi.cfg
sudo stty -F /dev/ttyS0 speed 9600
dmesg | grep console
sudo systemctl enable getty@ttyS0
sudo systemctl start getty@ttyS0
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
dracut --force --no-hostonly /boot/initramfs-${file:14}.img ${file:14} ; done
sudoo halt -p
