#--------------------------------------------------------------
#               K1 Make framework
# Author: Andrea Ravalli (andrea.ravalli@nttdata.com)
#--------------------------------------------------------------

include $(MKFRW)/functions.mk 

#--------------------------------------------------------
# ARTIFACTS CONFIGURATION
# Note: No Need to change them
#--------------------------------------------------------

BUILD_DIR = $(MKFRW)/../build-$(ARCH)
LIB_DIR = $(MKFRW)/../lib-$(ARCH)
RESOURCES_DIR = ../resources
#INFO_DIR := $(BUILD_DIR)
LIB_INFO := $(BUILD_DIR)/service-lib.info

INTERFACES_OUT = $(foreach IF_SPEC, $(INTERFACE_SPECS), $(subst .xml,,$(subst $(IF_PREFIX).,,$(IF_SPEC))))
GENERATED_SRCS := $(addsuffix .c, $(addprefix $(GEN_DIR)/,$(call lc, $(INTERFACES_OUT)))) 
GENERATED_OBJS := $(addsuffix .o, $(addprefix $(BUILD_DIR)/,$(call lc, $(INTERFACES_OUT))))
GENERATED_HDRS := $(GENERATED_SRCS:%.c=%.h)
GENERATED_LIB := lib$(lastword $(subst ., ,$(IF_PREFIX))).so
GENERATED_STATIC_LIB := lib$(lastword $(subst ., ,$(IF_PREFIX))).a

GENERATED_LIB_T := $(LIB_DIR)/$(GENERATED_LIB)
GENERATED_STATIC_LIB_T := $(LIB_DIR)/$(GENERATED_STATIC_LIB)
 
#$(info --- DEBUG: INTERFACES_OUT=$(INTERFACES_OUT))
$(info --- DEBUG: GENERATED_SRCS=$(GENERATED_SRCS))
$(info --- DEBUG: GENERATED_OBJ=$(GENERATED_OBJ))
$(info --- DEBUG: GENERATED_LIB=$(GENERATED_LIB))
$(info --- DEBUG: GENERATED_STATIC_LIB=$(GENERATED_STATIC_LIB))


#INST_SERVICE_DIR = $(PREFIX)/share/dbus-1/system-service/
INST_LIB_DIR = $(PREFIX)/lib/k1
INST_INC_DIR = $(PREFIX)/include/k1/$(lastword $(subst ., ,$(IF_PREFIX)))
INST_CONF_DIR = $(K1OS_ROOT)/etc/dbus-1/system.d/

#INST_SERVICE_DIR_ADB = $(PREFIX)/share/dbus-1/system-service/
INST_CONF_DIR_ADB = $(INST_CONF_DIR:$(K1OS_ROOT)%=%)
INST_LIB_DIR_ADB = $(INST_LIB_DIR:$(K1OS_ROOT)%=%)
INST_INC_DIR_ADB = $(INST_INC_DIR:$(K1OS_ROOT)%=%)

CONFIG_FILES_FULL = $(addprefix $(INST_CONF_DIR_ADB), $(CONFIG_FILES))
GENERATED_HDRS_FULL = $(addprefix $(INST_INC_DIR_ADB)/, $(GENERATED_HDRS:$(GEN_DIR)/%=%))
INC_DIR := $(lastword $(subst /, ,$(INST_INC_DIR_ADB)))

INST_ADB_CFG_TARGETS := $(addprefix install-adb-, $(CONFIG_FILES))
UNINST_CFG_TARGETS := $(addprefix uninstall-, $(CONFIG_FILES))
#--------------------------------------------------------
# TOOLS BASIC CONFIG
# Note: No Need to change them
#--------------------------------------------------------

MKDIR = mkdir -p

ifeq ($(ARCH),$(filter $(ARCH), x86 gcov))
  $(info --- ${ARCH} -- Setting up for D-BUS testing ---)

  GLIB_PLATFOFRM_INC = -I/usr/lib64/glib-2.0/include
  CPPFLAGS += -g -O0
  ifndef $(PREFIX)
    PREFIX = /usr
  endif
  INST_CONF_DIR := $(PREFIX)/share/dbus-1/system.d/
else
  $(info --- ${ARCH} -- Setting up for Quectel SDK ---)
  QL_SDK_PATH   ?= $(QL_SDKPATH)/../ql-ol-extsdk
  QL_EXP_LDLIBS  = -lql_sys_log
  GLIB_PLATFOFRM_INC = -I$(SDKTARGETSYSROOT)/usr/lib/glib-2.0/include
  ifndef $(K1OS_ROOT)
    K1OS_ROOT = $(QL_SDKPATH)/../ql-ol-rootfs
  endif

  TARGET_BASE = $(SDKTARGETSYSROOT)
  CPPFLAGS += -I$(QL_SDK_PATH)/include

  PREFIX = $(K1OS_ROOT)/usr

