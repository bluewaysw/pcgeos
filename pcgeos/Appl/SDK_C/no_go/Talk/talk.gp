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

resource APPRESOURCE 	ui-object
resource INTERFACE 	ui-object
resource MENUINTERFACE	ui-object
resource DISPLAYINTERFACE ui-object
