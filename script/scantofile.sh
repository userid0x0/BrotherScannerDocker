#!/bin/bash
# $1 = scanner device
# $2 = friendly name

script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# simply call main scan script - omit parameters as only one scanner is supported anyway
exec ${script_dir}/scan.sh