APP = build/Launcher.app
BIN = .build/release/Launcher
# herdr kills every process carrying its pane's HC_SCOPE when the pane's holder dies, and open passes the env through
OPEN = env -u HC_SCOPE -u HC_TERMINAL_ID -u HC_TERMINAL_SOCKET open
AGENT = $(HOME)/Library/LaunchAgents/dev.jacob.launcher.plist
SERVICE = gui/$(shell id -u)/dev.jacob.launcher

all: $(APP)

$(BIN): Package.swift $(wildcard Sources/Launcher/*.swift)
	swift build -c release

$(APP): $(BIN) Info.plist $(wildcard ai/*)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp $(BIN) $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/
	mkdir -p $(APP)/Contents/Resources
	cp -R ai $(APP)/Contents/Resources/
	codesign --force --sign "Launcher Dev" $(APP)

# Unloads the agent so it doesn't respawn the installed copy beside this one; make install loads it again
run: $(APP)
	launchctl bootout $(SERVICE) 2>/dev/null || true
	pkill -x Launcher || true
	$(OPEN) $(APP)

install: $(APP)
	launchctl bootout $(SERVICE) 2>/dev/null || true
	pkill -x Launcher || true
	rm -rf /Applications/Launcher.app
	cp -R $(APP) /Applications/
	cp dev.jacob.launcher.plist $(AGENT)
	launchctl bootstrap gui/$(shell id -u) $(AGENT)

test:
	swift test

clean:
	rm -rf build .build

.PHONY: all run install test clean
