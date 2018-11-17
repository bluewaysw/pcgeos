##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	prints banners out - professional version
# FILE:		banner.gp
#
# AUTHOR:	Roger, 8/91
#
#
# Parameters file for: banner.geo
#
#	$Id: banner.gp,v 1.2 97/07/01 12:05:09 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name banner.app
#
# Long name
#
longname "Banner Maker"
#
# DB Token
#
tokenchars "GBNR"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	BannerProcessClass
#
# Specify application object
#
appobj	BannerApp
#
# Import library routine definitions
#
library	geos
library	ui
library	spool
#
# Define resources other than standard discardable code
#
resource Interface ui-object
resource Menus ui-object
resource PrintUI ui-object
resource AppResource ui-object
resource BannerStrings read-only shared lmem
#
# Resources containing monikers
#
resource MonikerResource lmem read-only shared
#
# Export classes
#
export BannerClass
export BannerGenViewClass
export BannerTextClass
export BannerPrimaryClass
