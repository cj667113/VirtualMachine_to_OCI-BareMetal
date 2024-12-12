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
echo 'GRUB_CMDLINE_LINUX="crashkernel=auto ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,115200 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=5M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi iscsi_initiator=iqn.2015-02.oracle.boot:instance"' >> /tmp/grub
#Old CMDLINE
##"crashkernel=auto ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,115200 rd.luks=0 rd.md=0 rd.dm=0 rd.net.timeout.carrier=5 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=5M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi iscsi_initiator=iqn.2015-02.oracle.boot:instance rd.iscsi.param=node.session.timeo.replacement_timeout=6000 net.ifnames=1 nvme_core.shutdown_timeout=10 ipmi_si.tryacpi=0 ipmi_si.trydmi=0 libiscsi.debug_libiscsi_eh=1 loglevel=4 rd.net.timeout.dhcp=10 crash_kexec_post_notifiers"' >> /tmp/grub
#
mkdir /etc/iscsi
echo 'InitiatorName=iqn.2015-02.oracle.boot:instance' > /etc/iscsi/initiatorname.iscsi
echo 'InitiatorName=iqn.2015-02.oracle.boot:instance' > /etc/initiatorname.iscsi
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
