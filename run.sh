#!/bin/bash

source ./config.sh

source include/common.sh
source include/git.sh
source include/build.sh
source include/pack.sh
source include/tests.sh
source include/dist.sh

run_update() {
	for i in $(seq 0 7 $((${#BRANCHES_REPO[@]} - 1)))
	do
		LOCAL_BRANCH=${BRANCHES_REPO[i+0]}
		REPO=${BRANCHES_REPO[i+1]}
		REMOTE_BRANCH=${BRANCHES_REPO[i+2]}
		SKIP_PULL=${BRANCHES_REPO[i+3]}
		SKIP_BUILD=${BRANCHES_REPO[i+4]}
		SKIP_TEST=${BRANCHES_REPO[i+5]}
		FORCE_BUILD_TEST=${BRANCHES_REPO[i+6]}
		UPDATED=0

		MAKE_KERNEL="ARCH=arm CROSS_COMPILE='$CROSS_COMPILE' make"

		[ $SKIP_PULL -eq 0 ] && [ $SKIP_BUILD -eq 0 ] && run "Cleaning src tree" "clean_src_tree"

		run "Checking-out $LOCAL_BRANCH" "checkout_branch"

		[ $SKIP_PULL -eq 0 ] && run "Pulling $REPO/$REMOTE_BRANCH" "pull" "NO_STDREDIRECT"

		KERNEL_VER="$(kernel_version)"

		OUTPUT_DIR="$BUILD_OUT_DIR/$LOCAL_BRANCH/$KERNEL_VER"
		mkdir -p "$OUTPUT_DIR"

		[ $SKIP_BUILD -eq 0 ] && run "Updating .config" "update_config"

		if [ $UPDATED -ne 0 -o $FORCE_BUILD_TEST -eq 1 ]; then
			[ $SKIP_BUILD -eq 0 ] && build_kernel
			[ $SKIP_TEST  -eq 0 ] && test_kernel

			git_push "$GITHUB_REPO" "$LOCAL_BRANCH"
			git_push "$BITBUCKET_REPO" "$LOCAL_BRANCH"

			distribute
		else
			echo "No new version..."
		fi

		echo ""
	done

	reset_logs "" ""
}

run_update
