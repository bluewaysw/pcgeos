##############################################################################
#
#	Copyright (c) NewDeal 2001 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Tabs (Sample GEOS application)
# FILE:		tabs.gp
#
# AUTHOR:	Edward Di Geronimo Jr., 2/11/01
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       Ed		2/11/01	        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	Your basic GP file for the tabs sample application
#
##############################################################################
#
name tabsamp.app
#
longname "Tabs Sample"
#
tokenchars "TABS"
tokenid 8
#
type	appl, process, single
#
class	TabsProcessClass
#
appobj	TabsApp
#
library	geos
library	ui
#
resource AppResource object
resource Interface object
