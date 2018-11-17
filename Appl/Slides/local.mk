##############################################################################
#
# 	Copyright (c) GlobalPC 2000 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	ScrapBk -- special definitions
# FILE: 	local.mk
# AUTHOR: 	brianc, 02/17/00
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	02/17/00	Initial Revision
#
# DESCRIPTION:
#	Special definitions for ScrapBk
#
#	$Id$
#
###############################################################################

#
# GPC additions
#
#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC
UICFLAGS	+= -DGPC
LINKFLAGS	+= -DGPC
#endif

#include <$(SYSMAKEFILE)>
