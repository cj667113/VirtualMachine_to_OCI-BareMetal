#!/bin/bash
yum install iscsi-initiator-utils iscsi-initiator-utils-iscsiuio libiscsi udisks2-iscsi grub2-efi-x64 grub2-efi-x64-modules shim-x64 -y
#Disk may need to change
grub2-install /dev/sda
sudo ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
# grep rootlv may need to be adjusted if the root filesystem is on a different lv_name
read VG LV < <(lvs --noheadings -o vg_name,lv_name | grep root | awk '{print $1, $2}')
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
GRUB_CMDLINE_LINUX="ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,115200 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=5M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=${VG} rd.lvm.lv=${VG}/${LV} rd.lvm=1 root=/dev/mapper/${VG}-${LV} rd.net.timeout.dhcp=10 rd.net.timeout.carrier=5 rd.iscsi.param=node.session.timeo.replacement_timeout=6000 net.ifnames=1 nvme_core.shutdown_timeout=10 ipmi_si.tryacpi=0 ipmi_si.trydmi=0 libiscsi.debug_libiscsi_eh=1 loglevel=4 crash_kexec_post_notifiers crashkernel=1G-64G:448M,64G-:512M rd.iscsi.firmware=1 rd.iscsi.initiator=iqn.2015-02.oracle.boot:instance"
echo "GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX\"" >> /tmp/grub
cp /tmp/grub /etc/default/grub
cat <<EOF > /etc/kernel/cmdline
ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,115200 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=5M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=${VG} rd.lvm.lv=${VG}/${LV} rd.lvm=1 root=/dev/mapper/${VG}-${LV} rd.net.timeout.dhcp=10 rd.net.timeout.carrier=5 rd.iscsi.param=node.session.timeo.replacement_timeout=6000 net.ifnames=1 nvme_core.shutdown_timeout=10 ipmi_si.tryacpi=0 ipmi_si.trydmi=0 libiscsi.debug_libiscsi_eh=1 loglevel=4 crash_kexec_post_notifiers crashkernel=1G-64G:448M,64G-:512M rd.iscsi.firmware=1 rd.iscsi.initiator=iqn.2015-02.oracle.boot:instance
EOF
echo "Done. Rebuilding GRUB config..."
KERNEL_VERSION=$(uname -r)
rm -f /boot/loader/entries/*-${KERNEL_VERSION}.conf
kernel-install add $(uname -r) /boot/vmlinuz-$(uname -r)
grub2-mkconfig -o /etc/grub2-efi.cfg
sudo stty -F /dev/ttyS0 speed 115200
dmesg | grep console
sudo systemctl enable getty@ttyS0
sudo systemctl start getty@ttyS0
cat <<EOF > /tmp/iscsi-dracut.conf
install_items+=" /etc/iscsi/iscsid.conf /etc/iscsi/nodes /var/lib/iscsi "
EOF
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
dracut --force --no-hostonly --add "iscsi lvm network base" /boot/initramfs-${file:14}.img ${file:14} ; done
sudo halt -p
