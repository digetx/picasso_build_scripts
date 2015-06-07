#!/bin/bash

source ./config.sh

source include/common.sh
source include/git.sh
source include/build.sh
source include/pack.sh
source include/tests.sh
source include/dist.sh

MAKE_KERNEL="ARCH=arm CROSS_COMPILE='$CROSS_COMPILE' make"

build_and_dist() {
	KERNEL_VER="$(kernel_version)"
	KERNEL_VER_STRIPPED="$(echo $KERNEL_VER | sed 's/-.*//')"

	OUTPUT_DIR="$BUILD_OUT_DIR/$LOCAL_BRANCH/$KERNEL_VER$3"
	mkdir -p "$OUTPUT_DIR"

	ROOTFS_PARTITION_PATH=$4

	[ $SKIP_BUILD -eq 0 ] && build_kernel
	[ $SKIP_TEST  -eq 0 ] && test_kernel "$1"

	local zip_fname="linux_kernel_$KERNEL_VER_STRIPPED"

	distribute "$zip_fname$3" "$2"
}

run_update() {
	for i in $(seq 0 8 $((${#BRANCHES_REPO[@]} - 1)))
	do
		LOCAL_BRANCH=${BRANCHES_REPO[i+0]}
		DOWNSTREAM_VIDEO=${BRANCHES_REPO[i+1]}
		REPO=${BRANCHES_REPO[i+2]}
		REMOTE_BRANCH=${BRANCHES_REPO[i+3]}
		SKIP_PULL=${BRANCHES_REPO[i+4]}
		SKIP_BUILD=${BRANCHES_REPO[i+5]}
		SKIP_TEST=${BRANCHES_REPO[i+6]}
		FORCE_BUILD_TEST=${BRANCHES_REPO[i+7]}
		UPDATED=0

		[ $SKIP_PULL -eq 0 ] && [ $SKIP_BUILD -eq 0 ] && run "Cleaning src tree" "clean_src_tree"

		run "Checking-out $LOCAL_BRANCH" "checkout_branch"

		[ $SKIP_PULL -eq 0 ] && run "Pulling $REPO/$REMOTE_BRANCH" "pull" "NO_STDREDIRECT"

		if [ $UPDATED -ne 0 -o $FORCE_BUILD_TEST -eq 1 ]; then
			build_and_dist "$KERNEL_TEST_CMDLINE" "$KERNEL_RELEASE_CMDLINE" "" "$SDCARD_PARTITION_PATH"

			git_push "$GITHUB_REPO" "$LOCAL_BRANCH"
			git_push "$BITBUCKET_REPO" "$LOCAL_BRANCH"
		else
			echo "No new version..."
		fi

		reset_logs "" ""

		echo ""
	done
}

build_downstream() {
	for i in $(seq 0 8 $((${#BRANCHES_REPO[@]} - 1)))
	do
		LOCAL_BRANCH=${BRANCHES_REPO[i+0]}
		DOWNSTREAM_VIDEO=${BRANCHES_REPO[i+1]}
		REPO=${BRANCHES_REPO[i+2]}
		REMOTE_BRANCH=${BRANCHES_REPO[i+3]}
		SKIP_PULL=${BRANCHES_REPO[i+4]}
		SKIP_BUILD=${BRANCHES_REPO[i+5]}
		SKIP_TEST=${BRANCHES_REPO[i+6]}
		FORCE_BUILD_TEST=${BRANCHES_REPO[i+7]}

		[ -z "$DOWNSTREAM_VIDEO" ] && continue

		ask_yes_no "Build $LOCAL_BRANCH with downstream video?"

		[ $? -eq 0 ] && continue

		run "Cleaning src tree" "clean_src_tree"

		run "Creating temporary branch for downstream video" "detach_and_merge_downstream"

		build_and_dist "$KERNEL_TEST_DOWNSTREAM_CMDLINE" "$KERNEL_RELEASE_DOWNSTREAM_CMDLINE" "_downstream_video" "$USB_PARTITION_PATH"

		reset_logs "" ""

		echo ""
	done
}

run_update

build_downstream
