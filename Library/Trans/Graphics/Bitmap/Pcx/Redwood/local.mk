##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	tif translation library
# FILE: 	local.mk
#
# AUTHOR: 	maryann 2/92
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jimmy	1/92	    	Initial Version	
#	maryann 2/92		copied for tif
# DESCRIPTION:
#	Special definitions required for Redwood pcx
#
#	$Id: local.mk,v 1.1 97/04/07 11:29:00 newdeal Exp $
#
###############################################################################

INSTALL_GEODE_DIR = $(INSTALL_DIR:H)

.PATH.asm .PATH.def: ../../GraphicsCommon $(INSTALL_GEODE_DIR:H)/GraphicsCommon \
		     ../../../../TransCommon $(INSTALL_GEODE_DIR:H)/../../TransCommon

.PATH.ui: ../UI $(INSTALL_GEODE_DIR)/UI

.PATH.h: ../CommonH $(INSTALL_GEODE_DIR)/CommonH \
	 ../../GraphicsCommonH $(INSTALL_GEODE_DIR:H)/GraphicsCommonH

.PATH.c: ../../GraphicsCommonC $(INSTALL_GEODE_DIR:H)/GraphicsCommonC

#
# set include file path
#
-IFLAGS		+= -I../UI -I$(INSTALL_GEODE_DIR)/UI \
		-I../../GraphicsCommon -I$(INSTALL_GEODE_DIR:H)/GraphicsCommon \
		-I../../../../TransCommon -I$(INSTALL_GEODE_DIR:H)/../../TransCommon

-CIFLAGS	+= -I../CommonH -I$(INSTALL_GEODE_DIR)/CommonH \
		-I../../GraphicsCommonH -I$(INSTALL_GEODE_DIR:H)/GraphicsCommonH

PROTOCONST	= XLATLIB

#include	<$(SYSMAKEFILE)>
