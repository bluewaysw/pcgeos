##############################################################################
#
#       Copyright (c) 2002 Designs in Light -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       New UI -- special definitions
# FILE:         local.mk
#
###############################################################################

# search inside COMMENT blocks for tags
PCTAGSFLAGS     += -c
PROTOCONST      = SPUI

#
#       Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS        += -DISUI -wprivate -wunref -wunref_local
UICFLAGS        += -DISUI

#
#include    <$(SYSMAKEFILE)>
