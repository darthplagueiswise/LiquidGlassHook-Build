SDK   := $(shell xcrun --sdk iphoneos --show-sdk-path)
CC    := $(shell xcrun --sdk iphoneos --find clang)

ARCHS := -arch arm64
IOS_DEPLOYMENT_TARGET ?= 26.0
MIN_IOS_VER := -miphoneos-version-min=$(IOS_DEPLOYMENT_TARGET)

CFLAGS  := -Os -fobjc-arc -isysroot $(SDK) $(ARCHS) $(MIN_IOS_VER)
LDFLAGS := -dynamiclib -framework Foundation

SRCS_OBJC := IGLiquidGlassHook.m
OBJS      := $(SRCS_OBJC:.m=.o)

TARGET := IGLiquidGlassHook.dylib

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)
