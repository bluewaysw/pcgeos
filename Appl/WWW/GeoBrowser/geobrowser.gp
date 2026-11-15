##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Penelope
# FILE:		geobrowser.gp
#
# AUTHOR:	Edwin Yu, Apr 15, 1996
#
#
# 
#
#	$Id: geobrowser.gp,v 1.1 97/04/04 17:20:30 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name browser.app
#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname "Geos Web Browser"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application thread. Methods sent to the Application's
# process will be handled by the ProcessClass, which is defined in .goc.
#
class	GBProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. 
#
appobj	GBApp
#
# Token: this four-letter name is used by GeoManager to locate the icon for this
# application in the database.
#
tokenchars "GBRW"
tokenid 8
#
# Libraries: list which libraries are used by the application.
# geos libraries
#
library	geos
library	ui
library ansic
#
# www libraries
#
library htcore
library htmem
library http
library htmlp
library htjpeg

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource		ui-object	read-only shared
resource Interface		ui-object	read-only shared
resource TestHTMLResource	read-only lmem discardable

#
# My Content-type handlers. These classes receive converted data from
# the Web Library, that is, they do not do any coversion.
#
export HTPlainClass
export HTMLClass
export HTGIFClass

#
# Exported Routines
#



