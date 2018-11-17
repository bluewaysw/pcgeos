##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	zap.tcl
# AUTHOR: 	Doug Fults , Jun 26, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	zap	    	    	Zap running patient
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	6/26/93		Initial Revision
#
# DESCRIPTION:
#	Commands/routines for getting rid of a patient
#
#	$Id: zap.tcl,v 1.3.13.1 97/03/29 11:27:38 canavese Exp $
#
###############################################################################

[defcommand zap {{zpat {}}} obscure
{Usage:
    FEATURE IN PROGRESS -- Not yet ready for prime time
    zap [<patient>]

Examples:
    "zap"			zaps last zapped or run patient
    "zap uki"			zaps Uki

Synopsis:
    "Zaps" an application as best possible.

Notes:

    * If no argument is given, zaps the last patient passed to this command or
      started up using "run"

    * If the machine stops for any other reason other than the call's
      completion, you are left wherever the machine stopped.

    * This function is only "reasonably" robust at this time.  Performs well
      at Idle or after a Ctrl-C.

See also:
	send, run
}
{
    global defaultPatient
    if {[null $zpat]} {
	if {[null $defaultPatient]} {
		error {Sorry, default patient not known}
	} else {
		var zpat $defaultPatient
	}
    }
    # save for next time
    var defaultPatient $zpat
    var threads [patient threads [patient find $zpat]]
    var remote 0
    foreach i $threads {
	switch $zpat:[thread number $i]
	var at [func]
	echo $at
	if {[string match $at WaitForRemoteCall]} {var remote [expr $remote+1]}
    }
    echo Remote calls:  $remote

    var geode [handle id [index [patient resource [patient find $zpat]] 0]]

    #if {[detach-patient $zpat]} {error}
}]


[defsubr detach-patient {dpat}
{
    omfq MSG_META_DETACH $dpat cx 0 dx 0 bp 0
    var bp [brk Idle]
    stop-catch {
	continue-patient
	var abortFlag [wait]
    }
    brk clear $bp
    return $abortFlag
}]

[defsubr zap-geode {geode}
{
    assign {word debug::debugGeode} $geode
    omfq debug::MSG_DEBUG_ZAP_APP debug
    var bp [brk Idle]
    stop-catch {
	continue-patient
	var abortFlag [wait]
    }
    brk clear $bp
    return $abortFlag
}]

[defcommand test {} obscure
{
}
{
	echo [get-crashed-threads [thread all]]
}]

[defsubr get-crashed-threads {threads}
{
    foreach i $threads {
	var thisThread {}
	var name [patient name [handle patient [thread handle $i]]]:[thread number $i]
	var nameForSwitch $name
	switch $nameForSwitch
	var at [func]
	if {[string match $at FatalError]} {
		var thisThread [list [list $i $name FatalError]]
	}
	var fc [index $at 0 char]
	if {!([string c $fc 0]==-1) && !([string c $fc 9]==1)} {
		var thisThread [list [list $i $name IllegalInstruction]]
	}
	if {![null $thisThread]} {
		if {[null $badThreads]} {
			var badThreads $thisThread
		} else {
			var badThreads [list $badThreads $thisThread]
		}
	}
    }
    return $badThreads
}]

