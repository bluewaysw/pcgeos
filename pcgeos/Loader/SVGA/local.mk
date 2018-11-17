##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       SVGA loader program
# FILE:         local.mk
# AUTHOR:       Jeremy Dashe, April 15, 1993
#
#       $Id: local.mk,v 1.1 97/04/04 17:26:36 newdeal Exp $
#
###############################################################################

GEODE=loader
# This beastie is a .exe program
GSUFF=exe

ASMFLAGS        += -DINCLUDE_SVGA_IMAGE -DIMAGE_TO_BE_DISPLAYED

.PATH.asm .PATH.def: .. $(INSTALL_DIR:H)

#include <$(SYSMAKEFILE)>
