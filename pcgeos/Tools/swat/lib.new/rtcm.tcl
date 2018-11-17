##############################################################################
#
# 	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat system library
# FILE: 	rtcm.tcl
# AUTHOR: 	Chris Thomas, Dec  6, 1995
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#  rtcm-print-events            prints out the RTCM event list
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CT	12/ 6/95   	Initial Revision
#
# DESCRIPTION:
#	
#  Provides debugging support in swat for the RTCM library
#
#	$Id: rtcm.tcl,v 1.3.3.1 97/03/29 11:27:53 canavese Exp $
#
###############################################################################

##############################################################################
#	indent-print
##############################################################################
#
# SYNOPSIS:	Prints an indented string, maintaining indentation levels
# PASS:		str = string to print
#               itoken = a token representing the current level.
#                        If token is found in rtcmIndentStack,
#                          indentation is reset to that level,
#                          otherwise token is bound to current indent level,
#                          and pushed onto indent stack
#               preIndent = Amount to adjust rtcmIndent before printing
#               postIndent = Amount to adjust after printing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       CT 	12/ 8/95   	Initial Revision
#
##############################################################################

var rtcmIndent 0
var rtcmIndentStack {}

[defsubr indent-print {str itoken {preIndent 0} {postIndent 0}} {
    global rtcmIndent rtcmIndentStack
    var sl [length $rtcmIndentStack]
#    echo Indent: $itoken : $rtcmIndentStack
    for {var i 0} {$i < $sl} {var i [expr $i+1]} {
	if {[string match $itoken [index [index $rtcmIndentStack $i] 0]]} {
	    break
	}
    }
    if {$i < $sl} {
	#
	# Token found, reset indent to here, and remove rest of stack
	#
	var rtcmIndent [index [index $rtcmIndentStack $i] 1]
	var rtcmIndentStack [range $rtcmIndentStack $i $sl]
    } {
	#
	# Token not found : push onto stack
	#
	var rtcmIndentStack [concat [list [list $itoken $rtcmIndent]] $rtcmIndentStack]
    }
#    echo ... $rtcmIndentStack
    var rtcmIndent [expr $rtcmIndent+$preIndent]
    echo [format %*s%s $rtcmIndent {} $str]
    var rtcmIndent [expr $rtcmIndent+$postIndent]
}]
    
##############################################################################
#	fmt-string
##############################################################################
#
# SYNOPSIS:	Fetches a string from the PC, and returns it.
# PASS:		addr = address of start of string
#               
# CALLED BY:	
# RETURN:	the string.
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision (pstring)
#       martin  11/10/92        added ability to "silence" pstring
#	dloft	11/10/92	Changed how carriage returns get printed
#       CT 	12/ 7/95   	mutated for fmt-string
#
##############################################################################
[defsubr fmt-string {args} {
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

    var str {}

    if {$wide == 1} {
    	[for {var c [value fetch $s:$o [type byte]]}
    	 {$c != 0}
    	 {var c [value fetch $s:$o [type byte]]}
    	{
	    # if we encounter CR, echo "\r"
            if {$c == 0dh} {
		var str [format %s\\n $str]
            } elif {$c < 32 || $c > 127} {
		var str [format %s. $str]
            } else {
		var str [format %s%c $str $c]
    	    }
            var o [expr $o+$wide]
    	    if {![null $maxlength]} {
    	    	var maxlength [expr $maxlength-1]
    	    	if {$maxlength == 0} break
    	    }
    	}]
    } else {
    	var qp 0
    	[for {var c [value fetch $s:$o [type word]]}
    	 {$c != 0}
    	 {var c [value fetch $s:$o [type word]]}
    	{
	    # if we encounter CR, echo "\r"
            if {$c == 0dh} {
		var str [format %s\\n $str]
            } elif {$c < 32 || $c > 127} {
    	    	var str [format {%s<%s>} $str [penum geos::Chars $c]]
            } else {
        	var str [format %s%c $str $c]
    	    }
            var o [expr $o+$wide]
    	    if {![null $maxlength]} {
    	    	var maxlength [expr $maxlength-1]
    	    	if {$maxlength == 0} break
    	    }
    	}]
    }
    return $str
}]

