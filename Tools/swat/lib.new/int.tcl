##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Interrupt Manipulation
# FILE: 	int.tcl
# AUTHOR: 	Adam de Boor, Jul 21, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	int 	    	    	manipulate interrupt masks used while
#				machine is stopped.
#   	intr	    	    	manipulate interrupt vectors
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/21/89		Initial Revision
#
# DESCRIPTION:
#	
#
# 	$Id: int.tcl,v 3.13.11.1 97/03/29 11:27:28 canavese Exp $
#
###############################################################################
defvar ic1bits {{Timer 1} {Keybd 2} {Slave 4} {Com2 8} {Com1 16}
    	     {LPT2 32} {Floppy 64} {LPT1 128}}
defvar ic2bits {{Clock 1} {Net 2} {FPA 32} {HardDisk 64}}

defvar zic1bits {{Timer0 1} {Timer1 2} {Timer2 4} {Button 8}
		 {Serial 16} {Alarm 32} {RTC 64} {Pen 128}}
defvar zic2bits {{PCMCIA 1} {Sound 2} {Power 4} {Locked 8}
		 {Battery 16} {Protect 32}}

defvar int_detach_event nil
defvar int_attach_event nil

[defsubr _int_attach {arg masks}
{
    global int_attach_event int_detach_event
    
    #
    # Nuke the event that called us
    #
    event delete $int_attach_event
    #
    # Invoke set-masks on the two masks we had before we detached
    #
    eval [concat set-masks $masks]
    global IC1Mask IC2Mask
    var IC1Mask [index $masks 0] IC2Mask [index $masks 1]
    #
    # Catch detaches again.
    #
    var int_detach_event [event handle DETACH _int_detach]
    return EVENT_HANDLED
}]
    
[defsubr _int_detach {args}
{
    global int_detach_event IC1Mask IC2Mask int_attach_event

    #
    # Nuke the event that called us
    #
    event delete $int_detach_event
    var int_detach_event nil
    #
    # Register an event handler for the ATTACH event when we
    # re-attach
    #
    var int_attach_event [event handle ATTACH _int_attach
    	    	    	    	 [concat $IC1Mask $IC2Mask]]
    return EVENT_HANDLED
}]

