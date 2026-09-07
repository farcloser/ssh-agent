#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail
# ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★
# (c) 2024 Farcloser <apostasie@farcloser.world>
# Distributed under the terms of the MIT license
# ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)"
readonly root

. "$root"/lib/log.sh
. "$root"/lib/utils.sh

destination="$HOME"/Applications/bin
readonly destination="${1:-"$destination"}"

brew_root="$(brew --prefix || true)"
readonly brew_root
brew_log_root="${brew_root:+$brew_root/var/log}"
posh_log_root="${POSH_LOG:-$HOME/Library/Log}"
readonly log_root="${brew_log_root:-$posh_log_root}"

fs::ensuredir "$destination"

ssh_agent_bin="${brew_root:+$brew_root/bin/ssh-agent}"
ssh_agent_bin="${ssh_agent_bin:-$(command -v ssh-agent)}"
[ -e "$ssh_agent_bin" ] || {
  log::error "Failed to find ssh-agent binary"
  exit 1
}

# Retire the system ssh-agent — hygiene, not a requirement: ours listens on
# its own socket, and Apple's is socket-activated, so it only runs when a
# client connects to its listener. `disable` covers every future login and,
# on macOS 26, is the only lever: SIP refuses both `bootout` and `kill` of
# an Apple LaunchAgent ("Operation not permitted while System Integrity
# Protection is engaged", "Not privileged to signal service"), so it stays
# loaded until the next login.
launchctl disable "gui/$(id -u)/com.openssh.ssh-agent" || {
  log::warning "Failed to disable the system ssh-agent"
}

launchctl bootout "gui/$(id -u)/world.farcloser.ssh_agent" 2>/dev/null || true

cp -f "$root"/farcloser-ssh-agent "$destination" || {
  log::error "Failed to copy launch script to destination"
  exit 1
}

cp -f "$root"/world.farcloser.ssh_agent.plist "$HOME"/Library/LaunchAgents || {
  log::error "Failed to install plist"
  exit 1
}

sed -Ei "" "s|[{]LAUNCH_SCRIPT[}]|$destination/farcloser-ssh-agent|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
sed -Ei "" "s|[{]SSH_AGENT[}]|$ssh_agent_bin|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
sed -Ei "" "s|[{]OUT_PATH[}]|$log_root/world.farcloser.ssh_agent-stdout.log|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
sed -Ei "" "s|[{]ERR_PATH[}]|$log_root/world.farcloser.ssh_agent-stderr.log|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist

launchctl bootstrap "gui/$(id -u)" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
