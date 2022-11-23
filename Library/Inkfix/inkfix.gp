##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# FILE:		inkfix.gp
#
# AUTHOR:	Andrew Wilson, 10/93
#
#
# Parameters file for: inkfix
#
#	$Id: inkfix.gp,v 1.1 97/04/05 01:06:35 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name inkfix.lib
#
# Long name
#
longname "Fixed Ink Object Library"
#
# DB Token
#
tokenchars "INKF"
tokenid 0

entry	InkfixEntry
#
# Specify geode type
#
type	library, single

#
# Import kernel routine definitions
#
library	geos
library	ui
library	pen

#
# Exported routines (and classes)
#
export	FixedInkClass
export	InkParentClass
