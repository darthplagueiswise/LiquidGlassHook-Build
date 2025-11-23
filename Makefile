export THEOS ?= $(HOME)/theos
export THEOS_MAKE_PATH ?= $(THEOS)/makefiles

TARGET := iphone:clang:latest:17.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES = com.burbn.instagram

include $(THEOS_MAKE_PATH)/common.mk

TWEAK_NAME = IGLiquidGlassHook

IGLiquidGlassHook_FILES = src/IGLiquidGlassHook.xm
IGLiquidGlassHook_FRAMEWORKS = UIKit Foundation
IGLiquidGlassHook_CFLAGS += -fobjc-arc
IGLiquidGlassHook_LDFLAGS += -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
