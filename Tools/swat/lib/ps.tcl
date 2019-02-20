##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- System Status
# FILE: 	ps.tcl
# AUTHOR: 	Adam de Boor, Apr 14, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	ps  	    	    	print status
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/14/89		Initial Revision
#
# DESCRIPTION:
#	Functions for printing system status from swat's perspective
#
#	$Id: ps.tcl,v 3.0 90/02/04 23:37:31 adam Exp $
#
###############################################################################
[defsubr ps-p {args}
{
    var patients [map i [patient all]
		  {format {%04x %d} [handle id
				     [index [patient resources $i] 0]] $i}]
    echo {PID   NAME        THREADS}
    foreach	i [sort $patients] {
    	var n [patient name [index $i 1]]
    	if {[null $args] || ![null [assoc $args $n]]} {
	    echo -n [format {%s  %-12s} [index $i 0] $n]
	    map i [patient threads [index $i 1]] {
		echo -n [format {%04x } [handle id [thread handle $i]]]
	    }
	    echo
    	}
    }
}]

[defsubr ps-t {args}
{
    #
    # Form a list of all the threads in the system
    #
    var threads [map i [thread all] 
		 {format {%04x %d} [handle id [thread handle $i]] $i}]
    var curp [patient data] cur [format %04x [index [addr-parse @curThread] 1]]
    echo { TID  #  BASE USGE PRIO NAME        SS:SP      CS:IP}
    foreach i [sort $threads] {
	var thread [index $i 1] tid [index $i 0]
	if {[string c $tid 0000] == 0} {
	    var h {{HT_basePriority 0 0} {HT_cpuUsage 0 0} {HT_curPriority 0 0}}
	} else {
	    var h [value fetch kdata:${tid}h HandleThread]
	}
	var n [patient name [handle patient [thread handle $thread]]]
    	if {[null $args] || ![null [assoc $args $n]]} {
	    echo -n [format {%s%s %-2d %4d %4d %4d %-12s%04x:%04x  }
		     [if {[string c $tid $cur]==0} {format *} {format { }}]
		     $tid
		     [thread number $thread]
		     [field $h HT_basePriority]
		     [field $h HT_cpuUsage]
		     [field $h HT_curPriority]
		     $n
		     [thread register $thread ss]
		     [thread register $thread sp]]
	    switch ${tid}h
	    if {[string c $tid 0000] == 0 && [string c $tid $cur] != 0} {
		echo Dispatch
	    } else {
		var sym [frame funcsym [frame top]]

		if {![null $sym]} {
		    var sn [symbol fullname $sym]
		    if {[string m $sn *BlockOnLongQueue]} {
			#
			# Stopped in BlockOnLongQueue -- see if we can locate
			# its caller. We'd prefer to print that out than just 
			# BlockOnLongQueue as it's more informative.
			#
			var nf [frame next [frame top]]
			if {![null $nf]} {
			    var sym [frame funcsym $nf]
			    if {![null $sym]} {
				var sn [symbol fullname $sym]
			    }
			}
		    }
		    #46 chars in above info, leaving 34 for the name
		    if {[length $sn chars] > 33} {
			echo <[range $sn [expr [length $sn chars]-31] end chars]
		    } else {
			echo $sn
		    }
		} else {
		    echo [format {%04x:%04x} [thread register $thread cs]
					     [thread register $thread ip]]
		}
	    }
    	}
    }
    #
    # Switch back to previous "current patient"
    #
    switch [index $curp 0]:[index $curp 2]
}]

[defsubr ps-h {args}
{
    echo {HID  T  Owner                         Addr   Size  State}
    foreach i [sort -n [handle all]] {
	var handle [handle lookup $i]
	var state [handle state $handle]
	if {[handle ismem $handle]} {
    	    var n [patient name [handle patient $handle]]
    	    if {[null $args] || ![null [assoc $args $n]]} {
		# memory handle
		echo -n [format {%04x %s  %-30s%04x %6d  }
			 $i [index {M R P P} [expr ($state&0x180)>>7]]
			 [if {$state&0x80 || [handle iskernel $handle]} {
			    [format {%s::%s} $n
				    [symbol name [handle other $handle]]]
			 } else {
			    [patient name [handle patient $handle]]
			 }]
			 [handle segment $handle]
			 [handle size $handle]]
		if {($state & 1) == 0} {
		    if {$state & 0x20} {echo -n {Swpd }} {echo -n {Nukd }}
		}
		if {$state & 0x010} {echo -n {Shrd }}
		if {$state & 0x008} {echo -n {Fxd }}
		if {$state & 0x004} {echo -n {Nkbl }}
		if {$state & 0x002} {echo -n {Swpbl }}
		if {$state & 0x800} {echo -n {LMem }}
		if {$state & 0x200} {echo -n {Atchd }}
		echo
	    }
    	}
    }
}]

[defcommand ps {{flags -p} args} misc
{Print out system status. Only one of the following flags may be given:
    -p	    Prints out info on all patients. May be followed by a list of
    	    a patients to be displayed.
    -t	    Prints out info on all threads. May be followed by a list of
    	    patients whose threads are to be displayed.
    -h	    Prints out info on all handles. May be followed by a list of
    	    patients whose handles are to be displayed.}
{
    var pflag 0
    var tflag 0
    var hflag 0
    
    var flags [explode [index $flags 0]]

    foreach i $flags {
	[case $i in
	 p { var pflag 1 subr ps-p}
	 t { var tflag 1 subr ps-t}
	 h { var hflag 1 subr ps-h}
	]
    }

    var what [expr {$pflag + $hflag + $tflag}]
    if {$what > 1} {
    	error {Only one of -p, -h and -t may be given}
    } elif {$what == 0} {
    	error {Must specify one of -p, -h and -t}
    }
    eval [concat $subr $args]
}]
