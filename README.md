# macOS ssh-agent

This is a very simple user launch agent for ssh-agent.

This is typically useful if you are using a YubiKey, or otherwise want to use
`sk-` keys, that the vanilla macOS ssh-agent does not support.

## TL;DR

```bash
# Install and start updated agent (the tap must be trusted: the formula
# depends on farcloser/brews/openssh)
brew tap farcloser/brews && brew trust farcloser/brews
brew install farcloser/brews/ssh-agent
brew services start ssh-agent

# Get the socket location in profile
printf '. "$HOME/.posh_ssh'"\n" >> ~/.profile
. ~/.profile

# Optional: retire Apple's ssh-agent. Not required — ours listens on its own
# socket, and Apple's is socket-activated: it only ever runs when a client
# connects to its listener, which nothing does once SSH_AUTH_SOCK points at
# ours. `disable` covers every future login and, on macOS 26, is the only
# lever: SIP refuses `bootout` and `kill` of an Apple LaunchAgent, so the
# listener stays until you log out.
launchctl disable gui/$(id -u)/com.openssh.ssh-agent
```

## Socket location

The agent listens on `$HOME/.ssh/agent.sock`, and `~/.posh_ssh` (written by the
launch script) exports it as `SSH_AUTH_SOCK`.

It used to be `$HOME/.ssh/agent`. That path is no longer usable: OpenSSH 10 (and
the macOS 26 system ssh-agent) put ssh-agent's own default socket in a *directory*
at `$HOME/.ssh/agent/s.*`, and the system agent creates that directory the first
time anything talks to it — a socket file cannot be bound over it. After upgrading,
open a new shell (or re-source `~/.posh_ssh`) so clients pick up the new path.

## Installing without using brew services

Be sure to either have brew and the formula `openssh` installed, or alternatively
that you do have a compatible ssh-agent in your PATH.

Git clone.

Then:
```bash
# Install
./install.sh destination_folder

# Get the socket location in profile
printf '. "$HOME/.posh_ssh'"\n" >> ~/.profile
. ~/.profile
```

To uninstall:
```bash
# Remove our service
launchctl remove world.farcloser.ssh_agent
# Re-enable the system service: `enable` covers the next login (SIP refuses
# to bootstrap an Apple LaunchAgent by hand — log out and back in)
launchctl enable gui/$(id -u)/com.openssh.ssh-agent
```

### What is this doing exactly?

`./install.sh` will:
- disable (`launchctl disable`) the system `ssh-agent` launch agent — hygiene, not a
  requirement (ours has its own socket): it stays loaded until the next login, which is
  when `disable` takes effect, since SIP refuses `bootout` and `kill` of an Apple LaunchAgent
- copy the run script `farcloser-ssh-agent` into `destination_folder`
- install and start a user launch agent in `~/Library/LaunchAgents/world.farcloser.ssh_agent.plist`
  (the brew formula's `brew services start` does the same, minus the system-agent step —
  hence the two `launchctl` lines in the TL;DR):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>world.farcloser.ssh_agent</string>
        <key>ProgramArguments</key>
        <array>
            <string>/Users/dmp/Applications/bin/farcloser-ssh-agent</string>
            <string>/Users/dmp/Applications/homebrew/bin/ssh-agent</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/Users/dmp/Applications/homebrew/var/log/world.farcloser.ssh_agent-stdout.log</string>
        <key>StandardErrorPath</key>
        <string>/Users/dmp/Applications/homebrew/var/log/world.farcloser.ssh_agent-stderr.log</string>
    </dict>
</plist>
```

`./farcloser-ssh-agent` does:
- check if it has been launched already
- clean-up any possible socket remnant (`~/.ssh/agent.sock`, and a socket file left at the
  old `~/.ssh/agent` path by earlier versions — never the directory the system agent keeps there)
- write `~/.posh_ssh`, which exports `SSH_AUTH_SOCK` for your shell
- exec the ssh-agent binary that has been passed as an argument, bound to the socket
