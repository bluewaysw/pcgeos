##############################################################################
#
#	Copyright (c) GlobalPC 1998.  All rights reserved.
#	GLOBALPC CONFIDENTIAL
#
# PROJECT:	Backup Restore Library
# FILE:		backrest.gp
#
# AUTHOR:	Edwin Yu, Nov 23, 1998
#
#
# HTML Converter.
#
#	$Id: $
#
##############################################################################
#
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name bckrst.lib

#
# Long filename: this name can be displayed by GeoManager, and is used to 
# identify the application for inter-application communication.
#
longname        "Backup Restore Library"
tokenchars      "BKRT"
tokenid         0
#
#       Specify geode type
#
type            library, single
#
#       Libraries
#
library geos
library ui
library ansic
#library text

resource TEXTSTRINGS data

export BRCREATEBACKUPGROUP
export BRBACKUPSINGLEFILE
export BRBACKUPSYSTEMCONFIG
export BRBACKUPUSERDOC
export BRBACKUPSYSTEMCONFIGWITHID
export BRRECURSIVEBACKUPDIR
export BRRESTOREBACKUPGROUP
export BRLISTBACKUPGROUPS
export BRGETINFOONBACKUPGROUP
export BRVIEWBACKUPGROUP
export BRDELETEBACKUPGROUP
export BRGETINFOONUSERDOCDIR
export BRGETINFOONUSERMAILDIR
export BRGETINFOONUSERFAXDIR
export BRGETBACKUPDISKFREESPACE
