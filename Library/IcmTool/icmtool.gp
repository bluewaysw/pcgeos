##############################################################################
#
# PROJECT:      Icon Editor and more Tool Library
# FILE:         icmtool.gp
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################

name            icmtool.lib
longname        "IconEd and more Tool Library"
tokenchars      "IMTl"
tokenid         16480
usernotes	"International version 1.0\rMade by RABE-Soft 10/2026"

type            library, single

platform        geos20

library         geos
library         ansic
library 	ui

# ******************** resources ************************

resource	DataResource 	lmem read-only shared

# ******************** exported Classes ************************

export  WordValueClass
export	SmartTextClass
export 	SeparationLineClass
export 	PaletteColorItemGroupClass

# ******************** exported Routines ************************

export  ITDRAWFULLPALETTE
export 	ITPALETTEINDEXFROMMOUSEPOS

export 	ITGETHSV8BITFROMCOLOR
export 	ITGETCOLORFROMHSV8BIT

export	ITWRITEICONASM
export	ITWRITEICONGOC
export	ITWRITEPTRASM
export	ITWRITEPTRGOC

