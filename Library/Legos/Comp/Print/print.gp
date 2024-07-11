##############################################################################
#
#       Copyright (c) 1997 New Deal, Inc -- All Rights Reserved
#
# PROJECT:      NewBASIC
# MODULE:       print
# FILE:         print.gp
#
# AUTHOR:       Martin Turon, June 2, 1998
#
#
#       $Id: print.gp,v 1.1 98/07/12 05:02:59 martin Exp $
#
##############################################################################
#
# Specifiy this library's permanent name, long name, 
# token charaters, and type
#
name 		coolprint.lib
longname        "Print Component Object Library"
tokenchars      "CoOL"
type    	library, single

library ui
library geos
library spool
library ent
library basrun
library gadget


#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export PrintLibraryClassTable
export PrintControlComponentClass

