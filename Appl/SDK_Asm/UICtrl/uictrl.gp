##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
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
#	$Id: uictrl.gp,v 1.1 97/04/04 16:32:29 newdeal Exp $
#
##############################################################################
#
name uictrl.app
#
longname "UICtrl"
#
type	appl, process, single
#
class	UICProcessClass
#
# Bigger stack for one-thread model
#
stack 5000
#
appobj	UICApp
#
tokenchars "SAMP"
tokenid 8
#
library	geos
library	ui
library	text
#

resource AppResource object
resource Interface object

resource ControlStrings read-only shared lmem
resource AppTCMonikerResource read-only shared object
resource AppTMMonikerResource read-only shared object
resource AppTCGAMonikerResource read-only shared object

resource TextStyleControlToolboxUI read-only shared object
resource TextStyleControlUI read-only shared object
#
# Exported entry points
#
export UICTextStyleControlClass
