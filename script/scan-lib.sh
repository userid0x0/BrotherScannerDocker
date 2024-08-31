
# -----------------------------------------------------------------------------

get_basename () {
  date --date=@$1 +%Y-%m-%d-%H-%M-%S
}

cleanup_old_dirs () {
  local unixtime dir
  unixtime="$1"
  for dir in $(find /scans -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | grep '^[[:digit:]]*$'); do
    # is a unixdate - delete folders older than 5 minutes
    if [[ $((unixtime - dir)) -ge $((5 * 60)) ]]; then
      rm -rvf "/scans/${dir}"
    fi
  done
}

get_latest () {
  find /scans -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort | grep '^[[:digit:]]*$' | tail -1 | sed '/^..*$/ s#^#/scans/#'
}

# -----------------------------------------------------------------------------

wait_for_scanner () {
  local i rc
  for i in $(seq 5); do
    echo "[info] Try #${i} to reach scanner"
    sleep 1
    scanimage -n >/dev/null 2>&1
    rc=$?
    [ ${rc} -eq 0 ] && return
  done
  echo "[info] Scanner seems to be unreachable - continue anyway"
}

scan () {
  local scan_cmd workdir unixtime outfile_pattern
  workdir="$1"
  unixtime="$2"

  outfile_pattern="${workdir}/$(get_basename "${unixtime}")-%04d.pnm"

  scan_cmd=(scanimage -l 0 -t 0 -x 215 -y 297)
  if [ -n "${RESOLUTION}" ]; then
    RESOLUTION=$(echo "${RESOLUTION}" | sed 's/^"\(.*\)"$/\1/')
    scan_cmd+=("--resolution=${RESOLUTION}")
  fi
  if [ -n "${MODE}" ]; then
    # remove quotes
    MODE=$(echo "${MODE}" | sed 's/^"\(.*\)"$/\1/')
    scan_cmd+=("--mode=${MODE}")
  fi
  #scan_cmd+=("${scanimage_args_misc[@]}")
  scan_cmd+=(--batch=$outfile_pattern)

  echo "[run] ${scan_cmd[@]}"
  "${scan_cmd[@]}"
}

# -----------------------------------------------------------------------------

run_convert () {
  local outfile infiles
  local gm_cmd
  outfile="$1"
  shift
  infiles=("$@")


  gm_cmd=("gm" "convert")
  gm_cmd+=("-page" "A4+0+0")
  if [ "${USE_JPEG_COMPRESSION}" = "true" ]; then
    gm_cmd+=("-compress" "JPEG" "-quality" "80")
  fi
  #gm_cmd+=("${graphicsmagic_args_misc[@]}")
  gm_cmd+=("${infiles[@]}")
  gm_cmd+=("${outfile}")

  echo "[run] ${gm_cmd[@]}"
  "${gm_cmd[@]}"

  #change ownership to target user/group
	chown $UID:$GID "${outfile}"
}

convert () {
  local workdir outfile
  local graphicsmagic_args_misc
  workdir="$1"
  outfile="$2"

  files=( ${workdir}/*.pnm )

  [ ${#files[@]} -eq 0 ] && echo "No '.pnm' files found, skip convert." && return

  run_convert "${outfile}" "${files[@]}"
  trigger_inotify "${outfile}"
  upload "${outfile}"
  trigger_ocr "${outfile}"
}

# -----------------------------------------------------------------------------

merge () {
  local workdir latest outfile
  local latest_files workdir_files merge_files cnt
  local graphicsmagic_args_misc

  workdir="$1"
  latest="$2"
  outfile="$3"

  [ -z "${latest}" ] && return
  [ ! -d "${latest}" ] && echo "Path '${latest}' doesn't exist, skip merge." && return

  latest_files=( ${latest}/*.pnm )
  workdir_files=( ${workdir}/*.pnm )

  [ ${#latest_files[@]} -ne ${#workdir_files[@]} ] && echo "Pagecount doesn't match (${#latest_files[@]} != ${#workdir_files[@]}), skip merge." && return

  cnt=${#latest_files[@]}
  merge_files=()
  for i in ${!latest_files[@]}; do
    merge_files+=("${latest_files[$i]}")
    merge_files+=("${workdir_files[$cnt-1-$i]}")
  done

  run_convert "${outfile}" "${merge_files[@]}"
}

# -----------------------------------------------------------------------------

trigger_inotify() {
  local filename

  filename="$(basename "$1")"

  if [ -z "${SSH_USER}" ] || [ -z "${SSH_PASSWORD}" ] || [ -z "${SSH_HOST}" ] || [ -z "${SSH_PATH}" ]; then
    echo "SSH environment variables not set, skipping inotify trigger."
    return 0
  fi

  if sshpass -p "${SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no "${SSH_USER}"@"${SSH_HOST}" "sed \"\" -i \"${SSH_PATH}/${filename}\""; then
    echo "trigger inotify successful"
  else
    echo "trigger inotify failed"
    return 1
  fi
}

trigger_ocr() {
  local infile outfile

  infile="$1"
  outfile="${1/\.pdf/_ocr.pdf}"

  if [ -z "${OCR_SERVER}" ] || [ -z "${OCR_PORT}" ] || [ -z "${OCR_PATH}" ]; then
    echo "OCR environment variables not set, skipping OCR."
    return 0
  fi

  echo "starting OCR for $infile..."
  curl -F "userfile=@${infile}" -H "Expect:" -o "${outfile}" ${OCR_SERVER}:${OCR_PORT}/${OCR_PATH}
  #change ownership to target user/group
  chown $UID:$GID "${outfile}"
}

ftp_upload() {
  local file

  file="$1"

  if [ -z "${FTP_USER}" ] || [ -z "${FTP_PASSWORD}" ] || [ -z "${FTP_HOST}" ] || [ -z "${FTP_PATH}" ] || [ -z "${file}" ]; then
    echo "FTP environment variables not set, skipping FTP upload."
    return 0
  fi

  if curl --silent \
      --show-error \
      --ssl-reqd \
      --user "${FTP_USER}:${FTP_PASSWORD}" \
      --upload-file "${file}" \
      "ftp://${FTP_HOST}${FTP_PATH}" ; then
    echo "Uploading to ftp server ${FTP_HOST} successful."
  else
    echo "Uploading to ftp failed while using curl"
    echo "user: ${FTP_USER}"
    echo "address: ${FTP_HOST}"
    echo "filepath: ${FTP_PATH}"
    echo "file: ${file}"
    return 1
  fi
}

upload() {
  ftp_upload "$1"
}