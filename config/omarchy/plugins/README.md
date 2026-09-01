# Cloud agent and development plugins

Drop shell plugins here to sync them into `~/.config/omarchy/plugins/` during Cloud Agent setup.

Each immediate subdirectory must be a complete plugin folder with a `manifest.json` at its root. For example:

```
config/omarchy/plugins/thelinuxitguy.change-cursor/
  manifest.json
  ChangeCursor.qml
  bin/
  test/
```

On Cloud Agent boot, `.cursor/cloud-agent-install.sh` copies every subdirectory into the live user plugin directory so agents can develop and test third-party plugins without relying on a local-only install path.

These paths are not shipped to end users as part of Omarchy defaults. Features intended for the distro should be ported into `shell/plugins/` and `bin/` instead of living here permanently.
