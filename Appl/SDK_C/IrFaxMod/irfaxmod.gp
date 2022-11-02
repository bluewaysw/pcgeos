##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Responder Ircomm/Serial Testing App
# FILE:		IrFaxModApp.gp
#
# AUTHOR:	Edwin Yu, Feb  1, 1996
#
#       Name    Date            Description
#       ----    ----            -----------
#       Edwin	2/1/1996        Initial version
#	RainerB	4/27/2022	Resource names adjusted for Watcom compatibility
#
# Description:  This is an app testing the Ircomm library.
# 
#
#	$Id: irfaxmod.gp,v 1.1 97/04/04 16:40:34 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name IrFaxModApp.app
#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname "C Ircomm Testing App"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application thread. Methods sent to the Application's
# process will be handled by the IrFaxModlProcessClass, which is defined in 
# IrFaxModApp.goc.
#
class	IrFaxModAppProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. 
#
appobj	IrFaxModApp
#
# Token: this four-letter name is used by GeoManager to locate the icon for this
# application in the database.
#
tokenchars "ISAP"
tokenid 8
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library	streamc
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource	ui-object
resource Interface	ui-object
resource ConstantData	shared, lmem, read-only
#
# Exported Classes
#

