##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Klondike
# FILE:		cards.gp
#
# AUTHOR:	Jon Witort
#
# DESCRIPTION:
#
# RCS STAMP:
#$Id: soli.gp,v 1.1 97/04/04 15:46:59 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name solitaire.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Solitaire"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify heapspace requirement
#
# Adjusted for new heapspace usage allocation method.  --JimG 3/18/95
#

heapspace 1300
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the YodaProcessClass, which is defined in yoda.asm.
#
class	SolitaireProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See yoda.ui.
#
appobj	SolitaireApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "SOLI"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library cards
library wav

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource AppResource ui-object
resource StuffResource object
resource Interface ui-object
#resource HelpUI ui-object
#resource Countdown ui-object
#resource HighScore ui-object
#resource HighScoreDisplay ui-object
resource Strings shared ui-object read-only
resource SolQuickTipsResource		ui-object

resource AppLCMonikerResource lmem read-only shared
resource AppSCMonikerResource lmem read-only shared
resource AppLMMonikerResource lmem read-only shared
resource AppSMMonikerResource lmem read-only shared
resource AppYCMonikerResource lmem read-only shared
resource AppYMMonikerResource lmem read-only shared
resource AppSCGAMonikerResource lmem read-only shared

ifdef GP_FULL_EXECUTE_IN_PLACE
resource SolitaireClassStructures fixed read-only shared
endif
#
# Export classes: list classes which are defined by the application here.
#
export SolitaireClass
export SolitaireTalonClass
export SolitaireHandClass
export SolitaireDeckClass
