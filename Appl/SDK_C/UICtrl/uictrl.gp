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
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource CONTROLSTRINGS lmem read-only shared
resource TEXTSTYLECONTROLTOOLBOXUI ui-object read-only shared
resource TEXTSTYLECONTROLUI ui-object read-only shared
#
# Exported entry points
#
export UICTextStyleControlClass
