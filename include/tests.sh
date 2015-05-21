ADB="adb"

adb_do() {
	local retries=40

	>&2 echo "adb $1"

	[ -n "$2" ] && retries=$2

	while ! eval "$ADB $1"; do
		notify-send -i 'dialog-information' \
					"adb $1" '<b><font color=red>Failed'
	
		retries=$((retries-1))

		[ $retries -eq 0 ] && return 1

		sleep 3
	done

	return 0
}

flash_bootimg() {
	print_log "flashing kernel"

# 	adb_do "wait-for-device"

	local bootimg=$1

# 	adb_do "shell iwconfig wlan0 power off
	adb_do "push '$bootimg' /tmp/boot.img"
	[ $? -eq 0 ] && adb_do "shell dd if=/tmp/boot.img of='$BOOTIMG_DST_PATH'"

	local sts=$?

	[ $sts -ne 0 ] && >&2 echo "failed to flash kernel img"

	return $sts
}

upload_kernel_modules() {
	print_log "uploading kernel modules"

# 	adb_do "wait-for-device"

	local sdcard="/mnt/external_sd"
	local tmpdir="$(mktemp -d)"

	[ $? -ne 0 ] && return 1

	install_modules "$tmpdir"

	[ $? -eq 0 ] && adb_do "shell mkdir -p '$sdcard'"
	[ $? -eq 0 ] && adb_do "shell mount '$SDCARD_PARTITION_PATH' '$sdcard'"
	[ $? -eq 0 ] && adb_do "shell rm -r '$sdcard/lib/modules/*'"
	[ $? -eq 0 ] && adb_do "push '$tmpdir/lib' '$sdcard/lib/'"

	local sts=$?

	[ $sts -ne 0 ] && >&2 echo "failed to upload kernel modules"

	rm -r "$tmpdir"

	return $sts
}

run_ssh() {
	print_log "ssh $1"

	sshpass -p "$SSH_PASS" ssh "$SSH_USER@$NET_ADDR" $1 < /dev/null

	return $?
}

wait_ssh() {
	print_log "waiting ssh"

	local retries=10

	until [ $retries -eq 0 ]; do
		run_ssh 'uname -a'

		[ $? -eq 0 ] && return 0

		let retries-=1

		sleep 5
	done

	>&2 echo "$FUNCNAME() timeout"

	return 1
}

grab_dmesg() {
	print_log "grabbing dmesg"

	local dmesg_err=""

	run_ssh 'dmesg' > "$OUTPUT_DIR/dmesg.txt"
	[ $? -ne 0 ] && return 1

	run_ssh 'dmesg --level=err,warn' > "$OUTPUT_DIR/dmesg_err.txt"
	[ $? -ne 0 ] && return 1

	run_ssh 'dmesg --level=err,warn --color=always' >&3

	return $?
}

check_modlist() {
	print_log "checking modlist"

	local modules=("tegra_udc" "a500_ec_battery" "a500_ec_leds")

	local loaded_modules="$(run_ssh 'lsmod')"
	[ $? -ne 0 ] && return 1

	echo >&3 "$loaded_modules"

	echo "$loaded_modules" > "$OUTPUT_DIR/lsmod.txt"
	[ $? -ne 0 ] && return 1

	for module in "${modules[@]}"
	do
		echo "$loaded_modules" | grep -q "^$module\s"
		if [ ${PIPESTATUS[1]} -ne 0 ]; then
			echo -e >&2 "\n$module not loaded!"
			return 1
		fi
	done

	return 0
}

adb_reboot() {
	print_log "rebooting"

	adb_do 'reboot'

	return $?
}

ssh_reboot() {
	print_log "rebooting"

	run_ssh 'reboot >/dev/null &'

	return 0
}

check_kernel_ver() {
	print_log "checking kernel version"

	local remote_ver="$(run_ssh 'uname -r')"

	[ "$KERNEL_VER" = "$remote_ver" ] && return 0

	echo >&2 "$KERNEL_VER != $remote_ver"

	return 1
}

