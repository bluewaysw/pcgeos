##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Compress library
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 15, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/15/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for compress library
#
#	$Id: local.mk,v 1.1 97/04/04 17:49:05 newdeal Exp $
#
###############################################################################

PROTOCONST	= COMPRESS
#include    <$(SYSMAKEFILE)>

.PATH.asm .PATH.def: $(INSTALL_DIR:H)/AnsiC
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)
