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
#       Tcl routines to work with the profiling log
#	
#
#	$Id: log.tcl,v 1.3.4.1 97/03/29 11:28:02 canavese Exp $
#
###############################################################################

require format-procedures proclog

# log
#     command interface to the log functions
#
[defcommand log {args} {profile profile.utils}
{Usage:
     log init                              (Re)Initialize variables for examining 
                                           the profile. This must be done each 
                                           time swat attaches to the patient.

     log reset                             Reset the profile log.  This will 
                                           erase all of the log entries.  It 
                                           will also turn of logging for all of 
                                           the profiling modes.

     log start <mode>                      Start logging for one of the 
                                           profiling modes :
                                           PMF_MESSAGE
                                           PMF_GENERIC

     log end <mode>                        End logging for one of the 
                                           profiling modes :
                                           PMF_MESSAGE
                                           PMF_GENERIC
     
     log (format-messages|fm) <patient> <thread number> [<start address>]
                                           Print the messages out for a
                                           given thread, formatted in a 
                                           readble manner.

         format of the messages is:
         <field1>:<field2> @<field3> L:<field4>
         field1 = method used to send message
         field2 = message 
         field3 = address of entry. This address can be passed to log print 
         field4 = address of entry where message was finally proccessed 
                  in ObjCallMethodTable. This address can be passed to log print. 

     log (format-procedures|fp) [<start address>] [<patient> <thread number>]
                                           Print out the procedure calls.  
                                           If no patient is specified, then 
                                           for all patients. If no address is
                                           specified, then starts at address 0

     log print <address>                   Print the entry at address

     log flush                             Flush the profiling cache
     
     log Summary <msg|proc>                Generate a summary of the time spent in 
                                           each procedure and a count of 
                                           how many times each procedure was 
                                           called.
 Synopsis:
     
     Various commands to access the profiling log, and to print out the 
     profiling log.

 Examples:
     
     log fm geos 0            Print out message tree for patient geos thread 0.
     
     log fm geos 0 128        Print out message tree for patient geos thread 0
                              starting at address 128 in the log.

     log print 128            Print out the log entry at address 128 in the profiling
                              log.

     log fp                   print out all of the procedure calls for all of the threads 
                              in the log.

     log summary proc         print out a summary of time spent in each procedure and 
                              how many times each procedure was called.

 Notes:

     The summary printed out by "log summary (proc|msg)" is created when the 
     log is printed out during "log fm ..." or "log fp ...".  Therefore one of these
     commands must be executed before a log summary command.

     Also the symmary printed out by "log summary (proc|msg)" is cummulative, so you
     will want to do a log init between each "log fp.." or "log fm..." command if 
     you plan to use log summary.

 }
 {
     global pet_list

     [case  [index $args 0] in
      {flush} {
	  flush-profile-cache
      }
      {init} {
	  log-init
	  proclog-init
      }     
      {reset} {
	  reset-profile-cache
	  log-init
      }     
      {summary} {
	  if {[index $args 1] == msg} {
	      msg-log-summary
	  } else {
	      proc-log-summary
	  }
      }
      {start} {
	  #
	  # first check to see if things are initialized, if they are not then
	  # initialize things.
	  #
	  if {$pet_list == {}} {
	      log-init
	  } elif {[symbol name [index $pet_list 0]] == {}} {
	      log-init
	  }
	  #
	  # check to make sure that they passed us a profiling mode
	  #
	  if {[length $args] < 2} {
	      echo Need to pass a profiling mode
	  } else {
	      set-profile-mode [index $args 1]
	  }
      }
      {end} {
	  if {[length $args] < 2} {
	      echo Need to pass a profiling mode
	  } else {
	      clear-profile-mode [index $args 1]
	  }
      }
      {print} {
	  var entry [get-entry [index $args 1]]
	  if {$entry != 0} {
	      print-entry $entry
	  }
      }
      {format-messages fm} {
	  # 
	  # do we have enough arguments to work with
	  #
	  if {[length $args] < 3} {
	      echo Usage: log format-messages/fm <patient> <thread number> [<start address>]
	      break
	  }
	  # 
	  # get the thread that we are looking for
	  #
	  var patient [index $args 1]
	  var threadNum [index $args 2]
	  var oldPatient [index [patient data] 0]
	  var oldThreadNum [index [patient data] 2]
	  
	  var threads [patient threads [patient find $patient]]
	  var thread [index $threads $threadNum]
	  if {$thread == {}} {
	      echo Don't understand $patient:$threadNum
	  } else {
	      switch $patient:$threadNum
	      var thread [handle id [thread handle $thread]]
	  }
	  #
	  # get the start address if there is one
	  #
	  if {[length $args] >= 4} {
	      var startAddress [index $args 3]
	  } else {
	      var startAddress 0
	  }
	  if {$thread == 0} {
	      var thread 198
	  }
	  format-messages $startAddress $thread
	  switch $oldPatient:$oldThreadNum
      }
      {format-procedures fp} {
	  # 
	  # do we have enough arguments to work with
	  #
	  if {[length $args] < 1} {
	      echo Usage: log format-procedures|fp [<start address>] [<patient> <thread number>]
	      break
	  }
	  # 
	  # get the thread that we are looking for
	  #
	  var thread {}
	  if {[expr [length $args]==3] || [expr [length $args]==4]} {
	      var i [expr [length $args]-2]
	      var patient [index $args $i]
	      var threadNum [index $args [expr $i+1]]
	      var oldPatient [index [patient data] 0]
	      var oldThreadNum [index [patient data] 2]
	      
	      var threads [patient threads [patient find $patient]]
	      var thread [index $threads $threadNum]
	      if {$thread == {}} {
		  echo Don't understand $patient:$threadNum
	      } else {
		  switch $patient:$threadNum
		  var thread [handle id [thread handle $thread]]
	      }
	  }
	  #
	  # get the start address if there is one
	  #
	  if {[expr [length $args]==2] || [expr [length $args]==4]} {
	      var startAddress [index $args 1]
	  } else {
	      var startAddress 0
	  }
	  if {$thread == 0} {
	      var thread 198
	  }
	  format-procedures $startAddress $thread
	  switch $oldPatient:$oldThreadNum
      }
      default {
	  echo do not recognize [index $args 0]
	  error .
      }
     ]
 }]

