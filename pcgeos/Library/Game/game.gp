##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		game.gp...
#
# AUTHOR:	Chris Boyke
#
#	$Id: game.gp,v 1.1 97/04/04 18:04:43 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name game.lib

#
# Imported libraries
#
library geos
library ui
ifdef HIGH_SCORE_SOUND
library wav
endif

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Game Library"
tokenchars	"GAME"
tokenid		0

#
# Define the library entry point
#
entry GameLibraryEntry

#
# Define resources other than standard discardable code
#
nosort
resource RandomCode	read-only code shared
resource ContentCode	read-only code shared
resource MainCode	read-only code shared
resource GameControlCode	read-only code shared
resource StringsUI	lmem
resource GameStatusControlUI	ui-object read-only shared
resource HighScoreUI	ui-object read-only shared
resource GameClassStructures read-only fixed shared

#
# Exported Classes
#
export  GameContentClass

# Controllers

export	GameStatusControlClass
export	HighScoreClass

#
# Export routines
#

export	GameRandom
export	GAMERANDOM

# added by edwdig
export  UnderlinedGlyphClass

#
# Added "don't play sound" attribute to HighScoreClass.
#
incminor HighScoreNoSound
