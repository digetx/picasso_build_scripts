install_modules() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	INSTALL_MOD_PATH="$1" ARCH=arm make modules_install

	[ $? -eq 0 ] && unlink "$1"/lib/modules/*/source
	[ $? -eq 0 ] && unlink "$1"/lib/modules/*/build
	[ $? -eq 0 ] && rm -r "$1/lib/firmware"

	[ $? -ne 0 ] && exit 1

	popd >/dev/null

# 	find "$1" -type f -name '*.ko' -exec gzip "{}" \;
# 	[ $? -ne 0 ] && exit 1
# 
# 	/sbin/depmod -b "$1" "$KERNEL_VER"

	return $?
}

reset_logs() {
	LOG_FILE="$1"
	LOG_ERR_FILE="$2"

	[ -n "$LOG_FILE" ] && truncate -s 0 "$OUTPUT_DIR/$LOG_FILE"
	[ -n "$LOG_FILE" ] && truncate -s 0 "$OUTPUT_DIR/$LOG_ERR_FILE"
}

print_log() {
	[ -z "$LOG_FILE" ] && return

	echo "[$(LANG="en_US.utf8" date '+%h %d %H:%M:%S')] $1" >> "$OUTPUT_DIR/$LOG_FILE"

	[ "$LOG_ERR_FILE" = "$LOG_FILE" ] && return

	echo "[$(LANG="en_US.utf8" date '+%h %d %H:%M:%S')] $1" >> "$OUTPUT_DIR/$LOG_ERR_FILE"
}

eval_log() {
	print_log "$1"

	eval "$1"
}

run() {
	printf "%-75s" "$1"

	local temp_stderr="$(mktemp)"
	[ $? -ne 0 ] && exit 1

	local temp_logimm="$(mktemp)"
	[ $? -ne 0 ] && exit 1

	if [ "$3" == "NO_STDREDIRECT" ]; then
		eval "LANG=en_US.utf8 $2"
	elif [ -z "$LOG_FILE" ]; then
		eval "LANG=en_US.utf8 $2 &>>'$temp_stderr' 3>'$temp_logimm'"
	else
		eval "LANG=en_US.utf8 $2 1>>'$OUTPUT_DIR/$LOG_FILE' 2>'$temp_stderr' 3>'$temp_logimm'"
	fi

	local sts=$?

	[ -n "$LOG_ERR_FILE" ] && cat "$temp_stderr" >> "$OUTPUT_DIR/$LOG_ERR_FILE"

	if [ $sts -eq 0 ]; then
		echo -e "[\033[32mOK\033[0m]"
	else
		echo -e "[\033[31mFAIL\033[0m]"
	fi

	if [ $sts -eq 0 ]; then
		notify-send -i 'dialog-information' \
		"$LOCAL_BRANCH $KERNEL_VER" "$1 <b><font color=green>OK"
	else
		notify-send -i 'dialog-information' \
		"$LOCAL_BRANCH $KERNEL_VER" "$1 <b><font color=red>FAIL"
	fi

	local err_txt="$(<$temp_stderr)"
	rm "$temp_stderr"

	local imm_txt="$(<$temp_logimm)"
	rm "$temp_logimm"

	[ -n "$imm_txt" ] && echo -e "$imm_txt"

	[ $sts -ne 0 ] && echo -e "$err_txt"
	[ $sts -eq 0 ] && return

	ask_yes_no "Retry?"
	[ $? -eq 0 ] && exit $sts

	run "$1" "$2" "$3"
}

ask_yes_no() {
	while [ 1 ]
	do
		read -p "$1 Y/n: "
		if [[ $REPLY =~ ^[Nn]$ ]]; then
			return 0
		fi

		if [ -z "$REPLY" ] || [[ $REPLY =~ ^[Yy]$ ]]; then
			return 1
		fi
	done
}

ask_and_run() {
	ask_yes_no "$1"

	local sts=$?

	[ $sts -eq 1 ] && eval "$2"

	return $sts
}
