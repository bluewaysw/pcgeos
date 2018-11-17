##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Compress
# FILE:		compress.gp
#
# AUTHOR:	dloft 4/92	
#
#
# 
#
#	$Id: compress.gp,v 1.1 97/04/04 17:49:04 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name compress.lib
#
# Long name
#
ifdef DO_DBCS
longname 	"PKware Lib"
else
longname 	"PKware Compression Library"
endif

tokenchars	"CMPL"
#
# Specify geode type
#
type	library, single
#
# Define library entry point
#
entry	CompressLibraryEntry

#
# Access symbols from kernel library
#
library	geos

#
# Define resources other than standard discardable code
#
nosort
resource PK_TEXT code fixed read-only
resource _TEXT code fixed read-only
resource CRC325_DATA fixed
resource CompressCode code read-only shared
#
# Exported routines (and classes)
#
export	COMPRESSDECOMPRESS
