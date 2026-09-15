# Launcher

Cmd+Space, type, Enter. Opens apps. Nothing else.

Setup (once): System Settings → Keyboard → Keyboard Shortcuts → Spotlight → uncheck "Show Spotlight search", otherwise Spotlight takes Cmd+Space.

    make install   # builds, copies to /Applications, opens; registers itself as a login item

Escape hides, Cmd+Q (while the panel is up) quits.

Cmd+Left / Cmd+Right snap the front window to the left / right half of its screen, Cmd+Up fills the screen, Cmd+Shift+Up / Cmd+Shift+Down enter / leave real full screen, Cmd+Shift+Left / Cmd+Shift+Right move to the previous / next space like a three-finger swipe, Cmd+1 … Cmd+9 jump straight to that space (the desktop is 1). First use prompts for Accessibility access (System Settings → Privacy & Security → Accessibility). The build signs with a self-signed "Launcher Dev" certificate so that grant survives rebuilds; create one in Keychain Access (Certificate Assistant → Create a Certificate, type Code Signing) if you don't have it.
