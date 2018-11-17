##############################################################################
#
# 	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- GeoPlanner (Calendar) application
# FILE: 	geoplanner.tcl
# AUTHOR: 	Simon Auyeung, Feb 17, 1997
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	pdbevent		Print information about an event in a dbase
#				item of database 
#
#	pidarray		Print out the elements of event ID array
#
#	trackSMS		Print the received/sent SMS text as it reaches/
#				leaves calendar
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	simon   	2/17/97   	Initial Revision
#	simon		2/18/97		Added pidarray. pdbevent also prints
#					event text 
#
# DESCRIPTION:
#	Routines for GeoPlanner(Calendar) application.
#	
#
#	$Id: geoplanner.tcl,v 1.5 97/04/21 19:13:56 kho Exp $
#
###############################################################################

##############################################################################
#		pdbevent
##############################################################################
#
# SYNOPSIS:	Print information about an event in a dbase item of database
# PASS:		group = db group to look up
#               item  = db item to look up
# CALLED BY:	User
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon   2/17/97   	Initial Revision
#	simon	2/18/97		Also prints event text
#       simon   2/27/97         Also prints out repeat event
#       simon   3/ 7/97         Specify patient "geoplann" when
#                               displaying text field of struct
#
##############################################################################
[defcommand    pdbevent {group item} lib_app_driver.geoplanner
{Usage:
    pdbevent <group> <item>
     
Examples:
    "pdbevent ax di"	Print the event in database at Group:Item AX:DI
    "pdbevent d4h 18h"	Print the event in database at Group:Item D4h:18h

Synopsis:
    Print information about an event in a dbase item of GeoPlanner 
    (Calendar) database. 

Notes:
    * dgroup:[vmFile] has to be open and contains valid VM file handle.

See also:
    print-db-item, print-db-group
}
{
    require map-db-item-to-addr db.tcl

    #
    # Get numeric values of arguments
    #
    var group     [getvalue $group]
    var item      [getvalue $item]
    var file      [value fetch geoplann::vmFile] 

    #
    # Get memory address of item
    #
    var itemInfo  [map-db-item-to-addr $file $group $item]
    var itemHan   [index $itemInfo 1]       
    var itemChunk [index $itemInfo 3]       

    #
    # Print out EventStruct information
    #
    echo [format 
	  {Event:\tGroup:Item = %04xh:%04xh {^l%04xh:%04xh}}
	  $group,
	  $item,
	  $itemHan,
	  $itemChunk]

    #
    # Normal events and repeat events have different structures. So,
    # we want to display them differently.
    #
    # Since repeat events are in the same group, we can check DB group
    # against it.  
    #
    if {$group == [getvalue geoplann::repeatMapGroup]} {

	#
	# Repeat event
	#
	echo {************ Repeat Event *************}
	print geoplann::RepeatStruct ^l$itemHan:$itemChunk

	#
	# Display event text
	#
	echo -n {Event text: }
	pstring (^l$itemHan:$itemChunk).geoplann::RES_data
    } else {

	#
	# Normal event
	#
	echo {>>>>>>>>>>>> Normal Event <<<<<<<<<<<<<<}
	print geoplann::EventStruct ^l$itemHan:$itemChunk

	#
	# Display event text
	#
	echo -n {Event text: }
	pstring (^l$itemHan:$itemChunk).geoplann::ES_data
    }
}]

##############################################################################
#		pidarray
##############################################################################
#
# SYNOPSIS:	Print out the elements of event ID array
# PASS:		VM block handle of event ID array
# CALLED BY:	User
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       simon    	2/18/97   	Initial Revision
#
##############################################################################
[defcommand    pidarray {arrayHan} lib_app_driver.geoplanner
{Usage:
    pidarray <event ID array handle>
     
Examples:
    "pidarray 74h"		Print out the event ID array elements in VM
				Block handle 74h 

Synopsis:
    Print out the elements of event ID array of GeoPlanner (Calendar) appl.

Notes:
    It sometimes prints nothing where there are ID array entries
    because some huge array directory or data blocks are not residents.

See also:
    pharray
}
{
    pharray -e -tgeoplann::EventIDArrayElemStruct geoplann::vmFile $arrayHan
}]


