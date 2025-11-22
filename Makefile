ARCHS = arm64
TARGET = iphone:clang:latest:17.0

THEOS_DEVICE_IP = localhost

INSTALL_TARGET_PROCESSES = Instagram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IGLiquidGlassHook

IGLiquidGlassHook_FILES  = src/IGLiquidGlassHook.xm
IGLiquidGlassHook_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
