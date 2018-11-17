##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	analysis.tcl
# AUTHOR: 	Tony Requist
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	analbrk	    	    	Set analysis breakpoints
#
#
# DESCRIPTION:
#	Functions for doing analysis
#
#	$Id: analysis.tcl,v 1.39.3.1 97/03/29 11:28:14 canavese Exp $
#
###############################################################################

defvar analbrklist {}

##############################################################################
#				analbrk
##############################################################################
#
# SYNOPSIS:	Set tally breakpoints for analysis
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	4/14/92		Initial Revision
#
##############################################################################
[defcommand analbrk {args} profile
{Usage:
    analbrk [-hmlif] 	    Set one or more groups of tally breakpoints
    analbrk clear   	    Delete all breakpoints set with this command
    analbrk reset   	    Reset the counters for all breakpoints set
			    with this command.

Examples:
    "usage"	Explanation

Synopsis:
    Sets groups of tally breakpoints for various areas in the system.

Notes:
    * The various flags you can give mean:
	-h : heap
	-m : message and resource calls
	-l : local memory
	-i : .ini file
	-f : file system
    	-g : graphics
    	-r : relocation

See also:
    restally, workset
}
{
    global analbrklist geos-release

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [index $arg 0 chars] in
		h { addanalbrk {
    	    	    MoveBlock CompactHeap ThrowOutBlocks ThrowOutOne
    	    	    AllocHandleAndBytes LMemCompactHeap::doMove
    	    	    LoadResourceLow CompactHeap::blockLoop
    	    	    FindFree SearchHeap SearchHeap::blockLoop
    	    	    FindNOldest LMemCompactHeap::startCompact
    	    	}}
    	    	m {
    	    	    if {${geos-release} < 2} {
    	    	    	addanalbrk {
    	    	    	    ObjCallMethodTable ResourceCallInt
    	    	    	    ProcCallModuleRoutine
    	    	    	}
    	    	    } else {
    	    	    	addanalbrk {
    	    	    	    ObjCallMethodTable ResourceCallInt
    	    	    	    ProcCallModuleRoutine ProcCallFixedOrMovable
    	    	    	    ObjMessage::recordMode
    	    	    	}
    	    	    }
    	    	}
    	    	l { addanalbrk {
    	    	    LMemAlloc LMemReAlloc LMemFree
    	    	}}
    	    	r { addanalbrk {
    	    	    LockOrUnlockImportedLibraries RelocOrUnRelocObj RelocateLow
    	    	    UnRelocateLow DoRelocation
    	    	}}
    	    	g { addanalbrk {
    	    	    GrCreateState GrDestroyState EnterGraphics GrFillRect
    	    	}}
    	    	i {
    	    	    if {${geos-release} < 2} {
    	    	    	addanalbrk {
    	    	    	    InitFileWriteData InitFileWriteString
    	    	    	    InitFileWriteInteger InitFileWriteBoolean
    	    	    	    InitFileGetData InitFileGetString
    	    	    	    InitFileGetStringSection InitFileGetInteger
    	    	    	    InitFileGetBoolean InitFileGetTimeLastModified
    	    	    	    InitFileBackup InitFileRestore InitFileCommit
    	    	    	    InitFileDeleteEntry InitFileDeleteCategory
    	    	    	}
    	    	    } else {
    	    	    	addanalbrk {
    	    	    	    InitFileWriteData InitFileWriteString
    	    	    	    InitFileWriteInteger InitFileWriteStringSection
    	    	    	    InitFileReadData InitFileReadString
    	    	    	    InitFileWriteBoolean InitFileReadInteger
    	    	    	    InitFileReadBoolean InitFileReadStringSection
    	    	    	    InitFileEnumStringSection
    	    	    	    InitFileGetTimeLastModified InitFileSave
    	    	    	    InitFileRestore
    	    	    	}
    	    	    }
    	    	}
    	    	f {
    	    	    if {${geos-release} < 2} {
    	    	    	addanalbrk {
    	    	    	    FileOpen FileClose FileRead FileWrite FilePos
    	    	    	    FileEnum Int21
    	    	    	}
    	    	    } else {
    	    	    	addanalbrk {
    	    	    	    FileOpen FileClose FileRead FileWrite FilePos
    	    	    	    FileEnum FSDInt21
    	    	    	}
    	    	    }
    	    	}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }
    #
    # if there is anything left then do it
    #
    if {[length $args] > 0} {
    	[case [index $args 0] in
    	    clear {
    	    	foreach i $analbrklist {
    	    	    tbrk clear $i
    	    	}
    	    	var analbrklist {}
    	    	echo {Analysis breakpoints cleared}
    	    }
    	    reset {
    	    	foreach i $analbrklist {
    	    	    tbrk reset $i
    	    	}
    	    	echo {Analysis breakpoints reset to 0}
    	    }
    	]
    }
}]


[defsubr addanalbrk {alist}
{
    global analbrklist

    foreach i $alist {
    	var analbrklist [concat [tbrk $i] $analbrklist]
    }
}]

