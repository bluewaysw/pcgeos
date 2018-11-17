##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:
# FILE:         letterpref.gp
#
# AUTHOR:       Jeremy Dashe, April 18, 1993
#
# Parameters file for: ltrpref.geo
#
#       $Id: letterpref.gp,v 1.1 97/04/04 16:45:25 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name ltrpref.lib

#
# Long name
#
longname "Typographer's Nightmare Options"

#
# Desktop-related definitions
#
tokenchars "PREF"
tokenid 0

#
# Specify geode type
#
type    library, single

#
# Import library routine definitions
#
library geos
library ui
library config
library saver

#
# Define resources other than standard discardable code
#
resource LetterPrefUIResource           object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export LetterPrefGetPrefUITree

# Exported classes

export LetterPrefInteractionClass
