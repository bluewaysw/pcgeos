##############################################################################
#
#	Copyright (c) Geoworks 1993 -- All Rights Reserved
#
# PROJECT:	GEOS SDK Sample Application	
# MODULE:	Benoit (Mandelbrot Set Sample Application)
# FILE:		benoit.gp
#
# AUTHOR:	Tom Lester, Aug  3, 1993
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       TL      8/3/93			Initial version
#		RainerB	8/11/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "Benoit" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
#	$Id: benoit.gp,v 1.1 97/04/04 16:39:40 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name benoit.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "C Benoit"
#
# Specify geode type: is an application, and will have its own process
# (thread).  By the way, it's multi-launchable...
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the GeoFileProcessClass, which is defined
# in geofile.asm.
#
class	BProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. 
#
appobj	BApp
#
# Token: this four-letter name is used by geoManager to locate the icon for 
# this application in the database.
#
tokenchars "SAMP"
tokenid 8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 6353
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library mset		# use the Mandelbrot Set Library
#
# Resources: list all resource blocks which are used by the application.
#
# Mark the DisplayUI resource as shared and read-only so its handle will be
# shared between instances of this application. The resource will never come
# into memory as itself, but always as a copy of itself, so it can safely be
# shared.
#
resource DisplayUI ui-object shared read-only
resource AppResource ui-object
resource DocumentUI object
resource Interface ui-object
resource BenoitErrorStrings	lmem discardable read-only shared

# this resource contains the MSet object template that is duplicated
# for each document
resource MSetTemplateResource object shared read-only

# these resources contain the icon monikers
resource BenoitSCMonikerResource lmem read-only shared
resource BenoitSMMonikerResource lmem read-only shared
resource BenoitYCMonikerResource lmem read-only shared
resource BenoitYMMonikerResource lmem read-only shared


#
#
# Exported entry points. To allow the relocation of the DocumentUI resource
# to occur and be independent of insignificant (as far as the operation of
# the application is concerned) changes in the physical location of the
# BDocumentClass class record, the relocation information for the
# GenDocumentGroup object specifies the class to use for document objects
# as an exported routine number for this application. Entry point numbers
# change far less frequently, and only for much greater cause, than the
# offsets of variables and routines.
#
export BDocumentClass
