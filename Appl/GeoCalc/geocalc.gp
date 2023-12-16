##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoCalc
# FILE:		geocalc.gp
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Gene	2/91		Initial version
#	RainerB	12/2023		Renamed to GeoCalc
#
# Parameters file for: geocalc.gp
#
#	$Id: geocalc.gp,v 1.2 97/07/02 09:33:35 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name geocalc.app
#
# Long name
#
longname "GeoCalc"

#
# DB Token
#
tokenchars "GCAL"
tokenid 0
#
# Specify geode type
#
type	appl, process

#
# Specify class name for process
#
class	GeoCalcProcessClass

#
# Specify application object
#
appobj	GCAppObj
#
# Stack must be very large
# It's been increased, in fact, because of the extensive use of
# very large buffers on the stack.  This really ought to be fixed.
#  The DBCS version asks ParseLib to allocate a 4K struct on the
#  stack (SBCS is only 2K).
#  SBCS, up to Nov 93
#
#ifdef DO_DBCS
stack   11000
#else
stack   7512
#endif

heapspace	53k
#
# Import library routine definitions
#
library	geos
library	ui
library	spool
library cell
library parse
library math
library	ssheet
library	ruler
library text

library impex

library spline
library grobj
library chart
library bitmap


#
# Define resources other than standard discardable code
#
resource GeoCalcClassStructures read-only fixed shared
ifdef GP_FULL_EXECUTE_IN_PLACE
resource UsabilityTableXIP lmem  read-only shared
endif

ifndef GPC
resource AppLCMonikerResource ui-object read-only shared
resource AppLMMonikerResource ui-object read-only shared
endif
resource AppSCMonikerResource ui-object read-only shared
ifndef GPC
resource AppSMMonikerResource ui-object read-only shared
resource AppYCMonikerResource ui-object read-only shared
resource AppYMMonikerResource ui-object read-only shared
resource AppSCGAMonikerResource ui-object read-only shared
endif

resource Interface ui-object
resource ApplicationUI ui-object
resource DocumentUI object

resource MenuUI ui-object
resource EditUI ui-object
resource AttrsUI ui-object
ifdef GP_CHARTS
resource ChartUI ui-object
endif
ifdef GP_TEXT_OPTS
resource ParaMenuUI ui-object
endif
resource ChooseUI ui-object
resource CellSizeUI ui-object

resource GraphicUI ui-object
resource PrintUI ui-object
resource PrimaryUI ui-object

resource DisplayUI ui-object read-only shared
resource ContentUI object read-only shared

resource TextObjectPrintUI object

resource UserLevelUI ui-object
resource OptionsMenuUI ui-object

ifdef GP_TOOL_BAR
resource FunctionBarUI ui-object
resource StyleBarUI ui-object
resource GraphicBarUI ui-object
endif
resource GrObjToolUI ui-object

ifdef  GP_SUPER_IMPEX
resource ExtraSaveAsUI ui-object
endif


#resource FormatMenuUI ui-object

# This must be defined here so that the grobj body is relocated when
# the block is read from disk.
resource GrObjBodyUI object

#
# Added for Jedi
ifdef GP_JEDI
resource DocNoteUI	ui-object
endif

resource StringsUI		shared lmem read-only

#
# Added for Nike
ifdef GP_NIKE
resource PointerImages 		shared lmem read-only 
endif

#
#
# Our classes
#
export GeoCalcDisplayClass
export GeoCalcDocumentClass
export GeoCalcContentClass
export GeoCalcSpreadsheetClass
export GeoCalcViewClass
ifdef GP_CHARTS
export GeoCalcGrObjHeadClass
endif
export GeoCalcSSEditBarControlClass
export GeoCalcApplicationClass
export GeoCalcDisplayGroupClass
ifdef GP_JEDI
export GeoCalcNoteShellClass
export GeoCalcJDocControlClass
export JGeoCalcPrimaryClass
export GCNoteDialogClass
endif
#ifdef GP_CHARTS
#export GeoCalcChartBodyClass
#endif

#ifdef GP_SUPER_IMPEX
export GeoCalcDocCtrlClass
#endif
