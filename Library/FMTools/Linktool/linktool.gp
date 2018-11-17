##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		linktool.gp
#
# AUTHOR:	Adam de Boor, Aug 26, 1992
#
#
# 
#
#	$Id: linktool.gp,v 1.1 97/04/04 18:01:15 newdeal Exp $
#
##############################################################################
#
name linktool.fmtl
type library, single

#
# Token must be FMTL for file manager to find us
#
tokenchars "FMTL"
tokenid 0

longname "Link creation tool"

library geos
library ui

nosort
resource LinktoolUI object shared
resource LinktoolStrings lmem shared read-only

entry LinktoolEntry

#
# These must conform to the FMToolFunction enumerated type:
#
export LinktoolFetchTools
#
# Other things we provide for the file manager
#
export LinktoolToolActivated
export FileSelectorTextClass