##############################################################################
#				workset
##############################################################################
#
# SYNOPSIS:	Do working set analysis on a geode
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	4/14/92		Initial Revision
#
##############################################################################
[defcommand workset {args} profile
{Usage:
    workset start <geode> [flags]   Start working set analysis on <geode>
    workset end	    	    	    End working set analysis
    workset time <num>	    	    Define a working set to be <num> seconds
    	    	    	    	    (0 means forever, default is 5)
    workset summary    	    	    Print working set information -- summary
    workset info [sort fields] 	    Print working set information -- full

Examples:
    "workset start desktop" Begins collecting working set information for
			    the patient named "desktop"

Synopsis:
    This uses hooks in the EC kernel to provided working-set information for
    a particular geode. The working-set of a geode is the set of blocks
    that have been used in the recent past (the exact amount of time is
    configurable).

Notes:
    * The working set for all geodes can be tracked by using "workset start all"

    * The optional parameter to "workset start" specifies the type(s) of
      resources to be analyzed.  The default is "code".  The options
      are:
    	* code -- analyze code resources
    	* object -- analyze object resources
    	* fixed -- include fixed resources

    * The optional parameter(s) to "workset info" changes how the output is
      sorted.  The default is "inws".  The options are:
    	* inws -- sort by time in the working set (the default)
    	* inuse -- sort by in use time
    	* patient -- sort by patient
    	* ws -- sort by whether the resource is currently in the working set
    	* uses -- sort by the number of times the resource has been used
    	* loads -- sort by the number of times the resource has been loaded
    	* size -- sort by resource size
        * total -- sort by total amount of loads caused by this resource

    * "workset summary" gives a brief description of the parameters of the
      current working set.

    * All time values are in seconds, in the format <seconds>:<ticks>. Each
      tick is 1/60th of a second.

    * "workset info" gives a complete breakdown of the working-set by resource.
      The table produced is divided into the following columns:
      
      	Resource Name	    The name of the resource whose info is on that
			    line.
    	W Set	    	    "Yes"/"No" tell whether it is/isn't currently in
			    the working-set. A '*' indicates the resource was
			    a part of the maximum working-set (the largest
			    working-set seen so far), regardless of whether
			    it's currently in.
    	% In WS	    	    The percent of the time the resource has been in
			    the working-set.
    	Uses	    	    The number of calls to routines in the resource
    	    	    	    from outside the resource.
    	Loads	    	    The number of times the resource was loaded. The
			    number in parentheses indicates the number of those
			    times that the resource was already in the working-
			    set when it was loaded (this is a measure of the
			    thrashing of the system)
    	Last Use    	    Time (in seconds) since last use.
    	Status	    	    The resource's current status: "Loaded", "Swapped",
			    or "Discarded"
			    
    * PC-SDK: To use this command, you must run the non-error-checking
      version of Geos (GEOSNC) and select "GEOS Profiling Kernel - Workset"
      via the Debug application.

See also:
    restally
}
{
    global wsStartTime wsFixed

    if {[null $args]} {
    	echo {workset: commands: start, end, time, summary, info}
    } else {
	[case [index $args 0] in
	    start {
    	    	if {![string c [index $args 1] all]} {
    	    	    value store wsGeode 0
    	    	} else {
    	    	    value store wsGeode [handle id [index [patient resources
    	    	    	    	    	    [patient find [index $args 1]]] 0]]
    	    	}
    	    	if {[length $args] > 2} {
    	    	    var flags [range $args 2 end]
    	    	} else {
    	    	    var flags {code}
    	    	}
    	    	var bits 0
    	    	var wsFixed 0
    	    	foreach i $flags {
    	    	    [case $i in
    	    	    	code {
    	    	    	    var bits [expr $bits|[fieldmask WSF_CODE]]
    	    	    	}
    	    	    	object {
    	    	    	    var bits [expr $bits|[fieldmask WSF_OBJECT]]
    	    	    	}
    	    	    	fixed {
    	    	    	    var wsFixed 1
    	    	    	}
    	    	    ]
    	    	}
    	    	value store wsFlags $bits byte
    	    	value store wsSize 0
    	    	value store maxWSSize 0
    	    	value store wsTotalSize 0
    	    	value store wsTotalCode 0
    	    	value store wsResCount 0
    	    	value store wsCodeCount 0
    	    	value store wsResourceList 0 word
    	    	var wsStartTime [value fetch systemCounter word]
    	    	echo [format {Starting working set analysis for %s}
    	    	    	    	    	    [index $args 1]]
	    }
	    end {
    	    	value store wsGeode 0
    	    	echo [format {Working set analysis ended}]
	    }
	    time {
    	    	value store workingSetTime [index $args 1]
    	    	echo [format {Working set defined as %s seconds}
    	    	    	    [format-seconds [index $args 1]]]
	    }
	    summary {
    	    	wssummary 0 0 0 0 0
	    }
	    info {
    	    	var off 0
    	    	var result {}
    	    	var sysCount [value fetch systemCounter word]
    	    	var totalTime [expr $sysCount-$wsStartTime]
    	    	var all [expr [value fetch wsGeode]==0]
    	    	var wsBoth [expr [field [value fetch wsFlags] WSF_CODE]&&[field
    	    	    	    	    	    [value fetch wsFlags] WSF_OBJECT]]
    	    	if {[length $args] > 1} {
    	    	    var sortFields [range $args 1 end]
    	    	} else {
    	    	    var sortFields {inws}
    	    	}
    	    	var totalCurrentSize 0 totalLoaded 0 totalLoads 0 totalWSLoads 0
    	    	while {[value fetch {wsResourceList[$off].WSRE_handle}] != 0} {
    	    	    var blk [value fetch {wsResourceList[$off].WSRE_handle}]
    	    	    var entry [value fetch {wsResourceList[$off]}]
    	    	    var currentSize [expr [value fetch kdata:$blk.HM_size]*16]
    	    	    var totalCurrentSize [expr $totalCurrentSize+$currentSize]
    	    	    var totalLoaded [expr $totalLoaded+($currentSize*[field
    	    	    	    	    	    	    	$entry WSRE_loads])]
    	    	    var totalLoads [expr $totalLoads+[field $entry WSRE_loads]]
    	    	    var totalWSLoads [expr $totalWSLoads+[field
    	    	    	    	    	    	    $entry WSRE_loadsInWS]]
    	    	    var line [ws-format-line $entry $sortFields $totalTime
    	    	    	    	    	     $wsBoth $all $sysCount]
    	    	    var result [concat $result $line]
    	    	    var off [expr $off+1]
if {$off == 1000} { break }
    	    	}
    	    	#
    	    	# Now go through the heap and add entries for each fixed block
    	    	#
    	    	var han [value fetch loaderVars.KLV_handleBottomBlock]
    	    	var continue $wsFixed
    	    	var fixedCount 0
    	    	var fixedSize 0
    	    	while {$continue} {
    	    	    var data [value fetch kdata:$han HandleMem]
    	    	    var own [field $data HM_owner]
    	    	    var target [value fetch wsGeode]
    	    	    if {$own != 0} {
    	    	    	if {![field [field $data HM_flags] HF_FIXED]} {
    	    	    	    var continue 0
    	    	    	} else {
    	    	    	    if {$all || ($own == $target)} {
    	    	    	    	var fixedCount [expr $fixedCount+1]
    	    	    	    	var fixedSize [expr $fixedSize+16*[field
    	    	    	    	    	    	    	    $data HM_size]]
				var entry [list
				    [list WSRE_handle {} $han]
				    {WSRE_uses {} 0}
				    {WSRE_loads {} 1}
				    {WSRE_loadsInWS {} 0}
				    {WSRE_lastUse {} 0}
				    {WSRE_inUseStart {} 0}
				    {WSRE_totalInUse {} $totalTime}
				    {WSRE_totalInWS {} $totalTime}
				    {WSRE_flags {} {
					{WSRF_IN_USE {} 1}
					{WSRF_IN_WORKING_SET {} 1}
					{WSRF_IN_MAX_WORKING_SET {} 1}
				    }}
				]
				var line [ws-format-line $entry $sortFields
						    $totalTime $wsBoth $all
						    $sysCount]
				var result [concat $result $line]
    	    	    	    }
    	    	    	}
    	    	    }
    	    	    var han [field $data HM_next]
    	    	}
    	    	var result [sort -n -r $result]
    	    	var gval {}
    	    	[wssummary $fixedCount $fixedSize
    	    	    	   $totalLoaded $totalLoads $totalWSLoads]
    	    	if {[field [value fetch wsFlags] WSF_OBJECT]} {
    	    	    echo [format
    	    	    	    {Total *current* size of all resources is %d bytes}
    	    	    	    $totalCurrentSize]
    	    	}

    	    	echo
    	    	echo -n {Resource Name           W Set % InWS  Uses }
    	    	echo {%InUse  Loads   Size  LastUse Stat}
    	    	echo -n {-------------           ----- ------  ---- }
    	    	echo {------  -----   ----  ------- ----}
    	    	foreach i $result {
    	    	    if {![null $gval]} {
    	    	    	if {$gval != [index $i 1]} {
    	    	    	    echo {---}
    	    	    	}
    	    	    }
    	    	    echo [index $i 2]
    	    	    var gval [index $i 1]
    	    	}
	    }
	    * {
		echo [format {workset: command %s not recognized}
    	    	    	    	    	    [index $args 0]]
	    }
    	]
    }
}]

