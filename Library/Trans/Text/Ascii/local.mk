##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Impex
# MODULE:	Ascii Translation Library
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
#	$Id: local.mk,v 1.1 97/04/07 11:40:56 newdeal Exp $
#
###############################################################################

PROTOCONST		= XLATLIB
LIBNAME         = ascii,xlatlib

.PATH.asm .PATH.def:	../../TransCommon $(INSTALL_DIR:H)/../TransCommon

#
# set include file path
#
-IFLAGS			+= -I../../TransCommon -I$(INSTALL_DIR:H)/../TransCommon

#include	<$(SYSMAKEFILE)>
