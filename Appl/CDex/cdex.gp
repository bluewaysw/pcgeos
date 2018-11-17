##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	GeoDex
# FILE:		cdex.gp
#
# AUTHOR:	Ted Kim, 3/92
#
#
# Parameters file for: geodex.geo
#
# PORT TO GOC: 11/23/04 jfh
#
##############################################################################
#
# Permanent name
#
name cdex.app
#
# Long name
#
longname "CAddress Book"

#
# token information
#
tokenchars "SAMP"
tokenid 0
#
# Specify geode type - we'll do single for now jfh
#
type	appl, process, single
#
# Specify class name for process
#
class	RolodexProcessClass
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
library	geos
library	ui
library ansic
library text
library spool
library impex
library	ssmeta
library convert noload

#
# Define resources other than standard discardable code
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource SEARCHRESOURCE ui-object
resource WINDOWRESOURCE ui-object
resource MENURESOURCE ui-object
resource ROLDOCUMENTBLOCK object
resource TEXTRESOURCE lmem read-only shared
#resource Fixed fixed code
resource TEXTOBJECTPRINTUI ui-object
#resource UserLevelUI ui-object

resource BUTTONRESOURCE read-only shared lmem

resource APPLCMONIKERRESOURCE read-only shared lmem
resource APPSCMONIKERRESOURCE read-only shared lmem
resource APPTCMONIKERRESOURCE read-only shared lmem

resource COLORLETTERSRESOURCE read-only data shared
resource COLORMIDSECTRESOURCE read-only data shared
resource COLORBOTTOMRESOURCE read-only data shared

#resource ImpexDialogResource ui-object

#
#Define exported routines for relocation purposes
#
export	LettersCompClass
export	LettersClass
export	NotesDialogClass
export	RolodexApplicationClass
export	RolDocumentControlClass
