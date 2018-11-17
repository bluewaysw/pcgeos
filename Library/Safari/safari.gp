##############################################################################
#
#	Copyright (c) New Deal 1999 -- All Rights Reserved
#
# PROJECT:	GeoSafari
# MODULE:	GeoSafari
# FILE:		safari.gp
#
# AUTHOR:	Gene Anderson
#
#
# Parameters file for: safari.geo
#
#	$Id$
#
##############################################################################

#
# Permanent name
#
name safari.lib

#
# Desktop-related definitions
#
longname "GeoSafari Library"
tokenchars "SAFL"
tokenid 0

#
# Specify geode type
#
type	library, single
#
# Import library routine definitions
#
library	geos
library ui
library game

#
# Special resource definitions
#
resource Bitmaps		shared lmem read-only
resource Strings                shared lmem read-only

#
# library entry point
#
entry SafariEntry
#
# exported classes
#
export IndicatorClass
export PlayerIndicatorClass
export SpacerClass
export GameCardClass
export IndicatorGroupClass

export SafariImportBitmap
export SAFARIIMPORTBITMAP
export SafariFreeBitmap
export SAFARIFREEBITMAP

export SafariButtonClass
export SafariBackgroundClass
export SafariFeedbackClass
export SafariTimebarClass
export SafariGlyphClass
export SafariScoreClass
