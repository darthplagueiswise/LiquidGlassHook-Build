export THEOS        ?= $(HOME)/theos
export THEOS_MAKE_PATH ?= $(THEOS)/makefiles

include $(THEOS_MAKE_PATH)/common.mk

TWEAK_NAME = LiquidGlassHook

LiquidGlassHook_FILES      = src/IGLiquidGlassHook.xm
LiquidGlassHook_FRAMEWORKS = UIKit Foundation
LiquidGlassHook_CFLAGS    += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
