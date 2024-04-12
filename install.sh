#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail
# ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★
# (c) 2024 Farcloser <apostasie@farcloser.world>
# Distributed under the terms of the MIT license
# ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★ ★

readonly COLOR_RED=1
readonly COLOR_GREEN=2
readonly COLOR_YELLOW=3

# Prefix a date to a log line and output to stderr
logger::stamp(){
  local color="$1"
  local level="$2"
  local i
  shift
  shift

  [ ! "$TERM" ] || [ ! -t 2 ] || >&2 tput setaf "$color" 2>/dev/null || true
  for i in "$@"; do
    >&2 printf "[%s] [%s] %s\n" "$(date 2>/dev/null || true)" "$level" "$i"
  done
  [ ! "$TERM" ] || [ ! -t 2 ] || >&2 tput op 2>/dev/null || true
}

logger::info(){
  logger::stamp "$COLOR_GREEN" "INFO" "$@"
}

logger::warning(){
  logger::stamp "$COLOR_YELLOW" "WARNING" "$@"
}

logger::error(){
  logger::stamp "$COLOR_RED" "ERROR" "$@"
}

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)"
readonly root

destination="$HOME"/Applications/bin
readonly destination="${1:-"$destination"}"

brew_root="$(brew --prefix || true)"
readonly brew_root
brew_log_root="${brew_root:+$brew_root/var/log}"
posh_log_root="${POSH_LOG:-$HOME/Library/Log}"
# Favor brew first, fallback on POSH_ otherwise, finally drop to macOS Library location if none of the above is set
readonly log_root="${brew_log_root:-$posh_log_root}"

mkdir -p "$destination" || {
  logger::error "Failed to create destination $destination"
  exit 1
}

mkdir -p "$HOME"/.ssh || {
  logger::error "Failed to create ssh home directory"
  exit 1
}

ssh_agent_bin="${brew_root:+$brew_root/bin/ssh-agent}"
ssh_agent_bin="${ssh_agent_bin:-$(which ssh-agent)}"
[ -e "$ssh_agent_bin" ] || {
  logger::error "Failed to find ssh-agent binary"
  exit 1
}

launchctl stop gui/501/com.openssh.ssh-agent || {
  logger::warning "Failed to stop system ssh-agent"
}

launchctl disable gui/501/com.openssh.ssh-agent || {
  logger::warning "Failed to disable system ssh-agent"
}

# Remove any previous version
launchctl remove world.farcloser.ssh_agent || true

# Copy the run script
cp -f "$root"/farcloser-ssh-agent "$destination" || {
  logger::error "Failed to copy launch script to destination"
  exit 1
}

# Copy plist
cp -f "$root"/world.farcloser.ssh_agent.plist "$HOME"/Library/LaunchAgents || {
  logger::error "Failed to install plist"
  exit 1
}

# Modify plist to fit system
sed -Ei "" "s|[{]LAUNCH_SCRIPT[}]|$destination/farcloser-ssh-agent|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
sed -Ei "" "s|[{]SSH_AGENT[}]|$ssh_agent_bin|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
sed -Ei "" "s|[{]OUT_PATH[}]|$log_root/world.farcloser.ssh_agent-stdout.log|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
sed -Ei "" "s|[{]ERR_PATH[}]|$log_root/world.farcloser.ssh_agent-stderr.log|" "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist

# Register the service
launchctl load "$HOME"/Library/LaunchAgents/world.farcloser.ssh_agent.plist
