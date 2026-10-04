# This file is the project's own — add recipes below. Keep the import: it
# mounts every shared limen task under `just do ...`.
import '.limen/just/main.just'

# The FIRST recipe defined here becomes `just`'s default.
lint: do::lint::default
fix: do::fix::default

# brew is hidden by the hermetic PATH on purpose; main.just captures it as
# BREW_BIN.

# Run test.sh (installs and starts the agent for real; macOS only, no-op elsewhere).
test:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$(uname -s)" != 'Darwin' ]; then
        echo "ssh-agent is macOS-only — nothing to test on this platform (skipped, not failed)."
        exit 0
    fi
    # shellcheck disable=SC2154 # BREW_BIN is exported by the canonical Justfile (main.just).
    [ -n "${BREW_BIN:-}" ] || { echo "brew was not found on your PATH when just started" >&2; exit 1; }
    PATH="$(dirname "$BREW_BIN"):$PATH" ./test.sh
