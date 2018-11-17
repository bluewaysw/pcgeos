##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	LWPref
# FILE:		lwpref.gp
#
# AUTHOR:	jdashe, 5/27/93
#
#
# Parameters file for: lwpref.geo
#
#	$Id: lwpref.gp,v 1.1 97/04/04 16:49:27 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name lwpref.app

#
# Long name
#
longname "Last Words Options"

#
# Desktop-related definitions
#
tokenchars "PREF"
tokenid 0

#
# Specify geode type
#
type    library, single, c-api

#
# Import library routine definitions
#
library geos
library ui
library config
library saver
library text
library color
library ansic

#
# Define resources other than standard discardable code
#
resource LWPREFUIRESOURCE           object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

# This routine returns an optr to the root UI object, and has no args.
export LWPrefGetPrefUITree

# Exported classes

export LWPrefInteractionClass
