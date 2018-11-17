
##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	CSV
# FILE: 	local.mk
#
# AUTHOR: 	Ted Kim, June 8, 1992
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ted	6/90		Initial version
#
# DESCRIPTION:
#	Special definitions required for CSV translation libraries
#
#	$Id: local.mk,v 1.1 97/04/07 11:42:54 newdeal Exp $
#
###############################################################################

GEODE		= csv

.PATH.asm .PATH.def: ../../TransCommon $(INSTALL_DIR:H)/../TransCommon\
                     ../DBCommon $(INSTALL_DIR:H)/DBCommon

.PATH.ui: ./UI $(INSTALL_DIR)/UI

#
# set include file path
#
-IFLAGS		+= -I./UI -I$(INSTALL_DIR)/UI \
		-I../../TransCommon -I$(INSTALL_DIR:H)/../TransCommon\
		-I../DBCommon -I$(INSTALL_DIR:H)/DBCommon

PROTOCONST      = XLATLIB
LIBNAME		= csv,xlatlib

#include	<$(SYSMAKEFILE)>
