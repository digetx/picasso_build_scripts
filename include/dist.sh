distribute_it() {
	eval "bbpost -user '$BUSR' -pass '$BPWD' -proj '$2' -post '$1'"

	[ $? -ne 0 ] && return 1

	local url="https://bitbucket.org/digetx/$2/downloads/$(basename "$1")"

	perl post.pl "$(echo $KERNEL_VER | sed 's/-.*//')" "$url"

	[ $? -eq 0 ] && print_log "success $url"

	return $?
}

distribute() {
	local zip_fname="linux_kernel_$(echo $KERNEL_VER | sed 's/-.*//')"
	local ZIP_PATH="$OUTPUT_DIR/$zip_fname.zip"

	ask_and_run "Pack zip?" "pack_flashable_zip '$ZIP_PATH'"

	[ $? -eq 0 ] && return

	reset_logs "distribute" "distribute"

	ask_and_run "Post it?" "run 'Distributing' \"distribute_it '$ZIP_PATH' 'picasso_upstream_support'\" NO_STDREDIRECT"
}
