#!/sbin/sh

LINUX_CMDLINE="cmdline=$(cat /tmp/CMDLINE) root=$1"
KVER="$(cat /tmp/KVER)"

/sbin/dd if=/dev/block/mmcblk0p5 of=/tmp/boot_file bs=1 skip=15 count=256
[ $? -ne 0 ] && exit 1

BOOTMENU_PART="$(awk -F ":" '{print $1}' /tmp/boot_file)"
BOOTMENU_FILE="/bootmenu_file_part/$(awk -F ":" '{print $2}' /tmp/boot_file)"

if   [ "$BOOTMENU_PART" == "SOS" ]; then
	PART="/dev/block/mmcblk0p1"
elif [ "$BOOTMENU_PART" == "LNX" ]; then
	PART="/dev/block/mmcblk0p2"
elif [ "$BOOTMENU_PART" == "APP" ]; then
	PART="/dev/block/mmcblk0p3"
elif [ "$BOOTMENU_PART" == "CAC" ]; then
	PART="/dev/block/mmcblk0p4"
elif [ "$BOOTMENU_PART" == "FLX" ]; then
	PART="/dev/block/mmcblk0p6"
elif [ "$BOOTMENU_PART" == "AKB" ]; then
	PART="/dev/block/mmcblk0p7"
elif [ "$BOOTMENU_PART" == "UDA" ]; then
	PART="/dev/block/mmcblk0p8"
else
	exit 1
fi

/sbin/busybox umount /dev/block/mmcblk0p6
/sbin/busybox mount /dev/block/mmcblk0p6 /flexrom
[ $? -ne 0 ] && exit 1

/sbin/busybox cp /tmp/zImage "/flexrom/zImage_$KVER"
[ $? -ne 0 ] && exit 1

/sbin/busybox cp /tmp/init.cpio /flexrom/
[ $? -ne 0 ] && exit 1

/sbin/busybox umount /flexrom
[ $? -ne 0 ] && exit 1


/sbin/busybox mkdir /bootmenu_file_part

/sbin/busybox umount $PART
/sbin/busybox mount $PART /bootmenu_file_part
[ $? -ne 0 ] && exit 1

file_not_exists=1
[ -e $BOOTMENU_FILE ] && file_not_exists=0

if [ $file_not_exists -eq 0 ]; then
	echo -e "[LINUX_$KVER]" >> $BOOTMENU_FILE
	echo -e "title=Linux $KVER" >> $BOOTMENU_FILE
	echo -e "zImage=FLX:/zImage_$KVER" >> $BOOTMENU_FILE
	echo -e "ramdisk=FLX:/init.cpio" >> $BOOTMENU_FILE
	echo -e "cmdline=$LINUX_CMDLINE\n\n" >> $BOOTMENU_FILE

	echo -e "[LINUX_RECOVERY_MODE_$KVER]" >> $BOOTMENU_FILE
	echo -e "title=Linux $KVER (Recovery Mode)" >> $BOOTMENU_FILE
	echo -e "zImage=FLX:/zImage_$KVER" >> $BOOTMENU_FILE
	echo -e "ramdisk=FLX:/init.cpio" >> $BOOTMENU_FILE
	echo -e "cmdline=$LINUX_CMDLINE single\n\n" >> $BOOTMENU_FILE
fi

/sbin/busybox umount /bootmenu_file_part
[ $? -ne 0 ] && exit 1

exit $file_not_exists
