#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		fp.tcl
# AUTHOR:	John Wedgwood, Nov 11, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pfloat	    	    	Print a FloatNum
#   	fpstack	    	    	Print the FP stack for a thread
#   	fpustate    	    	Print the stack of the coprocessor
#   	fpdumpstack 	    	same as fpstack but dumps out fp numbers
#   	    	    	    	in there there 80 bit format
#   	fpustate    	    	prints out hardware fp stack
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	11/11/91	Initial revision
#
# DESCRIPTION:
#	Misc stuff for debugging float library.
#
#	$Id: fp.tcl,v 1.30 97/04/29 19:06:49 dbaumann Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



##############################################################################
#				format-float
##############################################################################
#
# SYNOPSIS:	Format a floating point number
# PASS:		float	- FloatNum structure
# CALLED BY:	utility
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/25/91	Initial Revision
#
##############################################################################
[defsubr format-float {float}
{

    var m3  [field $float F_mantissa_wd3]
    var m2  [field $float F_mantissa_wd2]
    var m1  [field $float F_mantissa_wd1]
    var m0  [field $float F_mantissa_wd0]

    #
    # Get the information
    #
    var expWord [field $float F_exponent]
    var sgn [field $expWord FE_SIGN]
    var exp [field $expWord FE_EXPONENT]
    
    # check for boneheaded C stuff -- F_exponent is just defined as
    # a word here, so parse it manually.

    if {[null $exp]} {
    	var sgn 0
    	if {$expWord & 8000h} {
	    var sgn 1
	}
	var exp [expr $expWord&7fffh]
    }

    # Check for zero

    if {$exp==0} {
    	return {0}
    }
    #
    # Check for NAN (infinity, error, etc.)
    #
    if {$exp == 0x7fff} {
    	if {$sgn} {
    	    return {-NAN}
    	} else {
    	    return {NAN}
    	}
    }
    #
    # Fix up the exponent
    #
    var exp [expr $exp-0x3fff]
    
    #
    # Create a fractional expression.
    #
    if {$sgn} {
    	var sgn -1
    } else {
    	var sgn 1
    }

    # m3 is only divided by 32768, not 65536, as the normally-implied 1 is
    # explicit in this 80-bit real format...
    return [expr ((((((($m0/65536.0)+$m1)/65536)+$m2)/65536)+$m3)/32768)*2**$exp*$sgn float]
}]

##############################################################################
#				dump-float
##############################################################################
#
# SYNOPSIS:	Format a floating point number
# PASS:		float	- FloatNum structure
# CALLED BY:	utility
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/25/91	Initial Revision
#
##############################################################################
[defsubr dump-float {float}
{
    	return [format {%04x %04x %04x %04x %04x} 
    	    [field $float F_mantissa_wd0]
    	    [field $float F_mantissa_wd1]
      	    [field $float F_mantissa_wd2]
      	    [field $float F_mantissa_wd3]
    	    [field [field $float F_exponent] FE_EXPONENT]
    	    ]

}]


##############################################################################
#				pfloat
##############################################################################
#
# SYNOPSIS:	Print a floating point number
# CALLED BY:	user
# PASS:		address	- Address of a FloatNum
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defcommand pfloat {{address {ds:si}}} lib_app_driver.float
{Usage:
    pfloat [<address ds:si>]

Examples:
    "pfloat"	    	print the floating point number at ds:si
    "pfloat es:di"  	print the floating point number at es:di

Synopsis:
    Print a floating point number

Notes:

See also:
    fpstack
}
{
    if {[patient find math] == nil} {
	error {Unable to find math library.}
    }
    var flt [value fetch $address [sym find type math::FloatNum]]
    
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]

    echo [format {%04xh:%04xh = %s} $seg $off [format-float $flt]]
}]


##############################################################################
#				fpustate
##############################################################################
#
# SYNOPSIS:	    Fetch the 
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/92		Initial Revision
#
##############################################################################
defvar fpuregstype {}

