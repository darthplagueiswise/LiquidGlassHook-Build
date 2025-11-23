TARGET := iphone:clang:latest:17.0
ARCHS := arm64
PACKAGE_VERSION := 0.1.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := IGLiquidGlassHook
IGLiquidGlassHook_FILES := src/IGLiquidGlassHook.xm
IGLiquidGlassHook_LIBRARIES := substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	@echo "✅ Installed LiquidGlassHook"
