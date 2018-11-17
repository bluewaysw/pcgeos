##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Condo viewer
# FILE:		reader.gp
#
# AUTHOR:	Jonathan Magasin, Apr  8, 1994
#
#
# 
#
#	$Id: reader.gp,v 1.1 97/04/04 16:29:19 newdeal Exp $
#
##############################################################################
#
name reader.app

longname "Book Reader"

type	appl, process, single

class	ReaderProcessClass

appobj	ContentViewApp

#
# Full-screen version uses different token-chars, so that double-clicking on
# a Book will launch the standard book reader, not the full-screen version.
#
ifdef  PRODUCT_FULL_SCREEN
tokenchars "fscr"
else
tokenchars "cntv"
endif
tokenid 0

heapspace  5000

#
# Commenting these out so that the Jedi version will make on the trunk.
# Alternately we could have tried to move HINT_SEEK_SLOT out of the
# "protominor UINewForResponder" in genC.def, but that's harder.  Jedi
# is totally incompatible with Zoomer anyway.
#
#platform zoomer
#exempt conview

#
# Libraries: list which libraries are used by the application
#
library	geos
library	ui
library conview

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
nosort
resource ReaderClassStructures	shared, fixed, read-only
resource AppResource ui-object
resource ContentViewInterface ui-object

resource AppSCMonikerResource lmem read-only shared
resource AppSMMonikerResource lmem read-only shared
resource AppYCMonikerResource lmem read-only shared
resource AppYMMonikerResource lmem read-only shared
resource AppSCGAMonikerResource lmem read-only shared

#
# Export routines.
#

ifdef  PRODUCT_FULL_SCREEN
export FullScreenContentViewClass
endif



