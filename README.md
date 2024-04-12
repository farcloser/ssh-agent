# macOS ssh-agent

This is a very simple user launch agent for ssh-agent.

This is typically useful if you are using a YubiKey, or otherwise want to use
`sk-` keys, that the vanilla macOS ssh-agent does not support.

## TL;DR with brew

```bash
brew install farcloser/brews/ssh-agent
brew services start ssh-agent
```

## Without brew services

Be sure to either have brew and the formula `ssh-agent` installed, or alternatively
that you do have an ssh-agent in your PATH.


Git clone.

Then:
```
./install.sh destination_folder
```

## What is this doing exactly?

`./install.sh` will:
- stop and disable the system ssh-agent agent
- copy the run script `farcloser-ssh-agent` into `destination_folder`
- install and start a user launch agent in `~/Library/LaunchAgents/world.farcloser.ssh_agent.plist`:

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
- clean-up any possible socket remnant
- exec the ssh-agent binary that has been passed as an argument