ping_dev() {
	ping -c1 -W1 "$1" &>/dev/null

	return $?
}

setup_usbnet() {
	print_log "checking usbnet"

	ping_dev "10.1.1.3"
	[ $? -eq 0 ] && return 0

	run_ssh 'modprobe -r g_ether && modprobe g_ether && ifconfig usb0 10.1.1.3/27'

	[ $? -eq 0 ] && sleep 1

	[ $? -eq 0 ] && sudo ifconfig $USB_IF 10.1.1.5/27

	[ $? -eq 0 ] && ping -c3 10.1.1.3 >&2

	return $?
}

unload_usbd_modules() {
	print_log "unloading usbd modules"

	run_ssh 'modprobe -r tegra_udc && modprobe -r g_ether && modprobe tegra_udc'

	return $?
}

reload_modules() {
	print_log "reloading modules"

	local loaded_modules="$(run_ssh 'lsmod')"
	[ $? -ne 0 ] && return 1

	while read -r module
	do
		# it's too troublesome, just skip it for now
		[ "$module" == "brcmfmac" ] && continue

		echo >&2 "reloading $module"

		run_ssh "modprobe -r $module && modprobe $module"
		local sts=$?

		[ $sts -eq 0 ] && [ "$module" == "brcmfmac" ] && wait_ssh && return 1

		[ $sts -ne 0 ] && echo -e >&2 "\n$module reload failed"
		[ $sts -ne 0 ] && return $sts
	done <<< "$(echo "$loaded_modules" | awk -F" " 'NR > 1 && $3=="0" {printf("%s\n", $1)}')"

	return 0
}

# fb-adb returns shell status
prepare_adb() {
	adb_do "push misc/stub /tmp/fb-adb"
	[ $? -ne 0 ] && return 1

	adb_do "shell chmod 0755 /tmp/fb-adb"
	[ $? -eq 0 ] && ADB="misc/fb-adb.x86"

	return $?
}

grab_proc_interrupts() {
	print_log "grabbing /proc/interrupts"

	local proc_interrupts="$(run_ssh 'cat /proc/interrupts')"
	[ $? -ne 0 ] && return 1

	echo >&3 "$proc_interrupts"

	echo "$proc_interrupts" > "$OUTPUT_DIR/proc_interrupts.txt"

	return $?
}

grab_cpuidle_stats() {
	print_log "grabbing cpuidle stats"

	local cmd='cd /sys/devices/system/cpu/ && echo -e "'

	for cpu in 0 1; do
		cmd+="CPU $cpu\\n"

		for state in 0 1; do
			cmd+="\$(cat cpu$cpu/cpuidle/state$state/name): "
			cmd+="\$(cat cpu$cpu/cpuidle/state$state/usage)\\n"
		done

		cmd+='\n'
	done

	cmd+='"'

	local cpuidle_stats="$(run_ssh "$cmd")"
	[ $? -ne 0 ] && return 1

	echo >&3 "$cpuidle_stats"

	echo "$cpuidle_stats" > "$OUTPUT_DIR/cpuidle_stats.txt"

	return $?
}

suspend_test() {
	print_log "suspending"

	run_ssh "eval 'sleep 1 && rmmod brcmfmac && sleep 3 && rtcwake -s 5 -m mem && modprobe brcmfmac' &"
	[ $? -ne 0 ] && return 1

	sleep 15

	run_ssh 'dmesg --color=always | tail -n30' >&3

	return $?
}

ssh_flash_bootimg() {
	print_log "flashing kernel [ssh]"

	local bootimg=$1

	sshpass -p "$SSH_PASS" scp "$bootimg" "$SSH_USER@10.1.1.3":/tmp/bootimg
	[ $? -ne 0 ] && return 1

	sshpass -p "$SSH_PASS" ssh "$SSH_USER@10.1.1.3" "dd if=/tmp/bootimg of='$SSH_BOOTIMG_DST_PATH'"

	return $?
}

