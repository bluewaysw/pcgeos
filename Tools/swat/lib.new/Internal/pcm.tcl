##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	pcm.tcl
# AUTHOR: 	Adam de Boor, May 16, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/16/93		Initial Revision
#
# DESCRIPTION:
#	functions for abusing pcmcia functionality.
#
#	$Id: pcm.tcl,v 1.7.9.1 97/03/29 11:24:59 canavese Exp $
#
###############################################################################

##############################################################################
#				sserv-internal
##############################################################################
#
# SYNOPSIS:	Make a call to socket services, but don't print anything out.
# PASS:		func	= function to invoke
#   	    	regs	= list of register assignments, logically (though
#   	    	    	  not actually) organised as a list of 2-lists, the 
#			  first element of which is a thing to which to assign,
#			  and the second element of which is what to assign to 
#			  it.
# CALLED BY:	(INTERNAL)
# RETURN:	non-zero if function returned carry set
# SIDE EFFECTS:	previous thread registers all saved (to be restored with
#   	    	    restore-state, or nuked with discard-state)
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/16/93		Initial Revision
#
##############################################################################
[defsubr _call_sserv_catch {sp tnum}
{
    return [expr {[index [patient data] 2] == $tnum && [read-reg sp] >= $sp}]
}]

[defsubr sserv-internal {func regs}
{
    #
    # Perform whatever assignments are requested, after saving away the
    # registers.
    #
    var args [concat [list ah $func] $regs]

    var len [length $args]
    if {$len & 1} {
	error {Usage: sserv <func> [<var> <value>]*}
    }

    save-state
    
    for {var i 0} {$i < $len} {var i [expr $i+2]} {
    	if {[string c [index $args $i] push] == 0} {
	    uplevel 1 assign ss:sp-2 [index $args [expr $i+1]]
	    assign sp sp-2
    	} else {
	    uplevel 1 assign [index $args $i] [index $args [expr $i+1]]
    	}
    }

    #
    # Push the return address onto the stack, recording the sp above the
    # address in $sp for later use.
    #
    var sp [read-reg sp]
    var newsp [expr $sp-6]
    assign sp $newsp
    assign {word ss:sp} ip
    assign {word ss:sp+2} cs
    assign {word ss:sp+4} cc

    #
    # Set a breakpoint at the current CS:IP to invoke _call_catch with
    # the SP that must be reached for the call to be complete and the
    # thread in which the machine must be executing for the breakpoint
    # to apply...
    #
    var bp [brk pset cs:ip [format {_call_sserv_catch %d %d} $sp [index [patient data] 2]]]
    assign cs [value fetch 0:(1ah*4).segment]
    assign ip [value fetch 0:(1ah*4).offset]
    
    #
    # Let the machine go and wait for it. We don't want it to generate
    # the FULLSTOP event since if the call completes, we don't want to
    # print out that it got back to where it started from. If the call
    # doesn't complete, we want to warn the user about what s/he's gotten
    # into. "Ergo" we do this all inside a stop-catch.
    #
    stop-catch {
	continue-patient
    	var result [expr {![wait] && [read-reg sp] == $sp}]
    }
    brk clear $bp
    return [expr [read-reg cc]&1]
}]

##############################################################################
#				sserv
##############################################################################
#
# SYNOPSIS:	make a call to socket services
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
#	ardeb	5/16/93		Initial Revision
#
##############################################################################
[defsubr sserv {func args}
{
    sserv-internal $func $args

    echo Call complete. Type "break" to return to top level
    event dispatch FULLSTOP _DONT_PRINT_THIS_

    top-level

    #
    # Go back to previous registers
    #
    restore-state
}]


[defsubr ciserr {fmt}
{
    var ecode [read-reg ah]
    var ename [type emap $ecode [symbol find type SocketReturnCodes]]

    restore-state
    error [format $fmt [format {%s (%02xh)} $ename $ecode]]
}]

##############################################################################
#				pcis
##############################################################################
#
# SYNOPSIS:	Dump the CIS of the current card.
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
#	ardeb	5/16/93		Initial Revision
#
##############################################################################
[defsubr pcis {{socket 0}}
{
    require fmt-bytes memory
    #
    # state variables for remembering the most recent mapping established by
    # cis-getbyte
    #
    var lastBase -1 lastspace 0

    #
    # State variables for decoding configuration-table entries.
    #
    var def-ifname {mem, BVDs active, WP active, Rdy/-Bsy active}
    var def-power {{nominal=5V, min=none, max=none, static=none, peak=none, powerdown=none}
    	    	   {no Vpp1}
		   {no Vpp2}}
    var def-timing {none}
    var def-io {none}
    var def-irq {none}
    var def-mem {none}
    var def-misc {none}

    if {[null [patient find pcmcia]]} {
    	#
	# Not using card services on this machine
	#
	# XXX: preserve state

	[if {[sserv-internal SS_SET_WINDOW
			     {al 0 bl 0 bh 0 cx 4 dh 2 dl DS_250NS di 0xd0}]}
	{
	    ciserr {unable to enable window for socket: %s}
	}]

	# first print the initial cis at attr:0, with a default link to common:0
	var link [pcis-internal 0 {0 C} 0 1]

	while {[index $link 1] != N} {
	    if {[string c [index $link 1] C] == 0} {
		var link [pcis-internal [index $link 0] {0 N} 1 0]
	    } else {
		var link [pcis-internal [index $link 0] {0 N} 1 1]
	    }
	}
    } else {
    	pcis-cserv $socket
    }
}]

