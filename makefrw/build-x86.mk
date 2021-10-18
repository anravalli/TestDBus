#--------------------------------------------------------------
#               K1 Make framework
# Author: Andrea Ravalli (andrea.ravalli@nttdata.com)
#--------------------------------------------------------------

$(info ${ARCH} --- Setting up for D-BUS testing ---)

D_X86 = -DX86
CPPFLAGS += -g -std=gnu11 -O0

GLIB_PLATFOFRM_INC = -I/usr/lib64/glib-2.0/include
GLIB_PATH = -L/usr/lib64
SERVICE_INSTALL_DIR = $(PREFIX)/bin
INSTALL_BASE_DIR := 
CLIENT_INSTALL_DIR = $(PREFIX)/bin
ifndef $(PREFIX)
  PREFIX = /usr
endif