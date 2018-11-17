##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Card Games -- Main Card Library
# FILE:		cards.gp
#
# AUTHOR:	Jon Witort
#
# DESCRIPTION:
#
# RCS STAMP:
#$Id: cards.gp,v 1.1 97/04/04 17:44:25 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name cards.lib
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Card Library"
tokenchars "CARD"
tokenid 0
#
# Specify geode type: is a library
#
type	library, single
#
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
#
entry CardsEntry
#
#
#
# Specify alternate resource flags for anything non-standard
#
nosort
resource CardsCodeResource	shared, code, read-only
resource CardBackSelectorCode	shared, code, read-only
resource CardBackSelectorUI	 ui-object read-only shared
resource ControlStrings 	lmem data read-only shared
resource ErrorTextResource	ui-object, read-only
resource CardsClassStructures	shared, fixed, read-only
ifdef GP_FULL_EXECUTE_IN_PLACE
resource CardsControlInfoXIP	shared, read-only
endif


#
# Export classes: list classes which are defined by the library here.
#
export GameClass
export DeckClass
export HandClass
export CardClass
export CardBackSelectorClass

#
#	Routines
#

export VisSendToChildrenWithTest

export WriteTime
export WriteNum
export ScoreToTextObject

#
# XIP-enabled
# 

#
# Utility messages were added to GameClass (see cards.def).
#
incminor UtilityMessages

export CardBackDynamicListClass
export CardBackListItemClass
