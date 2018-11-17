##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse drivers -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Dave Durran
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Dave	1/29/93		Initial version
#
# DESCRIPTION:
#	Need to give .. as a -I flag because stupid masm doesn't understand
#	how one can "include ../mouseCommon.asm"
#
#	$Id: local.mk,v 1.1 97/04/18 11:48:07 newdeal Exp $
#
###############################################################################
.PATH.asm .PATH.def	: .. $(INSTALL_DIR:H)

PROTOCONST	= MOUSE

#include <$(SYSMAKEFILE)>
