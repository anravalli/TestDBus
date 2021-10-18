#--------------------------------------------------------------
#               K1 Make framework
# Author: Andrea Ravalli (andrea.ravalli@nttdata.com)
#--------------------------------------------------------------

include $(MKFRW)/build-noarch.mk
include $(MKFRW)/functions.mk

$(info Application is $(APPLICATION) )
MKDIR = mkdir -p
BINDIR = $(MKFRW)/../bin-$(ARCH)
BUILD_DIR = $(MKFRW)/../build-$(ARCH)

HEADERS := $(wildcard *.h) $(wildcard ../include/*.h)

OBJECTS := $(addprefix $(BUILD_DIR)/,$(notdir $(SOURCES:%.c=%.o)))

INSTALL_RESOUCES := $(addprefix install-,$(RESOURCES_FILES))
UNINSTALL_RESOUCES := $(addprefix uninstall-,$(RESOURCES_FILES))
INSTALL_RESOUCES_ADB := $(addprefix install-adb-,$(RESOURCES_FILES))
UNINSTALL_RESOUCES_ADB := $(addprefix uninstall-adb-,$(RESOURCES_FILES)) 


$(info SERVICE_NAME: $(SERVICE_NAME))
$(info SERVICE_VERSION: $(SERVICE_VERSION))
$(info SERVFRW_VERSION: $(SERVFRW_VERSION))
ifeq ($(MAKECMDGOALS),install)
$(info **** Installing $(SERVICE_NAME) and its resources:)
endif
ifeq ($(MAKECMDGOALS),install-adb)
$(info **** Installing $(SERVICE_NAME) and its resources on OBU:)
endif

all: $(SUBDIRS) $(BINDIR)/$(APPLICATION)
.PHONY: all install $(INSTALL_RESOUCES) uninstall $(UNINSTALL_RESOUCES) clean $(SUBDIRS) build

$(SUBDIRS):
	$(MAKE) -C $@ ARCH=$(ARCH) build

$(BINDIR):
	$(MKDIR) $@

$(BUILD_DIR):
	$(MKDIR) $@

$(BUILD_DIR)/%.o: %.c $(HEADERS)
	$(COMPILE.c) $(CPPFLAGS) $< $(D_X86) -o $@

$(BUILD_DIR)/%.o:
	$(COMPILE.c) $(CPPFLAGS) $< $(D_X86) -o $@

build: $(BUILD_DIR) $(OBJECTS)

$(BINDIR)/$(APPLICATION): build $(BINDIR) $(FRAMEWORK_OBJ)
	$(LINK.o) $(BUILD_DIR)/*.o $(LDFLAGS) -o $@ $(GENERATED_LIBS)


$(INSTALL_RESOUCES): $(RESOURCES_FILES)
	@mkdir -vp $(INSTALL_BASE_DIR)/$(@D:install-$(RESOURCES_DIR)/%=%)
	@cp -v $(@:install-%=%) $(INSTALL_BASE_DIR)/$(@D:install-$(RESOURCES_DIR)/%=%)

install: all prepare-info $(INSTALL_RESOUCES)
	@mkdir -p $(SERVICE_INSTALL_DIR) && cp -v $(BINDIR)/$(APPLICATION) $(SERVICE_INSTALL_DIR)

$(UNINSTALL_RESOUCES):
	@rm -fv $(INSTALL_BASE_DIR)/$(@:uninstall-$(RESOURCES_DIR)/%=%)

uninstall: $(UNINSTALL_RESOUCES)
	@rm -fv $(SERVICE_INSTALL_DIR)/$(APPLICATION)
	
$(INSTALL_RESOUCES_ADB): $(RESOURCES_FILES)
	#@mkdir -vp $(INSTALL_BASE_DIR)/$(@D:install-adb-$(RESOURCES_DIR)/%=%)
	adb push $(@:install-adb-%=%) /$(@:install-adb-$(RESOURCES_DIR)/%=%)

install-adb: all prepare-info $(INSTALL_RESOUCES_ADB)
	adb push $(BINDIR)/$(APPLICATION) $(SERVICE_INSTALL_DIR:$(INSTALL_BASE_DIR)%=%)

info-dir:
	mkdir -pv $(INFO_DIR)

prepare-info: info-dir
	@echo "[version]" > $(INFO_DIR)/$(PACK_INFO)
	@echo "$(SERVICE_NAME):  $(SERVICE_VERSION)" >> $(INFO_DIR)/$(PACK_INFO)
	@echo "K1 Framework:  $(SERVFRW_VERSION)" >> $(INFO_DIR)/$(PACK_INFO)
	@echo "" >> $(INFO_DIR)/$(PACK_INFO)
	@echo "[binary]" >> $(INFO_DIR)/$(PACK_INFO)
	@echo "$(SERVICE_INSTALL_DIR:$(INSTALL_BASE_DIR)%=%)/$(APPLICATION)" >> $(INFO_DIR)/$(PACK_INFO)
	@echo "" >> $(INFO_DIR)/$(PACK_INFO)
	@echo "[resources]" >> $(INFO_DIR)/$(PACK_INFO)
	@for R in $(RESOURCES_FILES_ADB); do echo "$$R" >> $(INFO_DIR)/$(PACK_INFO); done
	@echo "" >> $(INFO_DIR)/$(PACK_INFO)
	if [ -f $(LIB_INFO) ]; then cat  $(LIB_INFO) >> $(INFO_DIR)/$(PACK_INFO); fi
	@echo "" >> $(INFO_DIR)/$(PACK_INFO)

uninstall-adb:
	@echo "*** INFO *** No more needed: the uninstall script is now part of regular package resouorces"

	
clean:
	rm -rf $(BUILD_DIR) $(BINDIR)

.PHONY:checkmake
checkmake:  
	@echo "CURDIR =		\n	${CURDIR}"  
	@echo "\nMAKE_VERSION =	\n	${MAKE_VERSION}"  
	@echo "\nMAKEFILE_LIST =	\n	${MAKEFILE_LIST}"  
	@echo "\nCOMPILE.c =		\n	${COMPILE.c}"
	@echo "\nCOMPILE.cc =	\n	${COMPILE.cc}"
	@echo "\nCOMPILE.cpp =	\n	${COMPILE.cpp}"
	@echo "\nLINK.cc =		\n	${LINK.cc}"
	@echo "\nLINK.o =		\n	${LINK.o}"
	@echo "\nCPPFLAGS =		\n	${CPPFLAGS}"
	@echo "\nCFLAGS =		\n	${CFLAGS}"
	@echo "\nCXXFLAGS =		\n	${CXXFLAGS}"
	@echo "\nLDFLAGS =		\n	${LDFLAGS}"
	@echo "\nLDLIBS =		\n	${LDLIBS}"
	@echo "\nARCHIVE + FLAGS = \n ${AR} \n ${ARFLAGS}"
