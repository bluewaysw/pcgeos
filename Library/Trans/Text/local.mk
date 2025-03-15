##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Text translation libraries
# FILE: 	local.mk
#
# AUTHOR: 	Jenny Greenwood, 24 September, 1991
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	9/24/90		Initial version
#	jenny	11/91		Added TransCommon
#
# DESCRIPTION:
#	Special definitions required for all the text translation libraries
#
#	$Id: local.mk,v 1.1 97/04/07 11:40:10 newdeal Exp $
#
###############################################################################

.PATH.asm .PATH.def: ../TextCommon $(INSTALL_DIR:H)/TextCommon \
		     ../../TransCommon $(INSTALL_DIR:H)/../TransCommon

.PATH.ui: ./UI $(INSTALL_DIR)/UI

.PATH.h: ./CommonH $(INSTALL_DIR)/CommonH \
	 ../TextCommonH $(INSTALL_DIR:H)/TextCommonH

.PATH.c: ../TextCommonC $(INSTALL_DIR:H)/TextCommonC

#
# set include file path
#
-IFLAGS		+= -I./UI -I$(INSTALL_DIR)/UI \
		-I../TextCommon -I$(INSTALL_DIR:H)/TextCommon \
		-I../../TransCommon -I$(INSTALL_DIR:H)/../TransCommon

-CIFLAGS	+= -I./CommonH -I$(INSTALL_DIR)/CommonH \
		-I../TextCommonH -I$(INSTALL_DIR:H)/TextCommonH

PROTOCONST	= XLATLIB

#include	<$(SYSMAKEFILE)>
