#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library - GeoDex tcl commands
# FILE:		geodex.tcl
# AUTHOR:	Greg Grisco, November 15, 1994
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pdex-dbr    	    	Print a geodex database record
#       pdex-pname
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	grisco	11/15/94       	Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to print out geodex stuff
#
#       pdex-dbr           Prints a DB_Record structure with phone numbers
#       pdex-plist         Prints the list of phone number type names
#
#	$Id: geodex.tcl,v 1.1.10.1 97/03/29 11:27:49 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[defcommand pdex-dbr {address} print
{Usage:
    pdex-dbr [<flags>] [<address>]

Examples:
    "pdex-dbr"	    	    Print the database record at es:si
    "pdex-dbr es:di"        Print the database record at es:di

Synopsis:
    Print formatted info contained in the rolodex DB_Record

    Example:
    --------

    Index:   Smith, Joe
    Address: Joe Smith\r123 Park St.\rAlameda, CA
    Phone #s:    Type       Number
                 ----       ------
                   1        "(510) 555-1212"
                   7        "(510) 814-5700"
                   3    
                   4        "(510) 814-4250"
                   8        "(310) 555-1028"

}
{

    global dbcs

#    print DB_Record $address

    echo
   
    addr-preprocess $address seg off
    var dbsize [size DB_Record]

    #print the Index field

    var indexSize [value fetch $seg:$off.DBR_indexSize]
    echo -n Index:\t\t
    if {$indexSize} {
	var indexOff [expr $off+$dbsize]
	pstring $seg:$indexOff
    } else {
	echo
    }

if {[null $dbcs]} {
} else {

    #print the Name field

    var phoneticSize [value fetch $seg:$off.DBR_phoneticSize]
    echo -n Name:\t\t
    if {$phoneticSize} {
	var phoneticOff [expr $off+[value fetch $seg:$off.DBR_toPhonetic]]
	pstring $seg:$phoneticOff
    } else {
	echo
    }

}

if {[null $dbcs]} {
} else {

    #print the ZipCode field
    
   var zipSize [value fetch $seg:$off.DBR_zipSize]
   echo -n ZipCode:\t
    if {$zipSize} {
	var zipOff [expr $off+[value fetch $seg:$off.DBR_toZip]]
	pstring $seg:$zipOff
    } else {
	echo
    }
}
    #print the Address field
    
    var addrSize [value fetch $seg:$off.DBR_addrSize]
    echo -n Address:\t
    if {$addrSize} {
	var addrOff [expr $off+[value fetch $seg:$off.DBR_toAddr]]
	pstring $seg:$addrOff
    } else {
	echo
    }

    #print the Phone fields

    var phonesLeft  [value fetch $seg:$off.DBR_noPhoneNo]
    var curPhoneOff [expr $off+[value fetch $seg:$off.DBR_toPhone]]
    echo
    echo Phone #s:\tType\tNumber
    echo \t\t----\t------
    while {$phonesLeft} {
	var phoneType [value fetch $seg:$curPhoneOff.PE_type]
	var phoneLength [value fetch $seg:$curPhoneOff.PE_length]
	if {[null $dbcs]} {
	} else {
	     var phoneLength [expr $phoneLength*2]
        }

	echo -n \t\t $phoneType \t
	var curPhoneOff [expr $curPhoneOff+[size PhoneEntry]]
	if {$phoneLength} {
	    pstring $seg:$curPhoneOff
	    var curPhoneOff [expr $curPhoneOff+$phoneLength]
	} else {
	    echo
	}
	var phonesLeft [expr $phonesLeft-1]
    }

}]


[defcommand pdex-plist {address phonesToPrint} print
{Usage:
    pdex-plist [<flags>] [<address>] [<phonesToPrint>]

Examples:
    "pdex-plist es:di"      Print the phone name string as es:di
    "pdex-plist es:di 10"   Print the first 10 phone name strings

Synopsis:
    Print the rolodex phone name strings from the index table

    Example:
    --------
    0     "SOMETHING"
    1     
    2     "HOME"
    3     "OFFICE"
    4     "CAR"
    5     "FAX"
    6     "OTHER"
    7     "BATH"
    8     "OFFICE 2"
}
{

    global dbcs

    echo
   
    addr-preprocess $address seg off
    var curPhoneNum 0
    var oldOff $off

    echo #\tPhone Name
    echo -\t----------

    while {$phonesToPrint} {
	var stringOffset [value fetch $seg:$off word]
	var stringAddr [expr $stringOffset+$oldOff]
	if {$stringOffset} {
	    if {$curPhoneNum} {
	       echo -n $curPhoneNum \t
	       pstring $seg:$stringAddr
	    }
	    var off [expr $off+2]
	    var curPhoneNum [expr $curPhoneNum+1]
	    var phonesToPrint [expr $phonesToPrint-1]
	} else {
	    var phonesToPrint 0
	}
    }

    echo
}]