##############################################################################
#	rtcm-fmttime
##############################################################################
#
# SYNOPSIS:	Formats an rtcm-event date/time
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       CT 	12/ 6/95   	Initial Revision
#
##############################################################################
[defsubr    rtcm-fmttime {date hour min} {
    return [rtcm-fmttime-low 
	    [expr (($date>>9)&0x7f)] 
	    [expr ($date>>5)&0xf]
	    [expr $date&0x1f]
	    $hour
	    $min]
}]

[defsubr    rtcm-fmttime-low {year month day hour min} {
    if {[expr $year<<9|$month<<5|$day] == [getvalue rtcm::WHEN_DATE_TIME_CHANGE]} {
	return DATE-TIME-CHANGE
    }
    return [format {%s/%s/%s %s:%s}
	    [num-or-wildcard $month [getvalue rtcm::ANY_MONTH]]
	    [num-or-wildcard $day [getvalue rtcm::ANY_DAY]]
	    [num-or-wildcard [expr $year+1980] 
	     [expr [getvalue rtcm::ANY_YEAR]+1980]]

	    [num-or-wildcard $hour [getvalue rtcm::ANY_HOUR] %02d]
	    [num-or-wildcard $min [getvalue rtcm::ANY_MINUTE] %02d]]
}]

[defsubr rtcm-fmttime-at {addr} {
    return [rtcm-fmttime [value fetch $addr [type word]] 
	    [value fetch $addr+2 [type word]]
	    [value fetch $addr+4 [type word]]]
}]

[defsubr num-or-wildcard {val wild-val {fmt %d}} {
  if {$val == ${wild-val}} {
      return *
  } else {
      return [format $fmt $val]
  }
}]

##############################################################################
#	rtcm-fmt-event
##############################################################################
#
# SYNOPSIS:	formats an RTCMEvent into something readable
# PASS:		id = ID of event
#		addr  = address expression of event
#               indent = amount to indent new lines of event.  First line
#                        is not indented.
#
#               If ID < 0, then print arguments on stack, as
#                 arg structure is almost identical to RTCMEvent
# CALLED BY:	
# RETURN:	the event, nicely formatted
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       CT 	12/ 6/95   	Initial Revision
#
##############################################################################
[defsubr    rtcm-fmt-event {id addr {indent 0}} {
    var event [value fetch $addr [symbol find type rtcm::RTCMEvent]]
    var free [expr [field $event RTCME_hour]==0xffff]

    if {$free && $id >= 0} {
	return [format {ID = %2d  Token = FREE} $id]
    } else {
	var time [rtcm-fmttime-low
		  [field [field $event RTCME_date] TCD_YEAR]
		  [field [field $event RTCME_date] TCD_MONTH]
		  [field [field $event RTCME_date] TCD_DAY]
		  [field $event RTCME_hour]
		  [field $event RTCME_minute]
		 ]
	var indentstr [format {%*s} [expr $indent+2] {}]
	var gm [field $event RTCME_geodeMode]
	var otherinfo [format {%sAction: %-30s %s}
		       $indentstr
		       [type emap $gm [symbol find type rtcm::RTCMGeodeLaunchMode]]
		       [if {($gm == 4) || ($gm == 6)} {
			   # Driver/Library : fetch path
			   var a [addr-parse $addr]
			   if {$id >= 0} {
			       #
			       # parsing an RTCMEvent: path comes after
			       # struct
			       #
			       var s ^h[handle id [index $a 0]]
			       var o [expr {[index $a 1] + 
				   [type size [symbol find type rtcm::RTCMEvent]]}]
			   } {
			       #
			       # Parsing RegisterEventParams: pointer to
			       # path follows common params
			       #
			       var s ^h[handle id [index $a 0]]
			       var o [expr {[index $a 1] + 
				   [index 
				    [symbol get
				     [symbol find field rtcm::REP_geodePathPtr]
				    ] 0
				   ] / 8}]
			       
			       var a [value fetch $s:$o [type dword]]
			       var s [expr $a/0x10000]
			       var o [expr $a%0x10000]
			   }
			   [fmt-string $s:$o]
		       } {
			   # Application : fetch geode token
			   [format {%s/%d}
			    [mapconcat c [field [field $event RTCME_geodeToken] GT_chars] {var c}]
			    [field [field $event RTCME_geodeToken] GT_manufID]]
		       }]]
	if {![string match $time DATE-TIME-CHANGE] && $id >= 0} {
	    var otherinfo [format {%s\n%sTimer: handle = %04xh ID = %04xh}
			   $otherinfo
			   $indentstr
			   [field $event RTCME_timerHandle]
			   [field $event RTCME_timerID]]
	}
    }
    if {$id >= 0} {
	return [format {ID = %2d  Token = %2d   %s\n%s}
		$id
		[field $event RTCME_token]
		$time
		$otherinfo]
    } {
	return [format {Time: %s\n%s}
		$time
		$otherinfo]
    }
}]

