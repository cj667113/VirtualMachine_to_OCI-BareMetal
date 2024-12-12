#!/bin/bash

sudo ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
sudo apt-get install open-iscsi qemu-guest-agent -y
sudo systemctl enable --now iscsid
sudo systemctl enable --now open-iscsi
echo "Dependencies Installed"
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX=""' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 nvme.shutdown_timeout=10 libiscsi.debug_libiscsi_eh=1 crash_kexec_post_notifiers netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi iscsi_initiator=iqn.2015-02.oracle.boot:instance ip=dhcp"' >> /tmp/grub
mkdir /etc/iscsi
echo 'InitiatorName=iqn.2015-02.oracle.boot:uefi' > /etc/iscsi/initiatorname.iscsi
cp /tmp/grub /etc/default/grub
sudo update-grub
sudo stty -F /dev/ttyS0 speed 115200
dmesg | grep console
sudo systemctl enable getty@ttyS0
sudo systemctl start getty@ttyS0
update-initramfs -u
sudo halt -p
