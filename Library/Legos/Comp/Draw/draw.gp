##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      NewBASIC
# MODULE:       Component Object Library - Draw, Sprite
# FILE:         draw.gp
#
# AUTHOR:       Martin Turon, Dec 22, 1994
#
#
#	$Id: draw.gp,v 1.1 98/05/13 15:01:17 martin Exp $
#
##############################################################################
#
# Permanent name
#
name cooldraw.lib
#
# Long name
#
longname        "CoOL Draw"
tokenchars      "CoOL"
#
# Specify geode type
#
type    library, single
#
# Define library entry point
#
#entry  GoolLibraryEntry

library geos
library ui
library ansic
library ent
library basrun
library sprite
library game

#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export DrawComponentClass
export SpriteContentComponentClass
export SpriteComponentClass