##############################################################################
#	log-init
##############################################################################
#
# SYNOPSIS:	initialize variable used by for profiling
# PASS:		nothing
# CALLED BY:	log
# RETURN:	nothing
# SIDE EFFECTS:	none
#     initializes global variables
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/ 3/94   	Initial Revision
#
##############################################################################
[defsubr log-init {}
 {
     global pet_list pet_size_list xmsArgsType xmsProcOffset entryStack indent
     global inThread timeAway totalOutTime indentStep msgCountTable 
     global geosTimerValue
     
     #
     # table containing the number of times each msg was called
     #
     var msgCountTable [table create 500]

     #
     # the amount indented for printing nested routines
     #
     var indentStep 3

     #
     # The value that the 8253 timer is set to in geos so that it counts down
     # 60 times per second.
     #
     var geosTimerValue [symbol get [symbol find const GEOS_TIMER_VALUE]]
     
     var inThread TRUE
     var timeAway 0
     var totalOutTime 0
     # keep track of the indentation for message formatting
     var indent 0
     
     # stack of entries, used for message formatting
     var entryStack {}
     
     #
     # pet_list contains a list of the structure types associated with 
     # each entry types.  The entry types are defined in profile.def.
     #
     var pet_list {}
     var pet_list [list 
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileMessageEntry]
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileGenericEntry]
		    [symbol find type ProfileGenericEntry]]


     var pet_size_list {}
     foreach el $pet_list {
	 var pet_size_list [concat $pet_size_list [type size $el]]
     }
     
     var xmsArgsType [type make pstruct 
		     size [type dword] 
		     sourceOffset [type dword] 
		     sourceHandle [type word]
		     procSegment [type word]
		     procOffset [type word]]

     gc register $xmsArgsType

    #
    # get the address of the xms routine in kdata
    #
    var xmsProcOffset [symbol get [symbol find var xmsAddr]]
    var xmsProcOffset [index $xmsProcOffset 0]


 }]


##############################################################################
#	msg-log-summary
##############################################################################
#
# SYNOPSIS:	print out the tables containing the statistics gathered from 
#               format messages.  The tables printed out are.
#
#               msgCountTable
#                   contains a count of the number of times each message was 
#                   was sent
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
[defsubr    msg-log-summary {} {
    global msgCountTable
    

    echo Number of times message was sent:
    echo ---------------------------------------------------------------------
    table foreach $msgCountTable table-print-count
    echo
}]

