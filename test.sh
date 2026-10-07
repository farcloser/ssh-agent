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
. "$root"/lib/lint.sh

log::info "Linting"
lint::shell farcloser-ssh-agent ./*.sh ./lib/*.sh
log::info "Linting successful"

test::nobrew(){
  ./install.sh

  pgrep -lf "ssh-agent" ".ssh/agent.sock" >/dev/null || {
    log::error "No process found"
    exit 1
  }

  [ "$(pgrep -lf "ssh-agent" | wc -l |  tr -d ' ')" == 1 ] || {
    log::error "System agent still running"
    exit 1
  }
}

test::nobrew
