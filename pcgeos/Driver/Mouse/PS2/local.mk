##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse drivers -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, July 19, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/19/89		Initial Revision
#
# DESCRIPTION:
#	Need to give .. as a -I flag because stupid masm doesn't understand
#	how one can "include ../mouseCommon.asm"
#
#	$Id: local.mk,v 1.1 97/04/18 11:47:57 newdeal Exp $
#
###############################################################################
.PATH.asm .PATH.def	: .. $(INSTALL_DIR:H)

PROTOCONST	= MOUSE

#
# GPC additions
#
#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DCHECK_MOUSE_AFTER_POWER_RESUME
#endif

#include <$(SYSMAKEFILE)>
