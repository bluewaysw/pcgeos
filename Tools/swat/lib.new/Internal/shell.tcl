##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	shell.tcl
# AUTHOR: 	Martin Turon, Nov 11, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/11/92   	Initial version
#
# DESCRIPTION:
#	Routines to aid debugging the Shell Library.
#
#	$Id: shell.tcl,v 1.1.30.1 97/03/29 11:25:16 canavese Exp $
#
###############################################################################


##############################################################################
#			shell::DIRINFO_FILE_NOT_SORTED
##############################################################################
#
# SYNOPSIS:	Prints out the file that is out of place.
#
# CALLED BY:	
#
# PASS:		
# RETURN:	
#
# SIDE EFFECTS:	
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/11/92   	Initial version
#
##############################################################################
[defsubr    shell::DIRINFO_FILE_NOT_SORTED {} {
    pstring ds:di
}]



##############################################################################
#				monitor-dirinfo
##############################################################################
#
# SYNOPSIS:	
#
# CALLED BY:	Utility
#
# PASS:		nothing
# RETURN:	nothing
#
# SIDE EFFECTS:	
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/11/92   	Initial version
#
##############################################################################
[defsubr    monitor-dirinfo {} 
{

	[brk shell::ShellOpenDirInfo::oldDirInfo 
 	  {print-and-continue {DIRINFO: old protocol number}}]


}]

[defsubr print-and-continue {message} {
	echo $message
	return 0
}]






