# Launcher

Cmd+Space, type, Enter. Opens apps. Nothing else.

Setup (once): System Settings → Keyboard → Keyboard Shortcuts → Spotlight → uncheck "Show Spotlight search", otherwise Spotlight takes Cmd+Space.

    make install   # builds, copies to /Applications, loads a LaunchAgent that starts it at login and restarts it if it crashes or is killed

Escape hides, Cmd+Q (while the panel is up) quits.

Cmd+Left / Cmd+Right snap the front window to the left / right half of its screen, Cmd+Up fills the screen, Cmd+Shift+Up / Cmd+Shift+Down enter / leave real full screen, Cmd+1 opens Firefox, Cmd+2 Rex, Cmd+3 Citrix Viewer, Cmd+4 Zed (pinned in `Workspaces.swift`), Cmd+5 … Cmd+9 switch to the first, second … other workspace, and Cmd+Shift+Left / Cmd+Shift+Right step through them all. A workspace is an app with a window, numbered in launch order, so switching is instant: no Spaces, no slide. Fill each window with Cmd+Up and it feels like full screen.

Double-tap Cmd for the switchboard: Rex comes forward on a session labeled `switchboard`, which is started if needed. That session runs Claude Code (Sonnet) in the bundled `ai/` folder. Tap Space, talk, tap Space, and the switchboard hands the request to the right Claude session with SendMessage, or starts a new Rex session for it. When that session reports back, the switchboard reads the result aloud. `ai/CLAUDE.md` is its instructions. `ai/.claude/settings.json` speaks each reply with `say` and stops speaking when you talk again. It controls the lights itself with `ai/lights` (every Hue light at once, through lights.ragsdale.dev). Needs Rex, `claude` logged in to claude.ai, and `"voice": {"enabled": true, "mode": "tap"}` in `~/.claude/settings.json`. The first time, accept the folder-trust prompt and give Rex microphone access.
