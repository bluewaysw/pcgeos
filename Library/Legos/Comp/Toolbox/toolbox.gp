##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      NewBASIC
# MODULE:       Component Object Library - Toolbox
# FILE:         toolbox.gp
#
# AUTHOR:       Martin Turon, Dec 22, 1994
#
#
#       $Id: toolbox.gp,v 1.1 98/05/13 14:36:54 martin Exp $
#
##############################################################################
#
# Permanent name
#
name toolbox.lib
#
# Long name
#
longname        "CoOL Toolbox"
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
library gadget
library basco
library basrun
library hash
#library sprite
#library game

#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export GoolControlClassPtrTable
export GoolControlClass
skip 3
#export GoolGStringClass
#export GoolSpriteContentClass
#export GoolSpriteClass
export GoolSwitchFrameClass







