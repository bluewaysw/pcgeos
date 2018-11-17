##############################################################################
#
#	Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	TicTac test app
# FILE:		tictac.gp
#
# AUTHOR:	Peter Dudley  1/92
#
# DESCRIPTION:	This file contains the geode parameters for the Tic Tac Toe
#		sample application.  This application demonstrates the use
#		of Vis classes and mouse handling.
#
#IMPORTANT:
#	This example is written for the GEOS V2.0 API. 
#
# RCS STAMP:
#	$Id: tictac.gp,v 1.1 97/04/04 16:37:11 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name tictac.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Tic Tac Toe Game"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the TicTacProcessClass, which is defined
# in tictac.goc.
#
class	TicTacProcessClass
#
# Specify application object. This is the object in the .goc file which serves
# as the top-level UI object in the application. See hello.goc.
#
appobj	TicTacApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "SAMP"
tokenid 8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3490
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource BOARDBLOCK object

#
# Other classes
#
export	TicTacBoardClass
export 	TicTacPieceClass
