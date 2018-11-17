#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Parser
# FILE:		parse.tcl
# AUTHOR:	John Wedgwood,  February  8th, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 2/ 8/91	Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to assist in debugging name lists
#
#	$Id: names.tcl,v 1.1 97/04/05 01:27:04 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[load pseutils.tcl]

[defcommand name-list {{address es:0}} parser
{Print out a name-list whose base is at a passed address}
{
    var addr [addr-parse $address]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    
    var nameCount [value fetch $seg:$off.NH_nameCount]
    var nextToken [value fetch $seg:$off.NH_nextToken]
    var blockSize [value fetch $seg:$off.NH_blockSize]
    var s s
    if {$nameCount == 1} {
    	var s {}
    }
    echo [format {NameList: %d name%s, next token is %d, blocksize is %d}
    	    	    $nameCount $s $nextToken $blockSize]

    var off [expr $off+[type size [sym find type NameHeader]]]

    while {$nameCount} {
    	var token [value fetch $seg:$off.NS_token]
    	var length [value fetch $seg:$off.NS_length]

	var off [expr $off+[type size [sym find type NameStruct]]]

	echo [format {Token 0x%04x -- %s} $token
	    	    [printString $seg $off [expr $length+2]]]
	
	var off [expr $off+$length]

    	var nameCount [expr $nameCount-1]
    }
