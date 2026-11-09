APP = build/Launcher.app
BIN = .build/release/Launcher
# herdr kills every process carrying its pane's HC_SCOPE when the pane's holder dies, and open passes the env through
OPEN = env -u HC_SCOPE -u HC_TERMINAL_ID -u HC_TERMINAL_SOCKET open

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

run: $(APP)
	pkill -x Launcher || true
	$(OPEN) $(APP)

install: $(APP)
	pkill -x Launcher || true
	rm -rf /Applications/Launcher.app
	cp -R $(APP) /Applications/
	$(OPEN) /Applications/Launcher.app

test:
	swift test

clean:
	rm -rf build .build

.PHONY: all run install test clean
