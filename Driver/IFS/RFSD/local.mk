##############################################################################
#
#       (c) Copyright Geoworks 1994 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:      Network Extensions
# MODULE:       RFSD (Remote File System Driver)
# FILE:         local.mk
#
# AUTHOR:       Simon Auyeung, Nov  23, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       simon   11/23/94	Initial version.
#
# DESCRIPTION:
#       Compilation specific flags for RFSD
#
#       $Id: local.mk,v 1.1 97/04/18 11:46:20 newdeal Exp $
#
##############################################################################

ASMFLAGS        += -DREAD_CHECK -DWRITE_CHECK

#include <$(SYSMAKEFILE)>