##############################################################################
#				cis-getbyte
##############################################################################
#
# SYNOPSIS:	Map some part of the card into the bank at d000h
# PASS:		base	= base within the address space
#   	    	isattr	= non-zero if mapping attribute memory
# CALLED BY:	pattrcis, pcommoncis
# RETURN:	the offset within d000h of requested byte
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/16/93		Initial Revision
#
##############################################################################
[defsubr cis-getbyte {base isattr}
{
    if $isattr {
    	var realbase [expr ($base)*2]
    } else {
    	var realbase ($base)
    }
    # round down to nearest 16K, as required by window
    var winbase [expr ($realbase/16384)*16384]

    [if {[uplevel pcis var lastBase] != $winbase || 
	 [uplevel pcis var lastspace] != $isattr} 
    {
    	# flush the cache (XXX: isn't this done by the call?)
    	dcache bsize [index [dcache params] 0]

	[if {[sserv-internal SS_SET_PAGE
			     [concat {al 0 bh 0 bl 0 dl}
				     [if $isattr {expr 3} {expr 2}]
				     {di}
				     [expr $winbase/4096]]]}
	{
	    ciserr [format {unable to map page to %s:%d} 
			   [if $isattr {format attr} {format common}] $base]
	}]
	uplevel pcis var lastBase $winbase lastspace $isattr
    }]
    return [value fetch 0xd000:($realbase) byte]
}]

##############################################################################
#				pcis-internal
##############################################################################
#
# SYNOPSIS:	Print out a CIS in attribute memory
# PASS:		base	= offset within address space
#   	    	link	= default link
#   	    	second	= non-zero if CIS is secondary, and so must begin with
#			  a CISTPL_LINKTARGET
#   	    	isattr	= non-zero if CIS resides in attribute memory
# CALLED BY:	INTERNAL
# RETURN:	link to next CIS
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/16/93		Initial Revision
#
##############################################################################
[defsubr pcis-internal {base link second isattr}
{
    echo ------------------
    echo CIS at offset $base in [if $isattr {format attribute} {format common}] space
    var linkDefault 1
    var start $base
    
    # map the CIS to d000h:0 from attribute memory
    var ttype [symbol find type CISTuple]
    
    var done 0 first 1
    while {!$done} {
    	var tuple [cis-getbyte $base $isattr]
	var tname [type emap $tuple $ttype]
	
	echo [format {%04x: %s (%02xh)} [expr $base-$start] $tname $tuple]
	if {$first} {
	    if {$second} {
		if {$tname != CISTPL_LINKTARGET} {
		    echo {ERROR: TARGET OF LINK MUST BE CISTPL_LINKTARGET}
		    var done 1
		}
		var second 0
	    } elif {$tname != CISTPL_DEVICE && $tname != CISTPL_END && $tname != CISTPL_LONGLINK} {
		echo {ERROR: first CIS must begin with DEVICE, END or long link}
		var done 1
		# we quite intentionally leave the default link alone,
		# here, so we can look at this HP ram card that's so weird...
	    }
	    var first 0
	}
	if {$tname == CISTPL_END} {
	    var done 1
    	} elif {$tname == CISTPL_NULL} {
	    var base [expr $base+1]
    	} else {
	    var tsize [cis-getbyte $base+1 $isattr]
	    for {var bytes {} i $tsize} {$i != 0} {var i [expr $i-1] bytes [concat $bytes $b]} {
		var b [cis-getbyte $base+2+$tsize-$i $isattr]
	    }

	    if {$tname == CISTPL_LONGLINK_C || $tname == CISTPL_LONGLINK_A} {
    	    	#
		# Form the address by merging the bytes in reverse order.
		#
    	    	[for {var addr 0 i [expr $tsize-1]} 
		     {$i >= 0}
		     {var i [expr $i-1]}
    	    	{
		    var addr [expr ($addr<<8)|[index $bytes $i]]
    	    	}]
		#
		# Form the return value.
		#
		if {$tname == CISTPL_LONGLINK_C} {
		    var link [list $addr C]
    	    	} else {
		    var link [list $addr A]
    	    	}
    	    	if {!$linkDefault} {
		    echo ERROR: LINK $link ALREADY PRESENT IN THIS CIS
    	    	}
		var linkDefault 0
    	    } elif {$tname == CISTPL_NO_LINK} {
    	    	#
		# Cancel the default link.
		#
	    	var link {0 N}
    	    	if {!$linkDefault} {
		    echo ERROR: LINK $link ALREADY PRESENT IN THIS CIS
    	    	}
		var linkDefault 0
    	    }
				
    	    #
	    # If a specific command exists for the tuple, execute it.
	    #
	    if {![null [info command cis-$tname]]} {
	    	eval [list cis-$tname $tuple $bytes $base $isattr]
    	    } else {
		#
		# Spit out the bytes that make up the body
		#
		if {$tsize != 0} {
		    fmt-bytes $bytes 0 $tsize 4
		}
    	    }
	    var base [expr $base+2+$tsize]
	    if {$tsize == 255} {
		var done 1
	    }
    	}
    }
    
    return $link
}]

