########################################################################
#
#     Copyright (c) Dirk Lausecker 1997 -- All Rights Reserved
#
# PROJECT:      BestSound
# MODULE:       Preference Module
# FILE:         lokal.mk
#
# AUTHOR:       Dirk Lausecker
#
# RCS STAMP:
#   $Id$
#
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   21.06.97  DL	Initial Version.
#
########################################################################


#include <$(SYSMAKEFILE)>

GOCFLAGS += -L prefsndn
XCOMFLAGS =-WDE
LINKFLAGS += -N written\20by\20Dirk\20Lausecker\202000
_PROTO=2.0

