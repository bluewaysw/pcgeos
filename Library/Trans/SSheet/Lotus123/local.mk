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
#	$Id: local.mk,v 1.1 97/04/07 11:42:01 newdeal Exp $
#
###############################################################################

GEODE		= lot123ss

.PATH.asm .PATH.def: ../../TransCommon $(INSTALL_DIR:H)/../TransCommon

.PATH.ui: ./UI $(INSTALL_DIR)/UI

#
# set include file path
#
-IFLAGS		+= -I./UI -I$(INSTALL_DIR)/UI \
		-I../../TransCommon -I$(INSTALL_DIR:H)/../TransCommon

PROTOCONST	= XLATLIB
LIBNAME		= lot123ss,xlatlib

#include	<$(SYSMAKEFILE)>
