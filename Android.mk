# Copyright (C) 2012 Mozilla Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH:= $(call my-dir)

gonk_misc_LOCAL_PATH := $(LOCAL_PATH)
include $(call all-subdir-makefiles)
LOCAL_PATH := $(gonk_misc_LOCAL_PATH)


include $(CLEAR_VARS)
LOCAL_MODULE       := init.b2g.rc
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES    := init.b2g.rc
LOCAL_MODULE_PATH  := $(TARGET_ROOT_OUT)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := b2g.sh
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := DATA
LOCAL_SRC_FILES    := b2g.sh
LOCAL_MODULE_PATH  := $(TARGET_OUT_EXECUTABLES)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := api-daemon.sh
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := DATA
LOCAL_SRC_FILES    := api-daemon.sh
LOCAL_MODULE_PATH  := $(TARGET_OUT_EXECUTABLES)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := updater-daemon.sh
LOCAL_MODULE_TAGS  := optional
LOCAL_MODULE_CLASS := DATA
LOCAL_SRC_FILES    := updater-daemon.sh
LOCAL_MODULE_PATH  := $(TARGET_OUT_EXECUTABLES)
include $(BUILD_PREBUILT)

#
# Dhcpcd
#
include $(CLEAR_VARS)
LOCAL_MODULE := dhcpcd.conf
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc/dhcpcd-6.8.2
LOCAL_SRC_FILES := dhcpcd/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := dhcpcd-run-hooks
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc/dhcpcd-6.8.2
LOCAL_SRC_FILES := dhcpcd/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := 20-dns.conf
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc/dhcpcd-6.8.2/dhcpcd-hooks
LOCAL_SRC_FILES := dhcpcd/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := 95-configured
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc/dhcpcd-6.8.2/dhcpcd-hooks
LOCAL_SRC_FILES := dhcpcd/$(LOCAL_MODULE)
include $(BUILD_PREBUILT)

#
# Gecko glue
#

include $(CLEAR_VARS)
GECKO_PATH ?= gecko
ifeq (,$(GECKO_OBJDIR))
GECKO_OBJDIR := $(TARGET_OUT_INTERMEDIATES)/objdir-gecko
endif

LOCAL_MODULE := gecko
LOCAL_MODULE_CLASS := DATA
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT)
include $(BUILD_SYSTEM)/base_rules.mk

$(LOCAL_INSTALLED_MODULE): $(LOCAL_BUILT_MODULE)
	@echo Install dir: $(TARGET_OUT)/b2g
	rm -rf $(filter-out $(addprefix $(TARGET_OUT)/b2g/,$(PRESERVE_DIRS)),$(wildcard $(TARGET_OUT)/b2g/*))
	cd $(TARGET_OUT) && tar xvfz $(abspath $<)

GECKO_LIB_DEPS := \
	liblog.so \
	libmedia.so \
	libmtp.so \
	libsensorservice.so \
	libstagefright.so \
	libstagefright_omx.so \
	libsysutils.so \
	android.hardware.gnss@1.0.so \
	android.hardware.vibrator@1.0.so \
	libc++.so \
	libbinder.so \
	libutils.so \
	libcutils.so \
	libhardware_legacy.so \
	libhardware.so \
	libui.so \
	libgui.so \
	libsuspend.so \
	libhidlbase.so \
	$(NULL)

# For APEX_MODULE_LIBS
ifeq (1,$(filter 1,$(shell echo "$$(( $(PLATFORM_SDK_VERSION) < 29 ))" )))
GECKO_LIB_DEPS += \
	libc.so \
	libdl.so \
	libm.so \
	$(NULL)
endif

.PHONY: $(LOCAL_BUILT_MODULE)
$(LOCAL_BUILT_MODULE): $(TARGET_CRTBEGIN_DYNAMIC_O) $(TARGET_CRTEND_O) $(addprefix $(TARGET_OUT_SHARED_LIBRARIES)/,$(GECKO_LIB_DEPS)) $(GECKO_LIB_STATIC)
	echo "export GECKO_OBJDIR=$(abspath $(GECKO_OBJDIR))"; \
	echo "export GONK_PRODUCT_NAME=$(TARGET_DEVICE)"; \
	echo "export GONK_PATH=$(abspath .)"; \
	echo "export PLATFORM_VERSION=$(PLATFORM_SDK_VERSION)"; \
	unset CC_WRAPPER && unset CXX_WRAPPER && \
	export GONK_PATH="$(abspath .)" && \
	export GONK_PRODUCT_NAME="$(TARGET_DEVICE)" && \
	export PLATFORM_VERSION="$(PLATFORM_SDK_VERSION)" && \
	(cd gecko ; sh build-b2g.sh) && \
	(cd gecko ; sh build-b2g.sh package) && \
	mkdir -p $(@D) && cp $(GECKO_OBJDIR)/dist/b2g-*.tar.gz $@

