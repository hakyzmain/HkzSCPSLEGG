#!/bin/bash
# HkzSCPSLEGG — SCP: Secret Laboratory + EXILED install script for Pterodactyl
# Author: hakyz
# Server root: /mnt/server

set -e

HKZ_EGG_NAME="HkzSCPSLEGG"
HKZ_EGG_AUTHOR="hakyz"
HKZ_EGG_VERSION="1.0.0"

hkz_msg() { echo "[${HKZ_EGG_NAME}] $*"; }
hkz_step() { echo "[${HKZ_EGG_NAME}] >> $*"; }
hkz_err() { echo "[${HKZ_EGG_NAME}] ERROR: $*" >&2; }

hkz_banner() {
  cat <<'EOF'

  ╔══════════════════════════════════════════════════╗
  ║                                                  ║
  ║              HkzSCPSLEGG  v1.0.0                 ║
  ║                                                  ║
  ║        SCP: Secret Laboratory + EXILED           ║
  ║              Pterodactyl · hakyz                 ║
  ║                                                  ║
  ╚══════════════════════════════════════════════════╝

EOF
  hkz_msg "v${HKZ_EGG_VERSION} | ${HKZ_EGG_AUTHOR}"
}

hkz_steamcmd_install() {
  hkz_step "Installing SteamCMD"
  cd /tmp
  mkdir -p /mnt/server/steamcmd
  curl -fsSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
  tar -xzf steamcmd.tar.gz -C /mnt/server/steamcmd
  cd /mnt/server/steamcmd

  chown -R root:root /mnt
  export HOME=/mnt/server

  if [ "${BETA_TAG:-none}" = "none" ]; then
    ./steamcmd.sh +force_install_dir /mnt/server +login anonymous +app_update "${SRCDS_APPID}" validate +quit
  else
    ./steamcmd.sh +force_install_dir /mnt/server +login anonymous +app_update "${SRCDS_APPID}" -beta "${BETA_TAG}" validate +quit
  fi
}

hkz_write_start_sh() {
  hkz_step "Writing start.sh"
  mkdir -p /mnt/server/.egg
  rm -f /mnt/server/.egg/start.sh
  touch /mnt/server/.egg/start.sh
  chmod +x /mnt/server/.egg/start.sh

  if [ "${INSTALL_DIBOT:-false}" = "true" ]; then
    cat >>/mnt/server/.egg/start.sh <<'EOF'
#!/bin/bash
./.egg/DIBot/DiscordIntegration.Bot > /dev/null &
./LocalAdmin ${SERVER_PORT}
EOF
    hkz_msg "start.sh: LocalAdmin + Discord Integration bot"

  elif [ "${INSTALL_SCPBOT:-false}" = "true" ]; then
    cat >>/mnt/server/.egg/start.sh <<'EOF'
#!/bin/bash
./.egg/SCPDBot/SCPDiscordBot_Linux &
./LocalAdmin ${SERVER_PORT}
EOF
    hkz_msg "start.sh: LocalAdmin + SCPDiscord bot"

  else
    cat >>/mnt/server/.egg/start.sh <<'EOF'
#!/bin/bash
./LocalAdmin ${SERVER_PORT}
EOF
    hkz_msg "start.sh: LocalAdmin only"
  fi
}

hkz_install_dibot() {
  [ "${INSTALL_DIBOT:-false}" = "true" ] || { hkz_msg "Discord Integration: skipped"; return 0; }

  hkz_step "Installing Discord Integration"
  mkdir -p /mnt/server/.egg/DIBot
  mkdir -p /mnt/server/.config/EXILED/Plugins

  rm -f /mnt/server/.egg/DIBot/DiscordIntegration.Bot
  curl -fsSL -o /mnt/server/.egg/DIBot/DiscordIntegration.Bot \
    https://github.com/Exiled-Team/DiscordIntegration/releases/latest/download/DiscordIntegration.Bot
  chmod +x /mnt/server/.egg/DIBot/DiscordIntegration.Bot

  rm -f /mnt/server/.config/EXILED/Plugins/DiscordIntegration.dll
  curl -fsSL -o /mnt/server/.config/EXILED/Plugins/Plugin.tar.gz \
    https://github.com/Exiled-Team/DiscordIntegration/releases/latest/download/Plugin.tar.gz
  tar -xzf /mnt/server/.config/EXILED/Plugins/Plugin.tar.gz -C /mnt/server/.config/EXILED/Plugins
  rm -f /mnt/server/.config/EXILED/Plugins/Plugin.tar.gz
  hkz_msg "Discord Integration: done"
}

hkz_install_scpbot() {
  [ "${INSTALL_SCPBOT:-false}" = "true" ] || { hkz_msg "SCPDiscord: skipped"; return 0; }

  hkz_step "Installing SCPDiscord"
  local plugdir="/mnt/server/.config/SCP Secret Laboratory/PluginAPI/plugins/global"
  mkdir -p /mnt/server/.egg/SCPDBot "${plugdir}"

  rm -f /mnt/server/.egg/SCPDBot/SCPDiscordBot_Linux
  curl -fsSL -o /mnt/server/.egg/SCPDBot/SCPDiscordBot_Linux \
    https://github.com/KarlOfDuty/SCPDiscord/releases/latest/download/SCPDiscordBot_Linux
  chmod +x /mnt/server/.egg/SCPDBot/SCPDiscordBot_Linux

  rm -f "${plugdir}/SCPDiscord.dll" "${plugdir}/dependencies.zip"
  curl -fsSL -o "${plugdir}/dependencies.zip" \
    https://github.com/KarlOfDuty/SCPDiscord/releases/latest/download/dependencies.zip
  curl -fsSL -o "${plugdir}/SCPDiscord.dll" \
    https://github.com/KarlOfDuty/SCPDiscord/releases/latest/download/SCPDiscord.dll
  unzip -oq "${plugdir}/dependencies.zip" -d "${plugdir}/"
  rm -f "${plugdir}/dependencies.zip"
  hkz_msg "SCPDiscord: done"
}

