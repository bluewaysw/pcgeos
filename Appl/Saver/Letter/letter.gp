##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Letter
# FILE:		dribble.gp
#
# AUTHOR:	Gene, 3/92
#
#
# Parameters file for: letter.geo
#
#	$Id: letter.gp,v 1.1 97/04/04 16:45:33 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name letter.app
#
# All specific screen savers are libraries that may be launched but once
#
type appl, process
#
# This is the name that appears in the generic saver's list
#
longname "Typographer's Nightmare"
#
# All specific screen savers have a token of SSAV, and for now they must have
# our manufacturer's ID (until the file selector can be told to ignore the
# ID)
#
tokenchars "SSAV"
tokenid 0
#
# We use the saver library, of course.
#
library saver
#
# We must import the UI so our options block can be properly relocated, the
# relocations happening w.r.t. our imported libraries (we own the block) even
# though it's being duplicated on the generic saver's thread.
#
library ui
#
# The need for this is self-evident...
#
library geos
class	LetterProcessClass
appobj	LetterApp
export	LetterApplicationClass
