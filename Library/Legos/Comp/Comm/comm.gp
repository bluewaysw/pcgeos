##############################################################################
#
#       Copyright (c) 1997 New Deal, Inc -- All Rights Reserved
#
# PROJECT:      LEGOS
# MODULE:       commcomp
# FILE:         commcomp.gp
#
# AUTHOR:       Martin Turon, Nov. 17, 1997
#
#
#       $Id: comm.gp,v 1.1 98/05/13 14:45:48 martin Exp $
#
##############################################################################
#
# Specifiy this library's permanent name, long name, 
# token charaters, and type
#
name            coolcomm.lib
longname        "CoOL Comm"
tokenchars      "CoOL"
type            library, single
#
# Define library entry point
#
#entry  CommCompLibraryEntry

library ui
library ent
library geos
library shell
library basrun
library streamc

#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export CommLibraryClassTable
export SerialComponentClass       

