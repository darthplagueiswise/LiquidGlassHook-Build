# Makefile para compilar IGLiquidGlassHook.dylib (iOS arm64)
#
# Depende de:
#   - Xcode + iPhoneOS SDK (no runner macOS)
#   - fishhook.c / fishhook.h na raiz do repo

SDK   := $(shell xcrun --sdk iphoneos --show-sdk-path)
CC    := $(shell xcrun --sdk iphoneos --find clang)

ARCHS       := -arch arm64
MIN_IOS_VER := -miphoneos-version-min=17.0

CFLAGS  := -Os -fobjc-arc -isysroot $(SDK) $(ARCHS) $(MIN_IOS_VER) -I.
LDFLAGS := -dynamiclib -framework Foundation

SRCS_OBJC := IGLiquidGlassHook.m
SRCS_C    := fishhook.c

OBJS := $(SRCS_OBJC:.m=.o) $(SRCS_C:.c=.o)

TARGET := IGLiquidGlassHook.dylib

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)
