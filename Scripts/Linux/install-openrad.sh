#!/usr/bin/env bash
set -euo pipefail
umask 077

linux_user=rtunnel
node_name=
network_name=
network_password=

bin=/usr/local/bin/openrad
data_dir=/var/lib/openrad
identity="$data_dir/profile/identity.json"
unit_dir=/etc/systemd/system
service=openrad.service
timer=openrad.timer
package=openrad-v2.3.0-linux-x86_64
release=https://github.com/gringoestrangeiro/openrad/releases/download/v2.3.3

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

if [[ $EUID -ne 0 || $(dpkg --print-architecture) != amd64 ]]; then
  fail 'Запусти скрипт от root на Ubuntu 24.04 x86-64.'
fi
[[ -d /run/systemd/system ]] || fail 'Для автозапуска нужен системный экземпляр systemd.'

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl dbus-daemon \
  gnome-keyring iproute2 jq kmod sudo

if [[ ! -c /dev/net/tun ]]; then
  modprobe tun || true
fi
[[ -c /dev/net/tun ]] || fail 'Виртуальной машине нужен доступ к /dev/net/tun.'

# Создаём учётную запись для службы OpenRad.
if ! id "$linux_user" >/dev/null 2>&1; then
  if ! getent group "$linux_user" >/dev/null; then
    groupadd -- "$linux_user"
  fi
  useradd --create-home --home-dir "/home/$linux_user" \
    --gid "$linux_user" --shell /usr/sbin/nologin -- "$linux_user"
  printf 'Создан пользователь %s.\n' "$linux_user"
fi
linux_uid=$(id -u "$linux_user")
[[ $linux_uid -ne 0 ]] || fail "Выбери отдельного Linux-пользователя для OpenRad с UID, отличным от 0."
linux_home=$(getent passwd "$linux_user" | cut -d: -f6)
linux_group=$(id -gn "$linux_user")
[[ $linux_home == /* ]] || fail "Для пользователя $linux_user нужен абсолютный путь к домашнему каталогу."
if [[ ! -d "$linux_home" ]]; then
  install -d -m 0700 -o "$linux_user" -g "$linux_group" -- "$linux_home"
fi
install -d -m 0700 -o "$linux_user" -g "$linux_group" -- "$data_dir"

as_user() {
  runuser -u "$linux_user" -- env -i HOME="$linux_home" PATH=/usr/bin:/bin "$@"
}

openrad() {
  as_user "$bin" --data-dir "$data_dir" "$@"
}

stop_cli_daemon() {
  if [[ -x "$bin" ]] && openrad --json status 2>/dev/null |
    jq -e '(.data.process_id // 0) > 0' >/dev/null; then
    openrad stop
  fi
}

workdir=$(mktemp -d)
trap 'rm -rf -- "$workdir"' EXIT
(
  cd "$workdir"
  curl -fsSL --connect-timeout 15 --retry 3 \
    -O "$release/$package.tar.gz" -O "$release/SHA256SUMS"
  awk -v file="$package.tar.gz" '$2 == file || $2 == "*" file' SHA256SUMS | sha256sum -c -
  tar -xzf "$package.tar.gz" -- "$package/openrad"
)
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
ExecStart=$bin --data-dir $data_dir __daemon
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

new_binary="$workdir/$package/openrad"
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
printf '%s ALL=(root) NOPASSWD: %s tap-helper --vip %s --owner %s --lan\n' \
  "$linux_user" "$bin" "$vpn_ip" "$linux_uid" > "$workdir/openrad-sudoers"
visudo -cf "$workdir/openrad-sudoers"
install -m 0440 -o root -g root "$workdir/openrad-sudoers" /etc/sudoers.d/openrad-rtunnel

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
    fail 'OpenRad не подключился или не смог создать TAP-интерфейс за 90 секунд.'
  fi
  sleep 1
done

printf '%s\n' "$network_password" | as_user bash -c '
  set -euo pipefail
  umask 077
  password_file=$(mktemp)
  trap '\''rm -f -- "$password_file"'\'' EXIT
  cat > "$password_file"
  "$@" --password-file "$password_file"
' bash "$bin" --data-dir "$data_dir" join "$network_name"

systemctl enable --now "$timer"
systemctl is-enabled "$timer"
openrad status
openrad networks
openrad peers
ip -4 -brief address show dev radminvpn0
