#!/bin/bash
set -e

source "$(dirname "$0")/utils.sh"
REPO_URL=https://github.com/torvalds/linux
TAG=v6.18
DEST_DIR="$(get_root_dir)/linux"

if [ -d "$DEST_DIR" ]; then
	print_err "Directory $DEST_DIR already exists. Please remove it before running this script."
	exit 1
fi

print_info "Cloning Linux kernel repository (tag: $TAG) into $DEST_DIR..."
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$DEST_DIR" > /dev/null 2>&1

if [ $? -ne 0 ]; then
	print_err "Failed to clone repository."
	exit 1
fi

rm -rf "$DEST_DIR/.git"
print_info "Done."
