##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Custom Floating Keyboard (Sample GEOS application)
# FILE:		FloatKbd.gp
#
# AUTHOR:	Ed Ballot 2/95
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       EB		2/95	        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	Standard .gp stuff.
#
# RCS STAMP:
#	$Id: floatkbd.gp,v 1.1 97/04/04 16:38:38 newdeal Exp $
#
##############################################################################
#
name floatkbd.app
#
longname "Float Keyboard"
#
tokenchars "SAMP"
tokenid 8
#
type	appl, process
#
class	FloatKbdProcessClass
#
appobj	FloatKbdApp
#
#heapspace 2514
#
library	geos
library	ui
#
resource AppResource object
resource Interface object