##############################################################################
#	create-address
##############################################################################
#
# SYNOPSIS:	takes a virtual address to an xms log entry and converts it to 
#               and address composed of the handle of the xms memory block and 
#               the offset in that block followed by the handle of the next xms 
#               memory block.
# 
# PASS:		linear address
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
[defsubr create-address {address}
 {
    #
    # get the size of xms pages
    #
    var xmsPageSize [symbol get [symbol find const XMS_PAGE_SIZE]]
    var xmsPageSize [expr $xmsPageSize*1024]
    #echo $xmsPageSize     

    #
    # calculate the offset into the xms page table of the page we are
    # intereseted in
    #
    var xmsPageTableEntry [expr $address/$xmsPageSize]
    #echo $xmsPageTableEntry
    #echo ca $xmsPageTableEntry

    #
    # look up the handle of the xms page in the xmsPageTable
    #
    var xmsHandle [value fetch geos::xmsPageTable+$xmsPageTableEntry]
    var xmsNextHandle [value fetch geos::xmsPageTable+$xmsPageTableEntry+2]
    #echo offset = $xmsHandle

    var xmsOffset [expr $address%$xmsPageSize]

    return [list $xmsHandle $xmsNextHandle $xmsOffset $xmsPageSize]   
}]

##############################################################################
#	flush-profile-cache
##############################################################################
#
# SYNOPSIS:	Flush the profile profileCache into xms memory
# PASS:		nothing
# CALLED BY:	log
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/15/94   	Initial Revision
#
##############################################################################
[defsubr flush-profile-cache {args}
 {
    var udata [handle segment [index [addr-parse geos::dgroup] 0]]
    var oldValue [value fetch ss:TPD_callVector]
    value store ss:TPD_callVector.segment 0xadeb
    var success [call-patient ProfileFlushCacheFar ds $udata]
    value store ss:TPD_callVector $oldValue
    return $success
}] 

##############################################################################
#	reset-profile-cache
##############################################################################
#
# SYNOPSIS:	Reset the profileCache and the associated cache parameters. 
#               can be called when you want to clear the profile log and
#               restart profiling without quiting the patient.
#
# PASS:		nothing
# CALLED BY:	log
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/15/94   	Initial Revision
#
##############################################################################
[defsubr reset-profile-cache {args}
 {
    var udata [handle segment [index [addr-parse geos::dgroup] 0]]
    var oldValue [value fetch ss:TPD_callVector]
    value store ss:TPD_callVector.segment 0xadeb
    var success [call-patient geos::ProfileReset ]
    value store ss:TPD_callVector $oldValue
    return $success
}] 

##############################################################################
#	set-profile-mode
##############################################################################
#
# SYNOPSIS:	set one of the flags in profileModeFlags.  If a flag is set, 
#               then entries of that mode will be logged.
# PASS:		the flag to be set.
# CALLED BY:	log
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/15/94   	Initial Revision
#
##############################################################################
[defsubr set-profile-mode {profileMode}
 {
     if {[size ProfileModeFlags] == [size byte]} {
	 var bits [value fetch geos::profileModeFlags byte]
	 var bits [expr $bits|[fieldmask $profileMode]]
	 value store geos::profileModeFlags $bits byte
     } else {
	 error {This code assume that ProfileModeFlags are 1 byte in size}
     }
 }]

##############################################################################
#	clear-profile-mode
##############################################################################
#
# SYNOPSIS:	set one of the flags in profileModeFlags.  If a flag is clear, 
#               then entries of that mode will not be logged.
# PASS:		the flag to be cleared .
# CALLED BY:	log
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/15/94   	Initial Revision
#
##############################################################################
[defsubr clear-profile-mode {profileMode}
 {
     if {[size ProfileModeFlags] == [size byte]} {
	 var bits [value fetch geos::profileModeFlags byte]
	 var bits [expr $bits&[expr ~[fieldmask $profileMode]]]
	 value store geos::profileModeFlags $bits byte
     } else {
	 error {This code assume that ProfileModeFlags are 1 byte in size}
     }
 }]


