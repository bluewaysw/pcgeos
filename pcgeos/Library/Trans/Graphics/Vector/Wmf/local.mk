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
#	Special definitions required for all the graphics translation libraries
#
#	$Id: local.mk,v 1.1 97/04/07 11:24:59 newdeal Exp $
#
###############################################################################

.PATH.asm .PATH.def: ../VectorCommon $(INSTALL_DIR:H)/VectorCommon \
		     ../../../TransCommon $(INSTALL_DIR:H)/../../TransCommon

.PATH.ui: ./UI $(INSTALL_DIR)/UI

.PATH.h: ./CommonH $(INSTALL_DIR)/CommonH \
	 ../VectorCommonH $(INSTALL_DIR:H)/VectorCommonH

.PATH.c: ../VectorCommonC $(INSTALL_DIR:H)/VectorCommonC

#
# set include file path
#
-IFLAGS		+= -I./UI -I$(INSTALL_DIR)/UI \
		-I../VectorCommon -I$(INSTALL_DIR:H)/VectorCommon \
		-I../../../TransCommon -I$(INSTALL_DIR:H)/../../TransCommon

-CIFLAGS	+= -I./CommonH -I$(INSTALL_DIR)/CommonH \
		-I../VectorCommonH -I$(INSTALL_DIR:H)/VectorCommonH

#PROTOCONST	= XLATLIB

#include	<$(SYSMAKEFILE)>
