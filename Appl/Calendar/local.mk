##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Calendar
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, Wed Jan 10 14:16:44 PST 1990
#
#	$Id: local.mk,v 1.1 97/04/04 14:49:55 newdeal Exp $
#
###############################################################################
#
#	Define flags to handle the GCM version, program is called "geoplan"
#
GEODE		= geoplan

.PATH.ui	: UI Art $(INSTALL_DIR)/UI $(INSTALL_DIR)/Art
.PATH.uih	: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -IArt -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Art  

#
# Turn on time display below menu bar
#
#ASMFLAGS	+= -DDISPLAY_TIME
#UICFLAGS	+= -DDISPLAY_TIME

#
# Turn on read/write checking
#
#ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

#
# Turn on useful compile/link warnings
#
ASMFLAGS	+= -Wunreach -Wshadow 
ASMWARNINGS	 = -Wall -wprivate
LINKFLAGS	+= -Wunref

#
# GPC additions
#
#ASMFLAGS	+= -DGPC -DNO_PEN_SUPPORT
#UICFLAGS	+= -DGPC -DNO_PEN_SUPPORT

# BBXENSEM settings
ASMFLAGS	+= -DNO_PEN_SUPPORT
UICFLAGS	+= -DNO_PEN_SUPPORT

#include <$(SYSMAKEFILE)>