hkz_install_exiled() {
  [ "${INSTALL_EXILED:-true}" = "true" ] || { hkz_msg "EXILED: skipped"; return 0; }

  hkz_step "Installing EXILED (latest stable)"
  mkdir -p /mnt/server/.config/EXILED/Configs/Plugins
  mkdir -p "/mnt/server/.config/SCP Secret Laboratory/PluginAPI/plugins/global"

  curl -fsSL -o /tmp/Exiled.Installer-Linux \
    https://github.com/ExMod-Team/EXILED/releases/latest/download/Exiled.Installer-Linux
  chmod +x /tmp/Exiled.Installer-Linux

  local args="--path /mnt/server --appdata /mnt/server/.config --exiled /mnt/server/.config/EXILED --skip-version-select --exit"

  if [ "${EXILED_PRE:-false}" = "true" ]; then
    hkz_msg "EXILED channel: pre-release"
    /tmp/Exiled.Installer-Linux ${args} --pre-releases

  elif [ "${EXILED_PRE:-false}" = "false" ] || [ -z "${EXILED_PRE:-}" ]; then
    hkz_msg "EXILED channel: stable (latest)"
    /tmp/Exiled.Installer-Linux ${args}

  else
    hkz_msg "EXILED channel: version ${EXILED_PRE}"
    /tmp/Exiled.Installer-Linux ${args} --target-version "${EXILED_PRE}"
  fi

  rm -f /tmp/Exiled.Installer-Linux
  hkz_msg "EXILED: done"
}

hkz_remove_updater() {
  if [ "${REMOVE_UPDATER:-false}" = "true" ]; then
    hkz_step "Removing Exiled.Updater"
    rm -f /mnt/server/.config/EXILED/Plugins/Exiled.Updater.dll
  fi
}

hkz_install_custom_plugin() {
  local url="$1"
  local plugin_json="/tmp/hkz-plugin.json"

  if [ "${GITHUB_TOKEN:-none}" = "none" ]; then
    curl -fsSL "$url" -o "${plugin_json}"
  else
    curl -fsSL -u "${GITHUB_USERNAME:-}:${GITHUB_TOKEN}" "$url" -o "${plugin_json}"
  fi

  local dl name
  dl=$(jq -r '.assets[0].browser_download_url // empty' "${plugin_json}")
  name=$(jq -r '.assets[0].name // empty' "${plugin_json}")

  if [ -z "$dl" ] || [ "$dl" = "null" ]; then
    hkz_err "Bad plugin URL or GitHub rate limit: $url"
    rm -f "${plugin_json}"
    return 1
  fi

  hkz_msg "Custom plugin: ${name}"
  rm -f "/mnt/server/.config/EXILED/Plugins/${name}"

  if [ "${GITHUB_TOKEN:-none}" = "none" ]; then
    curl -fsSL -o "/mnt/server/.config/EXILED/Plugins/${name}" "$dl"
  else
    local api_url
    api_url=$(jq -r '.assets[0].url' "${plugin_json}" | sed "s|https://|https://${GITHUB_TOKEN}:@|")
    curl -fsSL --header 'Accept: application/octet-stream' "$api_url" \
      -o "/mnt/server/.config/EXILED/Plugins/${name}"
  fi

  rm -f "${plugin_json}"
}

hkz_install_custom_plugins() {
  [ "${INSTALL_CUSTOM:-false}" = "true" ] || return 0

  hkz_step "Installing custom plugins from .egg/customplugins.txt"
  touch /mnt/server/.egg/customplugins.txt
  mkdir -p /mnt/server/.config/EXILED/Plugins

  grep -v '^[[:space:]]*#' /mnt/server/.egg/customplugins.txt | while IFS= read -r line; do
    [ -n "$line" ] || continue
    hkz_install_custom_plugin "$line" || true
  done
}

hkz_fix_permissions() {
  hkz_step "Fixing file ownership for Pterodactyl (uid 998)"
  chown -R 998:998 /mnt/server
  chmod -R u+rwX,g+rwX /mnt/server/.config 2>/dev/null || true
}

# --- main ---
hkz_banner

cd /mnt/server 2>/dev/null || true
hkz_steamcmd_install

cd /mnt/server || { hkz_err "Cannot cd to /mnt/server"; exit 1; }

hkz_write_start_sh
hkz_install_dibot
hkz_install_scpbot
hkz_install_exiled
hkz_remove_updater
hkz_install_custom_plugins
hkz_fix_permissions

hkz_msg "Install complete — ${HKZ_EGG_NAME} by ${HKZ_EGG_AUTHOR}"
