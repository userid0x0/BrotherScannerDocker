#!/bin/bash
# $1 = scanner device
# $2 = friendly name

script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source /opt/brother/scanner/shell_env.txt
source "${script_dir}/scan-lib.sh"

main() {
  local unixtime workdir
  local outfile_scan outfile_merge outfile_ocr
  local latest

  unixtime=$(date +%s)
  workdir="/scans/${unixtime}"
  outfile_scan="/scans/$(get_basename "${unixtime}").pdf"
  outfile_merge="/scans/$(get_basename "${unixtime}")_merge.pdf"
  outfile_ocr="/scans/$(get_basename "${unixtime}")_ocr.pdf"

  cleanup_old_dirs "${unixtime}"
  latest=$(get_latest)

  mkdir -p "${workdir}"
  scan "${workdir}" "${unixtime}"
  convert "${workdir}" "${outfile_scan}"
  merge "${workdir}" "${latest}" "${outfile_merge}"

  if [ -f "${outfile_scan}" ]; then
    trigger_inotify "${outfile_scan}"
    upload "${outfile_scan}"
  fi
  if [ -f "${outfile_merge}" ]; then
    trigger_inotify "${outfile_merge}"
    upload "${outfile_merge}"
  fi

  # trigger_ocr "${outfile_scan}"

  return 0
}

{
  main
} 2>&1 | tee -a /var/log/scanner.log 

exit 0

