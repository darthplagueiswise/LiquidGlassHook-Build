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
