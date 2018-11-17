##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	dBase IV
# FILE: 	local.mk
#
# AUTHOR: 	Ted Kim, September 21, 1992
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ted	10/92		Initial version
#
# DESCRIPTION:
#	Special definitions required for dBase IV translation libraries
#
#	$Id: local.mk,v 1.1 97/04/07 11:43:49 newdeal Exp $
#
###############################################################################

GEODE		= dbase4

.PATH.asm .PATH.def: ../../TransCommon $(INSTALL_DIR:H)/../TransCommon \
		     ../DBCommon $(INSTALL_DIR:H)/DBCommon

.PATH.ui: ./UI $(INSTALL_DIR)/UI

#
# set include file path
#
-IFLAGS		+= -I./UI -I$(INSTALL_DIR)/UI \
		-I../../TransCommon -I$(INSTALL_DIR:H)/../TransCommon \
		-I../DBCommon -I$(INSTALL_DIR:H)/DBCommon

PROTOCONST      = XLATLIB
LIBNAME		= dbase4,xlatlib

#include	<$(SYSMAKEFILE)>
