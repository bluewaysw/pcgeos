##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	Gopher Client
# MODULE:	Sample Library -- Gopher Library
# FILE:		gopher.gp
#
# AUTHOR:	Alvin Cham, Aug  9, 1994
#
# DESCRIPTION:
#	geode parameters file for gopher library
#
#	$Id: gopher.gp,v 1.1 97/04/04 18:04:51 newdeal Exp $
#
##############################################################################
#

#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name gopher.lib

#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname	"Gopher Library"
tokenchars	"GOFR"
tokenid		0

#
# Specify geode type: is a library
#
type	library, single

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ui
library ansic
library streamc
library socket

# this resource holds the gopher object data
resource	GOPHERSERIALCONSTANTDATA	shared, lmem, read-only
resource	GOPHERSOCKETCONSTANTDATA	shared, lmem, read-only

#
# Export classes
#	These are the classes exported by the library
#
export GopherClass
export GopherSerialClass
export GopherSocketClass
export GopherSocketThreadClass

#
# Routines
#	These are the routines exported by the library	
#
export 	GopherCacheFileSetUp
export	GopherCacheFileEnd
export	GopherAllocBlockWithLock
export	GopherLookForNextLine
export	GopherCopyFileToBlock
export	GopherGetCachedFileLine
export	GopherLanguageMapToString
export	GopherCacheFileFound
