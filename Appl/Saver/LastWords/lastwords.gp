##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Last Words
# FILE:		lastwords.gp
#
# AUTHOR:	Jeremy, 5/93
#
# Parameters file for: lastword.geo
#
#	$Id: lastwords.gp,v 1.1 97/04/04 16:49:31 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name lastword.app
#
# All specific screen savers are libraries that may be launched but once
#
type appl, process
#
# This is the name that appears in the generic saver's list
#
longname "Last Words"
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
library ansic
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
class	LWProcessClass
appobj	LWApp
export	LWApplicationClass
