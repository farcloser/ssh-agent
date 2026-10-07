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
    # install.sh uses brew when there is one (its prefix, its openssh) and does
    # without otherwise. Appended, not prepended: the tools test.sh lints with
    # must stay aqua's, not whatever Homebrew happens to have installed.
    # shellcheck disable=SC2154 # BREW_BIN is exported by the canonical .justfile (main.just).
    if [ -n "${BREW_BIN:-}" ]; then PATH="$PATH:$(dirname "$BREW_BIN")"; fi
    ./test.sh
