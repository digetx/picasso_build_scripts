mk_kernel_dtb_appended() {
	local zImage="$LINUX_KERNEL_SRC_DIR/arch/arm/boot/zImage"
	local dtb="$LINUX_KERNEL_SRC_DIR/arch/arm/boot/dts/$DTB_FILE"

	local tmpfile="$(mktemp)"
	[ $? -ne 0 ] && return 1

	cat "$zImage" "$dtb" > "$tmpfile"
	[ $? -ne 0 ] && return 1

	echo "$tmpfile"

	return 0
}

pack_bootimg() {
	local kernel="$(mk_kernel_dtb_appended)"
	[ $? -ne 0 ] && return 1

	local ramdisk="$(pwd)/misc/flash/kernel/init.cpio"

	[ -n "$3" ] && ramdisk="$3"

	misc/mkbootimg --kernel "$kernel" \
			--ramdisk "$ramdisk" \
			--base 0x20000000 \
			--cmdline "$2" \
			-o "$1"

	local sts=$?

	rm "$kernel"

	return $sts
}

pack_kernel_src() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	git archive -o "$OUTPUT_DIR/$KERNEL_VER\_src.zip"

	popd >/dev/null
}

zip_it() {
	pushd $2 >/dev/null

	zip -r "$1" *

	local sts=$?

	popd >/dev/null

	return $sts
}

pack_zip() {
	local zip_file="$(mktemp --suffix=.zip --dry-run)"
	[ $? -ne 0 ] && return 1

	local out_dir="$(mktemp -d)"
	[ $? -ne 0 ] && return 1

	local kernel="$(mk_kernel_dtb_appended)"

	[ $? -eq 0 ] && cp -r misc/flash/* "$out_dir"

	[ $? -eq 0 ] && echo "$2" > "$out_dir/kernel/CMDLINE"

	[ $? -eq 0 ] && echo "$KERNEL_VER_STRIPPED" > "$out_dir/kernel/KVER"

	[ $? -eq 0 ] && mv "$kernel" "$out_dir/kernel/zImage"

	[ $? -eq 0 ] && sed -i "s#__KVER__#$KERNEL_VER_STRIPPED#" "$out_dir/META-INF/com/google/android/aroma-config"

	[ $? -eq 0 ] && install_modules "$out_dir"

	[ $? -eq 0 ] && zip_it "$zip_file" "$out_dir"

	[ $? -eq 0 ] && java -jar 'misc/signapk.jar' 'misc/platform.x509.pem' \
							'misc/platform.pk8' \
							"$zip_file" "$1"

	local sts=$?

	rm -r "$out_dir" "$zip_file"

	return $sts
}

pack_flashable_zip() {
	reset_logs "pack.txt" "pack.txt"

	run "Packing flashable zip" "pack_zip '$1' '$2'"
}

