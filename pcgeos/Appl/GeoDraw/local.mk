#
#	Local makefile for: GeoDraw
#
#	$Id: local.mk,v 1.1 97/04/04 15:52:05 newdeal Exp $
#

GEODE = draw
.PATH.ui	: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
.PATH.uih	: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
UICFLAGS	+= -IUI -IDocument -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Document

ASMFLAGS	+= -Wall

ASMFLAGS	+= -DBITMAP_EDITING
UICFLAGS	+= -DBITMAP_EDITING
LINKFLAGS	+= -DBITMAP_EDITING

#include <$(SYSMAKEFILE)>
