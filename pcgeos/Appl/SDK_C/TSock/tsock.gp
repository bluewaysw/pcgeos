##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Test htsock Library
# FILE:		tsock.gp
#
# AUTHOR:	Kok Kin Kee, Aug  7, 1996
#
#
# 
#
#	$Id: tsock.gp,v 1.1 97/04/04 16:41:21 newdeal Exp $
#
##############################################################################
#
name tsock.app

longname "Test htsock Lib"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application thread. Methods sent to the Application's
# process will be handled by the ProcessClass, which is defined in .goc.
#
class	TestProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. 
#
appobj	TestApp
#
# Token: this four-letter name is used by GeoManager to locate the icon for this
# application in the database.
#
tokenchars "THTS"
tokenid 8
#
# Libraries: list which libraries are used by the application.
# geos libraries
#
library	geos
library	ui
library ansic
library socket

#
# Library to test.
#
library htsock

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource APPRESOURCE		ui-object	read-only shared
resource INTERFACE		ui-object	read-only shared
resource TESTINTERFACE		object

#
# Exported Classes
#
export TestMgrClass



