# Launcher

Cmd+Space, type, Enter. Opens apps. Nothing else.

Setup (once): System Settings → Keyboard → Keyboard Shortcuts → Spotlight → uncheck "Show Spotlight search", otherwise Spotlight takes Cmd+Space.

    make install   # builds, copies to /Applications, loads a LaunchAgent that starts it at login and restarts it if it crashes or is killed

Escape hides, Cmd+Q (while the panel is up) quits.

Cmd+Left / Cmd+Right snap the front window to the left / right half of its screen, Cmd+Up fills the screen, Cmd+Shift+Up / Cmd+Shift+Down enter / leave real full screen, Cmd+1 opens Brave, Cmd+2 Rex Beta, Cmd+3 Citrix Viewer, Cmd+4 Zed (pinned in `Workspaces.swift`), Cmd+5 … Cmd+9 switch to the first, second … other workspace, and Cmd+Shift+Left / Cmd+Shift+Right step through them all. A workspace is an app with a window, numbered in launch order, so switching is instant: no Spaces, no slide. Fill each window with Cmd+Up and it feels like full screen.

Double-tap Cmd for Ask Claude: type a request, Enter, and Claude Code (Haiku) carries it out and answers in the panel. It runs with `ai/prompt.md` as its whole system prompt and may only run the scripts beside it, so far `ai/lights` (every Hue light at once, through lights.ragsdale.dev). Add a capability by adding a script, a section in the prompt, and an `--allowedTools` entry in `Claude.swift`. Needs `claude` at `~/.local/bin/claude`, logged in.