##############################################################################
#				pstring2
##############################################################################
#
# SYNOPSIS:	print a null-terminated string from memory at the given addr
# PASS:		addr	= address of start of the string
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	The string is enclosed in double-quotes,
#               unless a second argument is defined.
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision
#       martin  11/10/92        added ability to "silence" pstring
#	dloft	11/10/92	Changed how carriage returns get printed
#       kho     11/12/96        Show carriage return as is.
#
##############################################################################
[defsubr pstring2 {args} {
    var silent 0
    global dbcs
    if {[null $dbcs]} {
    	var wide 1
    } else {
    	var wide 2
    }
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		s {var silent 1}
		w {var wide 2}
    	    	n {var wide 1}
    	    	l { 
    	    	    var maxlength [index $args 1]
    	    	    var args [range $args 1 end] 
    	    	}
		default {error [format {unknown option %s} $i]}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    var a [addr-parse $args]
    var s ^h[handle id [index $a 0]]
    var o [index $a 1]

    if {$wide == 1} {
    	if {!$silent} {
       	    echo -n "
    	}
    	[for {var c [value fetch $s:$o [type byte]]}
    	 {$c != 0}
    	 {var c [value fetch $s:$o [type byte]]}
    	{
	    # if we encounter CR, do a line break
            if {$c == 0dh} {
        	echo
            } elif {$c < 32 || $c > 127} {
        	echo -n {.}
            } else {
        	echo -n [format %c $c]
    	    }
            var o [expr $o+$wide]
    	    if {![null $maxlength]} {
    	    	var maxlength [expr $maxlength-1]
    	    	if {$maxlength == 0} break
    	    }
    	}]
    	if {!$silent} {
       	    echo "
    	}
    } else {
    	var qp 0
    	[for {var c [value fetch $s:$o [type word]]}
    	 {$c != 0}
    	 {var c [value fetch $s:$o [type word]]}
    	{
	    # if we encounter CR, echo "\r"
            if {$c == 0dh} {
    	    	if {!$silent && !$qp} {
    	    	    echo -n "
    	    	    var qp 1
    	    	}
        	echo -n \\r
            } elif {$c < 32 || $c > 127} {
    	    	if {!$silent && $qp} {
    	    	    echo -n {",}
    	    	    var qp 0
    	    	}
    	    	echo -n [format {%s,} [penum geos::Chars $c]]
            } else {
    	    	if {!$silent && !$qp} {
    	    	    echo -n "
    	    	    var qp 1
    	    	}
        	echo -n [format %c $c]
    	    }
            var o [expr $o+$wide]
    	    if {![null $maxlength]} {
    	    	var maxlength [expr $maxlength-1]
    	    	if {$maxlength == 0} break
    	    }
    	}]
    	if {!$silent && $qp} {
    	    echo -n "
    	}
    	echo {}
    }
}]

[defsubr printToMailboxText {} {
    echo [format {\nMessage sent to mailbox:}]
    echo [format {------------------------}]
    echo [format {Text size: %d bytes} [read-reg cx]]
    pstring2 es:2
}]

[defsubr printTextFromMailbox {} {
    echo [format {\nMessage received from mailbox:}]
    echo [format {------------------------------}]
    pstring2 ds:2
}]

##############################################################################
#				trackSMS
##############################################################################
#
# SYNOPSIS:	Print the received/sent SMS text as it reaches/leaves calendar.
# PASS:		nothing
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kho      	4/21/97   	Initial Revision
#	
##############################################################################
[defsubr    trackSMS {} {
    brk geoplann::CreateVersitTextIntoBlock::done {
	printToMailboxText
	expr 0
    }
    
    brk geoplann::CreateMBAppointmentFromSMS {
	printTextFromMailbox
	expr 0
    }
    
    brk geoplann::CreateVersitReplyIntoBlock::quit {
	printToMailboxText
	expr 0
    }
    
    brk geoplann::CreateVersitUpdateIntoBlock::done {
	printToMailboxText
	expr 0
    }
}] 