[defcmd int {args} interrupt
{Usage:
    int [<int level> <state>]

Examples:
    "int"   	    	report the interrupt statuses
    "int 1:1 on"    	allow keyboard interrupt while in swat

Synopsis:
    Set or print the state of the two interrupt controllers for when
    then machine is stopped in Swat.

Notes:
    * If no arguments are given, the current state is printed.

    * The int level argument is specified by their names or their
      numbers with the form <controller>:<number> - <controller> is
      either 1 or 2, and <number> ranges from 0 to 7. The interrupts
      and their numbers are:

    	Timer  	 1:0	System timer. Probably dangerous to enable.
    	Keybd	 1:1 	Keyboard input.
    	Slave  	 1:2 	This is how devices on controller 2 interrupt.
    	    	    	Disabling this disables them all.
    	Com2   	 1:3 	This is the port usually used by Swat, so it 
    	    	    	can't be disabled.
        Com1   	 1:4 	The other serial port -- usually the mouse.
        LPT2   	 1:5 	The second parallel port
        Floppy 	 1:6 	Floppy-disk drive
        LPT1   	 1:7 	First parallel port
        Clock  	 2:0 	Real-time clock
        Net	 2:1 	Network interfaces (?)
        FPA	 2:5 	Coprocessor
        HardDisk 2:6 	Hard-disk drive

    * For the Zoomer, the interrupt names are different:
    	Timer0 	 1:0 	Pen debounce timer
	Timer1	 1:1	Interval timer
	Timer2	 1:2	Spare timer
	Button	 1:3	Fire/directional buttons
	Serial	 1:4	Serial port
	Alarm	 1:5	Real-time Clock alarm
	RTC 	 1:6	Real-time Clock timer
	Pen 	 1:7	Digitizer
	PCMCIA	 2:0	PCMCIA device
	Sound	 2:1	Sound DAC
	Power	 2:2	Power switch changed
	Locked	 2:3	PCMCIA lock switch on
	Battery	 2:4	Battery low
	Protect	 2:5	Special protect

    * The state argument is either 'on' or 'off'.

}
{
    global	ic1bits ic2bits IC1Mask IC2Mask int_detach_event
    global  	zic1bits zic2bits stub-type

    if {${stub-type} == zoomer} {
    	var bits1 $zic1bits bits2 $zic2bits
    } else {
    	var bits1 $ic1bits bits2 $ic2bits
    }

    if {[length $args] == 0} {
    	foreach i $bits1 {
    	    echo -n [index $i 0]:
    	    if {$IC1Mask & [index $i 1]} {
    	    	echo -n {off }
    	    } else {
    	    	echo -n {ON  }
    	    }
    	}
    	echo
    	foreach i $bits2 {
    	    echo -n [index $i 0]:
    	    if {$IC2Mask & [index $i 1]} {
    	    	echo -n {off }
    	    } else {
    	    	echo -n {ON  }
    	    }
    	}
    	echo
    } elif {[length $args] & 1} {
    	error {Usage: int [<irq> <state> [...]]}
    } else {
    	for {var i [expr [length $args]-2]} {$i >= 0} {var i [expr $i-2]} {
    	    var irq [index $args $i] state [index $args [expr $i+1]]
    	    var foo [assoc $bits1 $irq] foo2 [assoc $bits2 $irq]
    	    [if {![null $foo]} {
    	    	var bit [index $foo 1] mask IC1Mask
    	    } elif {![null $foo2]} {
    	    	var bit [index $foo2 1] mask IC2Mask
    	    } elif {([scan $irq {%d:%d} ctlr num] != 2) ||
		    ($ctlr != 1 && $ctlr != 2) ||
		    ($num < 0 || $num > 7)}
    	    {
    	    	error [format {%s: malformed interrupt number} $irq]
    	    } else {
    	    	var bit [expr 1<<$num] mask [format {IC%dMask} $ctlr]
    	    }]
    	    if {[string m $state {[Oo]*}]} {
    	    	if {[string m $state {[Oo][Nn]}]} {
    	    	    var $mask [expr {[var $mask]&~$bit}]
    	    	} else {
    	    	    var $mask [expr {[var $mask]|$bit}]
    	    	}
    	    } elif {$state} {
    	        var $mask [expr {[var $mask]&~$bit}]
    	    } else {
    	        var $mask [expr {[var $mask]|$bit}]
    	    }
    	}
    	set-masks $IC1Mask $IC2Mask
    	#
	# Set up an event to catch detaching from the PC so we can set
	# up an event to re-establish the interrupt masks when we re-attach
	#
	if {[null $int_detach_event]} {
	    var int_detach_event [event handle DETACH _int_detach]
	}
    }
}]

##############################################################################
#
# Stuff for using the stub to intercept interrupts. Background:
#   Within the stub is a table of 8-byte vectors consisting of:
#   	- a near call to a common, internal routine (3 bytes)
#   	- the interrupt number vectored to the vector (1 byte)
#   	- the previous value of the interrupt vector (4 bytes)
#   When an intercepted interrupt arrives, control passes to the
#   vector, which sends a HALT message to us telling us what interrupt
#   came in.
#
#   To avoid having vectors pointing at the stub when the stub is gone,
#   the intercepting of an interrupt causes a handler for the DETACH
#   event to be register, which handler resets the vector. This
#   will only fail if Swat dies horribly.
#

[defsubr _intr_detach {arg data}
{
    # Copy saved vector if not already restored.
    #
    var num [index $data 0] slot [index $data 1]
    
    global irqhandlers _intr_handler$num

    [if {[value fetch 0:[expr $num*4]+2 word] == 
    	 [handle segment [index [addr-parse SwatSeg] 0]]}
    {
    	assign 0:[expr $num*4] [value fetch
				  $irqhandlers+[expr $slot*8]+4
				  [type word]] 
    	assign 0:[expr $num*4]+2 [value fetch
				  $irqhandlers+[expr $slot*8]+6
				  [type word]]
    }]
    
    # Nuke handler in case this is a detach and not a quit.
    event delete [var _intr_handler$num]

    # All done
    return EVENT_HANDLED
}]

