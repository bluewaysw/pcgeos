##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	disk.tcl
# FILE: 	disk.tcl
# AUTHOR: 	Adam de Boor, Apr 15, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/90		Initial Revision
#
# DESCRIPTION:
#	Functions to print out Disk-related variables
#
#	$Id: disk.tcl,v 1.5 91/07/07 22:00:20 chris Exp $
#
###############################################################################

##############################################################################
#				pdisks
##############################################################################
#
# SYNOPSIS:	Print out info on known disks in the system
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/90		Initial Revision
#
##############################################################################
[defsubr pdisks {}
{
    var numDisks [expr ([value fetch (*diskTblHan).DT_tblHdr.TH_nextAvail]-4)/2]
    
    var num 0
    echo { #  Drive  W  Serial #  Label            }
    echo {-----------------------------------------}
    foreach i [value fetch {word (*diskTblHan).DT_entries#$numDisks}] {
    	var idh [value fetch kdata:$i.HD_idHigh]
	var serial [value fetch kdata:$i.HD_idLow]
    	var nullSeen 0

    	echo [format {%2d    %c    %1s  %06xh   %s} $num
	    	    [expr [field $idh DIDH_DRIVE]+65]
		    [if [field $idh DIDH_WRITABLE] {concat W}]
		    [expr ([field $idh DIDH_ID_HIGH]<<16)|$serial]
		    [mapconcat c [value fetch kdata:$i.HD_volumeLabel] {
		    	if {[string c $c \\000] == 0} {
			    var nullSeen 1
    	    	    	}
			if {$nullSeen} {
			    var c { }
			}
			var c
    	    	    }]
    	    	]
    	var num [expr $num+1]
    }
}]
