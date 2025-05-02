#!/bin/bash
yum install iscsi-initiator-utils iscsi-initiator-utils-iscsiuio libiscsi udisks2-iscsi -y

sudo ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
read VG LV < <(lvs --noheadings -o vg_name,lv_name | awk 'NR==1 {print $1, $2}')
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
GRUB_CMDLINE_LINUX="ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,115200 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=5M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=${VG} rd.lvm.lv=${VG}/${LV} rd.net.timeout.dhcp=10 rd.net.timeout.carrier=5 rd.iscsi.param=node.session.timeo.replacement_timeout=6000 net.ifnames=1 nvme_core.shutdown_timeout=10 ipmi_si.tryacpi=0 ipmi_si.trydmi=0 libiscsi.debug_libiscsi_eh=1 loglevel=4 crash_kexec_post_notifiers crashkernel=1G-64G:448M,64G-:512M rd.iscsi.firmware=1 iscsi_initiator=iqn.2015-02.oracle.boot:instance"
echo "GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX\"" >> /tmp/grub
cp /tmp/grub /etc/default/grub
grub2-mkconfig -o /etc/grub2-efi.cfg
sudo stty -F /dev/ttyS0 speed 9600
dmesg | grep console
sudo systemctl enable getty@ttyS0
sudo systemctl start getty@ttyS0
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
dracut --force --no-hostonly --add "iscsi lvm network base" /boot/initramfs-${file:14}.img ${file:14} ; done
sudo halt -p
