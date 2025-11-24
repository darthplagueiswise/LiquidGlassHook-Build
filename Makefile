TARGET := iphone:clang:latest
ARCHS  := arm64

INSTALL_TARGET_PROCESSES = Instagram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LiquidGlassHook

$(TWEAK_NAME)_FILES      = $(wildcard src/*.xm)
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_CFLAGS     = -fobjc-arc
$(TWEAK_NAME)_LDFLAGS   += -Wl,-install_name,@executable_path/$(TWEAK_NAME).dylib

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	@echo "✅  Installed LiquidGlassHook"
