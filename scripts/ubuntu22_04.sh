#!/bin/bash

sudo ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
sudo apt-get install dracut-core dracut-network iscsiuio open-iscsi qemu-guest-agent -y
sudo systemctl enable qemu-guest-agent
#sudo systemctl start qemu-guest-agent
sudo systemctl enable iscsid
#sudo systemctl start iscsid
echo "Dependencies Installed"
echo 'add_dracutmodules+=" iscsi "' >> /etc/dracut.conf.d/iscsi.conf
echo 'add_drivers+=" virtio_blk virtio_net virtio_scsi "' >> /etc/dracut.conf.d/virtio.conf
echo "ISCSI Modules Added to Dracut"
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX=""' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 nvme.shutdown_timeout=10 libiscsi.debug_libiscsi_eh=1 crash_kexec_post_notifiers"' >> /tmp/grub
mkdir /etc/iscsi
echo 'InitiatorName=iqn.2015-02.oracle.boot:uefi' > /etc/iscsi/initiatorname.iscsi
cp /tmp/grub /etc/default/grub
#grub2-mkconfig -o /etc/grub2-efi.cfg
sudo update-grub
sudo stty -F /dev/ttyS0 speed 115200
dmesg | grep console
sudo systemctl enable getty@ttyS0
sudo systemctl start getty@ttyS0
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
dracut --force --no-hostonly /boot/initramfs-${file:14}.img ${file:14} ; done
update-initramfs -u
sudo halt -p