##############################################################################
#	format-messages
##############################################################################
#
# SYNOPSIS:	This routine scans through a log containing message entries 
#               and prints them out in a useful manner.
# PASS:		start address - the address at which to begin scanning the log
#               thread        - the thread of the messages to examine.
# CALLED BY:	log
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
[defsubr format-messages {startAddress thread}
 {
     global entryStack inThread leaveThreadTime totalOutTime
     
     var inThread TRUE leaveThreadTime 0 totalOutTime 0

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
#	 echo $address
	 var address [expr $address+[index $entry 0]]
	
	 var entryType [get-entry-type $entry]

	 var entryBody [index $entry 1]

	 var threadHandle [get-thread $entry]


	 if {$threadHandle == $thread} {
	     [case  $entryType in 
	      {PET_OBJMESSAGE PET_OCINL PET_OCINLES PET_OCCNL PET_OCSNL} {
		  handle-send $entry $address $oldAddress
	      }     
	      {PET_END_CALL} {
		  handle-ret $entry $oldAddress
	      }     
	      {PET_MSG_DISCARD} {
#		  handle-send $entry $address $oldAddress
	      }     
	     ]
	 } elif {$entryType == PET_THREAD_SWITCH} {
	     handle-switch $thread $entryBody 
	 }
     }	 
     
 }]

##############################################################################
#	handle-switch
##############################################################################
#
# SYNOPSIS:     takes an entry for a context switch and the thread that we
#               are looking at now, and calculates how much time is spent 
#               executing outside of thread
#
# PASS:		thread    - the thread we are tracking
#               entryBody - the context switch log entry
# CALLED BY:	format-messages ...
# RETURN:	nothing
# SIDE EFFECTS:	none
#       updates the global variables inThread, leaveThreadTime, totalOutTime
#
# STRATEGY:
#       if (before this entry in thread?) 
#          if (thread != thread we are switching to)
#             record the time we left thread
#       else
#          if (thread == thread we are switching to)
#             calculate the time we just spent outside of this thread by 
#             subtracting the time we recorded when we left this thread from 
#             the current time.  Add this result to the total time spent 
#             outside of this thread.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr handle-switch {thread entryBody} 
 {
     global inThread leaveThreadTime totalOutTime geosTimerValue
     
     if {$inThread == TRUE} {
	 if {$thread != [field $entryBody PGE_data]} {
	     var leaveThreadTime [field [field $entryBody PGE_header] PLE_timeStamp ]
	     var low [expr $leaveThreadTime&0x0000ffff]
	     var high [expr $leaveThreadTime>>16]
	     var low [expr $geosTimerValue-$low]
	     var leaveThreadTime [expr $low+[expr $high*$geosTimerValue]]
	     var inThread FALSE
	     # echo leave thread $leaveThreadTime
	 }
     } else {
	 if {$thread == [field $entryBody PGE_data]} {
	     var time [field [field $entryBody PGE_header] PLE_timeStamp ]
	     var low [expr $time&0x0000ffff]
	     var high [expr $time>>16]
	     var low [expr $geosTimerValue-$low]
	     var time [expr $low+[expr $high*$geosTimerValue]]
	     var totalOutTime [expr $totalOutTime+[expr $time-$leaveThreadTime]]
	     var inThread TRUE
	     # echo return to thread $totalOutTime
	 }
     }
	     
 }]

##############################################################################
#	handle-send
##############################################################################
#
# SYNOPSIS:	handles the printing of information for entries indicating 
#               that a message has been sent or called.
# PASS:		entry triple, address of the next entry, address of this entry
# CALLED BY:	format-messages
# RETURN:	nothing
# SIDE EFFECTS:	none
#    pushes the time and entry onto the entryStack
# STRATEGY:
#    
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr handle-send {entry address oldAddress}
 {
     global indent totalOutTime indentStep msgCountTable 

     pushLogStack $totalOutTime
     pushLogStack $entry

     var space [format {%*s} $indent {}]
     var class [find-class $entry $address]
     var linkAddress [index $class 1]
     var class [index $class 0]
     echo -n $space ([get-entry-type $entry] 
     var method [map-method [get-message-value $entry] $class]
     # 
     # if map-method returned a number instead of a human readable message name 
     # try map-method on the optr stored with this entry.  It is entirely possible 
     # the optr points to an object that has been deleted, but it is worth a try.
     #
     # It is possible that instead of an optr this entry contains the process to 
     # which the message was sent.  
     #
     if {[string m $method {[0-9]*}] == 1} {
	 var object [get-optr $entry]
         if {[catch {[map-method [get-message-value $entry]
	             ^l[expr $object>>16]:[expr $object&0xffff]]} newGuess] == 0} {
			 var method $newGuess
		     }
     }
     #
     # update msgCountTable for this Message
     #
     var count [table lookup $msgCountTable $method]
     if {[null $count]} {
	 var count 0
     } 
     table enter $msgCountTable $method [expr $count+1]


     echo :$method @$oldAddress L:$linkAddress
     var indent [expr $indent+$indentStep]


 }]

