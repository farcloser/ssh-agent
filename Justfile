# This file is the project's own.
# Add recipes leveraging provided `do` ready-made recipes, or create your own.
# The import must be kept: it mounts every shared limen task under `just do ...`.
import '.limen/just/main.just'

# The FIRST recipe defined here becomes `just`'s default.
lint: do::lint::default
fix: do::fix::default

# The agent is a macOS launchd service, and test.sh installs and starts it for
# real (brew install, brew services, install.sh) — only a macOS host can run
# that. On the linux/windows legs of the matrix the suite is a loud no-op, so
# those legs still lint. brew is a machine-layer tool the hermetic PATH hides
# on purpose; main.just captures it as BREW_BIN, and test.sh gets its directory.

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
