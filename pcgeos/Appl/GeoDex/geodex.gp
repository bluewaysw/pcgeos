##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	GeoDex
# FILE:		geodex.gp
#
# AUTHOR:	Ted Kim, 3/92
#
#
# Parameters file for: geodex.geo
#
#	$Id: geodex.gp,v 1.3 98/02/15 19:12:09 gene Exp $
#
##############################################################################
#
# Permanent name
#
name geodex.app
#
# Long name
#
longname "Address Book"

# Product specific longnames
ifdef PRODUCT_NDO1998
longname "NewDex"
endif

#
# token information
#
tokenchars "ADBK"
tokenid 0
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	GeoDexClass
#
# Specify application object
#
appobj	RolodexApp
#
# Driver to be loaded
#
driver	serial
#
# Import library routine definitions
#
ifdef PRODUCT_NDO1998
platform geos201
exempt serial
exempt ssmeta
exempt convert
endif


library	geos
library	ui
library text
library spool
library impex
library	ssmeta
library convert noload
ifdef _FAX_SUPPORT
library mailbox
endif
ifdef GPC
library mailhub
endif
#
# Define resources other than standard discardable code
#
resource AppResource ui-object
resource Interface ui-object
resource SearchResource ui-object
resource WindowResource ui-object
resource MenuResource ui-object
resource RolDocumentBlock object
resource TextResource lmem read-only shared
resource Fixed fixed code
resource TextObjectPrintUI ui-object
resource UserLevelUI ui-object

resource BWUpMonikerResource read-only shared lmem
resource BWDownMonikerResource read-only shared lmem

resource AppLCMonikerResource read-only shared lmem
resource AppSCMonikerResource read-only shared lmem
resource AppSMMonikerResource read-only shared lmem
resource AppSCGAMonikerResource read-only shared lmem
#ifndef GPC
resource AppLMMonikerResource read-only shared lmem
resource AppYCMonikerResource read-only shared lmem
resource AppYMMonikerResource read-only shared lmem
#endif

resource ColorLettersResource read-only data shared
resource ColorMidsectResource read-only data shared
resource ColorBottomResource read-only data shared
resource BWLettersResource read-only data shared
resource BWMidsectResource read-only data shared
resource BWBottomResource read-only data shared
resource CGABWMidsectResource read-only data shared
ifdef IMPEX_MERGE
resource ImpexDialogResource ui-object
endif
ifdef GPC
resource NewDialogResource ui-object
endif
ifdef GPC
resource AppSCMonikerResource2 read-only shared lmem
endif
#
#Define exported routines for relocation purposes
#
export	LettersCompClass
export	LettersClass
export	TitledGenTriggerClass
export	NotesDialogClass
export	RolodexApplicationClass

ifdef _FAX_SUPPORT
export	RolSendControlClass
endif

ifdef GPC
export  AddrFieldTextClass
export  SearchDynamicListClass
export  NoteIconGlyphClass
endif
export  BlackBorderClass
export  RolDocumentControlClass
