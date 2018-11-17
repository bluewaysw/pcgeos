###############################################################################
#
#               Copyright (c)   GeoWorks 1994   -- All Rights Reserved
#
#       PROJECT:        GEOS
#       FILE:           hotspot.gp
#       AUTHOR:         Edwin Yu,    4/13/94
#
#       $Revision: 1.1 $
#       $Id: hotspot.gp,v 1.1 97/04/04 18:09:02 newdeal Exp $
#
###############################################################################
#
#       Permanent name
#
name    hotspot.lib

#
#       Long name and identification
#
longname        "HotSpot Library"
tokenchars      "HOTS"
tokenid         0

#
#       Specify geode type
#
type            library, single

#
# Condo will be shipped with 2.01, and may optionally be installed over 2.0,
# so we can't use anything more recent than the upgrade system software,
# except for the text library, which will also be shipped with Condo.
#
#platform upgrade
#exempt text

#
#       Libraries
#
library geos
library ui
library grobj
library spline
library text
library ansic

#
#       Export routines:
#
export  HotSpotHeadClass
export  HotSpotManagerClass
export  GenHotSpotClass
export  HotSpotRectClass
export  HotSpotSplineGuardianClass
export  HotSpotSplineWardClass
export	HotSpotPointerClass
export	HotSpotGroupClass
export  HotSpotTextClass

export  HotSpotTextUpdateHotSpotArray