##############################################################################
#				cis-CISTPL_DEVICE
##############################################################################
#
# SYNOPSIS:	Describe devices residing in common memory
# PASS:		tuple	= tuple code number
#   	    	bytes	= array of bytes that make up the tuple, minus tuple
#   	    	    	  code and size byte
#   	    	base	= start of tuple
#   	    	isattr	= non-zero if tuple comes from attribute space
# CALLED BY:	pcis-internal
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#	; Followed by array of variable-length entries describing each device
#	; in the common address space, starting from address 0.
#	;
#	; Each entry begins with a DeviceID, possibly followed by extended
#	; speed record and extended device type bytes, followed by a 
#	; DeviceSize record.
#	;
#	; Final DeviceSize record is followed by 0xff byte
#	; 
#    DeviceType		etype	byte
#	DTYPE_NULL	enum DeviceType, 0x0
#	DTYPE_ROM	enum DeviceType, 0x1
#	DTYPE_OTPROM	enum DeviceType, 0x2
#	DTYPE_EPROM	enum DeviceType, 0x3
#	DTYPE_EEPROM	enum DeviceType, 0x4
#	DTYPE_FLASH	enum DeviceType, 0x5
#	DTYPE_SRAM	enum DeviceType, 0x6
#	DTYPE_DRAM	enum DeviceType, 0x7
#	DTYPE_FUNCSPEC	enum DeviceType, 0xd
#	DTYPE_EXTENDED	enum DeviceType, 0xe
#
#    DeviceID	record
#	DID_TYPE DeviceType:4
#	DID_WPS:1		; is device affected by write-protect switch?
#	DID_SPEED DeviceSpeed:3
#    DeviceID	end
#    
#    DeviceSizeUnit	etype byte
#        DSU_512		enum DeviceSizeUnit
#	DSU_2K		enum DeviceSizeUnit
#	DSU_8K		enum DeviceSizeUnit
#	DSU_32K		enum DeviceSizeUnit
#	DSU_128K	enum DeviceSizeUnit
#	DSU_512K	enum DeviceSizeUnit
#	DSU_2M		enum DeviceSizeUnit
#
#    DeviceSize record
#	DS_NUM_UNITS:5			; number of units - 1
#	DS_UNITS DeviceSizeUnit:3	; size of each unit
#    DeviceSize end
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/17/93		Initial Revision
#
##############################################################################
[defsubr cis-CISTPL_DEVICE_A {tuple bytes base isattr}
{
    return [cis-CISTPL_DEVICE $tuple $bytes $base $isattr]
}]

[defsubr cis-CISTPL_DEVICE {tuple bytes base isattr}
{
    var len [length $bytes]
    var cur 0
    for {var i 0} {$i < $len} {var i [expr $i+1]} {
    	var b [index $bytes $i]
	if {$b == 0xff} {
	    break
    	}
	var i [cis-decode-device $b $bytes $i cur]
    }
    if {$i+1 < $len} {
    	echo {    Extra Bytes:}
	var b [range $bytes [expr $i+1] end]
	fmt-bytes $b [expr $i+1] [length $b] 4
    }
}]

[defsubr cis-decode-device {b bytes i curPtr}
{
    var type [expr ($b>>4)&0xf] wp [expr $b&8] speed [expr $b&7]
    [case $speed in
     0  {}
     1  {var speed 250ns}
     2  {var speed 200ns}
     3  {var speed 150ns}
     4  {var speed 100ns}
     {5 6} {var speed invalid}
     7  {
	var i [expr $i+1]
	var b [index $bytes $i]
	if {$b&128} {
	    var speed invalid
	    do {
		var i [expr $i+1]
		var b [index $bytes $i]
	    } while {$b & 128}
	} else {
	    var speed [expr [index {0 1 1.2 1.3 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 7.0 8.0} [expr ($b>>3)&0xf]]*[index {1 10 100 1 10 100 1 10} [expr $b&7]] float][index {ns ns ns us us us ms ms} [expr $b&7]]
	}
    }]

    var i [expr $i+1]
    var b [index $bytes $i]
    if {[null $b] || $b == 255} {
    	var size 0
	var i [expr $i-1]
    } else {
    	var size [expr [index {512 2048 8192 32768 131072 524288 2097152} [expr $b&7]]*[expr (($b>>3)&0x1f)+1]]
    }
    echo [format {    %06xh-%06xh: %s %s, %sgoverned by wp switch}
	    [uplevel 1 var $curPtr]
	    [expr [uplevel 1 var $curPtr]+$size-1]
	    $speed
	    [index {null ROM PROM EPROM EEPROM FLASH SRAM DRAM ? ? ? ? ? special extended ?} $type]
	    [if {$wp} {format {}} {format {not }}]]
    uplevel 1 var $curPtr [expr [uplevel 1 var $curPtr]+$size]

    return $i
}]

##############################################################################
#				cis-CISTPL_VERS_1
##############################################################################
#
# SYNOPSIS:	
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
#	ardeb	5/17/93		Initial Revision
#
##############################################################################
[defsubr cis-CISTPL_VERS_1 {tuple bytes base isattr}
{
    var len [length $bytes]

    echo [format {    version %d.%d} [index $bytes 0] [index $bytes 1]]
    [for {var i 2 snum 1}
	 {$i < $len}
	 {var i [expr $i+1] snum [expr $snum+1]}
    {
    	if {[index $bytes $i] == 0xff} {
	    break
    	}
	[for {var str {} b [index $bytes $i]} 
	     {$b != 0 && $i < $len}
	     {var str [format {%s%c} $str $b] b [index $bytes $i]}
    	{
	    var i [expr $i+1]
    	}]
	echo [format {    string %2d = %s} $snum $str]
    }]

    if {$i+1 < $len} {
    	echo {    Extra Bytes:}
	var b [range $bytes [expr $i+1] end]
	fmt-bytes $b [expr $i+1] [length $b] 4
    }
}]

##############################################################################
#				cis-CISTPL_DEVICE_OC
##############################################################################
#
# SYNOPSIS:	
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
#	ardeb	5/17/93		Initial Revision
#
##############################################################################
[defsubr cis-CISTPL_DEVICE_OC {tuple bytes base isattr}
{
    var len [length $bytes]
    var cur 0
    var cond [index $bytes 0]
    echo [format {    Conditions:%s%s}
    	    [if {$cond & 2} {format { 3V}}]
	    [if {$cond & 1} {format { MWAIT}}]]
    for {var i 1} {$i < $len} {var i [expr $i+1]} {
    	var b [index $bytes $i]
	if {$b == 0xff} {
	    break
    	}
	var i [cis-decode-device $b $bytes $i cur]
    }
    if {$i+1 < $len} {
    	echo {    Extra Bytes:}
	var b [range $bytes [expr $i+1] end]
	fmt-bytes $b [expr $i+1] [length $b] 4
    }
}]

