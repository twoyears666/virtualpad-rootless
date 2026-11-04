ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

VP_INCLUDES = -I$(THEOS_PROJECT_DIR)/Sources

# === 注入插件 —— 在每个 App 进程内绘制虚拟按键覆盖层 ===
TWEAK_NAME = VirtualPad
VirtualPad_FILES = Tweak.x \
	$(THEOS_PROJECT_DIR)/Sources/VPModel.m \
	$(THEOS_PROJECT_DIR)/Sources/VPTouchSynthesizer.m \
	$(THEOS_PROJECT_DIR)/Sources/VPControlView.m \
	$(THEOS_PROJECT_DIR)/Sources/VPOverlayWindow.m \
	$(THEOS_PROJECT_DIR)/Sources/VPOverlayManager.m
VirtualPad_CFLAGS = -fobjc-arc $(VP_INCLUDES)
VirtualPad_FRAMEWORKS = UIKit Foundation
VirtualPad_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

# === 偏好面板 —— 设置里的总开关与键位编辑器 ===
BUNDLE_NAME = VirtualPadPrefs
VirtualPadPrefs_INSTALL_PATH = /Library/PreferenceBundles
VirtualPadPrefs_FILES = \
	$(THEOS_PROJECT_DIR)/prefs/VPRootListController.m \
	$(THEOS_PROJECT_DIR)/prefs/VPEditorViewController.m \
	$(THEOS_PROJECT_DIR)/prefs/VPEditorControlView.m \
	$(THEOS_PROJECT_DIR)/Sources/VPModel.m
VirtualPadPrefs_CFLAGS = -fobjc-arc $(VP_INCLUDES) -I$(THEOS_PROJECT_DIR)/headers
VirtualPadPrefs_FRAMEWORKS = UIKit Foundation
VirtualPadPrefs_PRIVATE_FRAMEWORKS = Preferences
VirtualPadPrefs_RESOURCE_DIRS = prefs/Resources
VirtualPadPrefs_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk

# === 控制中心模块 —— 由 CCSupport 载入，可在「设置 > 控制中心」里添加 ===
BUNDLE_NAME = VirtualPadCCModule
VirtualPadCCModule_INSTALL_PATH = /Library/ControlCenter/Bundles
VirtualPadCCModule_FILES = \
	$(THEOS_PROJECT_DIR)/ccmodule/VPCCModule.m \
	$(THEOS_PROJECT_DIR)/Sources/VPModel.m
VirtualPadCCModule_CFLAGS = -fobjc-arc $(VP_INCLUDES)
VirtualPadCCModule_FRAMEWORKS = UIKit Foundation
VirtualPadCCModule_RESOURCE_DIRS = ccmodule/Resources
VirtualPadCCModule_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
