#
#	Local makefile for: color library
#
#	$Id: local.mk,v 1.1 97/04/04 17:48:59 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#include <$(SYSMAKEFILE)>
