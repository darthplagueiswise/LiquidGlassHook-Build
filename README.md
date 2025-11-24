# LiquidGlassIGHook (fishhook-only)

Standalone dylib (Objective-C + C) that hooks Instagram’s internal
LiquidGlass gates so the tab bar always uses the LiquidGlass style.

* **Injected path** – `@executable_path/Frameworks/LiquidGlassIGHook.dylib`
* **Hook technique** – [`facebook/fishhook`](https://github.com/facebook/fishhook)

## Build

```bash
make clean
make          # produces LiquidGlassIGHook.dylib

Requires Xcode-command-line tools; the Makefile auto-detects the iPhoneOS SDK.

Injection
1.Copy the dylib to Payload/Instagram.app/Frameworks/.
2.Add an LC_LOAD_DYLIB load command pointing to
@executable_path/Frameworks/LiquidGlassIGHook.dylib.
3.Re-sign the app bundle and the dylib.
```

### Makefile
```makefile
# Stand-alone Makefile (no Theos, no Logos)

SDK     := $(shell xcrun --sdk iphoneos --show-sdk-path)
CC      := xcrun --sdk iphoneos clang
CFLAGS  := -Os -fobjc-arc -isysroot $(SDK) -arch arm64 -miphoneos-version-min=17.0 -Ifishhook
LDFLAGS := -dynamiclib -isysroot $(SDK) -arch arm64 \
           -framework Foundation -framework UIKit \
           -install_name @rpath/LiquidGlassIGHook.dylib

TARGET  := LiquidGlassIGHook.dylib
SRC     := LiquidGlassIGHook.m fishhook/fishhook.c

all: $(TARGET)

$(TARGET): $(SRC)
$(CC) $(CFLAGS) $(SRC) -o $@ $(LDFLAGS)

clean:
rm -f $(TARGET) *.o
```
