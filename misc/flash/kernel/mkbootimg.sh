#!/sbin/sh

/sbin/busybox sysctl -w kernel.hung_task_timeout_secs=0

/tmp/mkbootimg --base 0x20000000 --kernel /tmp/zImage --ramdisk NONE --output /tmp/newboot.img --cmdline "$(cat /tmp/CMDLINE)"

exit $?
