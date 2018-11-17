##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Impex -- special definitions
# FILE: 	local.mk
# AUTHOR: 	jimmy Lefkowitz
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jimmy	3/91		Initial Revision
#
# DESCRIPTION:
#	Special definitions for the Impex library
#
#	$Id: local.mk,v 1.1 97/04/05 01:00:39 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS        += -IUI -I$(INSTALL_DIR)/UI

ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# Turn on read/write checking
#
#ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

#
# GPC additions
#
#  #if $(PRODUCT) == "NDO2000"
#  ASMFLAGS	+= -D_DOS_LONG_NAME_SUPPORT=TRUE
#  UICFLAGS	+= -D_DOS_LONG_NAME_SUPPORT=-1
#  #else
#  ASMFLAGS	+= -D_DOS_LONG_NAME_SUPPORT=TRUE -DGPC_ONLY
#  UICFLAGS	+= -D_DOS_LONG_NAME_SUPPORT=-1 -DGPC_ONLY
#  #endif

#include    <$(SYSMAKEFILE)>