[defcommand fpustate {{mode {}}} lib_app_driver.float
{Usage:
    fpustate <mode>

Examples:
    "fpustate"	    	Print out the state of the coprocessor
    "fpustate w"    	dumps out actual words of the numbers
    "fpustate s"    	just dumps out stack, no state info
Synopsis:
    Prints out the current state of the coprocessor. 

Notes:
    * See above

See also:
    fpstack, pfloat
}
{
    global fpuregstype
    if {[null $fpuregstype]} {
        var fpuregstype [type make pstruct
			 cr_control [type make struct
				     INF_CTRL [type word] 12 1
				     ROUND_CTRL [type word] 10 2
				     PREC_CTRL [type word] 8 2
				     PREC_MASK [type word] 5 1
				     UFLOW_MASK [type word] 4 1
				     OFLOW_MASK [type word] 3 1
				     DIV_ZERO_MASK [type word] 2 1
				     DENORMAL_MASK [type word] 1 1
				     INVALID_OP_MASK [type word] 0 1]
			 cr_status [type make struct
				    BUSY [type word] 15 1
				    C3 [type word] 14 1
				    TOS [type word] 11 3
				    C2 [type word] 10 1
				    C1 [type word] 9 1
				    C0 [type word] 8 1
				    ERR_SUM [type word] 7 1
				    STACK_FAULT [type word] 6 1
				    PREC_ERR [type word] 5 1
				    UFLOW_ERR [type word] 4 1
				    OFLOW_ERR [type word] 3 1
				    DIV_ZERO_ERR [type word] 2 1
				    DENORMAL_ERR [type word] 1 1
				    INVALID_OP_ERR [type word] 0 1]
			 cr_tag [type word]
			 cr_ip [type word]
			 cr_opAndHighIP [type word]
			 cr_dp [type word]
			 cr_highDP [type word]
			 cr_stack [type make array 8 
				   [type make pstruct 
				    F_mantissa_wd0 [type word]
				    F_mantissa_wd1 [type word]
				    F_mantissa_wd2 [type word]
				    F_mantissa_wd3 [type word]
				    F_exponent [type make struct
				    	        FE_EXPONENT [type word] 0 15
						FE_SIGN [type word] 15 1]]]]
    	gc register $fpuregstype
    }

    [if {[null [patient find intx87]] && [null [patient find int8087]]} {
    	return 
    }]

    [if {[catch {rpc call RPC_READ_FPU [type void] {} $fpuregstype} state] != 0}
    {
    	error $state
    }]

    var ctrl [field $state cr_control]
    var status [field $state cr_status]

    if {[string compare $mode s]} {
    	echo Control Word:
    	[case [field $ctrl ROUND_CTRL] in
    	    0 {echo \tRound to nearest}
	    1 {echo \tRound down}
	    2 {echo \tRound up}
	    3 {echo \tChop}
    	]
    	[case [field $ctrl PREC_CTRL] in
    	    0 {echo \tSingle precision}
	    1 {echo \tUnknown precision}
	    2 {echo \tDouble precision}
	    3 {echo \tExtended precision}
    	]
    	echo -n \tUnmasked exceptions:
    	if {![field $ctrl PREC_MASK]} {echo -n {Precision }}
    	if {![field $ctrl UFLOW_MASK]} {echo -n {Underflow }}
    	if {![field $ctrl OFLOW_MASK]} {echo -n {Overflow }}
    	if {![field $ctrl DIV_ZERO_MASK]} {echo -n {Divide-by-zero }}
    	if {![field $ctrl DENORMAL_MASK]} {echo -n {Denormal-operand }}
    	if {![field $ctrl INVALID_OP_MASK]} {echo -n {Invalid-operation }}
    	echo

    	echo Status word:
    	echo \tStack top = [field $status TOS]
    	echo \tBusy = [field $status BUSY]
    	echo [format {\tC3 C2 C1 C0\n\t%2d %2d %2d %2d} [field $status C3]
    	  [field $status C2] [field $status C1] [field $status C0]]

    	echo -n \tActive exceptions:
    	if {[field $status STACK_FAULT]} {echo -n {Stack-fault }}
    	if {[field $status PREC_ERR]} {echo -n {Precision }}
    	if {[field $status UFLOW_ERR]} {echo -n {Underflow }}
    	if {[field $status OFLOW_ERR]} {echo -n {Overflow }}
    	if {[field $status DIV_ZERO_ERR]} {echo -n {Divide-by-zero }}
    	if {[field $status DENORMAL_ERR]} {echo -n {Denormal-operand }}
    	if {[field $status INVALID_OP_ERR]} {echo -n {Invalid-operation }}

    	if {[field $status ERR_SUM]} {
    	    echo \n\tSome of those are unmasked
    	} else {
    	    echo \n\tNone unmasked
    	}
    }
    
    var i 0
    var tw [field $state cr_tag]
    var stop [field $status TOS]

    if {[string compare $mode w]} {  
      var tw [expr {($tw >> $stop * 2) | ($tw << (16 - 2 * $stop))}]
      foreach el [field $state cr_stack] {
    	echo -n ST($i):
	[case [expr $tw&3] in
	 0 {echo [format-float $el]}
	 1 {echo 0.0}
	 2 {echo special [dump-float $el]}
	 3 {echo empty}]
	var i [expr $i+1] tw [expr $tw>>2]
      }
    } else {
      var tw [expr {($tw >> $stop * 2) | ($tw << (16 - 2 * $stop))}]
      foreach el [field $state cr_stack] {
    	echo -n ST($i):
	[case [expr $tw&3] in
	 0 {echo [dump-float $el]}
	 1 {echo 0.0}
	 2 {echo special [dump-float $el]}
	 3 {echo empty}]
	var i [expr $i+1] tw [expr $tw>>2]
      }
    }
}]				    

