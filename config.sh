LINUX_KERNEL_SRC_DIR="/run/media/dima/449ec3d0-25ad-4332-9510-c28428d843b1/android/a500_kernel_rebase/"

CROSS_COMPILE="armv7a-hardfloat-linux-gnueabi-"

MAKE_ARGS="-j5"

DEFCONFIG="tegra_picasso_defconfig"

DTB_FILE="tegra20-picasso.dtb"

BUILD_OUT_DIR="/home/dima/vl/picasso_build_scripts/build"

KERNEL_TEST_CMDLINE="rootwait root=/dev/disk/by-path/platform-c8000400.sdhci-part1 rw cma=48M gpt gpt_sector=31258623 zswap.enabled=1 no_console_suspend=1"

KERNEL_TEST_DOWNSTREAM_CMDLINE="rootwait rw root=/dev/sda1 gpt gpt_sector=31258623 zswap.enabled=1 no_console_suspend=1"

KERNEL_RELEASE_CMDLINE="rootwait rw cma=64M gpt gpt_sector=31258623"

KERNEL_RELEASE_DOWNSTREAM_CMDLINE="rootwait rw gpt gpt_sector=31258623"

NET_ADDR="192.168.1.43"

USB_IF="usb0"
USB_NET_LOCAL_ADDR="10.1.1.5"
USB_NET_ADDR="10.1.1.3"
USB_NET_SUBNET_MASK="27"

SSH_USER="root"

SSH_PASS=""

SDCARD_PARTITION_PATH="/dev/block/mmcblk1p1"

USB_PARTITION_PATH="/dev/block/sda1"

BOOTIMG_DST_PATH="/dev/block/mmcblk0p7"

SSH_BOOTIMG_DST_PATH="/dev/disk/by-path/platform-c8000600.sdhci-part7"

GITHUB_REPO="github_upstream"

BITBUCKET_REPO="bitbucket_upstream"

#       local branch    downstream-video branch repo            remote branch   SKIP_PULL      SKIP_BUILD       SKIP_TEST       FORCE_BUILD_TEST
BRANCHES_REPO=(
        "3.18-merge"    "3.18-downstream-video" "stable"        "linux-3.18.y"  0               0               0               0
        "4.7-merge"     "4.7-downstream-video"  "stable"        "linux-4.7.y"   0               0               0               0
)
