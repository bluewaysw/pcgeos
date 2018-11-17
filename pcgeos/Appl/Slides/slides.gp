##############################################################################
#
#	Copyright (c) NewDeal 2000 -- All Rights Reserved
#
# PROJECT:	NDO2000
#
# Parameters file for: slides.geo
#
#	$Id$
#
##############################################################################
#
# Permanent name
#
name slides.app
#
# Long name
#
longname "Slide Show"
#
# DB Token
#
tokenchars "Slid"
tokenid 0
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	ScrapBookClass
#
# Specify application object
#
appobj	ScrapBookApp

heapspace 11665	#20K document, as the document is async update...

#
# Import librar routine definitions
#
library	geos
library	ui
library text
library impex
library convert noload
library saver
library color

# Testing the scan library

#
# Define resources other than standard discardable code
#
resource AppSCMonikerResource lmem read-only shared
resource DatafileMonikerListResource lmem read-only shared

resource FixedSlideCode shared code fixed read-only

resource AppInterface ui-object
resource PrimaryInterface ui-object
resource MenuInterface ui-object
resource ScrapNameListInterface ui-object
resource UIDocCtrlInterface ui-object
resource ScrapRunByAppUI object
resource ScrapViewAreaUI ui-object
resource ScrapStrings lmem shared read-only
resource UserLevelUI ui-object

export ScrapbookApplicationClass
export ScrapBookListClass
export SlideShowClass
