#
#	Local makefile for: icon editor
#
#	$Id: local.mk,v 1.1 97/04/04 16:06:38 newdeal Exp $
#
.PATH.uih .PATH.ui: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
UICFLAGS	+= -IUI -IDocument -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Document
ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

# Another geode that bucks conventions -- we need to change the GEODE variable
# GEODE		= write

#include <$(SYSMAKEFILE)>

# PCXREFFLAGS	+= -swrite.sym

