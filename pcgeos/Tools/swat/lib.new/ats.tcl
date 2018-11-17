###############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE: 	ats.tcl
# AUTHOR: 	Kenneth Liu, Oct  8, 1996
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	kliu	10/ 8/96   	Initial Revision
#
# DESCRIPTION:
#
#	
#
#	$Id: ats.tcl,v 1.10.2.1 97/03/29 11:27:46 canavese Exp $
#
###############################################################################

#
# Globals declaration used in ATS
#
# used for spacing in menu
defvar ats-minAspect 15

# used for limit in playback buffer
defvar bufsize-limit 200

# set/unset as user chooses to verify the commands or not
defvar error-check 1

# set/unset as user chooses to stop on error
defvar promptOnError 1

# set/unset as user chooses to do file logging
defvar doLogging 1

# set/unset as user chooses to execute command
defvar execCmd 1

#
# list for different levels of menus
#
defvar topList [list {Do Record} {Do Playback} {Settings} {Swat Prompt}]
defvar recordList  [list {End Record} {Resume Record} {Screen Dump} {Enter Script} {Swat Prompt}]
defvar playbackList [list {End Playback} {Resume Playback} {Swat Prompt}]
defvar settingsList [list {Current Status} {Toggle promptOnError} {Toggle doLogging} {Toggle execCmd} 
		     {Up level}]

#
# descriptions for different levels of menus
#
defvar topDesc {top-most level of ATS menu}
defvar recordDesc {ATS record menu}
defvar settingsDesc {ATS settings menu}
defvar playbackDesc {ATS playback menu}

#
# Mapping of menu options to corresponding commands
#
defvar opMap [list 
	      [list {Do Record} ats-do-record]
	      [list {Do Playback} ats-do-playback]
	      [list {End Record} ats-end-record]
	      [list {Resume Record} ats-resume-record]
	      [list {End Playback} ats-end-playback]
	      [list {Resume Playback} ats-resume-playback]
	      [list {Screen Dump} ats-record-screen-dump]
	      [list {Enter Script} ats-enter-script]
	      [list {Settings} ats-settings]
	      [list {Current Status} ats-current-status]
	      [list {Toggle promptOnError} ats-toggle-promptOnError]
	      [list {Toggle doLogging} ats-toggle-doLogging]
	      [list {Toggle execCmd} ats-toggle-execCmd]
	      [list {Up level} ats-up-level]
	      [list {Swat Prompt} ats-swat-prompt]]

#
# list to relate lists of menus and their corresponding descriptions
#
defvar ats-menu-list [list
		      [list top [list $topDesc $topList]]
		      [list record [list $recordDesc $recordList]]
		      [list settings [list $settingsDesc $settingsList]]
		      [list playback [list $playbackDesc $playbackList]]]

#
# Menu items which requires special handling
#
defvar special-case-list [list {Swat Prompt} {Screen Dump} {Enter Script}]

##############################################################################
#          ats
##############################################################################
#
# SYNOPSIS:	main tcl command to invoke ATS
# PASS:		nothing
# CALLED BY:	user
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defcmd ats {} top
{Usage:
     ats 
     Automated Testing System. This program enables user to record a session of inputs from the PC,
     and to playback the entire session for testing purpose. User can also enter swat commands or 
     screen-dump in the middle of the recording session, and have those commands verified during
     playback. 
}
 {
     global curFile curPath ats-path record-list isFinish

     if { $isFinish != 1 } {
	 echo Note: ATS has been terminated abnormally in the last session.\n
	 if { ![null ${record-list}] } {
	     for {} {1} {} {
		 echo -n There are some unsaved recording events, do you want to save them (y/n)?
		 var ans [read-char 0]
		 if {$ans == y} {
		     ats-end-record
		     break
		 } elif { $ans == n } {
		     #
		     # okay, delete it then.
		     var record-list {}
		     echo \nUnsaved information deleted.
		     break
		 } else {
		     continue
		 }
	     }
	 } else {
	     echo No unsaved recording information.
	 }
     }

     var curFile default.tcl
     if {[null ${ats-path}]} {
	var ats-path [getenv HOME]
    }
     var curPath ${ats-path}
     
     #
     # Do initialization for screendumps
    stop-patient
    if {[catch {call-patient ats::ATSInitialize}] != 0} {
	error {calling-patient ATSInitialize failed}
    }
     
     for {} {1} {} {
	 var level top
	 var operations [ats-menu $level]
	 if {![ats-pick $level $operations]} {
	     break
	 }
     }
     echo
 }]