[defsubr ws-format-line {entry sortFields totalTime wsBoth all sysCount} {
    var wsPercent [expr
	100*([field $entry WSRE_totalInWS]/$totalTime) f]
    var usePercent [expr
	100*([field $entry WSRE_totalInUse]/$totalTime) f]
    if {[field [field $entry WSRE_flags] WSRF_IN_WORKING_SET]} {
	var inWS {Yes}
    } else {
	var inWS {No }
    }
    if {[field [field $entry WSRE_flags]
				WSRF_IN_MAX_WORKING_SET]} {
	var inMaxWS {*}
    } else {
	var inMaxWS { }
    }
    var han [field $entry WSRE_handle]
    var num 2
    if {[field $entry WSRE_loads] > 9} { var num 1 }
    if {[field $entry WSRE_loadsInWS] > 9} {
	var num [expr $num-1]
    }
    var lu [format-seconds
	    [expr $sysCount-[field $entry WSRE_lastUse]]]

    var htok [handle lookup $han]
    var pat [handle patient [handle owner $htok]]
    if {[null $htok] || !([handle state $htok] & 0x80)} {
    	var name [patient name $pat]
	if {[handle state $htok] & 0x800} {
	    var name [format {O: %s:: %04xh} $name $han]
	} else {
	    var name [format {D: %s:: %04xh} $name $han]
	}
    } else {
	if {$wsBoth} {
	    if {[handle state $htok] & 0x800} {
		var name {O: }
	    } else {
		var name {C: }
	    }
	} else {
	    var name {}
	}
	if {$all} {
	    var name $name[symbol fullname
				[handle other $htok] w]
	} else {
	    var name $name[symbol name [handle other $htok]]
	}
    }

    var sval 0
    var gval 0
    foreach i $sortFields {
	[case $i in
	    ws { var sval [expr
		($sval<<1)+[string c $inWS Yes]]
	    }
	    inws { var sval [expr
		(10000*$sval)+(10000*[field $entry
				WSRE_totalInWS])/$totalTime]
	    }
	    inuse { var sval [expr
		(10000*$sval)+(10000*[field $entry
				WSRE_totalInUse])/$totalTime]
	    }
	    patient {
		var gval [handle id [index [patient resources $pat] 0]]
    	    	var sval [expr ($sval*10000000)+$gval]
	    }
	    uses { var sval [expr
		($sval*100000)+[field $entry WSRE_uses]]
	    }
	    loads { var sval [expr
		($sval*100000)+[field $entry WSRE_loads]]
	    }
	    size { var sval [expr
		($sval<<15)+[value fetch kdata:$han.HM_size]]
	    }
	    total { var sval [expr
		($sval*100000000)+([value fetch kdata:$han.HM_size]*[field $entry WSRE_loads])]
	    }
	]
    }
    var line [format {%-23.23s %s %s %5.1f%% %5d %5.1f%%  %d (%d)%*s%5d  %-6s  }
	    $name $inWS $inMaxWS $wsPercent
	    [field $entry WSRE_uses] $usePercent
	    [field $entry WSRE_loads]
	    [field $entry WSRE_loadsInWS]
	    $num { }
	    [expr 16*[value fetch kdata:$han.HM_size]] $lu]
    var flags [value fetch kdata:$han.HM_flags]
    if {[field $flags HF_SWAPPED]} {
	var line [format {%sSwap'd} $line]
    } elif {[field $flags HF_DISCARDED]} {
	var line [format {%sDisc'd} $line]
    } else {
	var line [format {%sLoaded} $line]
    }
    return [list [concat $sval $gval [list $line]]]
}]

##############################################################################
#				wssummary
##############################################################################
#
# SYNOPSIS:	    Provide a summary of the current working-set parameters
# PASS:		    nothing
# CALLED BY:	    workset
# RETURN:	    nothing
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	4/15/92		Initial Revision
#
##############################################################################
[defsubr wssummary {fixedCount fixedSize totalLoaded totalLoads totalWSLoads}
{
    global wsStartTime wsFixed

    var g [value fetch wsGeode]
    var totalSize [expr $fixedSize+16*[value fetch wsTotalSize]]
    var totalCount [expr $fixedCount+[value fetch wsResCount]]

    if {$g == 0} {
    	echo [format {Working set information for all geodes}]
    } else {
    	echo [format {Working set information for geode: %s}
    	    	    [patient name [handle patient [handle lookup $g]]]]
    }
    echo -n [format {Total analysis time is %s seconds} [format-seconds
    	    	[expr [value fetch systemCounter word]-$wsStartTime]]]
    var time [value fetch workingSetTime]
    if {$time > 0} {
    	echo [format {, working set is %s seconds} [format-seconds $time]]
    } else {
    	echo [format {, working set is infinite time}]
    }
    echo -n [format {Current working set size is %d bytes}
    	    	    	    [expr $fixedSize+16*[value fetch wsSize]]]
    echo [format {, max working set size is %d bytes}
    	    	    	    	  [expr $fixedSize+16*[value fetch maxWSSize]]]
    echo [format {Total size of all resources is %d bytes (in %d resources)}
    	    	    	    	  $totalSize $totalCount]
    if {$totalLoaded > 0} {
    	echo [format {Total of all loads is %d bytes (in %d(%d) loads)}
    	    	    	    	  $totalLoaded $totalLoads $totalWSLoads]
    }
    if {$fixedCount > 0} {
    	echo [format {Total fixed size is %d bytes (in %d resources)}
    	    	    	    $fixedSize $fixedCount]
    }

    if {[expr [field [value fetch wsFlags] WSF_CODE]&&[field
    	    	    	    	    [value fetch wsFlags] WSF_OBJECT]]} {
    	echo [format {%d bytes in %d code resources, %d bytes in %d object resources}
    	    	[expr $fixedSize+16*[value fetch wsTotalCode]]
    	    	[expr $fixedCount+[value fetch wsCodeCount]]
    	    	[expr 16*([value fetch wsTotalSize]-[value fetch wsTotalCode])]
    	    	[expr [value fetch wsResCount]-[value fetch wsCodeCount]]]
    }
    echo -n {Resource flags set: }
    [precord WSFlags [value fetch wsFlags byte] 1]
    if {$wsFixed} {
    	echo {Fixed resources included also}
    }
}]

##############################################################################
#				format-seconds
##############################################################################
#
# SYNOPSIS:	    Format a number of ticks as <seconds>:<ticks>, much
#		    as a number of seconds can be formatted as <min>:<sec>
# PASS:		    ticks   = number of ticks
# CALLED BY:	    ?
# RETURN:	    the formatted result
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	4/15/92		Initial Revision
#
##############################################################################
[defsubr format-seconds {ticks}
{
    var seconds [expr $ticks/60]
    var ticks [expr $ticks-($seconds*60)]
    return [format {%d:%d} $seconds $ticks]
}]

##############################################################################
#				restally
##############################################################################
#
# SYNOPSIS:	Tally calls to routines in a resource
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	4/14/92		Initial Revision
#
##############################################################################
[defcommand restally {args} profile
{Usage:
    restally start <resource>	Start analysis on the given resource.
    restally -n start <resource> Includes near routines in analysis 
    restally end    	    	End analysis
    restally info [args]    	Print analysis data


Examples:
    restally start CommonCode
    restally start CommonCode ObscureCode

Synopsis:
    Sets tally break points at routines in resources
    You may pass multiple resources

Notes:
    * "restally info" can take the following arguments:
    	nonzero (or nz) - print only routines that are actually called
    	zero - print only routines with zero calls
    	min N - print only routines called N or more times
        max N - print only routines called N or less times

    * tally break points require 24 bytes each. You will probably need
      to up the size of swat's break point heap. To do this pass the
      /h:xxxx flag to swat, where xxxx is the size in bytes of the
      heap you desire.

See also:
    workset
}
{
    global rtmodule rtlist rterror

    if {[null $args]} {
    	echo {restally: commands: start, end, time, summary, info}
    } else {
	var near 0
    	var minRoutine 0 maxRoutine 65535 matchRoutine {}
	while {[string m [index $args 0] -*]} {
	    var arg [range [index $args 0] 1 end chars]
	    var args [cdr $args]
	    while {![null $arg]} {
	        [case [index $arg 0 chars] in
		    n {
    	    	    	var near 1
    	    	    }
		    r {
    	    	    	var minRoutine [index [sym get
    	    	    	    	    	    [sym find proc [car $args]]] 0]
    	    	    	var args [cdr $args]
    	    	    	var maxRoutine [index [sym get
    	    	    	    	    	    [sym find proc [car $args]]] 0]
    	    	    	var args [cdr $args]
    	    	    }
		    m {
    	    	    	var matchRoutine [car $args]
    	    	    	var args [cdr $args]
    	    	    }
	        ]
	        var arg [range $arg 1 end chars]
	    }
	}
	[case [index $args 0] in
	    start {
    	    	clear-restally
       	    	var rterror 0
		for {var i 1} {$i < [length $args]} {var i [expr $i+1]} {
    	    	    var rtmodule [symbol find module [index $args $i]]
		    if {[null $rtmodule]} {
			echo [format {%s is not a resource} [index $args $i]]
		    } else {
			echo \nSetting breakpoints for [index $args $i]
			symbol foreach $rtmodule proc setrtbrk [list
				$near $minRoutine $maxRoutine $matchRoutine]
		    }	
    	    	    if {$rterror} {
    	    	        echo \nError setting breakpoints in [index $args $i]
    	    	        clear-restally
			break
    	    	    }
		}
    	    	if {!$rterror} {
	            echo \n[length $rtlist] breakpoints set 
		}
	    }
	    end {
    	    	clear-restally
    	    	echo {Resource call analysis ended}
	    }
	    info {
    	    	var total 0
    	    	var min 0 max 10000000
    	    	if {[length $args] > 1} {
		    [case [index $args 1] in
			zero {
			    var max 0
			}
			{nonzero nz} {
			    var min 1
			}
    	    	    	min {
    	    	    	    var min [index $args 2]
    	    	    	}
    	    	    	max {
    	    	    	    var max [index $args 2]
    	    	    	}
			* {
			    echo [format {Argument <%s> not recognized} $i]
			}
		    ]
    	    	}
    	    	var result [sort -n -r [map i $rtlist {
    	    	    if {[catch {tbrk count $i} c] == 0} {
			var s [index [tbrk symbol $i] 0]
			var total [expr $total+$c]
			var line [format {%-50.50s %5d} [symbol name $s] $c]
			list $c $line
    	    	    } else {
		    	list -1 {}
    	    	    }
    	    	}]]
    	    	echo [format {Resource call data for resource: %s}
    	    	    	    	[sym name $rtmodule]]
    	    	echo [format {Total calls to resource: %d} $total]
    	    	echo
    	    	echo {Routine                                         # calls}
    	    	echo {-------                                         -------}
    	    	foreach i $result {
		    var c [index $i 0]
    	    	    if {($c != -1) && ($c >= $min) && ($c <= $max)} {
    	    	    	echo [index $i 1]
    	    	    }
    	    	}
	    }
	    * {
		echo [format {restally: command %s not recognized}
    	    	    	    	    	    [index $args 0]]
	    }
    	]
    }
}]

[defsubr setrtbrk {sym params}
{
    global rtlist rterror

    # params are: $near $minRoutine $maxRoutine $matchRoutine

    if {[index $params 0] || ![string c [index [symbol get $sym] 1] far]} {
    	if {$rterror} {
    	    echo -n {E}
    	} else {
    	    var off [index [sym get $sym] 0]
    	    if {([null [index $params 3]] ||
    	    	    	    	[string m [sym name $sym] [index $params 3]]) &&
    	    	($off >= [index $params 1]) && ($off <= [index $params 2])} {
		if {[catch {
			var rtlist [concat [tbrk [symbol fullname
    	    	    	    	    	    	    $sym]] $rtlist]}]} {
		    var rterror 1
		    echo -n {E}
		} else {
		    echo -n {.}
		}
    	    } else {
    	    	echo -n {x}
    	    }
    	}
	flush-output
    }
}]

[defsubr clear-restally {}
{
    global rtlist

    echo -n Removing breakpoints.
    if {[length $rtlist] > 10} {
        echo { A moment please...}
    } else {
	echo
    }
    foreach i $rtlist {
    	tbrk clear $i
    }
    var rtlist {}
}]



##############################################################################
#			Recorded Message functions
##############################################################################

##############################################################################
#				rmsg
##############################################################################
#
# SYNOPSIS:	User command/subroutine to report recorded message data
# PASS:		command	= print
#			  reset
#			  debug
#		sortBy	= count
#			  message
#		floor	= value greater > 0
# CALLED BY:	User
# RETURN:	mothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don	4/18/92		Initial Revision
#
##############################################################################

[defcommand rmsg {{command print} {groupBy message} {sortBy count} {floor 0}}
		  profile
{Usage:
    rmsg
    rmsg (on|off)
    rmsg print <group-by> <sort-by> <lower-bound>
    rmsg header
    rmsg reset

Examples:
    "rmsg on"				Turn message recording on. This does
					*not* reset the recording buffer.

    "rmsg off"				Turn message recording off. This does
					*not* reset the recording buffer.

    "rmsg"				Print listing of all recorded messages,
					sorting by mesage/class count.

    "rmsg print class count 5"		Print listing of all recorded messages
					invoked 5 or more times

    "rmsg print message time"		Print listing of all recorded messages,
					grouped by message number & sorted by
					time spent in the method handlers
					across all classes

    "rmsg reset"			Reset the recorded message counts

    "rmsg debug"			Print debugging information for
					recorded messages

Synopsis:
    Print a report of all recorded messages, in decreasing order of use.

Notes:
    * Messages can be grouped by either the message sent, or the class of object
      to which the message was sent. This is controlled by the <group-by>
      argument to "rmsg print". <group-by> can be either "message" or "class".

    * Message groups can be sorted either by the number of times they were
      sent, or the amount of time spent processing the message. The
      <sort-by> parameter determines which, and can be either "count" or "time".
    
    * The <sort-by> argument also determines the meaning of the <lower-bound>
      argument. If <sort-by> is "count", this will not print out a message
      unless it was sent at least <lower-bound> times. If <sort-by> is "time",
      this will not print out a message unless it took longer than
      <lower-bound> (a real number) seconds.

    * The number of unrecorded messages, if non-zero, indicates the number of
      times ObjCallMethodTable was invoked with a message & class that couldn't
      be stored due to insufficient space in the table. If you need room for
      additional messages, increase the constant NUM_RECORDED_MESSAGE_ENTRIES

    * PC-SDK: To use this command, you must run the non-error-checking
      version of Geos (GEOSNC) and select "GEOS Profiling Kernel - Messages"
      via the Debug application.

See also:
    prmsg, int21
}
{
	#
	# Invoke the requested function
	#
	if {![string compare $command on]} {
		[value store recMsgState 0xffff]
		echo {Message recording is ON!}

	} elif {![string compare $command off]} {
		[value store recMsgState 0x0000]
		echo {Message recording is OFF!}

	} elif {![string first $command print]} {
		[prmsg $groupBy $sortBy $floor]

	} elif {![string first $command reset]} {
		#
		# Reset the header structure
		#
		var addr [addr-parse recMsgHeader]
		var seg [handle segment [index $addr 0]]
		var off [index $addr 1]
		var entries [value fetch $seg:$off.RMH_usedEntries]
		[value store $seg:$off.RMH_usedEntries 0]
		[value store $seg:$off.RMH_freeEntries 
			[expr [symbol get
			[symbol find const NUM_RECORDED_MESSAGE_ENTRIES]]+1]]
			[value store $seg:$off.RMH_unrecorded 0]
		#
		# Reset the elapsed time values
		#
		echo {Initializing time counts...}
		var addr [addr-parse recMsgTable]
		var seg [handle segment [index $addr 0]]
		var off [index $addr 1]
		while {$entries} {
			[value store $seg:$off 0 dword]
			var off [expr $off+[size RecordedMessageEntry]]
			var entries [expr $entries-1]
		}

	} elif {![string first $command debug]} {
		echo {Printing recMsgHeader:}
		print recMsgHeader

	} else {
		echo {rmsg - command not understood}
		help rmsg
	}
}]

##############################################################################
#				prmsg
##############################################################################
#
# SYNOPSIS:	User command/subroutine to print the recorded messages
# PASS:		nothing
# CALLED BY:	User
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don	4/14/92		Initial Revision
#
##############################################################################

[defcommand prmsg {{groupBy message} {sortBy count} {floor 0}} profile
{Usage:
    prmsg <group-by> <sort-by> <lower-bound>

Examples:
    "prmsg"				Print listing of all recorded messages

    "prmsg class count 5"		Print listing of all recorded messages
					invoked 5 or more times

    "prmsg message time"		Print listing of all recorded messages,
					grouped by message number & sorted by
					time in total invocations across all
					classes

Synopsis:
    Print a listing of all the recorded messages, in decreasing order of use

Notes:
    * The number of unrecorded messages, if non-zero, indicates the number of
      times ObjCallMethodTable was invoked with a message & class that couldn't
      be stored due to insufficient space in the table. If you need room for
      additional messages, increase the constant NUM_RECORDED_MESSAGE_ENTRIES

    * Messages can be grouped by either the message sent, or the class of object
      to which the message was sent. This is controlled by the <group-by>
      argument to "rmsg print". <group-by> can be either "message" or "class".

    * Message groups can be sorted either by the number of times they were
      sent, or the amount of time spent processing the message. The
      <sort-by> parameter determines which, and can be either "count" or "time".
    
    * The <sort-by> argument also determines the meaning of the <lower-bound>
      argument. If <sort-by> is "count", this will not print out a message
      unless it was sent at least <lower-bound> times. If <sort-by> is "time",
      this will not print out a message unless it took longer than
      <lower-bound> (a real number) seconds.

See also:
    rmsg
}
{
	#
	# Some set-up work
	#
	var addr [addr-parse recMsgHeader]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	var msgs [value fetch $seg:$off.RMH_usedEntries]
	var totalUnrec [value fetch $seg:$off.RMH_unrecorded]
	var totalMsgs [expr $msgs]
	var totalCount [expr $totalUnrec]
	var listedCount [expr 0]
	var addr [addr-parse recMsgTable]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	var header1 {}
	var header2 {}
	var format1 {}
	var format2 {}
	#
	# Now count messages in a myriad of different ways
	#
	if {![string first $groupBy class]} {
	    #
	    # Group data by message/class
	    #
	    if {![string first $sortBy count]} {
		#
		# Sort by count
		#
		echo {Tabulating data, grouping by class, sorting by count...}
		while {$msgs > 0} {
		    var count [value fetch $seg:$off.RME_count]
		    var totalCount [expr $totalCount+$count]
		    if {$count >= $floor} {
			var listedCount [expr $listedCount+$count]
			var message [value fetch $seg:$off.RME_message]
			var class_seg [value fetch $seg:$off.RME_class.segment]
			var class_off [value fetch $seg:$off.RME_class.offset]
			var timeT [value fetch $seg:$off.RME_elapsedTime.high]
			var timeU [value fetch $seg:$off.RME_elapsedTime.low]
			var time [expr $timeT+[expr $timeU/19886 f] f]
			var s [sym faddr var $class_seg:$class_off]
			var class_name [sym fullname $s]
			var msg_name [resolve-message $message $class_name]
			var class_root [range $class_name
			    [expr [string last {::} $class_name]+2] end chars]
			var all [concat $all [list [list
				$count
				$time
				$msg_name
				$class_root]]]
		    }
		    var off [expr $off+[size RecordedMessageEntry]]
		    var msgs [expr $msgs-1]
		}
		var header1 {Count Time(ticks) Message, Class}
		var header2 {----- ----------- --------------}
		var format1 {%5d %11.4f %s, %s}
	   } elif {![string first $sortBy time]} {
		#
		# Sort by time
		#
		echo {Tabulating data, grouping by class, sorting by time...}
		while {$msgs > 0} {
		    var count [value fetch $seg:$off.RME_count]
		    var totalCount [expr $totalCount+$count]
		    var timeT [value fetch $seg:$off.RME_elapsedTime.high]
		    var timeU [value fetch $seg:$off.RME_elapsedTime.low]
		    var time [expr $timeT+[expr $timeU/19886 f] f]
		    if {$timeT >= $floor} {
			var listedCount [expr $listedCount+$count]
			var message [value fetch $seg:$off.RME_message]
			var class_seg [value fetch $seg:$off.RME_class.segment]
			var class_off [value fetch $seg:$off.RME_class.offset]
			var s [sym faddr var $class_seg:$class_off]
			var class_name [sym fullname $s]
			var msg_name [resolve-message $message $class_name]
			var class_root [range $class_name
			    [expr [string last {::} $class_name]+2] end chars]
			var all [concat $all [list [list
				$time
				$count
				$msg_name
				$class_root]]]
		    }
		    var off [expr $off+[size RecordedMessageEntry]]
		    var msgs [expr $msgs-1]
		}
		var header1 {Time(ticks) Count Message, Class}
		var header2 {----------- ----- --------------}
		var format1 {%11.4f %5d %s, %s}
	    } else {
		echo {Group by class, sort by what?!}
		return 0
	    }
	} elif {![string first $groupBy message]} {
	    #
	    # Group data by message
	    #
	    if {![string first $sortBy count]} {
		#
		# Sort by count
		#
		echo {Tabulating data, grouping by message, sorting by count...}
		while {$msgs > 0} {
		    var count [value fetch $seg:$off.RME_count]
		    var totalCount [expr $totalCount+$count]
		    var listedCount [expr $listedCount+$count]
		    var message [value fetch $seg:$off.RME_message]
		    var class_seg [value fetch $seg:$off.RME_class.segment]
		    var class_off [value fetch $seg:$off.RME_class.offset]
		    var timeT [value fetch $seg:$off.RME_elapsedTime.high]
		    var timeU [value fetch $seg:$off.RME_elapsedTime.low]
		    var time [expr $timeT+[expr $timeU/19886 f] f]
		    var s [sym faddr var $class_seg:$class_off]
		    var class_name [sym fullname $s]
		    var msg_name [resolve-message $message $class_name]
		    var class_root [range $class_name
			    [expr [string last {::} $class_name]+2] end chars]
		    var all [concat $all [list [list
			$msg_name
			$count
			$time
			$class_root]]]
		    var off [expr $off+[size RecordedMessageEntry]]
		    var msgs [expr $msgs-1]
		}
		var header1 {Count Message (Count - Time - Class)}
		var header2 {----- ------------------------------}
		var format1 {%5d %s}
		var format2 {%15d %11.4f - %s}			
	    } elif {![string first $sortBy time]} {
		#
		# Sort by time
		#
		echo {Tabulating data, grouping by message, sorting by time...}
		while {$msgs > 0} {
		    var count [value fetch $seg:$off.RME_count]
		    var totalCount [expr $totalCount+$count]
		    var listedCount [expr $listedCount+$count]
		    var message [value fetch $seg:$off.RME_message]
		    var class_seg [value fetch $seg:$off.RME_class.segment]
		    var class_off [value fetch $seg:$off.RME_class.offset]
		    var timeT [value fetch $seg:$off.RME_elapsedTime.high]
		    var timeU [value fetch $seg:$off.RME_elapsedTime.low]
		    var time [expr $timeT+[expr $timeU/19886 f] f]
		    var s [sym faddr var $class_seg:$class_off]
		    var class_name [sym fullname $s]
		    var msg_name [resolve-message $message $class_name]
		    var class_root [range $class_name
			    [expr [string last {::} $class_name]+2] end chars]
		    var all [concat $all [list [list
			$msg_name
			$time
			$count
			$class_root]]]
		    var off [expr $off+[size RecordedMessageEntry]]
		    var msgs [expr $msgs-1]
		}
		var header1 {Time(ticks) Message (Time - Count - Class)}
		var header2 {----------- ------------------------------}
		var format1 {%11.4f %s}
		var format2 {%25.4f - %5d - %s}
	    } else {
		echo {Group by message, sort by what?!}
		return 0
	    }
	} else {
	    echo {Group by what?!}
	    return 0
	}
	#
	# Print out the report header
	#
	echo {}
	echo [format {%s %5d} {Message entries:    } $totalMsgs]
	echo [format {%s %5d} {Unrecorded entries: } $totalUnrec]
	echo [format {%s %5d} {Messages sent:      } $totalCount]
	echo [format {%s %5d %4d%%}
		{Messages listed:    } $listedCount
		[expr 100*$listedCount/$totalCount]]
	echo [format {%s %5d %4d%%}
		{Messages unlisted:  } [expr $totalCount-$listedCount]
		[expr 100*[expr $totalCount-$listedCount]/$totalCount]]
	echo {}	
	if {[string match $groupBy c*]} {
		[rmsg-report-by-class $all $header1 $header2 $format1]
	} else {
		[rmsg-report-by-message $all $header1 $header2
					$format1 $format2 $floor]
	}
}]

[defsubr rmsg-report-by-class {{data} {rh1} {rh2} {rf}}
{
	#
	# Print a report of all messages sent, in decreasing order of use
	#
	echo $rh1
	echo $rh2
	var data [sort -r -n $data]
	foreach lineData $data {
		echo [format $rf
			[index $lineData 0]
			[index $lineData 1]
			[index $lineData 2]
			[index $lineData 3]]
	}
}]

[defsubr rmsg-report-by-message {{data} {rh1} {rh2} {rf1} {rf2} {floor}}
{
	var msgGrCount 0
	var msgGrList {}
	var msgGrName {}
	var new {}
	#
	# Go through the list of message data structures, totalling each
	# message group, and tracking count & class name for each message
	#
	# Note that I add a bogus entry onto the end of the original data
	# list, so that the code works out nicely.
	#
	var data [sort $data]
	var data [concat $data [list [list {MSG_ZZZ} 0 0 0]]]
	foreach lineData $data {
		if {[string compare [index $lineData 0] $msgGrName]} {
			if {![expr $msgGrCount==0 f]} {
				var new [concat $new [list [list
					[expr $msgGrCount*1024 f]
					$msgGrCount
					$msgGrName
					[sort -r -n $msgGrList]]]]
			}
			var msgGrName  [index $lineData 0]
			var msgGrCount 0
			var msgGrList  {}
		}
		var msgGrCount [expr $msgGrCount+[index $lineData 1] f]
		var msgGrList [concat $msgGrList [list [list
			[expr [index $lineData 1]*1024 f]
			[index $lineData 1]
			[index $lineData 2]
			[index $lineData 3]]]]
	}
	#
	# Sort the new list in order of total message sent, and then report
	#
	var new [sort -r -n $new]
	echo $rh1
	echo $rh2
	foreach newData $new {
	    if {[expr [index $newData 1]<$floor f]} {
		break
	    }
	    echo [format $rf1 [index $newData 1] [index $newData 2]]
	    foreach msgClass [index $newData 3] {
		echo [format $rf2
			[index $msgClass 1]
			[index $msgClass 2]
			[index $msgClass 3]]
	    }
	}
}]

[defsubr resolve-message {{msg_num} {class_name}}
{
	#
	# Try to find the specific UI in use.
	# If not found, assume using the last one in the list.
	#
	foreach spui {rudy jmotif motif pm pmba redmtf stylus} {
	    if {![null [patient find $spui]]} {
		break
	    }
	}

	var msg_name [map-method $msg_num $class_name]
	#
	# Try to do some additional mapping of class names
	# for variants, in an attempt to find the message name
	#
	if {[string first MSG $msg_name] == -1} {
	foreach metaMsg [list
		geos::MetaMessages
		geos::MetaWindowMessages
		geos::MetaInputMessages
		ui::MetaUIMessages
		[format {%s::MetaSpecificUIMessages} $spui]
		ui::MetaApplicationMessages
		grobj::MetaGrObjMessages
		spool::MetaPrintMessages
		spell::MetaSearchSpellMessages
		geos::MetaGCNMessages
		text::MetaTextMessages
		styles::MetaStylesMessages
		color::MetaColorMessages] {
			var typeToken [sym find type $metaMsg]
			if {![null $typeToken]} {
				var msg_name [type emap $msg_num $typeToken]
				if {![null $msg_name]} {return $msg_name}
			}
		}
	} else {
		return $msg_name
	}
	#
	# Get to the root of the class
	#
	var class_root [range $class_name
			 [expr [string last {::} $class_name]+2] end chars]
	#
	# Now try all possible mapping for each of the classes. Each element
	# of the list is {word-to-match-in-class-name alternative-classes}
	#
	[foreach c {
    	    {Application {
	    	ui::GenApplicationClass
		spui::OLApplicationClass
	    }}
    	    {Content {
	    	ui::GenContentClass
		spui::OLContentClass
    	    }}
    	    {Document {
	    	ui::GenDocumentClass
		spui::OLDocumentClass
	    }}
    	    {DocumentGroup {
	    	ui::GenDocumentGroupClass
		spui::OLDocumentGroupClass
	    }}
    	    {DocumentControl {
	    	ui::GenDocumentControlClass
		spui::OLDocumentControlClass
	    }}
    	    {Display {
	    	ui::GenDisplayClass
		spui::OLDisplayWinClass
	    }}
    	    {DisplayGroup {
	    	ui::GenDisplayGroupClass
		spui::OLDisplayGroupClass
	    }}
    	    {Text {
	    	ui::GenTextClass
		spui::OLTextClass
	    }}
    	    {FileSelector {
	    	ui::GenFileSelectorClass
		spui::OLFileSelectorClass
	    }}
    	    {Field {
	    	ui::GenFieldClass
		spui::OLFieldClass
	    }}
    	    {Screen {
	    	ui::GenScreenClass
		spui::OLScreenClass
	    }}
    	    {SpinGadget {
	    	ui::GenSpinGadgetClass
		spui::OLSpinGadgetClass
	    }}
    	    {System {
	    	ui::GenSystemClass
		spui::OLSystemClass
	    }}
    	    {Gadget {
	    	ui::GenGadgetClass
		spui::OLGadgetClass
		spui::OLGadgetCompClass
    	    }}
	    {Glyph {
	    	ui::GenGlyphClass
		spui::OLGlyphDisplayClass
    	    }}
	    {GenViewClass {
		spui::OLPaneClass
	    }}
	    {OLPaneClass {
		ui::GenViewClass
	    }}
	    {GenTriggerClass {
		spui::OLButtonClass
	    }}
	    {OLButtonClass {
		ui::GenTriggerClass
	    }}
	    {GenValueClass {
		spui::OLValueClass
		spui::OLScrollbarClass
	    }}
	    {OLValueClass {
		ui::GenValueClass
	    }}
	    {OLScrollbarClass {
		ui::GenValueClass
	    }}
	    {GenPrimaryClass {
		spui::OLCtrlClass
		spui::OLWinIconClass
		spui::OLBaseWinClass
	    }}
	    {OLCtrlClass {
		ui::GenPrimaryClass
		ui::GenInteractionClass
	    }}
	    {OLWinIconClass {
		ui::GenPrimaryClass
	    }}
	    {OLBaseWinClass {
		ui::GenPrimaryClass
	    }}
	    {GenListEntryClass {
		spui::OLSettingClass
		spui::OLScrollItemClass
	    }}
	    {OLSettingClass {
		ui::GenListEntryClass
	    }}
	    {OLScrollItemClass {
		ui::GenListEntryClass
	    }}
	    {GenListClass {
		spui::OLDynamicListClass
		spui::OLSettingCtrlClass
		spui::OLScrollingListClass
	    }}
	    {OLDynamicListClass {
		ui::GenListClass
	    }}
	    {OLSettingCtrlClass {
		ui::GenListClass
	    }}
	    {OLScrollingListClass {
		ui::GenListClass
	    }}
	    {GenInteractionClass {
		spui::OLDialogWinClass
		spui::OLDisplayWinClass
		spui::OLReplyBarClass
		spui::OLMenuWinClass
		spui::OLMenuBarClass
		spui::OLMenuedWinClass
		spui::OLMenuItemGroupClass
		spui::OLPopupWinClass
	    }}
	    {OLDialogWinClass {
		ui::GenInteractionClass
	    }}
	    {OLDisplayWinClass {
		ui::GenInteractionClass
	    }}
	    {OLReplyBarClass {
		ui::GenInteractionClass
	    }}
	    {OLMenuWinClass {
		ui::GenInteractionClass
	    }}
	    {OLMenuBarClass {
		ui::GenInteractionClass
	    }}
	    {OLMenuedWinClass {
		ui::GenInteractionClass
	    }}
	    {OLMenuItemGroupClass {
		ui::GenInteractionClass
	    }}
	    {OLTriggerBarClass {
		ui::GenInteractionClass
	    }}
	    {OLPopupWinClass {
		ui::GenInteractionClass
	    }}
	    {GenItemGroupClass {
		spui::OLItemGroupClass
		spui::OLScrollListClass
	    }}
	    {GenDynamicListClass {
		spui::OLItemGroupClass
		spui::OLScrollListClass
	    }}
	    {OLItemGroupClass {
		ui::GenItemGroupClass
		ui::GenDynamicListClass
	    }}
	    {OLScrollListClass {
		ui::GenItemGroupClass
		ui::GenDynamicListClass
	    }}
	    {Item {
		ui::GenItemClass
		ui::GenBooleanClass
		spui::OLItemClass
		spui::OLScrollableItemClass
		spui::OLCheckedItemClass
	    }}}
    	{
	    if {[string match $class_root *[index $c 0]*]} {
		[foreach class_name [index $c 1]
		{
		    var class_name [string subst $class_name spui $spui]
		    var msg_name [map-method $msg_num $class_name]
		    if {[string compare $msg_name $msg_num]} {
			return $msg_name
		    }
		}]
    	    }
    	}]
	return $msg_num
}]



##############################################################################
#			Int21 recording functions
##############################################################################

##############################################################################
#				int21
##############################################################################
#
# SYNOPSIS:	Print the table of interrupt 21 function calls
# PASS:		Nothing
# CALLED BY:	User
# RETURN:	Data to screen
# SIDE EFFECTS:	None
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don	4/15/92		Initial Revision
#
##############################################################################

[defcommand int21 {{command print} {sortBy {time}}} {interrupt system.misc}
{Usage:
    int21
    int21 print [(count|time|name|number)]
    int21 reset

Synopsis:
    Print the table of interrupt 21 function calls

Examples:
    "int21"			Print data on calls made to Int21h

    "int21 print time"		Default operation, printing summary of calls
				to Int21h, sorted by total time/function call.

    "int21 print count"		Same as above, but sort by the # of calls made
				to a specific function, not by the time spent.

    "int21 print function"	Same as above, but sorted by function #

    "int21 reset"		Reset all the call totals

Notes:
    Unique abbreviations for the "command" & "sortBy" arguments are allowed.

    * PC-SDK: To use this command, you must run the non-error-checking
      version of Geos (GEOSNC) and select "GEOS Profiling Kernel - Int21"
      via the Debug application.

See also:
}
{
    var addr [addr-preprocess recInt21Table seg off]
    var function 0
    var max [index [type aget [index $addr 2]] 2]
    var entt [symbol find type geos::Int21RecordEntry]
    var esize [type size $entt]
    #
    # Determine which command to perform
    #
    if {[string match $command r*]} {
	#
	# Reset the call totals
	#
	echo {Resetting Int21 call counts}
	[for {var function 0}
	     {$function <= $max}
	     {var function [expr $function+1]}
    	{
	    value store $seg:$off.IRE_count 0
	    value store $seg:$off.IRE_elapsedTime.TR_units 0
	    value store $seg:$off.IRE_elapsedTime.TR_ticks 0
	    var off [expr $off+$esize]
	}]
	value store recFileReads 0
	value store recFileWrites 0
    } elif {[string match $command p*]} {
	#
	# Print the call totals
	#
	echo -n {Print Int21 call counts, sorted by }
	[case $sortBy in
	 t* {
	    echo {total time in call.}
	    var key time sort {sort -rn}
         }
	 c* {
	    echo {times called.}
	    var key count sort {sort -rn}
	 }
	 n* {
	    echo {name.}
	    var key name sort sort
	 }
         default {
	    echo {function number.}
	    var key function sort {sort -n}
	 }
    	]
	echo {}
	var total 0
	var totalTime 0
	var reads 0
	var writes 0
	var data {}
	#
	# Go through the table, only printing those functions that
	# have been called at least once
	#
	var callt [symbol find type geos::Int21Call]
	[for {var function 0}
	     {$function <= $max}
	     {
	     	var function [expr $function+1]
		var off [expr $off+[size Int21RecordEntry]]
	     }
    	{
	    var v [value fetch $seg:$off $entt]
	    var count [field $v IRE_count]
	    if {$count} {
		var total [expr $total+$count]
		var timeH [field [field $v IRE_elapsedTime] TR_ticks]
		var timeL [field [field $v IRE_elapsedTime] TR_units]
		var time [expr $timeH+($timeL/19886) f]
		var totalTime [expr $totalTime+$time f]
		var name [type emap $function $callt]
		
		var data [concat $data [list [list
		    [var $key] [format {%5d %11.2f %10.4f %s (%xh)}
		        $count
		        $time
		        [expr $time/$count f]
		        $name
			$function]]]]
		if {$name == MSDOS_READ_FILE} {var reads $count}
		if {$name == MSDOS_WRITE_FILE} {var writes $count}
	    }
	}]
	echo [format {Total: %d calls, %.2f ticks (%.2f seconds)}
		$total $totalTime [expr $totalTime/60 f]]
	echo {}
	if {$total} {
	    echo {Count Total Ticks Ticks/Call Function}
	    echo {----- ----------- ---------- --------}
	    foreach lineData [eval [concat $sort [list $data]]] {
		echo [index $lineData 1]
	    }
	}
	echo {}
	#
	# Average number of bytes read/written
	#
	if {$reads} {
	    var bytes [value fetch recFileReads dword]
	    echo [format {Average bytes/read:  %8.2f} [expr $bytes/$reads f]]
	}
	if {$writes} {
	    var bytes [value fetch recFileWrites dword]
	    echo [format {Average bytes/write: %8.2f} [expr $bytes/$writes f]]
	}
    } else {
	echo {Command not understood}
	help int21
    }
}]


##############################################################################
#				sint21
##############################################################################
#
# SYNOPSIS:	Print the table of interrupt 21 function calls tracked
#   	    	by the Swat stub.
# PASS:		Nothing
# CALLED BY:	User
# RETURN:	Data to screen
# SIDE EFFECTS:	None
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don	4/15/92		Initial Revision
#
##############################################################################
[defcommand sint21 {{command print} {sortBy {time}}} {interrupt system.misc}
{Usage:
    sint21
    sint21 print [(count|name|number)]
    sint21 reset

Synopsis:
    Print the table of interrupt 21 function calls as tracked by the Swat stub

Examples:
    "sint21"			Print data on calls made to Int21h

    "sint21 print count"	Same as above, but sort by the # of calls made
				to a specific function, not by the time spent.

    "sint21 print function"	Same as above, but sorted by function #

    "sint21 reset"		Reset all the call totals

Notes:
    Unique abbreviations for the "command" & "sortBy" arguments are allowed.

See also:
}
{
    var off [value fetch SwatSeg:2 word]
    if {$off == 0} {
    	error {Int21 tracking not supported by this stub.}
    }
    
    var addr [addr-preprocess SwatSeg:$off seg off]
    var function 0
    var max 255
    var esize 2
    #
    # Determine which command to perform
    #
    if {[string match $command r*]} {
	#
	# Reset the call totals
	#
	echo {Resetting Int21 call counts}
	[for {var function 0}
	     {$function <= $max}
	     {var function [expr $function+1]}
    	{
	    value store $seg:$off 0 [type word]
	    var off [expr $off+2]
	}]
	value store $seg:$off 0 [type dword]
    } elif {[string match $command p*]} {
	#
	# Print the call totals
	#
	echo -n {Print Int21 call counts, sorted by }
	[case $sortBy in
	 c* {
	    echo {times called.}
	    var key count sort {sort -rn}
	 }
	 n* {
	    echo {name.}
	    var key name sort sort
	 }
         default {
	    echo {function number.}
	    var key function sort {sort -n}
	 }
    	]
	echo {}
	var total 0
	var reads 0
	var data {}
	#
	# Go through the table, only printing those functions that
	# have been called at least once
	#
	var callt [symbol find type geos::Int21Call]
	[for {var function 0}
	     {$function <= $max}
	     {
	     	var function [expr $function+1]
		var off [expr $off+2]
	     }
    	{
	    var count [value fetch $seg:$off word]
	    if {$count} {
		var total [expr $total+$count]
		var name [type emap $function $callt]
		
		var data [concat $data [list [list
		    [var $key] [format {%5d %s (%xh)}
		        $count
		        $name
			$function]]]]
		if {$name == MSDOS_READ_FILE} {var reads $count}
	    }
	}]
	echo [format {Total: %d calls} $total]
	echo {}
	if {$total} {
	    echo {Count Function}
	    echo {----- --------}
	    foreach lineData [eval [concat $sort [list $data]]] {
		echo [index $lineData 1]
	    }
	}
	echo {}
	#
	# Average number of bytes read/written
	#
	if {$reads} {
	    var bytes [value fetch $seg:$off dword]
	    echo [format {Average bytes/read:  %8.2f} [expr $bytes/$reads f]]
	}
    } else {
	echo {Command not understood}
	help sint21
    }
}]


##############################################################################
#				rmod
##############################################################################
#
# SYNOPSIS:	Print data on recorded calls between modules
# PASS:		nothing
# CALLED BY:	User
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don	4/22/92		Initial Revision
#
##############################################################################

[defcommand rmod {{command print}} profile
{Usage:
    rmod
    rmod print
    rmod reset
    rmod debug

Examples:
    "rmod print"			Print a call report summary

    "rmod reset"			Reset the current call counts

    "rmod debug"			Print debugging information

Synopsis:
    Displays a report of the routines called between modules.

Notes:
    * The command "debug" is not yet implemented.

    * PC-SDK: To use this command, you must run the non-error-checking
      version of Geos (GEOSNC) and select "GEOS Profiling Kernel - Calls"
      via the Debug application.

See also:
    int21, rmsg
}
{
	#
	# Build a list of the routines called & count
	#
	var routineList {}
	var addr [addr-parse recModuleCallTable]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	var routines [value fetch recModuleCallHeader.RMCH_used]
	var unused [value fetch recModuleCallHeader.RMCH_unused]
	var missed [value fetch recModuleCallHeader.RMCH_overflow]
	var totalCalls $routines
	var totalCount 0
	if {[string match $command r*]} {
		#
		# Reset the call totals
		#
		value store recModuleCallHeader.RMCH_unused [expr $routines+$unused]
		value store recModuleCallHeader.RMCH_used 0
		value store recModuleCallHeader.RMCH_overflow 0
	} else {
		while {$routines} {
			var han [value fetch $seg:$off.RMCE_handle]
			var ofs [value fetch $seg:$off.RMCE_offset]
			var call [sym faddr func {^h$han:$ofs}]
			if {[null $call]} {
				var call {UNKNOWN}
			} else {
				var call [sym fullname $call]
			}
			var count [value fetch $seg:$off.RMCE_count]
			var routineList [concat $routineList [list [list $count $call]]]
			var totalCount [expr $totalCount+$count]			
			var off [expr $off+[size RecordModuleCallEntry]]
			var routines [expr $routines-1]
		}
		echo [format {%d calls were made to %d routines}
			$totalCount $totalCalls]
		if {$missed} {
			echo [format {%d calls are not shown} $missed]
		}
		echo
		var routineList [sort -r -n $routineList]
		echo {Count   Function}
		echo {------- --------}
		foreach i $routineList {
			echo [format {%7d %s} [index $i 0] [index $i 1]]
		}
	}
}]
