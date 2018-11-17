##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Bullet
# FILE:		bstartup.gp
#
# AUTHOR:	Steve Yegge, Sep  2, 1992
#
#
# 	Geode Parameters file for the Bullet Startup application.
#
#	$Id: bstartup.gp,v 1.1 97/04/04 16:53:01 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name bstartup.app
#
# Long name
#
longname "Graphical Setup"
#
# DB Token
#
tokenchars "BLST"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	BSProcessClass
#
# Specify application object
#
appobj	BSApp

# 
# This number is unrealistically low -- but it has to be here to
# ensure that the UI doesn't complain when trying to load GeoManager
# while this app is exiting.  It won't hurt anything, because this app
# is never running while other apps are...
#
# heapspace 1000
# Changed to use actual value (9/13/93 -atw)
heapspace 9217


#
# Import library routine definitions
#
library geos
library ui
library config

#
# Define resources other than standard discardable code
#

# General UI -- UI thread & shared
resource AppResource 		ui-object
resource Interface		ui-object
resource Strings		shared lmem read-only

# General UI -- app thread

#
# exported classes
#
export	BSPrimaryClass
export	BSApplicationClass
export	VisScreenContentClass
export	VisScreenClass
export	WelcomeContentClass

export	BSTimeDateDialogClass