##############################################################################
#	ats-pick
##############################################################################
#
# SYNOPSIS:	loop for menu processing and command executions
# PASS:		level = {top, playback, record, setting}
#               operation = list of operation in the menus
# CALLED BY:	?
# RETURN:	0 and isFinish = 1 if 0 is chosen
#               results of returned by commands
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-pick {level operations} {
    
    global opMap isFinish special-case-list
    
    var isFinish 0
    
    for {} {1} {} {
	prompt ats:$level> 
	var num [read-char 0]
	[case $num in 
	 
	 0 {
	     #
	     # signifying the end of ATS

	     var isFinish 1
	     return 0
	 }
	 {[1-9]*} {
	     #
	     # check whether operation exists
	     
	     var o [index $operations [expr $num-1]]
	     if [null $o] {
		 echo No such operations
		 continue
	     }

	     #
	     # check whether it requires special handling

	     if {[member $o ${special-case-list}]} {
		 eval [index [assoc $opMap $o] 1]
		 echo
		 [ats-menu $level]
		 continue
	     }
	     break
	 }
	 default {
	     echo
	     [ats-menu $level]
	     continue
	 }]
	
    }
    #
    #  call selected operations

    var op [index [assoc $opMap $o] 1]
    return [eval $op]
}]

##############################################################################
#	member
##############################################################################
#
# SYNOPSIS:	lisp-like utility to determine whether an element is inside a list
# PASS:		list
# CALLED BY:	
# RETURN:	1 for yes, 0 for no.
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr member {elt {list {}}}
 {
     foreach e $list {
	 if {$elt == $e} {
	     return 1
	 }
     }
     return 0
 }]

