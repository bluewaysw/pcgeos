##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	TrueType Font Driver
# FILE:		truetype.gp
#
# AUTHOR:	Gene, 11/89
#
#
# Parameters file for: truetype.geo
#
#	$Id: truetype.gp,v 1.1 97/04/18 11:45:31 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	truetype.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
#library ansic
#
# Desktop-related things
#
longname	"TrueType Font Driver"
tokenchars	"FNTD"
tokenid		0
usernotes	"#FreeGEOS font driver to render TrueType fonts."
#
# Define resources other than standard discardable code
#
resource Resident 	fixed code read-only shared
resource InitMod	code read-only shared discard-only

#resource WidthMod fixed code read-only shared
#resource CharMod fixed code read-only shared
#resource MetricsMod fixed code read-only shared
resource ttcalc_TEXT fixed code read-only shared
resource STRINGCODE fixed code read-only shared
resource ttmemory_TEXT fixed code read-only shared
resource MAINCODE fixed code read-only shared
resource ttchars_TEXT fixed code read-only shared
resource ttinit_TEXT fixed code read-only shared
resource ttmetrics_TEXT fixed code read-only shared
resource ttcharmapper_TEXT fixed code read-only shared 
resource ttadapter_TEXT fixed code read-only shared
resource ttwidths_TEXT fixed code read-only shared
resource ttpath_TEXT fixed code read-only shared
resource ttcache_TEXT fixed code read-only shared
resource ttraster_TEXT fixed code read-only shared
resource ttgload_TEXT fixed code read-only shared
resource ttapi_TEXT fixed code read-only shared
resource ftxkern_TEXT fixed code read-only shared
resource ttinterp_TEXT fixed code read-only shared
resource ttload_TEXT fixed code read-only shared
resource ttfile_TEXT fixed code read-only shared
resource ttcmap_TEXT fixed code read-only shared
resource ttobjs_TEXT fixed code read-only shared

resource InterpEntry	code read-only shared
resource InterpInfreq	code read-only shared
resource InterpExtra	code read-only shared

#
# XIP-enabled
#
