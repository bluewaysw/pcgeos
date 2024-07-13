##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      
# MODULE:       
# FILE:         local.mk
# AUTHOR:       Martin Turon, Nov 9, 1994
#
# COMMANDS:
#       Name                    Description
#       ----                    -----------
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       martin  11/9/94         Initial version
#
# DESCRIPTION:
#       
#	$Id: local.mk,v 1.1 97/12/02 14:57:41 gene Exp $
#       $Revision: 1.1 $
#
###############################################################################

# This flag enables "build .bas" triggers, user tool box, reload GECs
#GOCFLAGS += -DPAUL_FEATURES
GOCFLAGS += -DAUTO_INDENT

#
# The GANDALF compilation flag forces all build-time functions to be added
# to the builder.  When it is not defined, the resultant geode is duplo--a
# text editor only version of the builder.
#

GOCFLAGS  += -DGANDALF -Ha

#include <$(SYSMAKEFILE)>

zoomer  :: $(GEODE).geo

LINKFLAGS += $(.TARGETS:Mzoomer:S/zoomer/-DZOOMER/)
