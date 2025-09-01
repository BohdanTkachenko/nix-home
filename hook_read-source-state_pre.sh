#!/usr/bin/env bash

# shellcheck disable=SC1091
source common.sh

case "$(get_os)" in
bazzite-dx-gnome|bazzite-dx-nvidia-gnome)
    brew install -q age-plugin-yubikey
    ;;
esac