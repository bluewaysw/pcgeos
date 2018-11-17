##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	scrapbk
# FILE:		scrapbk
#
# AUTHOR:	brianc, 2/90
#
#
# Parameters file for: scrapbk.geo
#
#	$Id: scrapbk.gp,v 1.1 97/04/04 16:49:46 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name scrapbk.app
#
# Long name
#
#longname "PC/GEOS Scrapbook"
#ifdef GPC
#longname "Clip Art Scrapbook"
#else
longname "Scrapbook"
#endif
#
# DB Token
#
tokenchars "Scrp"
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
ifdef SLIDE_SHOW_FEATURE
library saver
library color
endif

# Testing the scan library

#
# Define resources other than standard discardable code
#
resource AppLCMonikerResource lmem read-only shared
resource AppLMMonikerResource lmem read-only shared
resource AppYCMonikerResource lmem read-only shared
resource AppYMMonikerResource lmem read-only shared
resource AppSCMonikerResource lmem read-only shared
resource AppSMMonikerResource lmem read-only shared
resource AppSCGAMonikerResource lmem read-only shared
resource DatafileMonikerListResource lmem read-only shared
resource MonikerResource lmem read-only shared
ifdef SLIDE_SHOW_FEATURE
resource FixedSlideCode shared code fixed read-only
endif

resource AppInterface ui-object
resource PrimaryInterface ui-object
resource MenuInterface ui-object
resource ScrapNameListInterface ui-object
resource UIDocCtrlInterface ui-object
resource ScrapRunByAppUI object
resource ScrapViewAreaUI ui-object
resource ScrapStrings lmem shared read-only
resource UserLevelUI ui-object
ifdef GPC
resource NoBackupUI ui-object
endif

export ScrapbookApplicationClass
export ScrapBookListClass
ifdef GPC
export ScrapBookDocumentClass
endif
ifdef SLIDE_SHOW_FEATURE
export SlideShowClass
endif
