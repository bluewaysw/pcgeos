##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	PCCom1 (Sample GEOS application)
# FILE:		pccom1.gp
#
# AUTHOR:	Cassie Hartzog, Jan 20, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       CH		1/20/94	        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "PCCom1" sample
#		application. This file is read by the Glue linker to
#		build this application.
#
# RCS STAMP:
#	$Id: pccom1.gp,v 1.1 97/04/04 16:39:16 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name pccom1.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "PCCom1 Sample Application"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type	appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the PCCom1ProcessClass, which is defined in pccom1.goc.
#
class	PCCom1ProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See pccom1.goc.
#
appobj	PCCom1App
#
# Token: this four-letter+integer name is used by GeoManager to locate the
# icon for this application in the token database. So that the token will
# be unique, the token id corresponds to the manufacturer ID of the program's
# author. Since this is a sample application, we use the manufacturer id of
# the SDK, which is 8.
#
tokenchars "SAMP"
tokenid 8
#
heapspace 3692
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library pccom 
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource ui-object
resource Interface ui-object

export	PCCom1TextClass


