##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Sprite Library
# FILE:		sprite.gp
#
# AUTHOR:	Martin Turon, Nov  8, 1994
#
#
# 
#
#	$Id: sprite.gp,v 1.2 98/07/06 19:04:05 martin Exp $
#
##############################################################################
#
#
# Permanent name
#
name sprite.lib
#
# Long name
#
longname 	"Sprite Library"
tokenchars	"SPIT"
#
# Specify geode type
#
type	library, single

library	geos
library ui

#
# Define resources other than standard discardable code
#
resource BOGUSDeclarationsForSwat ui-object


#
# Export all classes
#
export SpriteClass
export SpriteContentClass

