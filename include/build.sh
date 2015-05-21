run_build_kernel() {
	local FW_DIR="$(pwd)/firmware"

	print_log "build started"

	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	[ $? -eq 0 ] && eval_log "$MAKE_KERNEL clean"

	[ $? -eq 0 ] && sed -i.orig "s#\(CONFIG_EXTRA_FIRMWARE_DIR=\)\".*\"#\1\"$FW_DIR\"#" .config

	[ $? -eq 0 ] && eval_log "$MAKE_KERNEL $MAKE_ARGS"

	local sts=$?

	popd >/dev/null

	return $sts
}

build_kernel() {
	reset_logs "build.txt" "build_err.txt"

	run "Building kernel" "run_build_kernel"

	cat "$OUTPUT_DIR/$LOG_ERR_FILE"
}

update_config() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	eval_log "$MAKE_KERNEL $DEFCONFIG"

	local sts=$?

	popd >/dev/null

	return $sts
}
