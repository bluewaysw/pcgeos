##############################################################################
#      Copyright 1994-2003  Breadbox Computer Company LLC
#
# PROJECT:	GeoPoint
# 				porting from SlideShow that was started by Geoworks
#
# FILE:		geopoint.gp
#
# AUTHOR:	jfh 8/03
#
#              
##############################################################################
#
# Permanent name
#
name geopoint.app
#
# Long name
#
longname "GeoPoint"
#
# DB Token
#
tokenchars "GPta"
tokenid 16431
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	ScrapBookClass
#
# Specify application object
#
appobj	GeoPointApp

# process stack space (default is 2000):
stack 6000

#
# Import library routine definitions
#
platform geos201
library	geos
library	ui
library ansic
library text
library color

#
# Define resources other than standard discardable code
#
resource APPICONRESOURCE  data object
resource DATAFILEMONIKERLISTRESOURCE lmem read-only shared

#resource FixedSlideCode shared code fixed read-only

resource APPRESOURCE ui-object
resource INTERFACE ui-object
#resource APPRESOURCE object
#resource INTERFACE object
resource SHOWRESOURCE ui-object
resource DOCCONTROL object
resource SCRAPSTRINGS lmem shared read-only
resource BUTTONRESOURCE data

export SlideShowClass
export NameGenTextClass
export GPointDocumentControlClass

usernotes "Copyright 1994-2003  Breadbox Computer Company LLC  All Rights Reserved"

