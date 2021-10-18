#--------------------------------------------------------------
#               K1 Make framework
# Author: Andrea Ravalli (andrea.ravalli@nttdata.com)
#--------------------------------------------------------------


#---------------------
# service configuration
#---------------------
SUBDIRS = interfaces server client

#---------------------
# platform config
#---------------------
ARCH := x86
MKFRW = ./makefrw

#---------------------
# platform config
#---------------------
#src: interfaces

include $(MKFRW)/build.mk 
