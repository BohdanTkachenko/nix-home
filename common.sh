#!/usr/bin/env bash

get_os() {
  case "$(uname -s)" in
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ -n "$VARIANT_ID" ]; then
          echo "$VARIANT_ID"
        else
          echo "$ID"
        fi
      else
        echo "linux"
      fi
      ;;
    *)
      echo "other"
      ;;
  esac
}