endif

CPPFLAGS += -fPIC \
		-I./ \
        -I./inc \
		$(GLIB_PLATFOFRM_INC) \
        -I$(TARGET_BASE)/usr/lib/dbus \
        -I$(TARGET_BASE)/usr/include/glib-2.0 \
        -I$(TARGET_BASE)/usr/include/glib-2.0/include \
        -I$(TARGET_BASE)/usr/include/gio-unix-2.0 

ifeq ($(MAKECMDGOALS),install)
$(info **** Installing DBus interfaces generated lib and header:)
endif
ifeq ($(MAKECMDGOALS),install-adb)
$(info **** Installing DBus interfaces generated lib and header on OBU:)
endif
#--------------------------------------------------------
# TARGETS
# Note: No Need to change them
#--------------------------------------------------------

all: $(BUILD_DIR) $(GEN_DIR) $(GENERATED_LIB_T) $(GENERATED_STATIC_LIB_T)
.PHONY: all

$(BUILD_DIR):
	$(MKDIR) $@

$(LIB_DIR):
	$(MKDIR) $@

install: all prepare-info 
	@mkdir -p $(INST_CONF_DIR) && cp -v $(CONFIG_FILES) $(INST_CONF_DIR)
	@mkdir -p $(INST_LIB_DIR) && cp -v $(LIB_DIR)/$(GENERATED_LIB) $(INST_LIB_DIR)
	@mkdir -p $(INST_LIB_DIR) && cp -v $(LIB_DIR)/$(GENERATED_STATIC_LIB) $(INST_LIB_DIR)
	@mkdir -p $(INST_INC_DIR) && cp -v $(GEN_DIR)/$(GENERATED_SRCS:%.c=%.h) $(INST_INC_DIR)
.PHONY: install

$(UNINST_CFG_TARGETS):
	@rm -fv $(INST_CONF_DIR)/$(@:uninstall-%=%)
	
uninstall: uninstall-$(CONFIG_FILES)
	@rm -fv $(INST_LIB_DIR)/$(GENERATED_LIB)
	@rm -fv $(INST_LIB_DIR)/$(GENERATED_STATIC_LIB)
	@rm -rfv $(INST_INC_DIR)

$(INST_ADB_CFG_TARGETS):
	adb push $(@:install-adb-%=%) $(INST_CONF_DIR_ADB)/$(@:install-adb-%=%)
	
install-adb-$(GENERATED_LIB):
	adb push $(LIB_DIR)/$(@:install-adb-%=%) $(INST_LIB_DIR_ADB)/$(@:install-adb-%=%)

install-adb: prepare-info $(GENERATED_LIB_T) $(GENERATED_STATIC_LIB_T) $(INST_ADB_CFG_TARGETS) install-adb-$(GENERATED_LIB)

.PHONY: install-adb install-adb-$(CONFIG_FILES) install-adb-$(GENERATED_LIB)

uninstall-adb: $(UNINSTALLADBDIRS)
	@echo "*** INFO *** No more needed: the uninstall script is now part of regular package resouorces"

prepare-info:
	@echo "[interface conf]" > $(LIB_INFO)
	for a in $(CONFIG_FILES_FULL); do echo "$$a" >> $(LIB_INFO); done
	@echo "" >> $(LIB_INFO)
	@echo "[interface library]" >> $(LIB_INFO)
	@echo "$(INST_LIB_DIR:$(K1OS_ROOT)%=%)/$(GENERATED_LIB)\n" >> $(LIB_INFO)

.PHONY: uninstall uninstall-$(CONFIG_FILES)
	
$(GEN_DIR):
	$(MKDIR) $@

$(GENERATED_SRCS): $(INTERFACE_SPECS)
	gdbus-codegen --interface-prefix $(IF_PREFIX) --output-directory $(GEN_DIR) \
		--generate-c-code $(@:%.c=%) $(foreach SPEC, $(INTERFACE_SPECS), $(if $(findstring $(@F:%.c=%.xml), $(call lc,$(SPEC))), $(SPEC),)) 

$(BUILD_DIR)/%.o: $(GEN_DIR)/%.c
	$(COMPILE.c) $(CPPFLAGS) $< -o $@

$(GENERATED_STATIC_LIB_T): $(GENERATED_OBJS) $(LIB_DIR)
	$(AR) $(ARFLAGS) $@ $(GENERATED_OBJS)

$(GENERATED_LIB_T): $(GENERATED_OBJS)  $(LIB_DIR)
	$(CC) $(LDFLAGS) -shared -o $@ $(GENERATED_OBJS)

clean:
	rm -rf $(GEN_DIR)
	rm -f $(GENERATED_OBJS)
	rm -rf $(LIB_DIR)
