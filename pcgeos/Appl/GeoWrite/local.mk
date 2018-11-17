##############################################################################
#
# 	Copyright (c) Geoworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoWrite -- special definitions
# FILE: 	local.mk
# AUTHOR: 	tony, 10/21/91
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	10/21/91	Initial Revision
#
# DESCRIPTION:
#	Special definitions for GeoWrite
#
#	$Id: local.mk,v 1.1 97/04/04 15:57:30 newdeal Exp $
#
###############################################################################

.PATH.uih .PATH.ui: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
UICFLAGS	+= -IUI -IDocument -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Document

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE		= write

ASMFLAGS	+= -DINDEX_NUMBERS -DENABLE_CALC_MARGINS_KEY
UICFLAGS	+= -DINDEX_NUMBERS -DENABLE_CALC_MARGINS_KEY
LINKFLAGS	+= 
#ASMFLAGS	+= -DSUPER_IMPEX
#UICFLAGS	+= -DSUPER_IMPEX

#include <$(SYSMAKEFILE)>

PCXREFFLAGS	+= -swrite.sym

#
# If the target is "XIP" 
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# GPC-specific target "TOOLS"
#
#
# #ifdef $(PRODUCT) == "NDO2000"
# #else
# ASMFLAGS	+= $(.TARGET:X\\[TOOLS\\]/*:S|TOOLS| -DBATCH_RTF |g)
# UICFLAGS	+= $(.TARGET:X\\[TOOLS\\]/*:S|TOOLS| -DBATCH_RTF |g)
# LINKFLAGS	+= $(.TARGET:X\\[TOOLS\\]/*:S|TOOLS| -DBATCH_RTF |g)
# #endif

#
# XIP target for building the XIP version of the library.
#
xipOBJS		:= $(OBJS:S|^|XIP/|g)
xipEOBJS	:= $(EOBJS:S|^|XIP/|g)

XIP/write.geo:	$(xipOBJS) write.gp LINK

XIP/writeec.geo:	$(xipEOBJS) write.gp LINK

XIP:		 XIP/write.geo XIP/writeec.geo

#full		:: XIP


#
# Have each XIP .obj and .eobj depend upon the corresponding main
# object file.
#
$(OBJS:S,^,XIP/,g)	: $(.TARGET:T) ASSEMBLE
XIP/Article.obj		: $(ARTICLE)
XIP/Document.obj	: $(DOCUMENT)
XIP/Main.obj		: $(MAIN)
XIP/UI.obj		: $(UI)

$(EOBJS:S,^,XIP/,g)	: $(.TARGET:T) ASSEMBLE
XIP/Article.eobj	: $(ARTICLE)
XIP/Document.eobj	: $(DOCUMENT)
XIP/Main.eobj		: $(MAIN)
XIP/UI.eobj		: $(UI)
