##############################################################################
#
#	Copyright (c) Geoworks 1990 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	MultView (Sample GEOS application)
# FILE:		multview.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "MultView" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: multview.gp,v 1.1 97/04/04 16:36:37 newdeal Exp $
#
##############################################################################
#
name multview.app
#
longname "C MultView"
#
type	appl, process
#
class	MVProcessClass
#
appobj	MVApp
#
tokenchars "SAMP"
tokenid 8
#
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 4643
#
library	geos
library	ui
#
# Mark the DISPLAYUI resource as shared and read-only so its handle will be
# shared between instances of this application. The resource will never come
# into memory as itself, but always as a copy of itself, so it can safely be
# shared.
#
resource DISPLAYUI object shared read-only
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
#
#
# Exported entry points. To allow the relocation of the DOCUMENTUI resource
# to occur and be independent of insignificant (as far as the operation of
# the application is concerned) changes in the physical location of the
# DVDocumentClass class record, the relocation information for the
# GenDocumentGroup object specifies the class to use for document objects
# as an exported routine number for this application. Entry point numbers
# change far less frequently, and only for much greater cause, than the
# offsets of variables and routines.
#
export MVDocumentClass
