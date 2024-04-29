#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

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

lint::dockerfile(){
  >&2 printf " > %s\n" "$@"
  if ! hadolint "$@"; then
    logger::error "Failed linting Dockerfile\n"
    exit 1
  fi
}

lint::shell(){
  >&2 printf " > Shellchecking %s\n" "$@"
  shellcheck -a -x "$@" || {
    logger::error "Failed shellchecking shell script\n"
    return 1
  }
}

# Linting
logger::info "Linting"
lint::shell farcloser-ssh-agent ./*.sh
logger::info "Linting successful"


test::brew(){
  # Kill the system one
  launchctl stop gui/501/com.openssh.ssh-agent 2>/dev/null || true
  # Requires staff
  launchctl disable gui/501/com.openssh.ssh-agent 2>/dev/null || true
  killall ssh-agent 2>/dev/null || true

  # Install and start updated agent
  brew install farcloser/brews/ssh-agent
  brew services start ssh-agent

  pgrep -lf "ssh-agent" ".ssh/agent" >/dev/null || {
    logger::error "No process found"
    exit 1
  }

  [ "$(pgrep -lf "ssh-agent" | wc -l |  tr -d ' ')" == 1 ] || {
    logger::error "System agent still running"
    exit 1
  }

  brew services stop ssh-agent
  brew uninstall farcloser/brews/ssh-agent
}

test::nobrew(){
  ./install.sh

  pgrep -lf "ssh-agent" ".ssh/agent" >/dev/null || {
    logger::error "No process found"
    exit 1
  }

  [ "$(pgrep -lf "ssh-agent" | wc -l |  tr -d ' ')" == 1 ] || {
    logger::error "System agent still running"
    exit 1
  }
}

test::brew
test::nobrew
