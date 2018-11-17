#
#	Local makefile for: Borland library
#
#	$Id: local.mk,v 1.1 97/04/05 01:22:49 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

#
# XIP
#
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

# full		:: XIP

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#include <$(SYSMAKEFILE)>

