##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      GEOS
# MODULE:       Navigate Library -- special definitions
# FILE:         local.mk
# AUTHOR:       tony, 10/21/91
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       tony    10/21/91        Initial Revision
#
# DESCRIPTION:
#       Special definitions for Studio
#
#       $Id: local.mk,v 1.1 97/04/05 01:24:39 newdeal Exp $
#
###############################################################################

.PATH.uih .PATH.ui: NavControl Art \
						$(INSTALL_DIR)/NavControl \
						$(INSTALL_DIR)/Art 
UICFLAGS        += -INavControl -IArt\
						-I$(INSTALL_DIR)/NavControl \
						-I$(INSTALL_DIR)/Art

#include <$(SYSMAKEFILE)>

PCXREFFLAGS     += -snavigate.sym