##############################################################################
#				fpstack
##############################################################################
#
# SYNOPSIS:	   print out both software and hardware fp stacks
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/92		Initial Revision
#
##############################################################################
defvar fpuregstype {}

[defcommand fpstack {args} lib_app_driver.float
{Usage:
    fpstack [-s] [<patient current-patient>]

Examples:
    "fpstack"	    	Print out the fp stacks
    "fpstack -s"    	Print out just the stack registers, no state info
Synopsis:
    Prints out both the hardware and software stacks of the patient

Notes:
    * See above

See also:
    fpstack, pfloat
}
{

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
    	    	s { 
        	    	var short 1
    	    	    	var mode s
    	    	   }
	    ]
	}
    	var args [cdr $args]
    }
    var	pat [index $args 0]
    if {[null $mode]} {
    	var	mode [index $args 1]
    }
    #
    # Get the name and thread number of the appropriate patient.
    #
    if {![null $pat]} {
    	var pid   [patient find $pat]
	var pinfo [patient data $pid]
	var thrds [patient threads $pid]
    } else {
	var pinfo [patient data]
	var thrds [patient threads]
    }
    var pname [format {%s:%s} [index $pinfo 0] [index $pinfo 2]]

    foreach t $thrds {
	if {[thread number $t] == [index $pinfo 2]} {
    	    break
	}
    }
    var ss [thread register $t ss]

    var stOff  [value fetch stackHanOffset [type word]]
    var stkHan [value fetch $ss:$stOff [type word]]
    
    #
    # Check for no stack handle
    #
    if {$stkHan == 0} {
    	echo {There is no floating point stack for this thread}
	return
    }


    #
    # Now print the stack
    #
    var stkVar [value fetch (^h$stkHan) [sym find type math::FloatStackVars]]
    var stkTop [field $stkVar FSV_topPtr]
    var stkBot [field $stkVar FSV_bottomPtr]
    var stkType [field $stkVar FSV_stackType]
    #
    # Error check the stack handle.
    #
    if {$stkHan != [field $stkVar FSV_handle]} {
    	echo {WARNING: Stack handle in fp-stack does not appear correct.}
	echo [format {Real Handle: %04xh   StackVars.stkHan: %04xh}
	    	$stkHan
		[field $stkVar stkHan]]
    	return
    }
    
    var addr   [addr-parse ^h$stkHan]
    var stkSeg [handle segment [index $addr 0]]

    var fnType [sym find type math::FloatNum]

    if {[null $short]} {
    	echo [format {FP Stack for %s: ^h%04xh (%04xh:0)}
    	    $pname
    	    $stkHan
	    $stkSeg]
    	echo [format {Top: %04xh	Bottom: %04xh} $stkTop $stkBot]
    	echo [format {Type: %s } [penum math::FloatStackType $stkType]]
    	echo [format {Random: %s}
    	    [format-float [value fetch $stkSeg:FSV_randomX $fnType]]]

    	echo [format {tempSpace: %s}
    	    [format-float [value fetch $stkSeg:FSV_tempSpace $fnType]]]
        echo {Stack: }
        echo {-----Start-----}
    }

    echo [fpustate $mode]
    #
    # Get the address of the stack
    #
    var addr   [addr-parse ^h$stkHan]
    var stkSeg [handle segment [index $addr 0]]

    var fnType [sym find type math::FloatNum]
    var fnSize [type size $fnType]

    [if {![null [patient find intx87]] || ![null [patient find int8087]]} {
    	var fpindex 8
    } else {
    	var fpindex 0
    }]   
    #
    # Generate information for the stack
    #
    if {[null $mode]} {
      for {var off $stkTop} {$off < $stkBot} {var off [expr $off+$fnSize]} {
	echo [format {ST(%d):%s}
		$fpindex
    	    	[format-float [value fetch $stkSeg:$off $fnType]]]
    	var fpindex [expr $fpindex+1]
      }
    } else {
      for {var off $stkTop} {$off < $stkBot} {var off [expr $off+$fnSize]} {
	echo -n [format {ST(%d):}
		$fpindex]
    
        var flt [value fetch $stkSeg:$off [sym find type math::FloatNum]]
    	echo [dump-float $flt]
    	var fpindex [expr $fpindex+1]
      }
    }
    if {[null $short]} {
    	echo {------End------}
    }
}
]