##############################################################################
#	find-class
##############################################################################
#
# SYNOPSIS:	finds the class for an entry
# PASS:		entry triple, address of next entry
# CALLED BY:	handle-send
# RETURN:	class of the object receiving this message.
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
[defsubr find-class {entry address} 
 {
     #
     # find the next occurence of 
     #
     var entryBody [index $entry 1]
     var thread [field $entryBody PME_thread]
     var class [get-class $address $thread]
     return $class
 }]

##############################################################################
#	get-class
##############################################################################
#
# SYNOPSIS:	starting from startAddress find the class of the object 
#               the las message was sent to
# PASS:		startAddress, thread to look on
# CALLED BY:	get-handle, find-class
# RETURN:	class of object message was sent to
# SIDE EFFECTS:	none
#
# STRATEGY:
#       Since we know that the last entry was for a message, the next entry on
#       this thread should be for either ObjCallMethodTable entry, or a SendEvent 
#       entry.
#   
#       If the next entry is an ObjCallMethodTable entry, then we can find the 
#       class of the entry.
#
#       If the next entry is a SendEvent entry, then get the handle of the 
#       message that was sent, and look for when that message was taken of the 
#       queue.
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/16/94   	Initial Revision
#
##############################################################################
[defsubr get-class {startAddress thread}
 {
     var firstTime 1
     for {var address $startAddress} {1} {} {
#	 echo get-class $address
	 var entry [get-entry $address]
	 if {$retVal == 0} {
	     return -1
	 }
	 var entryType [get-entry-type $entry]

	 var oldAddress $address
	 var address [expr $address+[index $entry 0]]

	 var entryBody [index $entry 1]
#	 echo $entryType 
	 [case  $entryType in 
	  {PET_SEND_EVENT} {
	      var threadHandle [field $entryBody PGE_thread]
#	      echo here i am $thread $threadHandle
	      if {$thread == $threadHandle} {
#		  echo found send event calling get-handle
		  return [get-handle $address [field $entryBody PGE_data]]
	      }
	  }     
	  {PET_OCMT} {
	      var threadHandle [field $entryBody PME_thread]
	      if {$thread == $threadHandle} {
		  var classPtr [field $entryBody PME_class]
		  var sym [symbol faddr var [expr [expr $classPtr>>16]&0xffff]:[expr $classPtr&0xffff]]
		  if {[null $sym]} {
		      var class MetaClass
		  } else {
		      var class [symbol fullname $sym with-patient] 
		  }
		  return [list $class $oldAddress]
	      }
	  }
	  {PET_END_CALL} {
	      if {$firstTime == 1} {
#		  echo Maybe bx=0 was passed to ObjMessage ?
		  return MetaClass
	      }
	  }]
	 var firstTime 0
     }	 
     
 }]

##############################################################################
#	get-handle
##############################################################################
#
# SYNOPSIS:	from StartAddress find the next message processed with handle.
#               Once you find it, get the class of the object that the message 
#               was sen to.
# PASS:		startAddress, handle of message to look for
# CALLED BY:	get-class
# RETURN:	class of object message was sent to 
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
[defsubr get-handle {startAddress handle}
 {


     for {var address $startAddress} {1} {} {
#	 echo get-handle $address
	 var entry [get-entry $address]
	 if {$retVal == 0} {
	     return -1
	 }
	 var address [expr $address+[index $entry 0]]

	 var entryType [get-entry-type $entry]

	 var entryBody [index $entry 1]

#	 echo get-handle entryType $entryType

	 if {$threadHandle == $thread} {
	     [case  $entryType in 
	      {PET_MP} {
		  var threadHandle [field $entryBody PGE_thread]
#		  echo found handle
		  return [get-class $address [field $entryBody PGE_thread]]
	      }     
	     ]
	 }
     }	 
     
 }]

##############################################################################
#	get-optr
##############################################################################
#
# SYNOPSIS:	get the optr from a message entry
# PASS:		entry triple with a ProfeMessageEntry type entry.
# CALLED BY:	utility
# RETURN:	the optr in the PME_data field
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
[defsubr get-optr {entry} {
    var ret [field [index $entry 1] PME_data]
    return $ret
}]

