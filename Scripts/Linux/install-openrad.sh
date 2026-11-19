#!/usr/bin/env bash
set -euo pipefail
umask 077

linux_user=rtunnel
node_name=linux-server
install_dir=/usr/local/lib/openrad
network_names=()
network_passwords=()
config_file=
release_selection=
launcher=/usr/local/bin/openrad
data_dir=/var/lib/openrad
identity="$data_dir/profile/identity.json"
unit_dir=/etc/systemd/system
service=openrad.service
timer=openrad.timer
repository=gringoestrangeiro/openrad
releases_api=https://api.github.com/repos/$repository/releases

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

trim() {
  REPLY=${1#"${1%%[![:space:]]*}"}
  REPLY=${REPLY%"${REPLY##*[![:space:]]}"}
}

read_config() {
  local line stripped section= key value line_number=0
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    line=${line%$'\r'}
    if (( line_number == 1 )); then
      line=${line#$'\xef\xbb\xbf'}
    fi
    trim "$line"
    stripped=$REPLY
    case $stripped in
      ''|\#*|\;*) continue ;;
      '[Settings]'|'[Networks]') section=$stripped; continue ;;
    esac
    [[ $line == *=* ]] || fail "Invalid INI entry at $config_file:$line_number."
    trim "${line%%=*}"
    key=$REPLY
    value=${line#*=}
    case $section in
      '[Settings]')
        trim "$value"
        value=$REPLY
        [[ -n $value ]] || fail "Empty setting at $config_file:$line_number."
        case $key in
          User) linux_user=$value ;;
          InstallDir) install_dir=$value ;;
          NodeName) node_name=$value ;;
          Release) release_selection=$value ;;
          *) fail "Unknown setting at $config_file:$line_number." ;;
        esac
        ;;
      '[Networks]')
        [[ -n $key ]] || fail "Empty network name at $config_file:$line_number."
        network_names+=("$key")
        # Everything after the first '=' is a literal password, including spaces.
        network_passwords+=("$value")
        ;;
      *) fail "Expected [Settings] or [Networks] at $config_file:$line_number." ;;
    esac
  done < "$config_file"
}

choose_release() {
  local prompt_fd=$1 choice tag
  printf '%s\n' '1) Latest stable release' '2) Latest prerelease' \
    '3) Release by tag' '4) Build the latest commit from source' >&2
  while read -r -u "$prompt_fd" -p 'OpenRad version [1]: ' choice; do
    case $choice in
      ''|1) release_selection=latest ;;
      2) release_selection=prerelease ;;
      3)
        read -r -u "$prompt_fd" -p 'Release tag (e.g. v2.3.3): ' tag || fail 'Cannot read release tag.'
        [[ -n $tag ]] || fail 'Release tag must not be empty.'
        release_selection=tag:$tag
        ;;
      4) release_selection=source ;;
      *) printf 'Choose a number from 1 to 4.\n' >&2; continue ;;
    esac
    return
  done
  fail 'Cannot read OpenRad version.'
}

