#--------------------------------------------------------------
#               K1 Make framework
# Author: Andrea Ravalli (andrea.ravalli@nttdata.com)
#--------------------------------------------------------------


MAKE = make

CLEAN_DIRS = $(SUBDIRS:%=clean-%)
UNINSTALL_DIRS = $(SUBDIRS:%=uninstall-%)
INSTALL_DIRS = $(SUBDIRS:%=install-%)
INSTALL_ADB_DIRS = $(SUBDIRS:%=install-adb-%)
UNINSTALL_ADB_DIRS = $(SUBDIRS:%=uninstall-adb-%)

.PHONY: all install
all: $(SUBDIRS)

.PHONY: $(SUBDIRS) $(INSTALL_DIRS) $(UNINSTALL_DIRS) $(INSTALL_ADB_DIRS) $(UNINSTALL_ADB_DIRS)

install: $(INSTALL_DIRS)
$(INSTALL_DIRS): 
	$(MAKE) -C $(@:install-%=%) install ARCH=$(ARCH)

install-adb: $(INSTALL_ADB_DIRS)
$(INSTALL_ADB_DIRS): 
	$(MAKE) -C $(@:install-adb-%=%) install-adb ARCH=$(ARCH)

uninstall: $(UNINSTALL_DIRS)
$(UNINSTALL_DIRS): 
	$(MAKE) -C $(@:uninstall-%=%) uninstall ARCH=$(ARCH)

uninstall-adb: $(UNINSTALL_ADB_DIRS)
$(UNINSTALL_ADB_DIRS):
	$(MAKE) -C $(@:uninstall-adb-%=%) uninstall-adb ARCH=$(ARCH)

$(SUBDIRS):
	$(MAKE) -C $@ ARCH=$(ARCH)

clean: $(CLEAN_DIRS)

.PHONY: $(CLEAN_DIRS)
$(CLEAN_DIRS):
	$(MAKE) -C  $(@:clean-%=%) clean ARCH=$(ARCH)
	
.PHONY: test test-clean
test:
	$(MAKE) -C test $@ ARCH=$(ARCH)
	
test-clean:
	$(MAKE) -C test $@ ARCH=$(ARCH)
	
test-run:
	$(MAKE) -C test $@ ARCH=$(ARCH)
	
checkmake:
	$(MAKE) -C $(lastword $(SUBDIRS)) $@ ARCH=$(ARCH)