##############################################################################
#				cis-CISTPL_CONFIG
##############################################################################
#
# SYNOPSIS:	
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
#	ardeb	5/17/93		Initial Revision
#
##############################################################################
[defsubr cis-CISTPL_CONFIG {tuple bytes base isattr}
{
    var szflds [index $bytes 0]
    
    var rasz [expr ($szflds&3)+1]
    var rmsz [expr (($szflds>>2)&0xf)+1]
    var rfsz [expr ($szflds>>6)&3]
    
    var nconfig [expr [index $bytes 1]&0x3f]

    var raddr 0
    for {var i [expr $rasz+1]} {$i >= 2} {var i [expr $i-1]} {
    	var raddr [expr ($raddr<<8)|[index $bytes $i]]
    }
    var rmask 0
    for {var i [expr $rasz+1+$rmsz]} {$i > $rasz+1} {var i [expr $i-1]} {
    	var rmask [expr ($rmask<<8)+[index $bytes $i]]
    }
    echo [format {    %d possible %s} $nconfig 
		 [pluralize configuration $nconfig]]
    var i [expr $rasz+1+$rmsz+1]
    if {[length $bytes] > $i} {
	var diff [expr [length $bytes]-$i]
	echo ERROR: CONFIG TUPLE IS $diff [pluralize byte $diff] TOO LONG
	uplevel pcis-internal var tsize $i
    }
    [for {var rnum 0 mask 1}
	 {$rnum < 32}
	 {var rnum [expr $rnum+1] mask [expr $mask<<1]}
    {
    	if {$rmask & $mask} {
	    echo [format {    reg %2d at %06xh} $rnum [expr $raddr+($rnum*2)]]
    	}
    }]
}]
    
##############################################################################
#				cis-CISTPL_CFTABLE_ENTRY
##############################################################################
#
# SYNOPSIS:	
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
#	ardeb	5/17/93		Initial Revision
#
##############################################################################
[defsubr cis-CISTPL_CFTABLE_ENTRY {tuple bytes base isattr}
{
    var len [length $bytes]
    var index [index $bytes 0]
    var isdef [expr $index&0x40]
    echo [format {    Configuration %d:%s} [expr $index&0x3f]
    	    [if $isdef {format { (DEFAULT)}}]]
    var i 1
    if {$index&0x80} {
    	var iftype [index $bytes $i]
	var i [expr $i+1]
	var ifname [format {%s%s%s%s%s}
    	    	    [index {mem I/O res1 res2 cust0 cust1 cust2 cust3}
			   [expr $iftype&0xf]]
		    [if {$iftype&0x10} {format {, BVDs active}}]
		    [if {$iftype&0x20} {format {, WP active}}]
		    [if {$iftype&0x40} {format {, Rdy/-Bsy active}}]
		    [if {$iftype&0x80} {format {, WAIT active}}]]
    } else {
    	var ifname [uplevel pcis var def-ifname]
    }
    
    var features [index $bytes $i]
    var i [expr $i+1]
    [case [expr $features&0x3] in
     0	{var power [uplevel pcis var def-power]}
     1	{var power [list [cis-decode-power]
			 {no Vpp1}
			 {no Vpp2}]}
     2	{
     	var vcc [cis-decode-power]
	var vpp [cis-decode-power]
	var power [list $vcc $vpp $vpp]
     }
     3 {
     	var power [list [cis-decode-power]
			[cis-decode-power]
			[cis-decode-power]]
     }]

    if {$features&4} {
    	var timing [cis-decode-timing]
    } else {
    	var timing [uplevel pcis var def-timing]
    }
    
    if {$features&8} {
    	if {$i < $len} {
    	    var io [cis-decode-io-space]
    	} else {
	    var io AWOL
    	}
    } else {
    	var io [uplevel pcis var def-io]
    }
    
    if {$features&16} {
    	if {$i < $len} {
    	    var irq [cis-decode-irq]
	} else {
	    var irq {AWOL}
    	}
    } else {
    	var irq [uplevel pcis var def-irq]
    }

    [foreach l {{Interface {var ifname}}
    	        {Vcc {index $power 0}}
	        {Vpp1 {index $power 1}}
	        {Vpp2 {index $power 2}}
		{Timing {var timing}}
		{{I/O Space} {var io}}
		{IRQ {var irq}}}
    {
    	echo [format {    %s: %s} [index $l 0] [eval [index $l 1]]]
    }]
    if {$isdef} {
    	[uplevel pcis var def-ifname $ifname def-power $power
			  def-timing $timing def-io $io
			  def-irq $irq]
    }
}]
	
##############################################################################
#				cis-decode-power
##############################################################################
#
# SYNOPSIS:	Decode a power-description record in the CIS
# PASS:		in caller's scope:
#   	    	    bytes   = array of bytes in tuple
#   	    	    i	    = variable that advances through the bytes
# CALLED BY:	cis-CISTPL_CFTABLE_ENTRY
# RETURN:	description of power requirements
# SIDE EFFECTS:	$i in caller is advanced beyond bytes used
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/17/93		Initial Revision
#
##############################################################################
[defsubr cis-decode-power {}
{   var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]
    var features [index $bytes $i]
    if {[null $features]} {
	return err
    }
    var i [expr $i+1]
    
    if {$features & 1} {
    	var nom [cis-decode-voltage]
    } else {
    	var nom none
    }
    if {$features & 2} {
    	var min [cis-decode-voltage]
    } else {
    	var min none
    }
    if {$features & 4} {
    	var max [cis-decode-voltage]
    } else {
    	var max none
    }
    if {$features & 8} {
    	var static [cis-decode-current]
    } else {
    	var static none
    }
    if {$features & 16} {
    	var avg [cis-decode-current]
    } else {
    	var avg none
    }
    if {$features & 32} {
    	var peak [cis-decode-current]
    } else {
    	var peak none
    }
    if {$features & 64} {
    	var pdown [cis-decode-current]
    } else {
    	var pdown none
    }
    uplevel 1 var i $i
    return [format {nom=%s, min=%s, max=%s, static=%s, avg=%s, peak=%s, pdwn=%s}
    	    $nom $min $max $static $avg $peak $pdown]
}]

