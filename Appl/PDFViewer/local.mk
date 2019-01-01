#
#	Local makefile for: PDFViewer
#
#	$Id: local.mk,v 1.1 97/04/04 15:52:05 newdeal Exp $
#

GEODE = pdfvu
.PATH.ui	: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
.PATH.uih	: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI 

ASMFLAGS	+= -Wall

#
# GPC additions *** pulled - jfh
#
##ASMFLAGS	+= -DGPC
##UICFLAGS	+= -DGPC
##GOCFLAGS    += -DGPC

# The view code depends on this to orient the view properly.
#
CCOMFLAGS   += -DUSE_FULL_PAGE_ATTRS

# Enforce a limit on the number of cached page GStrings.
#
CCOMFLAGS   += -DENFORCE_PAGE_GSTRING_LIMIT

# Enable the ability to copy a page to the clipboard.
#
GOCFLAGS    += -DCOPY_PAGE
CCOMFLAGS   += -DCOPY_PAGE

# Borland C compiler option to merge duplicate strings
# (see gfxFont2.goh)
#
#CCOMFLAGS   += -d

#
# PDF viewer:
#
GOCFLAGS	+= -DUSE_NATIVE_FLOAT_TYPE


#include <$(SYSMAKEFILE)>
