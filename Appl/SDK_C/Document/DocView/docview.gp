##############################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	Document Control -- View display
# FILE:		docview.gp
#
# AUTHOR:	Tony Requist
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       Tony   	4/4/97	        Initial version
#		RainerB	4/21/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "DocView" sample
#		application. This file is read by the Glue linker to
#		build this application.
#
# RCS STAMP:
#	$Id: docview.gp,v 1.1 97/04/04 16:36:34 newdeal Exp $
#
##############################################################################
#
name docview.app
#
longname "C DocView"
#
type	appl, process
#
class	DVProcessClass
#
appobj	DVApp
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
heapspace 4325
#
library	geos
library	ui
#
resource AppResource ui-object
resource Interface ui-object
resource DocumentUI object
#
# Exported entry points. To allow the relocation of the DocumentUI resource
# to occur and be independent of insignificant (as far as the operation of
# the application is concerned) changes in the physical location of the
# DVDocumentClass class record, the relocation information for the
# GenDocumentGroup object specifies the class to use for document objects
# as an exported routine number for this application. Entry point numbers
# change far less frequently, and only for much greater cause, than the
# offsets of variables and routines.
#
export DVDocumentClass