[defcmd intr {num {what send}} interrupt
{Catch, ignore or deliver an interrupt on the PC. First argument is the
interrupt number. Optional second argument is "catch" to catch delivery of the
interrupt, "ignore" to ignore the delivery, or "send" to send the interrupt
(the machine will keep going once the interrupt has been handled). If no second
argument is given, the interrupt is delivered}
{
    global irqhandlers

    if {$num < 0 || $num > 255} {
    	error [format {%s num out of range (0-255)} $num]
    }
    if {$num == 3 || $num == 1} {
    	error {Can't do anything with the breakpoint or single-step interrupts}
    }
    
    var num [expr $num]
    #
    # The number of available vectors is stored just before the
    # InterruptHandlers table...
    #
    var numSlots [value fetch $irqhandlers-2 [type word]]
    #
    # Decide what the user wants to do.
    #
    [case $what in
     c* {
    	#
	# Fetch current vector, both for later use and to see if it's already
	# being intercepted.
	#
    	[var o [value fetch 0:[expr $num*4] [type word]]
	     s [value fetch 0:[expr $num*4]+2 [type word]]]

     	if {$s == [handle segment [index [addr-parse SwatSeg] 0]]} {
	    error [format {%s already caught.} $num]
	} else {
    	    #
	    # Locate a free vector. If a vector has a 0 for its old vector
	    # field, it is free.
	    #
	    for {var i 0} {$i < $numSlots} {var i [expr $i+1]} {
	    	if {[value fetch $irqhandlers+[expr $i*8]+6 [type word]]==0} {
		    break
		}
	    }
	    if {$i == $numSlots} {
	    	error [format {Can't catch %s: no vectors left in stub} $num]
	    }
    	    #
	    # Store away the previous value and the number the vector is
	    # catching.
	    #
    	    assign $irqhandlers+[expr $i*8]+4 $o
    	    assign $irqhandlers+[expr $i*8]+6 $s
    	    assign {byte $irqhandlers+[expr $i*8]+3} $num
    	    #
	    # Revector the interrupt to the proper slot in the IRQHandlers
	    # table.
	    #
	    assign {fptr 0:[expr $num*4]} $irqhandlers+[expr $i*8]
	    #
	    # Register a handler for the DETACH event so we can restore things
	    # before letting the stub go.
	    #
    	    global _intr_handler$num
	    var _intr_handler$num [event handle DETACH _intr_detach
		    	    	    	[concat $num $i]]
    	}
     }
     i* {
    	[var o [value fetch 0:[expr $num*4] [type word]]
	     s [value fetch 0:[expr $num*4]+2 [type word]]]

	# Need to make sure also that the thing's being caught by the stub
	# in the regular manner (i.e. the handler is w/in the bounds of the
	# irqhandlers table).
    	
    	var a [addr-parse $irqhandlers]
     	[if {$s != [handle segment [index $a 0]] ||
	    $o < [index $a 1] || $o >= [index $a 1]+$numSlots*8}
	{
	    error [format {%s not caught.} $num]
	} else {
    	    #
	    # Restore the previous value.
	    #
	    assign 0:[expr $num*4] [value fetch $s:$o+4 [type word]]
	    assign 0:[expr $num*4]+2 [value fetch $s:$o+4+2 [type word]]
    	    
	    #
	    # Mark the vector as free by setting the old-vector field's
	    # segment to 0.
	    #
    	    assign $s:$o+6 0
	    #
	    # Nuke the DETACH handler (if any).
	    #
    	    global _intr_handler$num
	    if {![null [var _intr_handler$num]]} {
    	    	event delete [var _intr_handler$num]
		var _intr_handler$num {}
	    }
    	}]
     }
     s* {
    	#
	# Switch to real current thread
	#
    	switch

    	#
	# Push the current flags, cs and ip onto the stack first so the
	# interrupt routine has something to which to return.
	#
     	assign sp sp-6
	assign ss:sp+4 cc
	assign ss:sp+2 cs
	assign ss:sp   ip
    	var b [brk tset cs:ip]
    	#
	# Adjust CS:IP to be the interrupt routine.
	#
    	[var seg [value fetch 0:[expr $num*4]+2 [type word]]
	     off [value fetch 0:[expr $num*4] [type word]]]

	if {$seg == [handle segment [index [addr-parse SwatSeg] 0]]} {
	    #
	    # Caught by stub -- fetch the real routine
	    #
	    assign ip [value fetch $seg:$off+4 [type word]]
	    assign cs [value fetch $seg:$off+6 [type word]]
    	} else {
	    assign ip $off
	    assign cs $seg
    	}
    	#
	# Turn off TF and IF in the flags word for the interrupt routine
	#
	assign cc [expr [read-reg cc]&~0x300]
    	#
	# Let the machine go and wait if told to.
	#
    	continue-patient
    	global waitForPatient
    	if {$waitForPatient} {
	    wait
	    brk delete $b
    	}
     }
    ]
}]
