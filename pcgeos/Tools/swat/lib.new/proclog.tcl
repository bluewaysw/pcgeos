##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	pcgeos
# MODULE:	
# FILE: 	log.tcl
# AUTHOR: 	Ian Porteous, Oct 12, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	IP	10/12/94   	Initial Revision
#
# DESCRIPTION:
#	Tcl routines to work with the profiling log, when the log contains
#       entries that can be treated as the beggining and end of routines.
#
#	$Id: proclog.tcl,v 1.2.10.1 97/03/29 11:27:40 canavese Exp $
#
###############################################################################

##############################################################################
#	format-procedures
##############################################################################
#
# SYNOPSIS:	Print the log out, formatting it as if it was a log of paired 
#               entries, marking the beg and end of routines.
#
# PASS:		The address in the log to start at.
# CALLED BY:	global
# RETURN:	nothing
# SIDE EFFECTS:	
#       modified
#           entryStack
# STRATEGY:
#         
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr    format-procedures {args} {
     global entryStack inThread leaveThreadTime totalOutTime locationList
     
     var inThread TRUE leaveThreadTime 0 totalOutTime 0

     var startAddress [index $args 0]
     var thread [index $args 1]
     for {var address $startAddress i 0} {1} {var i [expr $i+1]} {
	# if {[expr $i%20] == 0} {
	#     echo -n .
	#     flush-output
	# }
	var entry [get-entry $address]

	if {$entry == 0} {
	    break
	}
	var oldAddress $address
	var address [expr $address+[index $entry 0]]
	
	var entryType [get-entry-type $entry]
	
	var entryBody [index $entry 1]

	var threadHandle [get-thread $entry]

	var beg [get-entry-beg-end $entry]
	
	if {[null $thread] || [expr $threadHandle==$thread]} {
	    [case $entryType in
	     {PET_GENERIC PET_HEAP PET_LMEM PET_PROC_CALL} {
		 if {$beg == 1} {
		     handle-beg $entry $address $oldAddress
		 } else {
		     handle-end $entry $oldAddress
		 }
	     }
	     {PET_THREAD_SWITCH} {
#		 echo thread switch @$oldAddress
	      }]
	} elif {$entryType == PET_THREAD_SWITCH} {
	    handle-switch $thread $entryBody 
	}
    }
     
 }]

##############################################################################
#	get-proc-name
##############################################################################
#
# SYNOPSIS:	takes an entry and get the symbol closest to PGE_address.
#               Depending on what type of entry it is, the PGE_address field
#               is interpreted differently.  
#               if it id a PET_PROC_CALL entry the address is treated as 
#               handle:offset.  Otherwise, it is treated as a fptr.
# PASS:		entry triple {size entry type}
# CALLED BY:	utility
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/18/94   	Initial Revision
#
##############################################################################
[defsubr    get-proc-name {entry} {
    var entryType [get-entry-type $entry]
    [case $entryType in
     {PET_GENERIC PET_HEAP PET_LMEM} {
	 var addr [get-entry-addr $entry]	 
	 var addr [expr [expr $addr>>16]&0xffff]:[expr $addr&0xffff]
     }
     {PET_PROC_CALL} {
	 var addr [get-entry-addr $entry]	 
	 var addr ^h[expr [expr $addr>>16]&0xffff]:[expr $addr&0xffff]
     }
    ]
    var name [sym name [sym faddr any $addr]]
    return $name
}]

##############################################################################
#	proclog-init
##############################################################################
#
# SYNOPSIS:	Initialize global variable for proclog
# PASS:		nothing
# CALLED BY:	global
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/17/94   	Initial Revision
#
##############################################################################
[defsubr    proclog-init {} {
    global locTimeTable locCountTable entryStack indent
    
    var entryStack {}
    var indent 0
    var locCountTable [table create 1000]
    var locTimeTable [table create 1000]
}]

##############################################################################
#	proc-log-summary
##############################################################################
#
# SYNOPSIS:	print out the tables containing the statistics gathered from 
#               format procedures.  The tables printed out are.
#               locTimeTable:
#                  contains the sum of time spent in a particular routine for 
#                  all invocations of that routine.  If a routine is recursive,
#                  the time reported may not indicate what you expect.  The 
#                  time is calculated, from when the routine was entered, till 
#                  the routine is exited.  Therefore in the case of a recursive
#                  routine:
#                 
#                  foo
#                       foo
#                       foo time:1
#                  foo time:2
#                 
#                  the total time reported for foo will be 3 instead of 2
#
#                locCountTable
#                   contains a count of the number of times each routine is 
#                   called
#
# PASS:		nothing
# CALLED BY:	global
# RETURN:	nothing
# SIDE EFFECTS:	none
#              
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/17/94   	Initial Revision
#
##############################################################################
[defsubr    proc-log-summary {} {
    global locTimeTable locCountTable
    
    echo
    echo Time spent in each section:
    echo ---------------------------------------------------------------------
    table foreach $locTimeTable table-print-time
    echo 
    echo Number of times each section executed:
    echo ---------------------------------------------------------------------
    table foreach $locCountTable table-print-count
    echo
}]

