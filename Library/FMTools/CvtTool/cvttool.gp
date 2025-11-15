##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		convert.gp
#
# AUTHOR:	Adam de Boor, Aug 26, 1992
#
#
# 
#
#	$Id: cvttool.gp,v 1.1 97/04/04 18:00:43 newdeal Exp $
#
##############################################################################
#
name cvttool.fmtl
type library, single

#
# Token must be FMTL for file manager to find us
#
tokenchars "FMTL"
tokenid 0

longname "1.X VM Converter Tool"

library geos
library ui
library convert noload

nosort
resource CommonCode	      code read-only shared
resource AppLCMonikerResource shared lmem read-only
resource AppLMMonikerResource shared lmem read-only
resource AppLCGAMonikerResource shared lmem read-only
resource ConvertUI object shared
resource ConvertStrings lmem shared read-only

#
# These must conform to the FMToolFunction enumerated type:
#
export ConvertFetchTools
#
# Other things we provide for the file manager
#
export ConvertToolActivated
export ConvertToolActivatedNoFileManager
export ConvertCancelTriggerClass
