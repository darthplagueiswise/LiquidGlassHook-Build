TARGET := iphone:clang:17.0
INSTALL_TARGET_PROCESSES = Instagram
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LiquidGlassHook

# Arquivo único com hooks + config + menu
$(TWEAK_NAME)_FILES = src/IGLiquidGlassHook.xm

# Frameworks usados
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation

# Usamos MobileSubstrate para MSHookFunction
$(TWEAK_NAME)_LIBRARIES = substrate

# ARC para ObjC
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

# Alvo auxiliar para limpar
after-install::
	install.exec "killall -9 Instagram || true"