##############################################################################
#	get-entry-type
##############################################################################
#
# SYNOPSIS:	get the enumerated type for this entry. example: PET_OBJMESSAGE
# PASS:		an entry triple {size  log entry  type}
# CALLED BY:	utility
# RETURN:       the enumerated type for this entry. example: PET_OBJMESSAGE
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
[defsubr get-entry-type {entry} {

    var type [symbol name [index $entry 2]] 

    [case $type in 
     {ProfileGenericEntry} {
	 var entryType [type emap [field [field [field [index $entry 1] 
						 PGE_header] PLE_type] PLET_type] 
						 [symbol find type ProfileEntryType]]
     }
     {ProfileMessageEntry} {
	 var entryType [type emap [field [field [field [index $entry 1] 
						 PME_header] PLE_type] PLET_type] 
						 [symbol find type ProfileEntryType]]
     }]
	
    return $entryType
}]


##############################################################################
#	get-thread
##############################################################################
#
# SYNOPSIS:	get the thread that the this log entry was written on
# PASS:		entry triple {size entry entryType}
# CALLED BY:	utility
# RETURN:	the handle of the thread that this entry was written on
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
[defsubr get-thread {entry} 
 {
    
    var type [symbol name [index $entry 2]] 

    [case $type in 
     {ProfileGenericEntry} {
	 var thread [field [index $entry 1] PGE_thread]
     }
     {ProfileMessageEntry} {
	 var thread [field [index $entry 1] PME_thread]

     }]
    return $thread
}]
	
##############################################################################
#	handle-ret
##############################################################################
#
# SYNOPSIS:	Handle a return the return from a message call or send. 
#               Calculate the time it took to send or call that message, and
#               echo that to the screen, along with the type of return.
# PASS:		entry triple, address of the entry
# CALLED BY:	format-messages
# RETURN:	nothing
# SIDE EFFECTS:	none
#       decrements the indent
#       prints out the entry, calculates the time to execute the code since 
#       this message was sent.
#       pops a time and entry from the entryStack
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	11/ 3/94   	Initial Revision
#
##############################################################################
[defsubr handle-ret {entry oldAddress}
 {
     global indent totalOutTime indentStep geosTimerValue

     var indent [expr $indent-$indentStep]
     var matchEntry [popLogStack]
     
     if {$matchEntry == {}} {
	 error {return from a message before a message is sent}
     }
     var timeAway [popLogStack]
     var timeAway [expr $totalOutTime-$timeAway]
     
     var space [format {%*s} $indent {}]
     echo -n $space [get-entry-type $entry] time: 

     var timeStart [field [field [index $matchEntry 1] PME_header] PLE_timeStamp ]
     var timeEnd [field [field [index $entry 1] PME_header] PLE_timeStamp] 
     var timeBetween [time-difference $timeStart $timeEnd]
     
     echo [expr $timeBetween-$timeAway] @$oldAddress)

 }]
     

##############################################################################
#	time-difference
##############################################################################
#
# SYNOPSIS:	calculate the difference between to timer values
# PASS:		the high and low parts of the two time values
#               timeStart, timeEnd
# CALLED BY:	handle-ret, handle-end
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       IP 	12/ 5/94   	Initial Revision
#
##############################################################################
[defsubr    time-difference {timeStart timeEnd} {
    global geosTimerValue



    var timeStartLow [expr $timeStart&0x0000ffff]
    var timeStartHigh [expr $timeStart>>16]
    var timeStartLow [expr $geosTimerValue-$timeStartLow]
    var timeStart [expr $timeStartLow+[expr $timeStartHigh*$geosTimerValue]]
    
    var timeEndLow [expr $timeEnd&0x0000ffff]
    var timeEndHigh [expr $timeEnd>>16]
    var timeEndLow [expr $geosTimerValue-$timeEndLow]
    var timeEnd [expr $timeEndLow+[expr $timeEndHigh*$geosTimerValue]]     
    
    return [expr $timeEnd-$timeStart]
}]
     
##############################################################################
#	pushLogStack
##############################################################################
#
# SYNOPSIS:	push an item onto the entryStack.
# PASS:		item to be pushed on entryStack
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
[defsubr pushLogStack {entry} {
    global entryStack
    var entryStack [cons $entry $entryStack]
}]

[defsubr popLogStack {} {
    global entryStack
    
    var retVal [car $entryStack]
    var entryStack [cdr $entryStack]
    
    return $retVal
}]