ssh_upload_kernel_modules() {
	print_log "uploading kernel modules [ssh]"

	local tmpdir="$(mktemp -d)"
	[ $? -ne 0 ] && return 1

	install_modules "$tmpdir"

	[ $? -eq 0 ] && sshpass -p "$SSH_PASS" ssh "$SSH_USER@10.1.1.3" 'rm -r /lib/modules/*; exit 0'
	[ $? -eq 0 ] && sshpass -p "$SSH_PASS" rsync -rl "$tmpdir/lib/modules" -e ssh "$SSH_USER@10.1.1.3":/lib
	[ $? -eq 0 ] && sshpass -p "$SSH_PASS" ssh "$SSH_USER@10.1.1.3" 'sync'

	local sts=$?

	[ $sts -ne 0 ] && echo >&2 "failed to upload kernel modules"

	rm -r "$tmpdir"

	return $sts
}

test_sound() {
	sshpass -p "$SSH_PASS" scp "misc/32.mp3" "$SSH_USER@10.1.1.3":/tmp/32.mp3
	[ $? -ne 0 ] && return 1

	run_ssh 'mplayer /tmp/32.mp3'

	return $?
}

test_wifi_off_on() {
	run_ssh 'ifconfig wlan0 down && sleep 3 && ifconfig wlan0 up'

	return $?
}

grab_gpios() {
	print_log "grabbing /sys/kernel/debug/gpio"

	local gpios="$(run_ssh 'cat /sys/kernel/debug/gpio')"
	[ $? -ne 0 ] && return 1

	echo >&3 "$gpios"

	echo "$gpios" > "$OUTPUT_DIR/gpios.txt"

	return $?
}

test_kernel() {
	reset_logs "tests.txt" "tests.txt"

	print_log "tests started"

	local bootimg="$(mktemp)"
	[ $? -ne 0 ] && return 1

	run "[Testing] Packing bootimg" "pack_bootimg '$bootimg' '$KERNEL_TEST_CMDLINE'"

	if ! ping_dev "$NET_ADDR"; then
		run "[Testing] Preparing adb"            "prepare_adb"
		run "[Testing] Flashing bootimg"         "flash_bootimg '$bootimg'"
		run "[Testing] Uploading kernel modules" "upload_kernel_modules"
		run "[Testing] Rebooting"                "adb_reboot"
	else
		run "[Testing] Setting up usbnet"        "setup_usbnet"
		run "[Testing] Flashing bootimg"         "ssh_flash_bootimg '$bootimg'"
		run "[Testing] Uploading kernel modules" "ssh_upload_kernel_modules"
		run "[Testing] Rebooting"                "ssh_reboot"
		sleep 20
	fi

	rm "$bootimg"

	run "[Testing] Waiting linux boot-up"     "wait_ssh"

	run "[Testing] Checking kernel version"   "check_kernel_ver"

	run "[Testing] Checking modules"          "check_modlist"

	run "[Testing] Checking usbnet"           "setup_usbnet"

	run "[Testing] Unloading usbd modules"    "unload_usbd_modules"

	run "[Testing] Re-checking usbnet"        "setup_usbnet"

	run "[Testing] Reloading modules"         "reload_modules"

	run "[Testing] Setting up usbnet"         "setup_usbnet"

	run "[Testing] Playing sound"             "test_sound"

	run "[Testing] Wifi off/on"               "test_wifi_off_on"

# 	run "[Testing] Suspending"                "suspend_test"

	run "[Testing] Grabbing dmesg"            "grab_dmesg"

	run "[Testing] Grabbing /proc/interrupts" "grab_proc_interrupts"

	run "[Testing] Grabbing cpuidle stats"    "grab_cpuidle_stats"

	run "[Testing] Grabbing GPIO's state"     "grab_gpios"

# 	run "[Testing] Rebooting"                 "ssh_reboot"

	print_log "tests finished"
}
