##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Lgihts Out
# FILE:		stringpref.gp
#
# AUTHOR:	Jim Guggemos, Sep 16, 1994
#
# Prefs module for string art screen saver
# 
#
#	$Id: stringpref.gp,v 1.1 97/04/04 16:49:20 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name stringpf.lib
#
# Long name
#
longname "String Art Options"
#
# Desktop-related definitions
#
tokenchars "PREF"
tokenid 0
#
# Specify geode type
#
type	library, single
#

# Import library routine definitions
#
library	geos
library	ui
library config
#
# Define resources other than standard discardable code
#
nosort
resource StringOptions	object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export StringPrefGetPrefUITree
export StringPrefGetModuleInfo


