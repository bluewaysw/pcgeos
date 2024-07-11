##############################################################################
#
#       Copyright (c) 1998 New Deal, Inc -- All Rights Reserved
#
# PROJECT:      LEGOS
# MODULE:       Component Object Library -- Net
# FILE:         coolnet.gp
#
# AUTHOR:       Martin Turon, Apr. 22, 1998
#
#
#       $Id: net.gp,v 1.1 98/05/13 15:07:17 martin Exp $
#
##############################################################################
#
# Specifiy this library's permanent name, long name, 
# token charaters, and type
#
name 		coolnet.lib
longname        "Network Components Library"
tokenchars      "CoOL"
type    	library, single
#
# Define library entry point
#
#entry  FileCompLibraryEntry

library geos
library telnet
library basrun
library ent
library gadget
library shell

#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export CoolNetLibraryClassTable
export TelnetComponentClass	



