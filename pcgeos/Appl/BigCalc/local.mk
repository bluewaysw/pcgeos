##############################################################################
#
#       Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       GeoDex
# FILE:         local.mk
# AUTHOR:       Ted Kim
#
#       $Id: local.mk,v 1.1 97/04/04 15:51:04 newdeal Exp $
#
###############################################################################
#
#       Pass flags to handle the GCM version
#
GEODE           = bigcalc

#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DUSE_32BIT_REGS
#endif

#include <$(SYSMAKEFILE)>

