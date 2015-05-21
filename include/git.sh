clean_src_tree() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	eval_log "git reset --hard && git clean -f -d"

	local sts=$?

	popd >/dev/null

	return $sts
}

checkout_branch() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	eval_log "git checkout '$LOCAL_BRANCH'"

	local sts=$?

	popd >/dev/null

	return $sts
}

kernel_version() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	eval_log "$MAKE_KERNEL kernelrelease | tail -n1"

	local sts=$?

	popd >/dev/null

	return $sts
}

pull() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	local CURRENT_VER="$(kernel_version)"

	eval_log "git pull --no-stat --no-edit '$REPO' '$REMOTE_BRANCH'"

	local sts=$?

	local NEW_VER="$(kernel_version)"

	popd >/dev/null

	[ "$CURRENT_VER" != "$NEW_VER" ] && UPDATED=1

	return $sts
}

do_git_push() {
	pushd $LINUX_KERNEL_SRC_DIR >/dev/null

	run "Pushing to $1/$2" "git push '$1' '$2'"

	popd >/dev/null
}

git_push() {
	ask_and_run "Push to $1?" "do_git_push '$1' '$2'"
}
