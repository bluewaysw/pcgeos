##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Gene Anderson, Mar 28, 1991
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	ssheetec.geo		EC version
#	ssheet.geo		non-EC version
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	3/28/91		Initial Revision
#
# DESCRIPTION:
#	local makefile for spreadsheet object
#
#	$Id: local.mk,v 1.1 97/04/07 11:14:51 newdeal Exp $
#
###############################################################################

ASMFLAGS        += -Wall
LINKFLAGS       += -Wunref

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE           = ssheet

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#
# XIP
#
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# Jedi XIP version
#
ASMFLAGS	+= $(.TARGET:X\\[JediXIP\\]/*:S|JediXIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# PIZZA flags
#
ASMFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DSPIDER_CHART |g)
UICFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DSPIDER_CHART |g)
LINKFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DSPIDER_CHART |g)

#include    <$(SYSMAKEFILE)>

#
# GPC usability tweaks
#
ASMFLAGS	+= -DGPC -DGPC_ART
UICFLAGS	+= -DGPC -DGPC_ART
LINKFLAGS	+= -DGPC

#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC_ONLY
UICFLAGS	+= -DGPC_ONLY
LINKFLAGS	+= -DGPC_ONLY
#endif
