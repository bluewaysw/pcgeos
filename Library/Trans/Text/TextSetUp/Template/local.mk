##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Impex
# MODULE:	Template Translation Library
# FILE: 	local.mk
#
# AUTHOR: 	Jenny Greenwood, 2 September 1992
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	9/2/92		Initial version
#
# DESCRIPTION:
#	Special definitions required for all the text translation libraries
#
#	$Id: local.mk,v 1.1 97/04/07 11:40:37 newdeal Exp $
#
###############################################################################

GEODE			= templategeode

PROTOCONST		= XLATLIB

.PATH.asm .PATH.def:	../TextCommon $(INSTALL_DIR:H)/TextCommon \
			../../TransCommon $(INSTALL_DIR:H)/../TransCommon

.PATH.ui:		./UI $(INSTALL_DIR)/UI

.PATH.h:		./CommonH $(INSTALL_DIR)/CommonH \
			../TextCommonH $(INSTALL_DIR:H)/TextCommonH

.PATH.c:		../TextCommonC $(INSTALL_DIR:H)/TextCommonC

#
# set include file path
#
-IFLAGS			+= -I./UI -I$(INSTALL_DIR)/UI \
			-I../TextCommon -I$(INSTALL_DIR:H)/TextCommon \
			-I../../TransCommon -I$(INSTALL_DIR:H)/../TransCommon

-CIFLAGS		+= -I./CommonH -I$(INSTALL_DIR)/CommonH \
			-I../TextCommonH -I$(INSTALL_DIR:H)/TextCommonH

#include	<$(SYSMAKEFILE)>