##############################################################################
#	get-entry
##############################################################################
#
# SYNOPSIS:	get an entry out of the log stored in xms given the linear 
#               address of that entry
# PASS:		address
# CALLED BY:	utility
# RETURN:       entry triple {size entry entryType}
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
[defsubr get-entry {address}
 {
     global xmsArgsType xmsProcOffset

     var args [create-address $address]
     var xmsHandle [index $args 0]
     var xmsNextHandle [index $args 1]
     var xmsOffset [index $args 2]
     var sizeOfXmsPage [index $args 3]
     
     var info [get-entry-size-type $xmsHandle $xmsNextHandle 
		      $xmsOffset $sizeOfXmsPage ]
     
     var size [index $info 0]
     var entryType [index $info 1]
     
     # echo $entryType

     if {$size != 0} {
	 var entry [xmsread $xmsHandle $xmsNextHandle $xmsOffset 
		    $sizeOfXmsPage $xmsProcOffset 
		    $entryType $size]

	 return [list $size $entry $entryType]
     } else {
	 return $size
     }
 }]
     
##############################################################################
#	get-entry-size-type
##############################################################################
#
# SYNOPSIS:	get the size and type of an entry
# PASS:		xmsHandle     = handle of xms page containing entry
#               xmsNextHandle = handle of next xms page
#               xmsOffset     = offset into xms page
#               sizeOfXmsPage = the size of an xms page
#
# CALLED BY:	utility
# RETURN:       {size type}
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
[defsubr get-entry-size-type {xmsHandle xmsNextHandle xmsOffset sizeOfXmsPage}
 {
     global pet_size_list pet_list xmsProcOffset

     # echo $xmsHandle $xmsNextHandle $xmsOffset

     var entryType [xmsread $xmsHandle $xmsNextHandle $xmsOffset 
		    $sizeOfXmsPage $xmsProcOffset [type word] 2]

     # echo $entryType
     if {$entryType == 0} {
	 return $entryType
     } else {
	 var entryType [expr $entryType&0x7fff]
	 return [list [index $pet_size_list [expr $entryType-1]] 
		      [index $pet_list [expr $entryType-1]] ]
     }
	 
 }]

#############################################################################
# The following are routines that I am keeping around for nostalgic reasons
# and are not currently being used.
#############################################################################

[defsubr print-entry {entry}
 {
     fmtval  [index $entry 1] [index $entry 2] 0
 }]

[defsubr print-type {entry}
 {
     echo [type emap [field [field [field [index $entry 1] 
				    PME_header] PLE_type] PLET_type] 
				    [symbol find type ProfileEntryType]]
 }]

#
# get ProfileEntryType, assuming that it is a ProfileMessageEntry
#
[defsubr get-type {entry}
 {
     return [type emap [field [field [field [index $entry 1] 
				    PME_header] PLE_type] PLET_type] 
				    [symbol find type ProfileEntryType]]
 }]

#
# get the value of the message, assuming that it is a ProfileMessageEntry
#
[defsubr get-message-value {entry}
 {
     return [field [index $entry 1] PME_message]
 }]

[defsubr print-time {entry}
 {
     global lastTime
     
     var time [field [field [index $entry 1] PME_header] PLE_timeStamp] 
     var timeLow [expr $time&0x0000ffff]
     var timeHigh [expr $time>>16]
     var timeLow [expr 0xffff-$timeLow]
     var time [expr $timeLow+[expr $timeHigh<<16]]
#     echo $timeLow $timeHigh
     if {$lastTime != 0} {
	 echo [expr $time-$lastTime]
     }
     var lastTime $time

 }]

[defsubr count {entry}
 {
     global count

     var count [expr $count+1]
     if {[expr $count%50]==0} {
	 echo $count
     }
 }]

##############################################################################
#	foreach-entry
##############################################################################
#
# SYNOPSIS:	foreach entry in the log starting at address startAddress call
#               proc passing an entry triple
# PASS:		startAddress      = address to start looking at
#               proc              = proc to call with entry
# CALLED BY:	user
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
[defsubr foreach-entry {startAddress proc}
 {
     for {var address $startAddress} {1} {} {
	 var retVal [get-entry $address]
	 if {$retVal == 0} {
	     break
	 }
	 var address [expr $address+[index $retVal 0]]
	 $proc $retVal
     }	 
 }]

