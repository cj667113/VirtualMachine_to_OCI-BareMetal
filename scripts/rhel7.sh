#!/bin/bash
echo "Developed by Christopher M Johnston"
echo "05/23/2020"
echo "Configures RHEL 7.x to be moved to OCI Bare Metal Infrastructure"
sudo ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
sudo yum install dracut-network iscsi-initiator-utils -y
echo "Dependencies Installed"
echo 'add_dracutmodules+="iscsi"' >> /etc/dracut.conf.d/iscsi.conf
echo "ISCSI Modules Added to Dracut"
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX="crashkernel=auto ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,9600 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=100M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi iscsi_initiator=iqn.2015- 02.oracle.boot:instance"' >> /tmp/grub
cp /tmp/grub /etc/default/grub
grub2-mkconfig -o /etc/grub2-efi.cfg
echo "Grub Config Made"
sudo stty -F /dev/ttyS0 speed 9600
dmesg | grep console
sudo systemctl enable getty@ttyS0
sudo systemctl start getty@ttyS0
echo "Executing Dracut"
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
dracut --force --no-hostonly /boot/initramfs-${file:14}.img ${file:14} ; done
echo "Dracut Executed"
echo "Shutting Down"
sudo halt -p
