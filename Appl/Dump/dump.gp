##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Screen Dump Utility
# FILE:		dump.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: dump.geo
#
#	$Id: dump.gp,v 1.1 97/04/04 15:36:48 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name dump.util
#
# Specify geode type
#
type	process, single, appl
#
# Specify class name and application object for process
#
class	DumpClass
appobj	DumpApp
#
# Import library routine definitions
#
library	geos
library ui
library spool
library giflib
library ijgjpeg
library ansic
#
# Desktop-related definitions
#
longname "Screen Dumper"
tokenchars "DUMP"
tokenid 0
#
# Heap Space requirement
#
heapspace 8000
#
#
# Special resource definitions
#
resource Resident	fixed, code, read-only
resource Interface	ui-object
resource Annotation	ui-object
resource Application	ui-object
resource Postscript	ui-object
resource TiffUI		ui-object
resource AppSCMonikerResource ui-object, read-only
resource AppSMMonikerResource ui-object, read-only
resource AppSCGAMonikerResource ui-object, read-only
resource Strings	read-only, lmem, shared
#
# Exported routines and object classes
#
export	DumpApplicationClass
