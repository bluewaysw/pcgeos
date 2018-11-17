##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       Zoomer loader program
# FILE:         local.mk
# AUTHOR:       Jeremy Dashe, April 15, 1993
#
#       $Id: local.mk,v 1.1 97/04/18 11:46:00 newdeal Exp $
#
###############################################################################

# This beastie is a .exe program
GSUFF=geo

ASMFLAGS        += -DHARDWARE_TYPE=ZOOMER

.PATH.asm .PATH.def .PATH.gp : .. $(INSTALL_DIR:H)

#include <$(SYSMAKEFILE)>
