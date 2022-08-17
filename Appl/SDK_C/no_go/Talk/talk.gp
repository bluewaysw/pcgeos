##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Talk (Sample PC/GEOS application)
# FILE:		talk.gp
#
# AUTHOR:	Insik Rhee, 11/92
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       IR		11/92	        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This app tests the network library and the comm driver
#
# RCS STAMP:
#	$Id: talk.gp,v 1.1 97/04/04 16:38:23 newdeal Exp $
#
##############################################################################

name 		talk.app
longname 	"C Talk"
type		appl, process, single
class		TalkProcessClass
appobj		TalkApp
tokenchars 	"TALK"
tokenid 	0

library		geos
library		ui
# this app uses the network library, so we declare it here
library		net

resource AppResource 	ui-object
resource Interface 	ui-object
resource MenuInterface	ui-object
resource DisplayInterface ui-object