[defsubr cis-decode-voltage {}
{
    var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]
    var b [index $bytes $i]
    if {[null $b]} {
	return err
    }
    var i [expr $i+1]
    var m [index {1.0 1.2 1.3 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 7.0 8.0 9.0}
    	    	[expr ($b>>3)&0xf]]
		
    var exp [index {10 100 1 10 100 1 10 100} [expr $b&7]]
    var units [index {uV uV mV mV mV V V V} [expr $b&7]]
    
    var special 0
    while {$b&0x80} {
    	var b [index $bytes $i]
	var i [expr $i+1]
    	if {($b & 0x7f) > 63} {
	    [case [format %2x [expr $b&0x7f]] in
	     7d {var special 1 result {high-Z during pdown/sleep}}
	     7e {var special 1 result 0}
	     7f {var special 1 result {high-Z}}
	     default {var special 1 result unknown}]
    	} else {
	    var m ${m}[expr $b&0x7f]
    	}
    }
    if {!$special} {
    	var result [expr $m*$exp f]${units}
    }
    uplevel 1 var i $i
    return $result
}]

[defsubr cis-decode-current {}
{
    var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]
    var b [index $bytes $i]
    var i [expr $i+1]
    var m [index {1.0 1.2 1.3 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 7.0 8.0 9.0}
    	    	[expr ($b>>3)&0xf]]
		
    var exp [index {100 1 10 100 1 10 100 1} [expr $b&7]]
    var units [index {nA uA uA uA mA mA mA A} [expr $b&7]]
    
    var special 0
    while {$b&0x80} {
    	var b [index $bytes $i]
	var i [expr $i+1]
    	if {($b & 0x7f) > 63} {
	    [case [format %2x [expr $b&0x7f]] in
	     7d {var special 1 result {high-Z during pdown/sleep}}
	     7e {var special 1 result 0}
	     7f {var special 1 result {high-Z}}
	     default {var special 1 result unknown}]
    	} else {
	    var m ${m}[expr $b&0x7f]
    	}
    }
    if {!$special} {
    	var result [expr $m*$exp f]${units}
    }
    uplevel 1 var i $i
    return $result
}]

[defsubr cis-decode-timing {}
{
    var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]
    var b [index $bytes $i]
    if {[null $b]} {
	return err
    }
    var i [expr $i+1]

    if {($b&3) != 3} {
    	var maxwait [cis-decode-device-speed [expr 10**($b&3)]]
    } else {
    	var maxwait {not used}
    }
    if {($b&0x1c) != 0x1c} {
    	var maxbusy [cis-decode-device-speed [expr 10**(($b>>2)&7)]]
    } else {
    	var maxbusy {not used}
    }
    if {($b&0xe0) != 0xe0} {
    	cis-decode-device-speed [expr 10**(($b>>5)&7)]
    }
    
    uplevel 1 var i $i

    return [format {maxwait=%s, maxbusy=%s} $maxwait $maxbusy]
}]

[defsubr cis-decode-device-speed {{scale 1}}
{
    var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]

    var b [index $bytes $i]
    if {[null $b]} {
	return err
    }
    var i [expr $i+1]
    if {$b&128} {
	var speed invalid
	do {
	    var b [index $bytes $i]
	    var i [expr $i+1]
	} while {$b & 128}
    } else {
	var speed [expr [index {0 1 1.2 1.3 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 7.0 8.0} [expr ($b>>3)&0xf]]*[index {1 10 100 1 10 100 1 10} [expr $b&7]]*$scale float][index {ns ns ns us us us ms ms} [expr $b&7]]
    }
    uplevel 1 var i $i
    return $speed
}]