##############################################################################
#				fpdumpstack
##############################################################################
#
# SYNOPSIS:	   print out both software and hardware fp stacks
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/92		Initial Revision
#
##############################################################################

[defcommand fpdumpstack {{pat {}}} lib_app_driver.float
{Usage:
    fpdumpstack

Examples:
    "fpdumpstack"	    	Print out the fp stackss

Synopsis:
    Prints out both the hardware and sfotware stacks of the patient
    . NOTE: YOU MUST ACTUALLY HAVE A COPROCESSOR OR YOUR DEBUGGING 
    SESSION WILL HANG.

Notes:
    * See above

See also:
    fpstack, pfloat
}
{
       echo [fpstack $pat w]
}]


##############################################################################
#	pfloat32
##############################################################################
#
# SYNOPSIS:	print a 32 bit float from a tcl variable
# PASS:		value is a dword value in 32 bit float format
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JL 	12/ 8/95   	Initial Revision
#
##############################################################################
[defsubr    pfloat32 {value} {
    var sign [expr [expr $value>>4]&8000000h]
    var exponent [expr [expr [expr $value>>23]&0ffh]-127]
    var mantissa [expr [expr $value&7fffffh]|800000h]

    if {$sign == 0} {
    	var sign 1
    } else {
    	var sign -1
    }
    echo [expr $sign*[expr 2**$exponent]*[expr $mantissa/[expr 2**23] f] f]
}]


    


