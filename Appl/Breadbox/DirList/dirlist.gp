##############################################################################
# FILE:		dirls11.gp
#
# AUTHOR:	John F. Howard 3/95
#
# DESCRIPTION:	This file contains Geode definitions for the Directory/File
#		Lister application.
#
##############################################################################

name dirls11.app

longname "Directory Lister"

tokenchars "DL11"
tokenid 16423

type	appl, process, single

class	DirListProcessClass

appobj	DirListApp

library	geos
library	ui
library	ansic
library text
library spool

resource AppResource ui-object
resource Display ui-object
resource Interface ui-object

#
# These resources contain the bitmap monikers for use under different
# display types and are located in dirlistIcon.goh
#
resource DLMONIKERRESOURCE read-only shared lmem

#
# need this export for printing
#
export PrintGenTextClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"
