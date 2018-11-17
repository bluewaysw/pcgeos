##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IStartup
# FILE: 	local.mk
# AUTHOR: 	Brian Chin
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	10/22/92	Initial version 
#
# DESCRIPTION:
#	Special definitions for IStartup
#
#	$Id: local.mk,v 1.1 97/04/04 16:52:55 newdeal Exp $
#
###############################################################################

# If you're going to rebuild state files, then comment out this line:

ASMFLAGS	+= -DISTARTUP

# and uncomment out this one:

# ASMFLAGS	+= -DISTARTUP -DBUILD_STATE_FILE


# MAKE SURE YOU DON'T INSTALL THIS CHANGE!




UICFLAGS	+= -DISTARTUP

#include    <$(SYSMAKEFILE)>
