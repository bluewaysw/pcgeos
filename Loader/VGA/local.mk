##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       VGA loader program
# FILE:         local.mk
# AUTHOR:       Jeremy Dashe, April 15, 1993
#
#       $Id: local.mk,v 1.1 97/04/04 17:27:07 newdeal Exp $
#
###############################################################################

# This beastie is a .exe program
GEODE=loader
GSUFF=exe

ASMFLAGS        += -DINCLUDE_VGA_IMAGE -DIMAGE_TO_BE_DISPLAYED -DNO_LEGAL_IMAGE -DLOAD_VGA_IMAGE_FROM_FILE

.PATH.asm .PATH.def: .. $(INSTALL_DIR:H)

#include <$(SYSMAKEFILE)>
