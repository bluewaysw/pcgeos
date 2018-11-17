##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Library/StreamC
# FILE:		streamC.gp
#
# AUTHOR:	John D. Mitchell, 93.07.08
#
# Parameters file:	streamc.geo
#
#	$Id: streamc.gp,v 1.1 97/04/07 11:15:11 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name streamc.app
#
# Long name
#
longname "C Stream Driver Library"
#
# Desktop-related definitions
#
tokenchars "CSDL"
tokenid 0
#
# Specify geode type
#
type	library, single, discardable-dgroup
#
# Library entry point
#
entry	StreamCEntry

#
# Import library routine definitions
#
library	geos
library	ui
#
# Define resources other than standard discardable code
#
resource	StreamResident	fixed code shared read-only
#
# Export routines:
#
export	DRIVERCALLENTRYPOINT

export	STREAMGETDEVICEMAP
export	STREAMOPEN
export	STREAMCLOSE
export	STREAMSETNOTIFY
export	STREAMGETERROR
export	STREAMSETERROR
export	STREAMFLUSH
export	STREAMSETTHRESHOLD
export	STREAMREAD
export	STREAMREADBYTE
export	STREAMWRITE
export	STREAMWRITEBYTE
export	STREAMQUERY
export	STREAMESCLOADOPTIONS

export	STREAMGETDEVICEMAP as SERIALGETDEVICEMAP
export	SERIALOPEN
export	SERIALCLOSE
export	SERIALSETNOTIFY
export	STREAMGETERROR as SERIALGETERROR
export	STREAMSETERROR as SERIALSETERROR
export	SERIALFLUSH
export	STREAMSETTHRESHOLD as SERIALSETTHRESHOLD
export	STREAMREAD as SERIALREAD
export	STREAMREADBYTE as SERIALREADBYTE
export	STREAMWRITE as SERIALWRITE
export	STREAMWRITEBYTE as SERIALWRITEBYTE
export	STREAMQUERY as SERIALQUERY
export	STREAMESCLOADOPTIONS as SERIALESCLOADOPTIONS
export	SERIALSETFORMAT
export	SERIALGETFORMAT
export	SERIALSETMODEM
export	SERIALGETMODEM
export	SERIALOPENFORDRIVER
export	SERIALSETFLOWCONTROL
export	SERIALDEFINEPORT
export	SERIALSTATPORT
export	SERIALCLOSEWITHOUTRESET

incminor

export	STREAMSETMESSAGENOTIFY
export	STREAMSETNONOTIFY
export	SERIALLOADDRIVER
export	STREAMSETROUTINENOTIFY
export	STREAMSETDATAROUTINENOTIFY

export	PARALLELLOADDRIVER
export	PARALLELOPEN
export	PARALLELMASKERROR
export	PARALLELQUERY
export	PARALLELTIMEOUT
export	PARALLELRESTART
export	PARALLELVERIFY
export	PARALLELSETINTERRUPT
export	PARALLELSTATPORT

incminor

export	SERIALSETROLE
