##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Floating Keyboard Sample App
# FILE:		fltkbd.gp
#
# AUTHOR:	Allen Yuen, Jun 26, 1996
#
#	Sample app to demonstrate how to implement a floating keyboard outside
# 	of the UI.
#
#	$Id: fltkbd.gp,v 1.1 97/04/04 16:35:36 newdeal Exp $
#
##############################################################################
#
name	fltkbd.app
longname "Floating Keyboard Sample App"
tokenchars "flkb"
tokenid	0
type	appl, process, single
library	geos
library	ui
library	ark
appobj	FltKbdApp
class	FltKbdProcessClass

# Since we don't list any resources as "ui-object", all object blocks will
# be run by the process thread and the app will be single-threaded.

export	FltKbdApplicationClass
export	FltKbdContentClass
export	FltKbdTextClass
