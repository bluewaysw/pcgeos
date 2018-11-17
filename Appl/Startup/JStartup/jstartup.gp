##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	Jedi
# FILE:		jstartup.gp
#
# AUTHOR:	Steve Yegge, Sep  2, 1994
#
#
# 	Geode Parameters file for the Jedi Startup application.
#
#	$Id: jstartup.gp,v 1.1 97/04/04 16:53:12 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name jstartup.app
#
# Long name
#
longname "Graphical Setup"
#
# DB Token
#
tokenchars "JDST"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	JSProcessClass
#
# Specify application object
#
appobj	JSApp

heapspace 13k

#
# Import library routine definitions
#
library geos
library ui
library jlib

#
# Define resources other than standard discardable code
#

# General UI -- UI thread & shared
resource JStartUpClassStructures	shared read-only fixed
resource AppResource 		ui-object
resource Interface		ui-object
resource Strings		shared lmem read-only

# General UI -- app thread

#
# exported classes
#
export	JSPrimaryClass
export	JSApplicationClass

export	JSTimeDateDialogClass

ifdef GP_CITY_LIST
export	MnemonicInteractionClass
export	JSCityListClass
endif

#
# XIP enabled
#
