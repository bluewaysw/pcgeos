##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PostScript Translation Library -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	2/91	Initial Revision
#
# DESCRIPTION:
#	Special definitions for the eps library
#
#	$Id: local.mk,v 1.1 97/04/07 11:26:01 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#
# This is one of TWO compile flags that must be set in order to create
# a postscript _file_ instead of printing output.  You must also set the 
# PRINT_TO_FILE compile flag in the pscript driver.  Instead of printing, the
# output will be routed to "myfile" in the /privdata/spool directory.
#
#ASMFLAGS 	+= -DPRINT_TO_FILE

# EPS_NO_PACKETS removes the binary optimization, sending all data as ascii.
# Default for this flag is OFF.
#ASMFLAGS	+= -DEPS_NO_PACKETS

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS        += -IUI -I$(INSTALL_DIR)/UI

.PATH.asm .PATH.def: ../GraphicsCommon $(INSTALL_DIR:H)/GraphicsCommon \
		     ../../../TransCommon $(INSTALL_DIR:H)/../../TransCommon

#
# set include file path
#
-IFLAGS		+= -I./UI -I$(INSTALL_DIR)/UI \
		-I../GraphicsCommon -I$(INSTALL_DIR:H)/GraphicsCommon \
		-I../../../TransCommon -I$(INSTALL_DIR:H)/../../TransCommon

PROTOCONST	= XLATLIB
LIBNAME		= eps,xlatlib

#include    <$(SYSMAKEFILE)>

