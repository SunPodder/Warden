#!/bin/bash

print_success() {
    printf "[✓] %s%s%s\n" "$(tput setaf 2)" "$1" "$(tput sgr0)"
}

print_err() {
    printf "[✗] %s%s%s\n" "$(tput setaf 1)" "$1" "$(tput sgr0)" >&2
}

print_info() {
    printf "[*] %s%s%s\n" "$(tput setaf 4)" "$1" "$(tput sgr0)"
}

print_warn() {
    printf "[!] %s%s%s\n" "$(tput setaf 3)" "$1" "$(tput sgr0)" >&2
}

get_script_dir() {
    local SCRIPT_DIR
    SCRIPT_DIR=$(dirname "$0")
    SCRIPT_DIR=$(realpath "$SCRIPT_DIR")
    echo "$SCRIPT_DIR"
}

get_root_dir() {
    local SCRIPT_DIR ROOT_DIR
    SCRIPT_DIR=$(get_script_dir)
    ROOT_DIR=$(dirname "$SCRIPT_DIR")
    echo "$ROOT_DIR"
}
