##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      GEOS
# MODULE:       Library Library -- special definitions
# FILE:         local.mk
# AUTHOR:       acham, 10/21/91
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       acham    8/9/94        Initial Revision
#
# DESCRIPTION:
#       Special definitions for Gopher
#
#       $Id: local.mk,v 1.1 97/04/04 18:04:53 newdeal Exp $
#
###############################################################################

GOCFLAGS	+= -L gopher

#include <$(SYSMAKEFILE)>
