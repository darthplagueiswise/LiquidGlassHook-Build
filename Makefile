export TARGET = iphone:clang:latest:16.0
export ARCHS = arm64
export THEOS_DEVICE_IP = 127.0.0.1

INSTALL_TARGET_PROCESSES = Instagram

TWEAK_NAME = LiquidGlassHook
LiquidGlassHook_FILES = src/IGLiquidGlassHook.xm
LiquidGlassHook_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
