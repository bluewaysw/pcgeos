##############################################################################
# PROJECT:	Tiger
# MODULE:	local.mk
# FILE:		local.mk
# AUTHOR:	Tim Bradley, 7/15/96
#
# $Id: local.mk,v 1.1 96/07/15 17:28:50 tbradley Exp $
#
##############################################################################

.PATH.h		: ../../src/lib/lst $(INSTALL_DIR:H:H)/src/lib/lst ../../src/lib/include $(INSTALL_DIR:H:H)/src/lib/include

TYPE		= library

#if defined(unix)
CFLAGS		+= -Wall
#endif

#include	<$(SYSMAKEFILE)>