[defsubr cis-decode-io-space {}
{
    var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]
    var b [index $bytes $i]
    if {[null $b]} {
	return err
    }
    var i [expr $i+1]

    if {$b&0x1f == 0} {
    	var lines all
    } else {
    	var lines [expr $b&0x1f]
    }
    [case [expr ($b>>5)&3] in
     0	{var bus invalid}
     1 	{var bus 8bit}
     2	{var bus 16bit}
     3	{var bus 8/16bit}]

    if {$b & 0x80} {
    	var b [index $bytes $i]
	var i [expr $i+1]
	
	var nranges [expr ($b&0xf)+1]

	var asize [expr ($b>>4)&3]
	if {$asize} {
	    var asize [expr 2**($asize-1)]
    	}
	var lsize [expr ($b>>6)&3]
	if {$lsize} {
	    var lsize [expr 2**($lsize-1)]
    	}
	
    	var ranges {}
	for {var j 0} {$j < $nranges} {var j [expr $j+1]} {
	    [for {var k [expr $asize-1] a 0}
		 {$k >= 0} 
		 {var k [expr $k-1]}
    	    {
	    	var a [expr ($a<<8)|[index $bytes [expr $i+$k]]]
    	    }]
	    var i [expr $i+$asize]

	    [for {var k [expr $lsize-1] l 0}
		 {$k >= 0} 
		 {var k [expr $k-1]}
    	    {
	    	var l [expr ($l<<8)|[index $bytes [expr $i+$k]]]
    	    }]
	    var i [expr $i+$lsize]
	    if {[null $ranges]} {
	    	var ranges [format {, ranges=%06xh-%06xh} $a [expr $a+$l-1]]
	    } else {
	    	var ranges [format {%s, %06xh-%06xh} $ranges $a [expr $a+$l-1]]
    	    }
    	}
    }
    uplevel 1 var i $i
    
    return [format {#lines=%s, bus=%s%s} $lines $bus $ranges]
}]
    

[defsubr cis-decode-irq {}
{
    var bytes [uplevel 1 var bytes]
    var i [uplevel 1 var i]
    var b [index $bytes $i]
    var i [expr $i+1]
    
    if {$b&0x80} {
    	var type {shared, }
    } else {
    	var type {}
    }

    if {$b&0x40} {
    	var type [format {%spulse, } $type]
    }
    if {$b&0x20} {
    	var type [format {%slevel, } $type]
    }
    if {$b&0x10} {
    	var m [expr ((((($b&0xf)<<8)|[index $bytes [expr $i+1]])<<8)|[index $bytes $i])]
	var i [expr $i+2]
	[for {var avail {} j 0} {$j < 20} {var j [expr $j+1]} {
    	    if {$m & (1<<$j)} {
	    	var avail [concat $avail
		    	   [index {irq0 irq1 irq2 irq3 irq4 irq5 irq6 irq7
				   irq8 irq9 irq10 irq11 irq12 irq13 irq14 
				   irq15 nmi iocheck berr vend} $j]]
    	    }
    	}]
	var num [length $avail]
	if {$num > 1} {
	    var avail [mapconcat a [range $avail 0 [expr $num-2]] {
	    	format {%s, } $a
    	    }][format {or }][index $avail [expr $num-1]]
    	}
	var type [format {%slevels = %s} $type $avail]
    } else {
    	var type [format {%slevel = %d} $type [expr $b&0xf]]
    }
    uplevel 1 var i $i
    return $type
}]
    	
##############################################################################
#				cis-CISTPL_FUNCID
##############################################################################
#
# SYNOPSIS:	
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
#	ardeb	9/15/93		Initial Revision
#
##############################################################################
[defsubr cis-CISTPL_FUNCID {tuple bytes base isattr}
{
    var func [type emap [index $bytes 0] [symbol find type pcmcia::CISCardFunction]]
    var imask [index $bytes 1]
    
    if {[null $func]} {
    	var func [format {func = %d} [index $bytes 0]]
    }
    
    echo [format {    %-20s %s%s} $func
    	    [if {$imask & 1} {format {config in POST; }}]
	    [if {$imask & 2} {format {has expansion ROM}}]]
}]

##############################################################################
#				pcis-cserv
##############################################################################
#
# SYNOPSIS:	Print out a CIS using Card Services
# PASS:		socket	= logical socket #
# CALLED BY:	pcis
# RETURN:	nothing
# SIDE EFFECTS:	lots
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/15/93	Initial Revision
#
##############################################################################
[defsubr pcis-cserv {socket}
{
    #
    # Fetch values for things we use a lot
    #
    var gettuplesz [type size [symbol find type pcmcia::CSGetTupleArgs]]
    var getdatasz [type size [symbol find type pcmcia::CSGetTupleDataArgs]]
    var getnext [getvalue pcmcia::CSF_GET_NEXT_TUPLE]
    var getdata [getvalue pcmcia::CSF_GET_TUPLE_DATA]
    var cservFunc [getvalue pcmcia::CARD_SERVICES_SUB_COMMAND]
    var cistpl [symbol find type pcmcia::CISTuple]

    protect {
        #
	# Make it easy to get back to the way we were...
	#
	save-state

    	#
	# Make room for the larger of the two packets, plus the maximum
	# number of bytes in a tuple.
	#
	assign sp sp-($getdatasz+256)
    	#
	# Point es:bx at the packet for the duration.
	#
	assign es ss
	assign bx sp

    	#
	# Set up the stuff that's valid for both packets for the duration.
	#
	assign es:bx.pcmcia::CSGTA_socket $socket
	assign es:bx.pcmcia::CSGTA_attributes 0
	assign es:bx.pcmcia::CSGTA_desiredTuple pcmcia::CISTPL_END

	var func pcmcia::CSF_GET_FIRST_TUPLE
	for {} {1} {} {
    	    #
	    # Advance to the next tuple.
	    #
	    if {[sserv-internal $cservFunc {al $func cx $gettuplesz}]} {
    	    	#
		# Error. If error not NO_MORE_ITEMS, tell the user
		#
		if {[read-reg ax] != [getvalue pcmcia::CSRC_NO_MORE_ITEMS]} {
		    echo [format {pcis-cserv: GET_TUPLE: %s}
			  [type emap [read-reg ax] 
			   [symbol find type pcmcia::CardServicesReturnCode]]]
		}
		restore-state
		break
	    }
	    restore-state

    	    #
	    # Set function for next time through the loop, so we can just
	    # "continue" to go to the next tuple.
	    #
	    var func $getnext
	    
	    #
	    # Decode the tuple that came back.
	    #
	    var tuple [value fetch es:bx.pcmcia::CSGTA_tupleCode]
	    var tname [type emap $tuple $cistpl]
	    echo [format {%s (%02xh)} $tname $tuple]

	    if {$tname == CISTPL_END || $tname == CISTPL_NULL} {
		continue
	    }
	    #
	    # If the link field is non-zero, fetch all the bytes, too.
	    #
	    var tsize [value fetch es:bx.pcmcia::CSGTA_tupleLink]
	    if {$tsize > 0} {
		assign es:bx.pcmcia::CSGTDA_maxData $tsize
		assign es:bx.pcmcia::CSGTDA_tupleOffset 0

		[if {[sserv-internal $cservFunc 
		     {al $getdata cx $getdatasz+256}]}
		{
		    echo [format {pcis-cserv: GET_TUPLE_DATA: %s}
			  [type emap [read-reg ax] 
			   [symbol find type pcmcia::CardServicesReturnCode]]]
		    restore-state
		    break
		}]
		restore-state
		#
		# Now fetch the bytes from out of the argument packet.
		#
		var t [type make array $tsize [type byte]]
		var bytes [value fetch es:bx.pcmcia::CSGTDA_data $t]
		type delete $t
	    } else {
		var bytes {}
	    }

    	    #
	    # If a specific command exists for the tuple, execute it.
	    #
	    if {![null [info command cis-$tname]]} {
	    	eval [list cis-$tname $tuple $bytes 0 0]
    	    } else {
		#
		# Spit out the bytes that make up the body
		#
		if {$tsize != 0} {
		    fmt-bytes $bytes 0 $tsize 4
		}
    	    }
	}
    } {
    	catch {restore-state}
    }
}]

[defsubr csmon {}
{
    return [brk [value fetch (0:(1ah*4)).segment]:[value fetch (0:(1ah*4)).offset] csmon-monitor]
}]

[defsubr csmon-monitor {}
{
    if {[read-reg ah] == 0xaf} {
    	var func [type emap [read-reg al] [symbol find type pcmcia::CardServicesFunction]]
    	echo [format {%s (dx = %04xh, di:si = %04xh:%04xh)} $func
	    	[read-reg dx] [read-reg di] [read-reg si]]
	if {[read-reg cx] != 0} {
	    var upcase 1
	    var argStruct [format {CS%sArgs}
			   [mapconcat c
			    [eval [concat concat
				   [map c [explode [range $func 4 end char]] {
					if {$upcase} {
					    var upcase 0
					    var c
					} elif {$c == _} {
					    var upcase 1
					} else {
					    # downcase
					    scan $c %c cb
					    if {$cb >= 65 && $cb <= 65+26} {
						var c [format %c [expr $cb+32]]
					    }
					    var c
					}
				    }]]]
		    	    {
			    	var c
    	    	    	    }]]
    	    if {![null [symbol find type pcmcia::$argStruct]]} {
	    	print pcmcia::$argStruct es:bx
    	    } else {
	    	var argStruct {}
	    	bytes es:bx [read-reg cx]
    	    }
    	}
	brk [value fetch ss:sp.segment]:[value fetch ss:sp.offset] [list csmon-end [read-reg cx] $argStruct [read-reg es]:[read-reg bx]]
    }
    return 0
}]
		    
[defsubr csmon-end {len str arg}
{
    global breakpoint

    echo [format {result = %s (%d), dx = %04xh} 
    	    [type emap [read-reg ax] 
		  [symbol find type pcmcia::CardServicesReturnCode]]
    	    [read-reg ax]
	    [read-reg dx]]
    if {$len != 0} {
    	if {[null $str]} {
	    bytes $arg $len
    	} else {
	    print pcmcia::$str $arg
    	}
    }
    
    brk clear $breakpoint
    return 0
}]

[defsubr csdb {}
{
    if {[null [patient find cserv]]} {
    	def-cs
    }
    var o [value fetch cserv::_Free_Alloc_DB word]
    echo -n [format {alloc_db = %04xh} $o]
    do {
    	var o [value fetch cserv::_TEXT:$o word]
	if {$o} {
	    echo -n [format { -> %04xh} $o]
	} else {
	    echo { -|}
    	}
    } while {$o}
    echo [format {mem_low = %04xh, mem_high = %04xh} 
    	  [value fetch {(&cserv::_Static_Mem_Mgt)[0]}]
	  [value fetch {(&cserv::_Static_Mem_Mgt)[1]}]]
}]


##############################################################################
#				find-cs
##############################################################################
#
# SYNOPSIS:	Locate SystemSoft's Card Services
# PASS:		nothing
# CALLED BY:	INTERNAL
# RETURN:	the segment, as a hex number + radix char
# SIDE EFFECTS:	none
#
# STRATEGY
#   	    	Walk the device chain looking for one with the proper
#		name.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 6/93	Initial Revision
#
##############################################################################
[defsubr find-cs {}
{
    require dos-foreach-device dos

    return [dos-foreach-device {
    	[if {[string match 
	    	[mapconcat c [value fetch $ds:$do.DH_name] {var c}]
		CrdSrv*]}
    	{
	    return [format %04xh $ds]
    	}]
    }]
}]

[defsubr def-cs {}
{
    dossym cserv /n/eng/eng/bullet/pcmcia/cserv/cs.sym [find-cs]
}]

##############################################################################
#				csres
##############################################################################
#
# SYNOPSIS:	Print out a resource database
# PASS:		head	= address of the pointer to the first resource
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 6/93	Initial Revision
#
##############################################################################
[defsubr csres {head}
{
    echo [format {%-5s  %.3s  %-5s  %-5s  %-5s  %-3s  %-5s  %-5s  %s} Addr Typ Base Size Resrv Flg Alloc Lines Clients]
    protect {
	var rdb [type make pstruct
		q_next [type make nptr [type void]]
		q_prev [type make nptr [type void]]
		base [type word]
		size [type word]
		reserve [type word]
		shared [type byte]
		excl [type byte]
		alloc_db_head [type make nptr [type void]]
		alloc_db_tail [type make nptr [type void]]
		type [type byte]
		addr_lines [type byte]]
    	var adb [type make pstruct
	    	 rq_next [type make nptr [type void]]
		 rq_prev [type make nptr [type void]]
		 cq_next [type make nptr [type void]]
		 cq_prev [type make nptr [type void]]
		 rsrc_db_ptr [type make nptr [type void]]
		 clt_db_ptr [type make nptr [type void]]
		 skt_db_ptr [type make nptr [type void]]
		 ]
    	var cdb [type make pstruct
	    	 q_next [type make nptr [type void]]
		 q_prev [type make nptr [type void]]
		 handle [type word]
		 status_chg [type byte]
		 callback [type make fptr [type void]]
    	    	]

	[for {var r [value fetch $head word]}
	     {$r != 0}
	     {var r [field $res q_next]}
	{
	    var res [value fetch cserv::_TEXT:$r $rdb]
	    
	    [case [field $res type] in
	     0	{var rtype mem}
	     1	{var rtype io}
	     2	{var rtype irq}]
	    
    	    
	    echo -n [format {%04xh  %-3s  %04xh  %04xh  %04xh  %-3s  %5s  %-5s  }
	    	    $r
	    	    $rtype
		    [field $res base]
		    [field $res size]
		    [field $res reserve]
		    [if {[field $res shared]} {
		    	if {[field $res alloc_db_head] && [field $res excl]} {
			    format S/E
    	    	    	} else {
			    format { S }
    	    	    	}
		    } elif {[field $res alloc_db_head] && [field $res excl]} {
		    	format { E }
    	    	    } else {
		    	format { - }
    	    	    }]
		    [if {[field $res alloc_db_head]} {
		    	format %04xh [field $res alloc_db_head]
    	    	    } else {
		    	format FREE
    	    	    }]
		    [if {$rtype == io} {
		    	field $res addr_lines
    	    	    }]]
		    
	    if {[field $res alloc_db_head]} {
		var pref {}
		[for {var a [field $res alloc_db_head]}
		     {$a != 0}
		     {var a [field $alloc rq_next]}
		{
		    var alloc [value fetch cserv::_TEXT:$a $adb]
		    var clt [value fetch cserv::_TEXT:[field $alloc clt_db_ptr] $cdb]
		    echo [format {%s%04xh @ %04xh:%04xh} $pref
			    [field $clt handle]
			    [expr ([field $clt callback]>>16)&0xffff]
			    [expr [field $clt callback]&0xffff]]
		    var pref [format {%45s} {}]
		}]
	    } else {
		echo n/a
	    }
    	}]
    } {
    	if {![null $rdb]} {
    	    type delete $rdb
    	}
    	if {![null $adb]} {
    	    type delete $adb
    	}
    	if {![null $cdb]} {
    	    type delete $cdb
    	}
    }
}]

##############################################################################
#				csmem
##############################################################################
#
# SYNOPSIS:	Print out the memory address resource database
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
#	ardeb	12/ 6/93	Initial Revision
#
##############################################################################
[defsubr csmem {}
{
    if {[null [patient find cserv]]} {
    	def-cs
    }
    
    csres cserv::_Mem_Rsrc_DB
}]


##############################################################################
#				csio
##############################################################################
#
# SYNOPSIS:	Print out the I/O port resource database
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
#	ardeb	12/ 6/93	Initial Revision
#
##############################################################################
[defsubr csio {}
{
    if {[null [patient find cserv]]} {
    	def-cs
    }
    
    csres cserv::_IO_Rsrc_DB
}]

##############################################################################
#				csirq
##############################################################################
#
# SYNOPSIS:	Print out the interrupt request resource database
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
#	ardeb	12/ 6/93	Initial Revision
#
##############################################################################
[defsubr csirq {}
{
    if {[null [patient find cserv]]} {
    	def-cs
    }
    
    csres cserv::_Irq_Rsrc_DB
}]

[defsubr def-sram {}
{
    require dos-foreach-device dos
    require dos-foreach-dcb dos

    dos-foreach-device {
    	[if {![value fetch $ds:$do.DH_attr.DA_CHAR_DEV]} {
    	    dos-foreach-dcb {
	    	[if {[value fetch $dcs:$dco.DCB_deviceHeader.segment] == $ds &&
		     [value fetch $dcs:$dco.DCB_drive] == 6}
    	    	{
		    # found DCB for drive G, the first SRAM drive
	    	    var p [dossym sram /n/nevada/tools/zoomer/sram/bullet/spkss2.sym $ds]
		    break
    	    	}]
    	    }
    	}]
	if {![null $p]} {
	    break
    	}
    }
    return $p
}]

##############################################################################
#				csclts
##############################################################################
#
# SYNOPSIS:	Print the list of clients registered with SystemSoft
#   	    	Card Services
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
#	ardeb	12/ 6/93	Initial Revision
#
##############################################################################
[defsubr csclts {}
{
    if {[null [patient find cserv]]} {
    	def-cs
    }
    protect {
    	var cdb [type make pstruct
	    	 q_next [type make nptr [type void]]
		 q_prev [type make nptr [type void]]
		 handle [type word]
		 status_chg [type byte]
		 callback [type make fptr [type void]]
    	    	]

    	[foreach q {{{I/O Clients} _IO_Client_DB}
		    {{Memory Clients} _Mem_Client_DB}
		    {{Memory Technology Clients} _Mtd_Client_DB}}
    	{
    	    var banner {=======================================================}
	    var hdr [index $q 0]
	    echo $banner
	    echo [format {%*s%s} [expr ([length $banner char]-[length $hdr char])/2]
	    	    {} $hdr]
    	    echo $banner

	    [for {var c [value fetch cserv::[index $q 1] word]}
	    	 {$c != 0}
		 {var c [field $clt q_next]}
    	    {
    	    	var clt [value fetch cserv::_TEXT:$c $cdb]
	    	echo [format {%04xh @ %04xh:%04xh} 
		    	    [field $clt handle]
			    [expr ([field $clt callback]>>16)&0xffff]
			    [expr [field $clt callback]&0xffff]]
    	    }]
    	}]
    } {
    	if {![null $cdb]} {
	    type delete $cdb
    	}
    }
}]