##############################################################################
#	ats-file-choser
##############################################################################
#
# SYNOPSIS:   
# PASS:		operation = {record, playback}
#               promptStr = string displayed for file prompting
# CALLED BY:	Currently ats-do-record and ats-do-playback
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-file-choser {operation promptStr} 
 {
     global curPath curFile

     #
     # currently only playback or record should be using it.

     if {$operation != playback && $operation != record} {
	 error {wrong operation in ats-file-choser}
     }
     
     var prevFile $curFile
     
     for {} {1} {} {
	 echo -n \n$promptStr \[$curFile\] >
	 
	 var l [read-line]
	 if {[string m $l */*]} {
	     # it's a path and a filename, parse
	     var pos [string last / $l]
	     
	     var curPath [file dirname $l]
	     if {![file isdir $curPath] } {
		 echo $curPath is not a valid directory
		 echo Default directory ${ats-path} is used.
		 var curPath ${ats-path}
	     }
	     var curFile [range $l [expr $pos+1] end]
	 }
	 
	 if {![null $l]} {
	     var curFile $l
	 }
	 
	 #
	 # Append .tcl to the end if not yet.
	 # 
	 if {![string m $curFile *.tcl]} {
	     #
	     # append .tcl to the end of the name
	     var curFile $curFile.tcl
	 } 
	 
	 #
	 # Now we got the file name, check whether it exists
	 # 
	 if {![file exists $curPath/$curFile]} {
	     #
	     # File does not exist, a problem if it is a playback session.
	     if {$operation == playback} {
		 var curFile $prevFile
		 echo -n File does not exists, (l)s, (c)ancel?
		 var ans [read-char 0]
		 echo 
		 [case $ans in 
		  l {
		      echo Listing of $curPath:
		      echo -n [ls $curPath]
		      continue
		  }
		  c {
		      return 1
		  }
		  default  {
		      continue
		  }]
	     }
	     return 0
	 } elif { $operation == record } {
	     #
	     # It is a recording session
	     echo -n File already exists, (a)ppend, (t)runcate, or (c)ancel?
	     
	     var ans [read-char 0]
	     echo 
	     [case $ans in 
	      a {
		  return 0
	      }
	      t {
		  exec rm $curPath/$curFile
		  var l [range $curFile 0 [expr [string first .tcl $curFile]-1] char]
		  if {[file exists $curPath/LOG/$l.LOG]} {
		      [for {var n 1} {[file exists $curPath/LOG/$l.LOG.old$n]} 
		       {var n [expr $n+1]} {}]
		      exec mv $curPath/LOG/$l.LOG $curPath/LOG/$l.LOG.old$n
		      echo $l.LOG has been moved to $l.LOG.old$n
		  }
		  return 0
	      }
	      c {
		  return 1
	      }
	      default {
		      continue
		  }
	     ]
	 }
	 #
	 # For file existence in playback, just do it.
	 return 0
     }
 }]

##############################################################################
#	ats-do-record
##############################################################################
#
# SYNOPSIS:	The routine to start a recording session
# PASS:		nothing
# CALLED BY:	top-most level menu
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-do-record {} 
	  {
     global isFinish record-list 

     if {[ats-file-choser record {Enter the record session filename}]} {
	 #
	 # file has not been chosen
	 return 1
     }

     continue-patient
     echo \nRecording in progress. Press Ctrl-c to stop recording.
     
     var isSync 0
     var record-list {}
     
     #
     #  Initiation work for ATS Record
     #
     ats-record-reset-buffers
     assign ats::atsState ats::ATSM_RECORD
     assign ats::atsLastEventTime geos::systemCounter.low 
     
     #
     #  record main loop
     #
     for {} {1} {} {
	#
	# recording loop
	#
	ats-recording-loop

	#
	# record has been stopped, do cleanup 
	# 
	
	#
	# reset buffer at sync state
	#
	ats-record-reset-buffers

	var level record
	var operations [ats-menu $level]
	if {![ats-pick $level $operations]} {
	    break
	}
    }
     if {$isFinish} {
	 return 0
     }
     return 1
}]

##############################################################################
#	ats-record-reset-buffers
##############################################################################
#
# SYNOPSIS:     reset buffers necessary for record.
# PASS:		ats-do-record
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-record-reset-buffers {} {
     assign ats::currentBufPtr ats::atsEventBuffer1
     assign ats::backupBufPtr ats::atsEventBuffer2
     assign ats::atsBufSize 0
     assign ats::currentBufOffset 0
 }]

##############################################################################
#	ats-end-record
##############################################################################
#
# SYNOPSIS:	End the recording by translating the recorded events into scripts
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-end-record {} {

    global record-list curFile curPath

    echo \nTranslation in progress (iterative version), please wait..\n

    irq no
    ats-translate-to-script
    irq yes

    echo Saved to $curPath/$curFile

    var record-list {}
    assign ats::atsState ats::ATSM_IDLE
    return 0
}]

##############################################################################
#	ats-translate-to-script
##############################################################################
#
# SYNOPSIS:	Main routine to translate events to script
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-translate-to-script {} {
    global record-list curPath curFile
    
    if {[catch {[stream open [format {%s/%s} $curPath $curFile] a]} script] 
	== 0} {
	    protect {
		ats-translate-to-script-helper ${record-list} $script
	    } {
	    stream flush $script
	    stream close $script
	}
    } else {
	error {Cannot open file}
    }
}]

[defsubr ats-translate-to-script-helper {theList script} {
    
    var pointer [getvalue SET_POINTER]
    var key [getvalue SET_KEYBOARD]
    var power [getvalue SET_POWER]

    #
    #  Use iterative routine
    #

    var endCmdPending 0

    for {} {![null $theList]} {} {
	
	#
	# Only two possible conditions:
	# 1. command
	# 2. delay itself or delay followed by hardware events
	#
	
	var token [car $theList]
	[case $token in
	 {command:*} {
	     #
	     # sure it is a command
	     
	     if {$endCmdPending} {
		 var l [format {\[%s\]\n} [string subst $token command: {}]]
	     } else {
		 var l [format {\[if \{\$execCmd\} \{\n[ats-start-command\]\n\[%s\]\n} 
			[string subst $token command: {}]]
		 var endCmdPending 1
	     }
	     stream write $l $script
	     var theList [cdr $theList]
	     continue
	 }
	 default {

	     if { $endCmdPending } {
		 var l [format {\[ats-end-command\]\n\}\]\n\[ats-delay %s\]\n} $token]
		 var endCmdPending 0
	     } else {
		 var l [format {\[ats-delay %s\]\n} $token]
	     }
	     stream write $l $script
	 
	 var theList [cdr $theList]
	 if {[null $theList]} {
	     return
	 }
	 #
	 # Must have events following 
	 
	 var eventType [car $theList]
	 [case $eventType in 
	  $key {
	      var s [index $theList 1]
	      var i [index $theList 2]
	      var l [format {\[ats-key %s %s\]\n} $s $i]
	      stream write $l $script
	      var theList [range $theList 3 end]
	  }
	  $pointer {
	      var x [index $theList 1]
	      var y [index $theList 2]
	      var b [index $theList 3]
	      var l [format {\[ats-pointer %s %s %s\]\n} $x $y $b]
	      stream write $l $script
	      var theList [range $theList 4 end]
	  }
	  $power {
	      #	echo Do nothing right now
	  }
	  default {
	      echo Something must have gone wrong
	      return
	  }]
     } ]
    }
    if { $endCmdPending } {
	 var l [format {\[ats-end-command\]\n\}\]\n}]
	 var endCmdPending 0
	 stream write $l $script
     }
}]	  

##############################################################################
#	ats-resuming-record
##############################################################################
#
# SYNOPSIS:    resume recording
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:   PC was stopped at the time when recording is interrupted. The state
#             however is still in record. It basically continue-patient and setting
#             the atsLastEventTime.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-resume-record {} {
    echo \nRecording in progress. Press Ctrl-c to stop recording.
    assign ats::atsLastEventTime geos::systemCounter.low 
    continue-patient
    return 1
}]

##############################################################################
#	ats-enter-script
##############################################################################
#
# SYNOPSIS:  routine to enable user to type in swat commands into the record script.	
# PASS:	     nothing 
# CALLED BY: ?
# RETURN:    
# SIDE EFFECTS:	
#
# STRATEGY:  
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-enter-script {} {
    
    global record-list error-check

    for {} {1} {} {
	echo -n Do you want to verify the commands?(y/n)
	var ans [read-char 0]
	if {$ans == y} {
	    var error-check 1
	    break
	} elif {$ans == n} {
	    var error-check 0
	    break
	} else {
	    echo
	    continue
	}
    }
    
    echo \nAt the prompt, type in commands to be added to the script.
    echo Type <.> to finish.\n

    prompt ats:record:enterscript>
    if {${error-check}} {
	for {var l [read-line 1]} {1} {} {
	    echo -n Enter the error handling routine :
	    var r [read-line 1]
	    var l [format {ats-verify {%s} {%s}} $l $r]
	    var record-list [concat ${record-list} [list command:$l]]
	    prompt ats:record:enterscript>
	    var l [read-line 1]
	    if {$l == {.}} {
		break
	    }
	}
    } else {
	for {var l [read-line 1]} {$l!={.}} {var l [read-line 1]} {
	    var record-list [concat ${record-list} [list command:$l]]
	    prompt ats:record:enterscript>
	}
    }
}]
    
##############################################################################
#	ats-recording-loop
##############################################################################
#
# SYNOPSIS:	Main loop for record.
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-recording-loop {} {
	
	var isSync 0
	global record-list
     
     irq no
     for {} {$isSync != 1} {} {
	 for {} {![irq] && ![getvalue ats::atsBufferFull]} {} {
	     if {![sleep 0.1]} {
		 irq set
		 break
	     }
	 }

	 #
	 #  Get buffer pointed by atsBufPtr
	 #
	 if {[irq]} {
	     irq clear
	     stop-patient

	     #
	     #  Just in case irq happens as buffer becomes full.. rare.
	     
	     if {[getvalue ats::atsBufferFull]} {
		 var bufferSize [expr [getvalue ats::atsBufSize]/2]
		 if {$bufferSize} {
		     var record-list [concat ${record-list} 
				      [value fetch *ats::atsBufPtr
				       [type make array $bufferSize [type word]]]]
		 }
	     } 
	     var bufferSize [expr [getvalue ats::currentBufOffset]/2]
	     if {$bufferSize} {
		 var record-list [concat ${record-list}
				  [value fetch *ats::currentBufPtr
			   [type make array $bufferSize [type word]]]]  
	     }
	     var isSync 1
	 } else {
	     #
	     #  Normal case of Buffer Full, do not stop patient and get buffer
	     #
	     
	     var bufferSize [expr [getvalue ats::atsBufSize]/2]
	     if {$bufferSize} {
		 if {[catch {[value fetch *ats::atsBufPtr
			     [type make array $bufferSize [type word]]]} 
			     tmpList]} {
				 error {Error occurs in fetching data, breaking}
			     }
				 
		 var record-list [concat ${record-list} $tmpList]
	     }
	 }
         if {[catch {assign ats::atsBufferFull 0}] != 0} {
	     error { setting atsBufferFull error}
	 }
     }
     irq yes
 }]
   
##############################################################################
#	ats-do-playback
##############################################################################
#
# SYNOPSIS:	Routine to start a playback session
# PASS:		nothing
# CALLED BY:	top-most level of menu
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:     load the script file.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-do-playback {} {
    
    global  curFile curPath startPlayPending doLogging logstream
    #
    # Initialization work

    if {[ats-file-choser playback {Enter the session name for playback}]} {
	#
	# no file chosen
	return 1
    }
    global playback-list 
    var playback-list {}
    
    assign ats::atsBufferFull 0
    ats-playback-reset-buffers
    
    assign ats::atsSynchronized 0

    # 
    # Prepare directory for logging

    if {![file isdir $curPath/LOG]} {
	exec mkdir $curPath/LOG
    }
    
    #
    #
    # make sure stream is fresh each time
    var logstream {}
    if {$doLogging} {
	var l [range $curFile 0 [expr [string first .tcl $curFile]-1] char]
	
	if {[catch {stream open $curPath/LOG/$l.LOG a} logstream] != 0} {
	    error {Cannot open log file.}
	}
	var bar [format  {******************************************\n}]
	stream write $bar $logstream
	var line [format {Log session: %.s} [exec date]]
	stream write $line $logstream
	stream write $bar $logstream
    }
	          
    # do playback right here
    echo \nStarting Playback...
    
    var startPlayPending 1
    protect {
	load $curPath/$curFile
    } {
	ats-sync 
	if {![null $logstream]} {
	    stream close $logstream
	}
    }
    echo \nPlayback completed.
    return 1
}]

##############################################################################
#	ats-playback-reset-buffers
##############################################################################
#
# SYNOPSIS:	reset buffers used by playback
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-playback-reset-buffers {} {
    assign ats::atsBufPtr ats::atsEventBuffer1
    assign ats::backupBufPtr ats::atsEventBuffer2
    assign ats::bufSize 0
}]
    
##############################################################################
#	ats-swat-prompt
##############################################################################
#
# SYNOPSIS:	open a top-level tcl shell
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-swat-prompt {} {
    echo \nType <break> to return to ATS menu:\n
    top-level
}]

##############################################################################
#	ats-settings
##############################################################################
#
# SYNOPSIS:	Settngs menu. User can set values for doLogging and promptOnError.
#               User can also print out the current status of settings.
# PASS:		nothing
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-settings {} {

    global isFinish

    for {} {1} {} {
	var level settings
	var operations [ats-menu $level]
	if {![ats-pick $level $operations]} {
	    break
	}
    }
    if {$isFinish} {
	return 0
    }
    return 1
}]

[defsubr ats-up-level {} {
    echo
    return 0
}]

##############################################################################
#	ats-current-status
##############################################################################
#
# SYNOPSIS:	print out current status of ATS settings
# PASS:		ats-settings
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-current-status {} {
    global promptOnError doLogging execCmd

    echo \nCurrent settings as follows:
    echo -----------------------------

    if {$promptOnError} {
	var result set
    } else {
	var result unset
    }
    echo promptOnError is $result.
    if {$doLogging} {
	var result set 
    } else {
	var result unset
    }
    echo doLogging is $result.

    if {$execCmd} {
	var result set
    } else {
	var result unset
    }
    echo execCmd Is $result.
    echo 
    return 1
}]


[defsubr ats-toggle-promptOnError {} {
    global promptOnError 

    if {$promptOnError} {
	var promptOnError 0
	echo \nUnsetting promptOnError.
    } else {
	var promptOnError 1
	echo \nSetting promptOnError.
    }
    return 1
}]

[defsubr ats-toggle-doLogging {} {
    global doLogging

    if {$doLogging} {
	var doLogging 0
	echo \nUnsetting doLogging
    } else {
	var doLogging 1
	echo \nSetting doLogging
    }
    return 1
}]

[defsubr ats-toggle-execCmd {} {
    global execCmd

    if {$execCmd} {
	var execCmd 0
	echo \nUnsetting execCmd
    } else {
	var execCmd 1
	echo \nSetting execCmd
    }
    return 1
}]


[defsubr ats-menu {level} 
 {
    global ats-menu-list
    global menu
       
    var tmp [index [assoc ${ats-menu-list} $level] 1]

    #
    # Print out the menu description
    #
    echo [index $tmp 0]:\n

    #
    # Fetch operations for this level
    #
    var operations [index $tmp 1]

    var num 0

    var menu [concat {{ 0 FINISH}}
	      [map o $operations {
		  var num [expr $num+1]
		  format {%2d %s} $num $o
    }]]
    
    ats-print-as-table $menu
    echo
    return $operations
}]

[defsubr ats-print-as-table {operations {ignoreAspect 0}} 
 {
     global ats-minAspect

     #
     # Find the width of the longest one
     #
     var width 0
     foreach i $operations {
	 var len [length $i chars]
	 if {$len > $width} {
	     var width $len
	 }
     }
     #
     # Up that by the inter-column spacing (2 -- magic)
     #
     var width [expr $width+2]
     #
     # Figure the number of columns we can put up (minimum of 1)
    #
     var nc [expr ([columns]-1)/$width]
     if {$nc == 0} {
	 var nc 1
     }
     var tlen [length $operations]
     
     #
     # Figure out the distance between operations in a row. This is just
     # the number of operations divided by the number of columns, rounded up
     #
     var inc [expr ($tlen+$nc-1)/$nc]
     
    if {!$ignoreAspect && ${ats-minAspect}} {
	while {($inc*10)/$nc < ${ats-minAspect} && $nc != 1} {
	    var nc [expr $nc-1]
	    var inc [expr ($tlen+$nc-1)/$nc]
	}
    }    	
     
     #
     # Put up the table. Note that [index list n] when
     # n > [length list] returns empty, so there's no need to check
     # for overflow.
     #
     for {var i 0} {$i < $inc} {var i [expr $i+1]} {
	 for {var j 0} {$j < $nc} {var j [expr $j+1]} {
	     echo -n [format {%-*s} $width
		      [index $operations [expr $i+$j*$inc]]]
	 }
	 echo
     }
 }]     


##############################################################################
#	ats-key
##############################################################################
#
# SYNOPSIS:	script command for key events. append itself to playback list.
# PASS:	       
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-key {scan info} {
    global playback-list
    
    var playback-list [concat ${playback-list} [list 0 $scan $info]]
} ]
##############################################################################
#	ats-pointer
##############################################################################
#
# SYNOPSIS:	append pointer event to playback list
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       mjoy 	11/20/96   	Initial Revision
#
##############################################################################
[defsubr ats-pointer {xpos ypos button} {
    global playback-list

    var playback-list [concat ${playback-list} [list 2 $xpos $ypos $button]]
}]

##############################################################################
#	ats-send-list
##############################################################################
#
# SYNOPSIS:	subroutine to send playback list to buffer on PC
# PASS:		len = length of list to send
# CALLED BY:	ats-delay, ats-sync
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-send-list {len} {
    global playback-list 
    
    if { $len <= 0 } {
	return 0
    }
    
    for {} {[getvalue ats::bufSize] != 0} {} {
	sleep 0.1
    }
    
    echo debug: sending list.
    [value store *ats::atsBufPtr ${playback-list} 
     [type make array $len [type int]]]
    assign ats::bufSize [expr $len*2]
    assign ats::atsBufferFull -1
    var playback-list {}
    return 1
}]

##############################################################################
#	ats-delay
##############################################################################
#
# SYNOPSIS:	script command for delay event. append itself to playback list
#               in normal case for send list if list is long enough.
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-delay {ticks} {
    
    global playback-list bufsize-limit startPlayPending
    
    var len [length ${playback-list}]
    if {$len >= ${bufsize-limit}} {
	
	#
	# ready to send buffer, can start playback now
	if {$startPlayPending} {
	    stop-patient
	    echo debug: calling ATSStartPlayback
	    if {[catch {call-patient ats::ATSStartPlayback}] != 0} {
		error {call-patient ATSStartPlayback failed}
	    }
	    ats-send-list $len
	    continue-patient
	    var startPlayPending 0
	} else {
	    ats-send-list $len
	}
    }
    #
    # delay events added to the 
    var playback-list [concat ${playback-list} [list $ticks]]    
}]

##############################################################################
#	ats-sync
##############################################################################
#
# SYNOPSIS:	send list and make sure all events are playback on the PC
#               before stopping it.
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-sync {} {
    
    global playback-list startPlayPending

    if {[getvalue ats::atsSynchronized]} {
	echo it's already sync
	return 
    }
    
    var len [length ${playback-list}]

    if { $len > 0 && $startPlayPending } {
	stop-patient
	echo debug: Starting Playback
	if {[catch {call-patient ats::ATSStartPlayback}] != 0} {
		error {call-patient ATSStartPlayback failed}
	    }
        ats-send-list $len
	continue-patient
	var startPlayPending 0
	assign ats::atsWaitSynch -1
	for {} {[getvalue ats::atsWaitSynch]} {} {
	    sleep 0.2
	}
    } else {
	if {[ats-send-list $len]} {
	    assign ats::atsWaitSynch -1
	    for {} {[getvalue ats::atsWaitSynch]} {} {
		sleep 0.2
	    }
	}
    }

    #
    #  reset state for playback
    assign ats::atsBufferFull 0
    ats-playback-reset-buffers

    #
    #  Wait a little bit for UI to really synchronize
    sleep 3
    stop-patient
    assign ats::atsState ats::ATSM_IDLE
}]

##############################################################################
#	ats-resume-playback
##############################################################################
#
# SYNOPSIS:	Resume a playback session after a swat command or screendump is 
#               executed inside the script.
# PASS:		
# CALLED BY:	ats-end-command
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-resume-playback {} {
    
    global startPlayPending 
    #
    # Problem is before calling this we have to make sure there're more events to be sent

    assign ats::atsSynchronized 0
    var startPlayPending 1
}]

##############################################################################
#	ats-start-command
##############################################################################
#
# SYNOPSIS:	script command which is necessary to put before any swat command or 
#               screendump is executed. It calls ats-sync and prepare file logging
#               if necessary.
# PASS:		nothing
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-start-command {} {
    global doLogging

    ats-sync
    if {$doLogging} {
	echo debug: clearing buffer
	sbclr
	wclear
    }
}]

##############################################################################
#	ats-end-command
##############################################################################
#
# SYNOPSIS:	call resume playback and do file logging if necessary.
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-end-command {} {
    global curPath curFile doLogging logstream

    if {$doLogging} {
	if {[catch {slog $logstream}] != 0} {
	    error {Error has occured in slog.}
	}
	stream write \n $logstream
	stream flush $logstream
    }
    ats-resume-playback
}]
    
[defsubr ats-verify {command handler} {

    global promptOnError
    #
    # just try to eval the command
    
    var result [eval $command]
    if {![string m $result *FAIL*]} {
	echo Verification passed for \[$command\]
    } else {
	[echo Verification failed for \[$command\]]
	echo $result
	echo Calling handler: \[$handler\]
	eval $handler
	if {$promptOnError} {
	    echo \nType <break> to continue playback.
	    top-level
	}
    }
}]

##############################################################################
#	ats-screen-dump
##############################################################################
#
# SYNOPSIS:	script command to do screepdump.
# PASS:		filename to which the screen is dumped to.
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-screen-dump {dumpfile} {
    global screen-width screen-height
    
    echo Screen dump begins, it takes around a minute.
    #
    # do a screendump now plus....
    
    assign ats::getScreenDump -1
    continue-patient
    
    var video-list {}
    if {[catch {stream open $dumpfile w+} df] != 0} {
	error {Cannot open file for screendump.}
    }
    value log  ats::screenWidth $df
    var screen-width [value fetch ats::screenWidth]
    value log  ats::screenHeight $df
    var screen-height [value fetch ats::screenHeight]
    value log  ats::bitsPerPixel $df
    
    #
    # we have to check bufferfull first since PC could be much faster in filling the last
    # line and make it screendumpDone before we are done with the second last line.
    protect {
	for {var i 1} {[getvalue ats::videoBufferFull] || ![getvalue ats::screendumpDone]} {} {
	    for {} {![getvalue ats::videoBufferFull]} {} {
		sleep 0.1
	    }
	    var bufSize [getvalue ats::videoBufSize]
	    if {$bufSize <= 0} {
		error {Video data has zero length}
	    } else {
		[value log *ats::vidBufPtr $df [type make array $bufSize 
					      [type byte]]]
		echo $i buffers sent
		assign ats::videoBufferFull 0
	    }
	    var i [expr $i+1]
	}
    } {
	stream close $df
	assign ats::screendumpDone 0
	#
	# screendump is done.
	stop-patient
    }
}]

##############################################################################
#	ats-record-screen-dump
##############################################################################
#
# SYNOPSIS:  Call ats-screen-dump and do other handlings for screendumping in
#            record: Enter script, etc.
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-record-screen-dump {} {
    global curPath curFile record-list screen-width screen-height
 
    if {![file isdir $curPath/ScreenDump]} {
	exec mkdir $curPath/ScreenDump
    }

    echo
    var session [range $curFile 0 [expr [string first .tcl $curFile]-1] char]
    for {var n 1} {[file exists $curPath/ScreenDump/$session.SD$n]} {var n [expr $n+1]} {}
    echo Dumping screen to $curPath/ScreenDump/$session.SD$n

    ats-screen-dump $curPath/ScreenDump/$session.SD$n

    echo Screen dump completed.
    echo -n Adding screen dump to script....

    var l [format {ats-screen-dump %s} $curPath/ScreenDump/$session.PBK]
    var record-list [concat ${record-list} [list command:$l]]

    echo done.
    echo Screen dump in playback will be saved in $curPath/ScreenDump/$session.PBK
    
    for {} {1} {} {
	echo  For screen comparison, you need to specify a rectangular area.
	
	echo -n Enter the x-coordinate for the upper left corner \[0\] >
	var x [read-line]
	if {[null $x]} { var x 0 } {}
	echo -n Enter the y-coordinate for the upper left corner \[0\] >
	var y [read-line]
	if {[null $y]} { var y 0 } {}
	echo -n Enter the width of the rectangle \[${screen-width}\] >
	var w [read-line]
	if {[null $w]} { var w ${screen-width} } {}
	echo -n Enter the height of the rectangle \[${screen-height}\] >
	var h [read-line]
	if {[null $h]} { var h ${screen-height} } {}
	
	if {![bound-check $x $y $w $h]} {
	    # succeed
	    break
	} else {
	    echo \nRectangular area specifed is invalid.
	}
    }
    echo Adding screen comparison to script....
    [var l [format {ats-verify {exec vidcmp %s %s %s %s %s %s} {ats-backup-screen}}
	    $curPath/ScreenDump/$session.SD$n $curPath/ScreenDump/$session.PBK $x $y $w $h]]
    var record-list [concat ${record-list} [list command:$l]]
    echo done.
}]

##############################################################################
#	bound-check
##############################################################################
#
# SYNOPSIS:	Make sure rectangular area specified for screendump is not out
#               of bounds
# PASS:		
# CALLED BY:	
# RETURN:	0 if succed, 1 if fail
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/21/96   	Initial Revision
#
##############################################################################
[defsubr    bound-check {x y rec-width rec-height} {
    global screen-height screen-width

    #
    #  no negatives

    if {$x<0 || $y<0 || ${rec-width}<0 || ${rec-height}<0} {
	return 1
    }
    if { [expr $x+${rec-width}] > ${screen-width} } {
	return 1
    } elif { [expr $y+${rec-height}] > ${screen-height} } {
	return 1
    } else {
	#
	# bound check succeeds
	return 0
    }
}]


##############################################################################
#	ats-backup-screen
##############################################################################
#
# SYNOPSIS:	Save the playback screendump to a separate file. It is called when 
#               vidcmp fails to match the screendump in record and in playback.
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       kliu 	11/18/96   	Initial Revision
#
##############################################################################
[defsubr ats-backup-screen {} {
    global curPath curFile

    #
    #
    # if fail, probably we want to save the PBK screen file for later use.
    
    var session [range $curFile 0 [expr [string first .tcl $curFile]-1] char]
    for {var n 1} {[file exists $curPath/ScreenDump/$session.FAIL$n]} {var n [expr $n+1]} {}
    exec cp $curPath/ScreenDump/$session.PBK $curPath/ScreenDump/$session.FAIL$n
    echo $session.PBK has been copied to $session.FAIL$n
}]
    
    


















