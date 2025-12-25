#!/bin/bash
set -e

source "$(dirname "$0")/utils.sh"
REPO_URL=https://github.com/torvalds/linux
TAG=v6.18
DEST_DIR="$(get_root_dir)/linux"
PATCH_FILE="$(dirname "$0")/linux.patch"

if [ -d "$DEST_DIR" ]; then
	print_info "Directory $DEST_DIR already exists. Skipping clone."
else
	print_info "Cloning Linux kernel repository (tag: $TAG) into $DEST_DIR..."
	if ! git clone --depth 1 --branch "$TAG" "$REPO_URL" "$DEST_DIR" > /dev/null 2>&1; then
		print_err "Failed to clone repository."
		exit 1
	fi
	print_info "Successfully cloned Linux kernel repository."
fi

ln -s "$DEST_DIR"/kernel "$DEST_DIR"/security/warden
print_info "Created symbolic link from kernel/ to linux/security/warden/"

print_info "Applying patch from $PATCH_FILE..."
if patch -d "$DEST_DIR" -p1 < "$PATCH_FILE"; then
	print_err "Failed to apply patch."
	exit 1
fi
print_info "Patch applied successfully."
