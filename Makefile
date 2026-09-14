APP = build/Launcher.app
BIN = .build/release/Launcher

all: $(APP)

$(BIN): Package.swift $(wildcard Sources/Launcher/*.swift)
	swift build -c release

$(APP): $(BIN) Info.plist
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp $(BIN) $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/
	codesign --force --sign - $(APP)

run: $(APP)
	pkill -x Launcher || true
	open $(APP)

install: $(APP)
	pkill -x Launcher || true
	rm -rf /Applications/Launcher.app
	cp -R $(APP) /Applications/
	open /Applications/Launcher.app

test:
	swift test

clean:
	rm -rf build .build

.PHONY: all run install test clean
