##############################################################################
#
#	Copyright (c) Geoworks 1990 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	UICtrl (Sample GEOS application)
# FILE:		uictrl.gp
#
# AUTHOR:	Tony Requist
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       Tony	4/1/91	        Initial version
#		RainerB	8/7/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "UICtrl" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: uictrl.gp,v 1.1 97/04/04 16:37:04 newdeal Exp $
#
##############################################################################
#
name uictrl.app
#
longname "C UICtrl"
#
tokenchars "SAMP"
tokenid 8
#
type	appl, process, single
#
class	UICProcessClass
#
appobj	UICApp
#
heapspace 4539
#
platform zoomer
#
library	geos
library ansic
library	ui
library text
#
resource AppResource ui-object
resource Interface ui-object
resource ControlStrings lmem read-only shared
resource TextStyleControlToolboxUI ui-object read-only shared
resource TextStyleControlUI ui-object read-only shared
#
# Exported entry points
#
export UICTextStyleControlClass