[defsubr rtcm-print-array-callback {id addr size {indent 0}} {
    global rtcmNumEvents
    var rtcmNumEvents [expr $rtcmNumEvents+1]
    echo [format %*s%s $indent {} [rtcm-fmt-event $id $addr $indent]]
    return 0
}]

##############################################################################
#	rtcm-print-events
##############################################################################
#
# SYNOPSIS:	Prints the list of registered RTCM events
# PASS:		nothing
# CALLED BY:	Command
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       CT 	12/ 7/95   	Initial Revision
#
##############################################################################
[defcommand    rtcm-print-events {args} top.rtcm 
{Usage:
    rtcm-print-events

Examples:
    "rtcm-print-events" Prints the events in RTCM's event list

Synopsis:
    Prints out the event list of RTCM in a readable way.

    -h will print the header of the chunk array before the events
       themselves.

Notes:
    * Swat may have to continue the machine to ensure the list is
      in memory

See also:
    showcalls -R

}
{
    global rtcmNumEvents
    var rtcmNumEvents 0

    var printHeader 0

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
	foreach i [explode [car $args]] {
	    [case $i in
	     h {var printHeader 1}
	    ]
	}
	var args [cdr $args]
    }
    if {[null $args]} {
	var indent 0
    } else {
	var indent [car $args]
    }
    
    var file [value fetch rtcm::EventFile]
    var block [value fetch rtcm::EventBlock]

    ensure-vm-block-resident $file $block
    if {$printHeader} {
	print rtcm::RTCMEventArrayHeader *(^v$file:$block):[value fetch rtcm::EventArray]
    }
    carray-enum *(^v$file:$block):[value fetch rtcm::EventArray] rtcm-print-array-callback $indent
    if {!$rtcmNumEvents} {
	echo [format {%*s** No events} $indent {}]
    }
}]


##############################################################################
#	rtcm-showcalls
##############################################################################
#
# SYNOPSIS:	Provides the breakpoints used in the showcalls -R command
# PASS:		
# CALLED BY:	showcalls
# RETURN:	list of breakpoints
# SIDE EFFECTS:	sets breakpoints
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       CT 	12/ 6/95   	Initial Revision
#
##############################################################################
[defsubr    rtcm-showcalls {{verbose 0} {rest {}}} {
    global rtcmVerbose
    var rtcmVerbose [expr ![null $verbose]]
    return [concat
	    [list
	     [brk rtcm::RTCMRegisterEvent rtcm-pre]
	     [brk rtcm::RTCMRegisterEvent::done rtcm-pre-end]
	     [brk rtcm::RTCMUnregisterEvent rtcm-pure]
	     [brk rtcm::RTCMUnregisterEvent::quit rtcm-pure-end]
	     [brk rtcm::SETWPT_end rtcm-pset]
	     [brk rtcm::PRF_haveEvents rtcm-ppoll]
	     [brk rtcm::HPRTE_start rtcm-pet-now]
	     [brk rtcm::HPRTE_dtnotify rtcm-pet-dtnotify]
	     [brk rtcm::RSFEC_startornot rtcm-prs]
	     [brk rtcm::RTCMProcessEvent::notExpired rtcm-ppes]
	    ]  
	    [if {![null [symbol find label rtcm::OON_wakingUp]]} {
		[brk rtcm::OON_wakingUp rtcm-ppo]
	    } {
		[format {}]
	    }]
	   ]
}]

