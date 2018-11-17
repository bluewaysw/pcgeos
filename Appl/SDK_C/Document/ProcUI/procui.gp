##############################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	Document Control -- Procedural UI-Object display
# FILE:		procui.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "ProcUI" sample
#		application. This file is read by the Glue linker to
#		build this application.
#
# RCS STAMP:
#	$Id: procui.gp,v 1.1 97/04/04 16:36:41 newdeal Exp $
#
##############################################################################
#
name procui.app
#
longname "C ProcUI"
#
type	appl, process
#
class	PUIProcessClass
#
appobj	PUIApp
#
tokenchars "SAMP"
tokenid 8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 4316
#
library	geos
library	ui
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
