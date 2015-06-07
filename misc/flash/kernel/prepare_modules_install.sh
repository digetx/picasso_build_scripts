#!/sbin/sh

/sbin/busybox mkdir /linux_root

/sbin/busybox umount "$1"
/sbin/busybox mount "$1" /linux_root
[ $? -ne 0 ] && exit 1

/sbin/busybox rm -r /linux_root/lib/modules/

exit 0