[defsubr    table-print-time {args} {
    global locTimeTable
    echo [index $args 1] [table lookup [index $args 0] [index $args 1]]
    return 0
}]

[defsubr    table-print-count {args} {
    global locCountTable

    echo [index $args 1] [table lookup [index $args 0] [index $args 1]]
    return 0
}]  

##############################################################################
#	handle-beg
##############################################################################
#
# SYNOPSIS:	Handle a routine start label.
# PASS:		entry triple, address of the entry, address of this entry
# CALLED BY:	format-procedures
# RETURN:	nothing
# SIDE EFFECTS:	
#       global variables updated:
#           indent, locTimeTable, locCountTable
# STRATEGY:
#       Push the total time spent outside of this thread so far
#       Push this entry onto the stack.
#       If an entry in locTimeTable and locCountTable does not yet exist 
#           for this routine, add entries.
#       Print out the entry
#       Increase the indent amount.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr    handle-beg {entry address oldAddress} {
         global indent totalOutTime indentStep locTimeTable locCountTable

     pushLogStack $totalOutTime
     pushLogStack $entry

     var space [format {%*s} $indent {}]
     var procName [get-proc-name $entry]

     var i [table lookup $locTimeTable $procName]
     if {[null $i]} {
	 table enter $locTimeTable $procName 0
	 table enter $locCountTable $procName 0
     } 
     echo $space $procName @$oldAddress
     var indent [expr $indent+$indentStep]

}]

##############################################################################
#	handle-end
##############################################################################
#
# SYNOPSIS:	handle a routine end label
# PASS:		entry-triple, address of this entry
# CALLED BY:	format-procedures
# RETURN:	nothing
# SIDE EFFECTS:	none
#       modifies:
#           indent, locTimeTable, locCountTable
# STRATEGY:
#       pop the start entry matching this end entry off of the entryStack
#       pop totalTimeOut off the entryStack
#       decrement the indentation
#       calculate the difference in time from the start entry to the end entry
#       update locTimeTable and locCountTable
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/23/94   	Initial Revision
#
##############################################################################
[defsubr handle-end {entry oldAddress} {
     global indent totalOutTime indentStep locTimeTable locCountTable
     global geosTimerValue

     var matchEntry [popLogStack]
     
     if {$matchEntry == {}} {
	 echo entry stack empty ? @$oldAddress
	 return
     }
     var indent [expr $indent-$indentStep]

     #
     # get the total time that had been spent outside of this thread when this 
     # was called.  Then subtract it from the current total time that has been 
     # spent outside of this thread.  This will give you the amount of time 
     # that was spent outside of this thread during this procedure
     #
     var timeAway [popLogStack]
     var timeAway [expr $totalOutTime-$timeAway]
     
     var space [format {%*s} $indent {}]
     var procName [get-proc-name $matchEntry]
     echo -n $space $procName time: 


     var timeStart [field [field [index $matchEntry 1] PGE_header] PLE_timeStamp ]
     var timeEnd [field [field [index $entry 1] PGE_header] PLE_timeStamp] 
     var timeBetween [time-difference $timeStart $timeEnd]

     var time [expr $timeBetween-$timeAway] 

     if {$time < 0} {
	 echo -n *
	 var time [expr $geosTimerValue+[expr $geosTimerValue+$time]]
     }
     echo $time @$oldAddress 

     #
     # now add the time spent in the routine for this call to the total time 
     # spent in this routine
     #
     var oldTime [table lookup $locTimeTable $procName]
     if {[null $oldTime]} {
	 error [list {could not find entry} $procName]
     } else {
	 #
	 # add the time to the table for this section
	 #
#	 echo $oldTime --- $time
	 var time [expr $time+$oldTime]
	 table enter $locTimeTable $procName $time
	 # 
	 # increment the count for this section in the table
	 #
	 var count [table lookup $locCountTable $procName]
	 table enter $locCountTable $procName [expr $count+1]
     }
     
}]

##############################################################################
#	get-entry-beg-end
##############################################################################
#
# SYNOPSIS:	get the bit indicating whether this is a beg or end entry.
# PASS:		an entry triple {size  log entry  type}
# CALLED BY:	utility
# RETURN:       beg/end
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr get-entry-beg-end {entry} {

    var type [symbol name [index $entry 2]] 

    [case $type in 
     {ProfileGenericEntry} {
	 var beg [field [field [field [index $entry 1] 
						 PGE_header] PLE_type] PLET_beg]
     }
     {ProfileMessageEntry} {
	 var beg [field [field [field [index $entry 1] 
						 PME_header] PLE_type] PLET_beg]
     }]
	
    return $beg
}]


##############################################################################
#	get-entry-addr
##############################################################################
#
# SYNOPSIS:	reutrn the address field of the entry
# PASS:		entry-triple
# CALLED BY:	utility
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr    get-entry-addr {entry} {
    var type [symbol name [index $entry 2]] 

    [case $type in 
     {ProfileGenericEntry} {
	 var beg [field [index $entry 1] PGE_address]
     }
     {ProfileMessageEntry} {
	 var beg [field [index $entry 1] PME_address]
     }]
	
    return $beg
}]


