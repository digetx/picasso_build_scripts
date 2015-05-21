LINUX_KERNEL_SRC_DIR="/run/media/dima/449ec3d0-25ad-4332-9510-c28428d843b1/android/a500_kernel_rebase/"

CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-"

MAKE_ARGS="-j5"

DEFCONFIG="tegra_picasso_defconfig"

DTB_FILE="tegra20-picasso.dtb"

BUILD_OUT_DIR="/home/dima/vl/picasso_build_scripts/build"

KERNEL_TEST_CMDLINE="rootwait rw root=/dev/mmcblk0p1 cma=48M gpt gpt_sector=31258623 zswap.enabled=1 no_console_suspend=1"

KERNEL_RELEASE_CMDLINE="rootwait rw root=/dev/mmcblk0p1 cma=64M gpt gpt_sector=31258623"

NET_ADDR="192.168.1.43"

USB_IF="usb0"

SSH_USER="root"

SSH_PASS=""

SDCARD_PARTITION_PATH="/dev/block/mmcblk1p1"

BOOTIMG_DST_PATH="/dev/block/mmcblk0p7"

SSH_BOOTIMG_DST_PATH="/dev/mmcblk1p7"

GITHUB_REPO="github_upstream"

BITBUCKET_REPO="bitbucket_upstream"

#	local branch	repo		remote branch	SKIP_PULL	SKIP_BUILD	SKIP_TEST	FORCE_BUILD_TEST
BRANCHES_REPO=(
	"3.10-merge"	"stable"	"linux-3.10.y"	0		0		0		0
	"3.12-merge"	"stable"	"linux-3.12.y"	0		0		0		0
	"3.14-merge"	"stable"	"linux-3.14.y"	0		0		0		0
	"3.18-merge"	"stable"	"linux-3.18.y"	0		0		0		0
	"3.19-merge"	"stable"	"linux-3.19.y"	0		0		0		0
	"4.0-merge"	"stable"	"linux-4.0.y"	0		0		0		0
)
