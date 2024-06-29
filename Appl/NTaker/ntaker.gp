##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	NTaker (Sample PC/GEOS application)
# FILE:		ntaker.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "NTaker"
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: ntaker.gp,v 1.1 97/04/04 16:17:31 newdeal Exp $
#
##############################################################################
#
name ntaker.app
#
longname "Note Taker"
#
type	appl, process
#
class	NTakerProcessClass
#
appobj	NTakerApp
#
# This token must match both the token in the GenApplication and the token
# in the GenDocumentControl.
#
tokenchars "NTKR"
tokenid 0
#
library	geos
library	ui
library	pen
library text
library	spool
#
resource AppResource ui-object
resource Interface ui-object
resource DisplayUI ui-object
resource DialogUI ui-object
resource InkDialogUI ui-object
resource UserLevelUI ui-object
resource Strings ui-object read-only shared

resource DocumentUI object

resource AppSCGAMonikerResource lmem read-only shared
resource AppLCGAMonikerResource lmem read-only shared
resource AppSMMonikerResource   lmem read-only shared
resource AppSCMonikerResource   lmem read-only shared
resource AppTCMonikerResource   lmem read-only shared
resource AppLMMonikerResource   lmem read-only shared
resource AppLCMonikerResource  lmem read-only shared
resource AppTCMonikerResource  lmem read-only shared
resource AppTCGAMonikerResource  lmem read-only shared
resource AppTMMonikerResource  lmem read-only shared

#
# Exported entry points
#
export NTakerDocumentClass
export NTakerInkClass
export NTakerProcessClass
export NTakerTextClass
export NTakerDisplayClass
export NTakerApplicationClass
export TitledGenTriggerClass