[defsubr rtcm-pre {} {
    # prints calls to RTCMRegisterEvent
    global rtcmIndent rtcmIndentStack
    var rtcmIndent 0
    var rtcmIndentStack {}
    echo
    indent-print {RTCMRegisterEvent:} rtcm-pre 0 2
    indent-print [rtcm-fmt-event -1 [read-reg ss]:[read-reg bp] 2] rtcm-pre-e
    return 0
}]

[defsubr rtcm-pre-end {} {
    #
    # Prints return values of RTCMRegisterEvent
    #
    var error [read-reg ax]
    var token [read-reg bx]
    var id [read-reg cx]
    global rtcmVerbose

    echo -n [format {Returning: %s} [type emap $error [symbol find type rtcm::RTCMError]]]
    if {$error} {
	echo
    } {
	echo [format {  ID = %2d  Token = %2d} $id $token]
    }

    if { $rtcmVerbose } {
	echo {RTCM EVENT LIST:}
	rtcm-print-events 2
    }
    echo
    return 0
}]

[defsubr rtcm-pure {} {
    # prints calls to RTCMUnregisterEvent
    echo
    echo [format {RTCMUnregisterEvent:  ID = %2d  Token = %2d} [read-reg cx] [read-reg bx]]
    return 0
}]

[defsubr rtcm-pure-end {} {
    #
    # Prints return values of RTCMUnegisterEvent
    #
    global rtcmVerbose

    echo [format {Returning: %s} [type emap [read-reg ax] [symbol find type rtcm::RTCMError]]]

    if { $rtcmVerbose} {
	echo {RTCM EVENT LIST:}
	rtcm-print-events 2
    }
    echo
    return 0
}]

[defsubr rtcm-pset {} {
    # prints calls to StartEventTimer
    global rtcmIndent

    indent-print {Starting timer for RTCM event:} rtcm-pset 0 2
    indent-print [rtcm-fmt-event [read-reg dx] ds:di $rtcmIndent] rtcm-pset-e
    return 0
}]

[defsubr rtcm-ppoll {} {
    # prints calls to RTCMPollRoutine
    echo
    echo [format {RTCM poll of event queue finds %d new messages} [read-reg ax]]
    return 0
}]

[defsubr rtcm-pet-now {} {
    # prints out system date/time when handling events
    global rtcmIndent
    var rtcmIndent 0
    var date [value fetch nowDate]

    var out [format {RTCM thread processing new messages at %s}
	     [rtcm-fmttime-low
	      [expr [read-reg ax]-1980]
	      [read-reg bl]
	      [read-reg bh]
	      [read-reg ch]
	      [read-reg dl]
	     ]]
    
    echo
    indent-print $out rtcm-pet-now 0 2
    return 0
}]

[defsubr rtcm-pet-now {} {
    # prints out system date/time when handling events
    global rtcmIndent
    var rtcmIndent 0
    var date [value fetch nowDate]

    var out [format {RTCM thread processing new messages at %s}
	     [rtcm-fmttime-low
	      [expr [read-reg ax]-1980]
	      [read-reg bl]
	      [read-reg bh]
	      [read-reg ch]
	      [read-reg dl]
	     ]]
	      

    indent-print $out rtcm-pet-now 0 2
    return 0
}]

[defsubr rtcm-pet-dtnotify {} {
    indent-print {Received date-time change notification} process-message 0 2
    return 0
}]

[defsubr rtcm-prs {} {
    indent-print [format {Rescheduling floating event: ID = %d} [read-reg ax]] process-event 0 2
    if {[getcc s]} {
	indent-print [format {%s not reschedulable} [rtcm-fmttime-at ds:di]] rtcm-prs-nr
    }
    return 0
}]

[defsubr rtcm-ppes {} {
    global rtcmIndent
    indent-print [format {Processing event %s}
		  [if {[read-reg cx]}
		   {format {(EXPIRED)}}
		   {format {(on-time)}}]] process-message 0 2
    indent-print [rtcm-fmt-event [read-reg ax] ds:di $rtcmIndent] ppes-e 0
    
    return 0
}]

[defsubr rtcm-ppo {} {
    echo [format {Ignoring date-time change due to power on}]
    return 0
}]