collect_settings() {
  local script_dir prompt_fd=0 interactive=0 network_name network_password
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  if [[ -f $PWD/openrad.ini ]]; then
    config_file=$PWD/openrad.ini
  elif [[ -f $script_dir/openrad.ini ]]; then
    config_file=$script_dir/openrad.ini
  fi
  if [[ -n $config_file ]]; then
    read_config
  fi

  if [[ -t 0 || -t 1 || -t 2 ]]; then
    interactive=1
  fi
  if [[ -z $config_file || ${#network_names[@]} == 0 || ( $interactive == 1 && -z $release_selection ) ]]; then
    # Keep prompts usable when the installer itself is piped to Bash.
    if [[ ! -t 0 && $interactive == 1 ]]; then
      exec {prompt_fd}</dev/tty || fail 'Cannot open a terminal; provide openrad.ini.'
    fi
    if [[ -z $config_file ]]; then
      read -r -u "$prompt_fd" -p 'Linux user [rtunnel]: ' linux_user || fail 'Cannot read Linux user.'
      linux_user=${linux_user:-rtunnel}
      read -r -u "$prompt_fd" -p 'Node name [linux-server]: ' node_name || fail 'Cannot read node name.'
      node_name=${node_name:-linux-server}
    fi
    if (( ${#network_names[@]} == 0 )); then
      IFS= read -r -u "$prompt_fd" -p 'Network name: ' network_name || fail 'Cannot read network name; provide [Networks] in openrad.ini.'
      [[ -n $network_name ]] || fail 'Network name must not be empty.'
      IFS= read -r -s -u "$prompt_fd" -p 'Network password (empty for a public network): ' network_password || fail 'Cannot read network password.'
      printf '\n' >&2
      network_names+=("$network_name")
      network_passwords+=("$network_password")
    fi
    if [[ -z $release_selection && $interactive == 1 ]]; then
      choose_release "$prompt_fd"
    fi
    if (( prompt_fd != 0 )); then
      exec {prompt_fd}<&-
    fi
  fi
  [[ $linux_user =~ ^[a-z_][a-z0-9_-]*$ ]] || fail 'Invalid Linux user name.'
  release_selection=${release_selection:-latest}
  case $release_selection in
    latest|prerelease|tag:?*|source) ;;
    *) fail 'Release must be latest, prerelease, tag:<tag>, or source.' ;;
  esac
}

fetch_url() {
  curl -fsSL --proto '=https' --proto-redir '=https' --globoff --connect-timeout 15 --retry 3 "$@"
}

latest_prerelease() {
  local page=1 releases candidate published newest= newest_date=
  while :; do
    releases=$(fetch_url "$releases_api?per_page=100&page=$page") || fail 'Cannot list OpenRad releases on GitHub.'
    candidate=$(jq -c '
      map(select(.draft == false and .prerelease == true and .published_at != null))
      | max_by(.published_at) // empty
    ' <<< "$releases") || fail 'Invalid OpenRad release list from GitHub.'
    if [[ -n $candidate ]]; then
      published=$(jq -r '.published_at' <<< "$candidate")
      if [[ $published > $newest_date ]]; then
        newest=$candidate
        newest_date=$published
      fi
    fi
    [[ $(jq length <<< "$releases") == 100 ]] || break
    page=$((page + 1))
  done
  [[ -n $newest ]] || fail 'OpenRad has no published prereleases on GitHub.'
  printf '%s\n' "$newest"
}

download_release() (
  local release tag encoded_tag arch assets archive archive_url sums_url
  cd -- "$workdir" || return
  case $release_selection in
    latest)
      release=$(fetch_url "$releases_api/latest") || fail 'Cannot fetch the latest stable OpenRad release.'
      ;;
    prerelease)
      release=$(latest_prerelease) || return
      ;;
    tag:*)
      tag=${release_selection#tag:}
      encoded_tag=$(jq -rn --arg tag "$tag" '$tag | @uri') || return
      release=$(fetch_url "$releases_api/tags/$encoded_tag") || fail "Cannot fetch OpenRad release '$tag'."
      ;;
  esac
  tag=$(jq -er 'select(.draft == false) | .tag_name | strings | select(length > 0)' <<< "$release") ||
    fail 'Invalid OpenRad release metadata from GitHub.'
  arch=$(uname -m) || return
  assets=$(jq -er --arg arch "$arch" '
    .assets as $assets
    | [$assets[] | select(.name | test("^openrad-v?[0-9][A-Za-z0-9._+-]*-linux-" + $arch + "\\.tar\\.gz$"))] as $cli
    | [$assets[] | select(.name == "SHA256SUMS")] as $checksums
    | select(($cli | length) == 1 and ($checksums | length) == 1)
    | [$cli[0].name, $cli[0].browser_download_url, $checksums[0].browser_download_url] | @tsv
  ' <<< "$release") || fail "Release '$tag' needs a Linux $arch CLI archive and SHA256SUMS."
  IFS=$'\t' read -r archive archive_url sums_url <<< "$assets"
  printf 'Downloading OpenRad release %s (%s).\n' "$tag" "$archive"
  fetch_url -o "$archive" "$archive_url" || fail "Cannot download '$archive' from release '$tag'."
  fetch_url -o SHA256SUMS "$sums_url" || fail "Cannot download SHA256SUMS from release '$tag'."
  awk -v file="$archive" '$2 == file || $2 == "*" file' SHA256SUMS | sha256sum -c --strict - ||
    fail "SHA-256 verification failed for '$archive'."
  tar -xOzf "$archive" -- "${archive%.tar.gz}/openrad" > openrad ||
    fail "Cannot extract OpenRad CLI from '$archive'."
  [[ -s openrad ]] || fail "OpenRad CLI is empty in '$archive'."
)

build_latest_commit() {
  # Isolate the build from the service account and pass only the binary back on stdout.
  systemd-run --quiet --wait --pipe --collect -p DynamicUser=yes -p PrivateTmp=yes \
    /bin/bash -s -- "https://github.com/$repository.git" > "$workdir/openrad" <<'BUILD' || fail 'Cannot build OpenRad from source.'
set -euo pipefail
umask 077
{
  build_dir=$(mktemp -d "${TMPDIR:-/var/tmp}/openrad-build.XXXXXXXX")
  export HOME="$build_dir" CARGO_HOME="$build_dir/cargo" RUSTUP_HOME="$build_dir/rustup" TMPDIR="$build_dir"
  cd -- "$build_dir"
  git clone --depth 1 -- "$1" source
  cd source
  commit=$(git rev-parse HEAD)
  printf 'Building OpenRad commit %s.\n' "$commit"
  curl -fsSL --proto '=https' --proto-redir '=https' --connect-timeout 15 --retry 3 \
    -o "$build_dir/rustup-init.sh" https://sh.rustup.rs
  sh "$build_dir/rustup-init.sh" -y --profile minimal --default-toolchain stable --no-modify-path
  "$CARGO_HOME/bin/cargo" +stable build --locked --release --package openrad-client \
    --bin openrad --target-dir "$build_dir/target"
} </dev/null >&2
cat -- "$build_dir/target/release/openrad"
BUILD
  [[ -s $workdir/openrad ]] || fail 'The OpenRad build produced an empty CLI.'
}

resolve_install_dir() {
  case $install_dir in
    '~') install_dir=$linux_home ;;
    '~/'*) install_dir=$linux_home/${install_dir:2} ;;
  esac
  [[ $install_dir == /* ]] || fail 'InstallDir must be absolute or start with ~/.'
  install_dir=$(realpath -m -- "$install_dir")
  [[ $install_dir =~ ^/[-a-zA-Z0-9_./\ ]+$ ]] || fail 'InstallDir contains unsupported characters; use letters, numbers, spaces, /, -, _, or .'
  bin=$install_dir/openrad
  [[ $bin != "$launcher" ]] || fail 'InstallDir must differ from /usr/local/bin, which holds the launcher.'
}

write_launcher() {
  {
    printf '#!/usr/bin/env bash\nset -euo pipefail\n'
    printf 'linux_user=%q\nlinux_uid=%q\nlinux_home=%q\nbin=%q\ndata_dir=%q\n' \
      "$linux_user" "$linux_uid" "$linux_home" "$bin" "$data_dir"
    cat <<'LAUNCHER'

(( $# > 0 )) || set -- status
if (( EUID == 0 )); then
  # Control the supervised daemon instead of starting a second background process.
  if (( $# == 1 )); then
    case $1 in
      start|stop|restart) exec /usr/bin/systemctl "$1" openrad.service ;;
    esac
  fi
  exec /usr/sbin/runuser -u "$linux_user" -- /usr/bin/env -i \
    HOME="$linux_home" PATH=/usr/bin:/bin "$bin" --data-dir "$data_dir" "$@"
fi
if (( EUID != linux_uid )); then
  printf 'Run this command as root (sudo openrad) or as %s.\n' "$linux_user" >&2
  exit 1
fi
exec /usr/bin/env -i HOME="$linux_home" PATH=/usr/bin:/bin \
  "$bin" --data-dir "$data_dir" "$@"
LAUNCHER
  } > "$1"
}

join_network() {
  local network_name=$1 network_password=$2
  if [[ -z $network_password ]]; then
    openrad join -- "$network_name"
    return
  fi
  printf '%s\n' "$network_password" | as_user bash -c '
    set -euo pipefail
    umask 077
    password_file=$(mktemp)
    trap '\''rm -f -- "$password_file"'\'' EXIT
    cat > "$password_file"
    "$1" --data-dir "$2" join --password-file "$password_file" -- "$3"
  ' bash "$bin" "$data_dir" "$network_name"
}

# Installation starts here.
if [[ $EUID -ne 0 ]] || ! ( . /etc/os-release && [[ ${ID:-} == ubuntu ]] ); then
  fail 'Run this script as root on Ubuntu.'
fi
[[ -d /run/systemd/system ]] || fail 'Automatic startup requires a system instance of systemd.'
collect_settings

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl dbus-daemon \
  gnome-keyring iproute2 jq kmod sudo
if [[ $release_selection == source ]]; then
  apt-get install -y --no-install-recommends build-essential git pkg-config
fi

if [[ ! -c /dev/net/tun ]]; then
  modprobe tun || true
fi
[[ -c /dev/net/tun ]] || fail 'The virtual machine needs access to /dev/net/tun.'

# Создаём учётную запись для службы OpenRad.
if ! id "$linux_user" >/dev/null 2>&1; then
  if ! getent group "$linux_user" >/dev/null; then
    groupadd -- "$linux_user"
  fi
  useradd --create-home --home-dir "/home/$linux_user" \
    --gid "$linux_user" --shell /usr/sbin/nologin -- "$linux_user"
  printf 'Created user %s.\n' "$linux_user"
fi
linux_uid=$(id -u "$linux_user")
[[ $linux_uid -ne 0 ]] || fail "Choose a dedicated Linux user for OpenRad with a non-zero UID."
linux_home=$(getent passwd "$linux_user" | cut -d: -f6)
linux_group=$(id -gn "$linux_user")
[[ $linux_home == /* ]] || fail "User $linux_user must have an absolute home directory path."
if [[ ! -d "$linux_home" ]]; then
  install -d -m 0700 -o "$linux_user" -g "$linux_group" -- "$linux_home"
fi
resolve_install_dir
if [[ ! -d $install_dir ]]; then
  install -d -m 0755 -o root -g root -- "$install_dir"
fi
install -d -m 0700 -o "$linux_user" -g "$linux_group" -- "$data_dir"

as_user() {
  runuser -u "$linux_user" -- env -i HOME="$linux_home" PATH=/usr/bin:/bin "$@"
}

openrad() {
  as_user "$bin" --data-dir "$data_dir" "$@"
}

stop_cli_daemon() {
  local daemon_bin=$bin
  # Older installations kept the real binary at the launcher's path.
  [[ -x $daemon_bin ]] || daemon_bin=$launcher
  if [[ -x "$daemon_bin" ]] && as_user "$daemon_bin" --data-dir "$data_dir" --json status 2>/dev/null |
    jq -e '(.data.process_id // 0) > 0' >/dev/null; then
    as_user "$daemon_bin" --data-dir "$data_dir" stop
  fi
}

workdir=$(mktemp -d)
trap 'rm -rf -- "$workdir"' EXIT
if [[ $release_selection == source ]]; then
  build_latest_commit
else
  download_release
fi
cd /

# systemd отслеживает процесс OpenRad напрямую.
cat > "$workdir/$service" <<UNIT
[Unit]
Description=OpenRad VPN
Wants=network-online.target
After=network-online.target

[Service]
Type=exec
User=$linux_user
ExecStartPre=+/bin/sh -c 'test -c /dev/net/tun || { /usr/sbin/modprobe tun && test -c /dev/net/tun; }'
ExecStart="$bin" --data-dir "$data_dir" __daemon
Restart=always
RestartSec=5s
UNIT

cat > "$workdir/$timer" <<UNIT
[Unit]
Description=Start OpenRad VPN after boot

[Timer]
OnBootSec=30s
AccuracySec=1s
Unit=$service

[Install]
WantedBy=timers.target
UNIT

new_binary="$workdir/openrad"
if ! cmp -s "$new_binary" "$bin" || ! cmp -s "$workdir/$service" "$unit_dir/$service"; then
  if [[ -f "$unit_dir/$timer" ]]; then
    systemctl stop "$timer"
  fi
  if [[ -f "$unit_dir/$service" ]]; then
    systemctl stop "$service"
  fi
  # Переносим в systemd экземпляр, запущенный ранее командой openrad start.
  stop_cli_daemon
fi
if ! cmp -s "$new_binary" "$bin"; then
  install -m 0755 -o root -g root "$new_binary" "$bin"
fi

# При первой регистрации D-Bus и keyring работают от пользователя OpenRad.
if ! as_user test -s "$identity"; then
  as_user bash -s -- "$bin" "$data_dir" "$node_name" <<'INIT'
set -euo pipefail
umask 077
keyring_dir=$(mktemp -d)
trap 'rm -rf -- "$keyring_dir"' EXIT
export XDG_RUNTIME_DIR="$keyring_dir/run"
export XDG_DATA_HOME="$keyring_dir/data"
export OPENRAD_LOG_DIR="$HOME/.local/share/OpenRad/logs"
mkdir -- "$XDG_RUNTIME_DIR" "$XDG_DATA_HOME"
dbus-run-session -- bash -e -o pipefail -c '
  head -c 24 /dev/urandom | base64 -w0 |
    gnome-keyring-daemon --daemonize --unlock --components=secrets >/dev/null
  "$1" --data-dir "$2" init --node-name "$3"
' bash "$@"
INIT
fi

# Повышенные права нужны помощнику TAP с конкретным VPN-адресом и UID.
vpn_ip=$(as_user jq -er '.vip | strings | select(test("^26(\\.[0-9]{1,3}){3}$"))' "$identity")
# Pin the helper digest, since a custom InstallDir may be inside the user's home.
binary_digest=$(sha256sum -- "$bin")
binary_digest=${binary_digest%% *}
sudoers_bin=${bin// /\\ }
printf 'Defaults:%s fdexec=always\n%s ALL=(root) NOPASSWD: sha256:%s %s tap-helper --vip %s --owner %s --lan\n' \
  "$linux_user" "$linux_user" "$binary_digest" "$sudoers_bin" "$vpn_ip" "$linux_uid" > "$workdir/openrad-sudoers"
visudo -cf "$workdir/openrad-sudoers"
install -m 0440 -o root -g root "$workdir/openrad-sudoers" /etc/sudoers.d/openrad-rtunnel
write_launcher "$workdir/openrad-launcher"
install -m 0755 -o root -g root "$workdir/openrad-launcher" "$launcher"

if ! as_user jq -e --arg name "$node_name" '.node_name == $name' "$identity" >/dev/null; then
  openrad rename "$node_name"
fi

install -m 0644 -o root -g root "$workdir/$service" "$workdir/$timer" "$unit_dir/"
systemctl daemon-reload
if ! systemctl is-active --quiet "$service"; then
  stop_cli_daemon
fi
systemctl start "$service"

# Проверяем, что работает процесс systemd и что TAP-интерфейс готов.
deadline=$((SECONDS + 90))
while true; do
  service_pid=$(systemctl show --property=MainPID --value "$service")
  if openrad --json status 2>/dev/null |
    jq -e --argjson pid "$service_pid" '
      $pid > 0 and .data.process_id == $pid and
      .data.phase == "connected" and .data.snapshot.interface_ready == true
    ' >/dev/null; then
    break
  fi
  if (( SECONDS >= deadline )); then
    openrad status >&2 || true
    journalctl -u "$service" -n 30 --no-pager >&2 || true
    fail 'OpenRad failed to connect or create the TAP interface within 90 seconds.'
  fi
  sleep 1
done

for i in "${!network_names[@]}"; do
  join_network "${network_names[i]}" "${network_passwords[i]}"
done

systemctl enable --now "$timer"
systemctl is-enabled "$timer"
openrad status
openrad networks
openrad peers
ip -4 -brief address show dev radminvpn0
printf '\nInstalled. Run openrad for status, openrad --help for CLI commands, or openrad restart to restart the service.\n'
