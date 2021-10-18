#--------------------------------------------------------------
#               K1 Make framework
# Author: Andrea Ravalli (andrea.ravalli@nttdata.com)
#--------------------------------------------------------------

#--------------------------------------------------------
# TOOLS BASIC CONFIG
# Note: No Need to change them
#--------------------------------------------------------

ifeq ($(ARCH), x86)
  include $(MKFRW)/build-x86.mk
else
  ifeq ($(ARCH), gcov)
    include $(MKFRW)/build-gcov.mk
  else
    include $(MKFRW)/build-armv7.mk
  endif
endif

FRW_INCLUDES := $(MKFRW)/../include

#--------------------------------------------------------
# SETTING UP INCLUDES
#--------------------------------------------------------

# for backward compatibility with projects including only the current directory 
ifeq ($(PROJECT_INC_PATH),)
  PROJECT_INC_PATH = ./
endif

LIBS_INCLUDE_PATHS := $(PROJECT_INC_PATH) $(SERVICE_IF_INC_PATH) $(EXT_IF_INC_PATH) $(TARGET_BASE)/$(EXTERNAL_INC_PATH)

CPPFLAGS += -Wall $(foreach IPATH, $(LIBS_INCLUDE_PATHS), -I$(IPATH))

ifneq ($(FRW_INCLUDES),)
  CPPFLAGS += -I$(FRW_INCLUDES)
endif

CPPFLAGS += -fPIC \
		-I./inc \
		$(GLIB_PLATFOFRM_INC) \
		-I$(TARGET_BASE)/usr/include/glib-2.0 \
		-I$(TARGET_BASE)/usr/include/glib-2.0/include \
		-I$(TARGET_BASE)/usr/include/gio-unix-2.0

#--------------------------------------------------------
# SETTING UP LIBS
#--------------------------------------------------------
ifeq ($(LINKING), STATIC)
  STATIC_SERVICE_IF_LIBS := $(foreach LIB, $(SERVICE_IF_LIBS), :lib$(LIB).a)
  STATIC_EXT_IF_LIBS := $(foreach LIB, $(EXT_IF_LIBS), :lib$(LIB).a)
  LIBS := $(STATIC_SERVICE_IF_LIBS) $(STATIC_EXT_IF_LIBS) $(EXTERNAL_LIBS)
else
  LIBS := $(SERVICE_IF_LIBS) $(EXT_IF_LIBS) $(EXTERNAL_LIBS)
endif

LDFLAGS += $(foreach LIB, $(LIBS), -l$(LIB))
LIBS_PATHS := $(SERVICE_IF_LIBS_PATH) $(EXT_IF_LIBS_PATH) $(EXTERNAL_LIBS_PATH)
LDFLAGS += $(foreach LPATH, $(LIBS_PATHS), -L$(LPATH))

LDFLAGS += -L./ \
		$(GLIB_PATH) \
		-lpthread \
		-lrt \
		-lglib-2.0 \
		-lgio-2.0 \
		-lgobject-2.0
		
