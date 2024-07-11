##############################################################################
#
#       Copyright (c) 1997 New Deal, Inc -- All Rights Reserved
#
# PROJECT:      LEGOS
# MODULE:       filecomp
# FILE:         filecomp.gp
#
# AUTHOR:       Martin Turon, Nov. 17, 1997
#
#
#       $Id: file.gp,v 1.1 98/05/13 14:45:48 martin Exp $
#
##############################################################################
#
# Specifiy this library's permanent name, long name, 
# token charaters, and type
#
name 		coolfile.lib
longname        "File Component Object Library"
tokenchars      "CoOL"
type    	library, single
#
# Define library entry point
#
#entry  FileCompLibraryEntry

library ui
library ent
library geos
library shell
library basrun
library gadget

#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export FileLibraryClassTable
export FileComponentClass	
export FileBufferComponentClass	
export FileSelectorComponentClass

