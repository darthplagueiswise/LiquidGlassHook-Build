TARGET = iphone:clang:latest:17.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IGLiquidGlassHook
IGLiquidGlassHook_FILES = src/IGLiquidGlassHook.xm
IGLiquidGlassHook_INSTALL_TARGET_PROCESSES = com.burbn.instagram

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
@echo "✅  Installed LiquidGlassHook"
