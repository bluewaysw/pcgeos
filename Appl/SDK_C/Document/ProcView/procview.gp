##############################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	Document Control -- Procedural View display
# FILE:		procview.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "ProcView" sample
#		application. This file is read by the Glue linker to
#		build this application.
#
# RCS STAMP:
#	$Id: procview.gp,v 1.1 97/04/04 16:36:45 newdeal Exp $
#
##############################################################################
#
name procview.app
#
longname "C ProcView"
#
type	appl, process
#
class	PVProcessClass
#
appobj	PVApp
#
tokenchars "SAMP"
tokenid 8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 4305
#
library	geos
library	ui
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
