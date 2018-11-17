##############################################################################
#
# 	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	clavin.tcl
# AUTHOR: 	Adam de Boor, Sep 19, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	cpanels	    	    	Print out the control panels up for the
#				inbox or outbox
#   	cmedia	    	    	Print out the contents of maps related to
#				media
#   	dmap	    	    	Print out the device driver maps
#	vms 	    	    	Print out the stuff in the VM Store
#   	msgq	    	    	Print out the contents of a message DBQ
#   	track-refs  	    	Track the addition and removal of references
#				to messages
#   	cthread	    	    	Prints info about the running transmit or
#				receive threads
#   	capps	    	    	Prints the app token -> name map
#   	cmsg	    	    	Prints info for a single message
#   	cprog	    	    	Prints the list of progress boxes for one of
#				the two possible directions
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/19/94		Initial Revision
#
# DESCRIPTION:
#	Random Tcl routines to print out Clavin data structures
#
#	$Id: clavin.tcl,v 1.9 96/04/11 17:40:09 adam Exp $
#
###############################################################################

defvar clavin-transport-types {
    {0 mailbox::GeoworksMailboxTransportID}
}

defvar clavin-media-types {
    {0 mailbox::GeoworksMediumID}
}

defvar clavin-storage-types {
    {0 mailbox::GeoworksMailboxStorageID}
}

defvar clavin-format-types {
    {0 mailbox::GeoworksMailboxDataFormatID}
}

[defsubr clavin-get-admin-file {}
{
    var admin [value fetch mailbox::adminInitFile]

    if {$admin == 0} {
    	error {admin file not open yet}
    } else {
    	return $admin
    }
}]

#
# like penum, but returns the number, not nil, if the thing's not in the type
#
[defsubr clavin-map-enum {num type}
{
    var res [type emap $num [symbol find type $type]]
    if {[null $res]} {
    	var res $num
    }
    return $res
}]


[defsubr fmtstruct-MailboxDataFormat {type val offset space}
{
    global clavin-format-types
    
    return [format-clavin-token ${clavin-format-types} $type $val $offset 
    	    $space]
}]

[defsubr fmtstruct-MailboxStorage {type val offset space}
{
    global clavin-storage-types
    
    return [format-clavin-token ${clavin-storage-types} $type $val $offset 
    	    $space]
}]

[defsubr fmtstruct-MailboxTransport {type val offset space}
{
    global clavin-transport-types
    
    return [format-clavin-token ${clavin-transport-types} $type $val $offset 
    	    $space]
}]

[defsubr fmtstruct-MediumType {type val offset space}
{
    global clavin-media-types
    
    return [format-clavin-token ${clavin-media-types} $type $val $offset 
    	    $space]
}]

[defsubr clavin-get-names {map man id}
{
    var mname [type emap $man [symbol find type geos::ManufacturerID]]
    if {[null $mname]} {
    	var mname $man
    } elif {[string match $mname MANUFACTURER_ID_*]} {
    	var mname [range $mname 16 end char]
    }

    foreach i $map {
    	if {[index $i 0] == $man} {
	    foreach t [range $i 1 end] {
	    	var idname [type emap $id [symbol find type $t]]
		if {![null $idname]} {
		    break
    	    	}
    	    }
    	}
    }
    
    if {[null $idname]} {
    	var idname $id
    }
    return [list $mname $idname]
}]

[defsubr format-clavin-token {map type val offset space}
{
    var res [clavin-get-names $map [index [index $val 1] 2] 
    	    	[index [index $val 0] 2]]
    echo -n [index $res 0]::[index $res 1]
    return 1
}]

[defsubr fmtstruct-GeodeToken {type val offset space}
{
    var man [field $val GT_manufID]
    var mname [type emap $man [symbol find type geos::ManufacturerID]]
    if {[null $mname]} {
    	var mname $man
    } elif {[string match $mname MANUFACTURER_ID_*]} {
    	var mname [range $mname 16 end char]
    }
    echo -n [format {"%s", %s} [mapconcat c [field $val GT_chars] {var c}]
    	    $mname]
    return 1
}]

[defsubr fmtstruct-TalID {type val offset space}
{
    if {[field $val TID_ADDR_INDEX]} {
    	echo -n addr #[field $val TID_NUMBER]
    } else {
    	echo -n ID #[field $val TID_NUMBER]
    }
    return 1
}]

[defcommand msgq {head} top.clavin
{Usage:
    msgq <head>

Examples:
    "msgq di"	Print the contents of the message queue whose handle is in di
    "msgq -i"	Print the contents of the inbox
    "msgq -o" 	Print the contents of the outbox
    "msgq -t:1"	Print the queue for the outbox transmit thread mailbox:1

Synopsis:
    

Notes:
    * The numbers under the "@" heading are value history references to the
      MailboxMessageDesc structures for the individual messages.

See also:
    othread.
}
{
    var admin [clavin-get-admin-file]
    if {[string match $head -*]} {
        # make sure the header block is in so we can get the map block handle
        require ensure-vm-block-resident vm
        ensure-vm-block-resident $admin 32
    
        var map [value fetch (^v$admin:32).geos::VMH_mapBlock]
	ensure-vm-block-resident $admin $map
	[case $head in
	    -i	{var head [value fetch (^v$admin:$map).mailbox::AMB_inbox]}
	    -o	{var head [value fetch (^v$admin:$map).mailbox::AMB_outbox]}
	    -t* {
	    	var tnum [range $head 2 end char]
		if {[index $tnum 0 char] == :} {
		    var tnum [range $tnum 1 end char]
		    foreach t [patient threads [patient find mailbox]] {
		    	if {[thread number $t] == $tnum} {
			    var tnum [thread id $t]
			    break
    	    	    	}
    	    	    }
    	    	} else {
		    var tnum [getvalue $tnum]
    	    	}
    	    	var t [carray-enum *mailbox::mainThreads clavin-find-thread $tnum]
		if {$t == 0} {
		    error [format {%s is not a mailbox transmit thread}
		    	    [range $head 2 end char]]
    	    	}
		var head [value fetch $t.mailbox::OTD_dbq]
		var ids [list [value fetch $t.mailbox::OTD_queuedID]
			      [value fetch $t.mailbox::OTD_xmitID]]
    	    }
	    default {
	    	error [format {unknown queue designator %s} $head]
    	    }
    	]
    } else {
    	var head [getvalue $head]
    }
    
    pmsg-banner
    var msgtype [symbol find type mailbox::MailboxMessageDesc]
    require harray-enum hugearr
    harray-enum $admin $head msgq-callback [list $admin $msgtype]
}]

[defsubr clavin-find-thread {elNum elAddr elSize tnum}
{
    if {[value fetch ($elAddr).mailbox::MTD_thread] == $tnum} {
    	return $elAddr
    } else {
    	return 0
    }
}]

[defsubr msgq-callback {elNum elAddr elSize extra}
{
    [var grp [value fetch ($elAddr).geos::DBGI_group] 
	 item [value fetch ($elAddr).geos::DBGI_item]]

    var admin [index $extra 0] msgtype [index $extra 1]
    pmsg-desc $admin $grp $item $msgtype
    # keep going, please
    return 0
}]

[defsubr pmsg-banner {}
{
    #     %3d  %04xh %04xh  %3d  %30.30s                         %s
    echo { @   Group Item   Ref  Subject                         Trans/Dest}
    echo {---  ----- -----  ---  ------------------------------  ----------}
}]

[defsubr pmsg-desc {admin grp item msgtype}
{
    # run through the db structures to get to the item block for the message
    require map-db-item-to-addr db
    var msg [map-db-item-to-addr $admin $grp $item]

    # make sure the item block is in memory so we can get to the message data
    ensure-vm-block-resident $admin [index $msg 0]
    
    var a [addr-preprocess *(^v$admin:[index $msg 0]):[index $msg 3] s o]
    var h [value hstore [concat [range $a 0 1] [list $msgtype]]]
    var subj [getstring *$s:$o.mailbox::MMD_subject 30]
    
    echo -n [format {%3d  %04xh %04xh  %3d  %-30.30s  }
    	    	$h $grp $item [value fetch $s:$o.mailbox::DBQD_refCount] $subj]
    if {[value fetch $s:$o.mailbox::MMD_transport dword] == 0} {
	fmtstruct-GeodeToken {} [value fetch $s:$o.mailbox::MMD_destApp] 0 0
    } else {
    	fmtstruct-MailboxTransport {} [value fetch $s:$o.mailbox::MMD_transport] 0 0
    }
    echo
}]

[defcommand cmsg {grp {item {}}} top.clavin
{Usage:
    cmsg <group> <item>
    cmsg <variable>

Examples:
    "cmsg dx ax"	Prints a short description of the message whose 
			MailboxMessage token resides in dxax
    "cmsg curMsg"   	Prints a short description of the message whose
			MailboxMessage token is in the "curMsg" variable.

Synopsis:
    Prints a short description of a particular message

Notes:
    * To look at the individual fields of the message descriptor, use @n in
      subsequent commands, where n is the number in the @ column of this 
      command's output.

See also:
    msgq.
}
{
    cmsg-parse-args $grp $item 0 grp item

    #
    # Now we've got the group and item, use common code to print the
    # thing out.
    #
    pmsg-banner
    pmsg-desc [clavin-get-admin-file] $grp $item [symbol find type mailbox::MailboxMessageDesc]
}]

[defsubr cmsg-parse-args {grp item mayBeMMD grpVar itemVar}
{
    require map-db-item-to-addr db

    if {[null $item]} {
    	#
    	# Only got one argument. It might be a variable holding a MailboxMessage
	# token. Parse the address to find out.
	#
    	var a [addr-parse $grp 0]
	var t [index $a 2]

	if {[index $a 0] == value} {
	    # it's a literal of some sort
	    [if {[type class [index $a 2]] == int && 
	         [type size [index $a 2]] == 4}
    	    {
	    	# it's the right size of literal, too, so just use its two 
		# halves. never know when Swat might start supporting register
		# pairs in expressions...
	    	var grp [expr ([index $a 1]>>16)&0xffff]
		var item [expr [index $a 1]&0xffff]
    	    } else {
	    	error [format {must have a MailboxMessage variable or the two words of the MailboxMessage in order to function. You gave just "%s"} $grp]
    	    }]
    	} elif {$mayBeMMD && ([null $t] ||
	        [type name $t {} 0] == {struct MailboxMessageDesc} )} {
    	    # do nothing
    	} elif {[type size $t] != 4} {
	    error [format {%s is not the right size to be a MailboxMessage variable} $grp]
    	} else {
	    # Fetch the two words from memory, please
	    [var grp [value fetch {((dword)$grp).high}]
		 item [value fetch {((dword)$grp).low}]]
    	}
    } else {
    	# Break the arguments into literals, please, from registers or
	# whatever they happen to be
        var grp [getvalue $grp] item [getvalue $item]
    }
    uplevel 1 var $grpVar $grp $itemVar $item
}]



[defcommand cmsgaddr {grp {item {}}} top.clavin
{Usage:
    cmsgaddr <MailboxMessageDesc>
    cmsgaddr <MailboxMessage>
    cmsgaddr <group> <item>

Examples:
    "cmsgaddr @16"	Prints out the addresses for the message that was 
			printed by msgq with an @-column entry of 16
    "cmsgaddr dx ax"	Prints out the addresses for the message whose
			MailboxMessage token is in dxax

Synopsis:
    Displays the address(es) for a registered Clavin message. If the message
    is in the inbox, the address(es) displayed is(are) the source address(es).

Notes:

See also:
    cmsg, msgq.
}
{
    var admin [clavin-get-admin-file]
    var reasons [index [clavin-get-map-word outboxReasons] 1]
    ensure-vm-block-resident $admin $reasons

    cmsg-parse-args $grp $item 1 grp item

    if {![null $item]} {
    	var msg [map-db-item-to-addr $admin $grp $item]
	ensure-vm-block-resident $admin [index $msg 0]
	
	var a [addr-preprocess *(^v$admin:[index $msg 0]):[index $msg 3] s o]
    } else {
    	var a [addr-preprocess $grp s o]
    }
    
    var ra [value fetch (^v$admin:$reasons):LMBH_offset]
    addr-preprocess (^v$admin:$reasons):$ra rs ro

    carray-enum *($s:$o.mailbox::MMD_transAddrs) cmsgaddr-callback $rs:$ro
}]

[defsubr cmsgaddr-callback {elNum elAddr elSize extra}
{
    echo =============== #$elNum ===============
    echo Medium = [value fetch ($elAddr).mailbox::MITA_medium]
    echo Addr List = [value fetch ($elAddr).mailbox::MITA_addrList]
    var f [value fetch ($elAddr).mailbox::MITA_flags]
    if {[field $f MTF_TRIES]} {
        var reason [value fetch ($elAddr).mailbox::MITA_reason]
        echo -n Reason = ${reason}:\ 
        var raddr [carray-get-element-addr *($extra) $reason]
        var rsize [expr [carray-get-element-size *($extra) $reason]-[getvalue NAE_data]]
        pstring -l $rsize $raddr.NAE_data
    }
    echo -n {Flags = }
    var state [clavin-map-enum [field $f MTF_STATE]
    	    	mailbox::MailboxAddressState]
    if {[string match $state MAS_*]} {
    	var state [range $state 4 end char]
    }
    echo [format {%s, %s#tries = %d} $state 
		 [if {[field $f MTF_DUP]} {format {DUP, }}]
		 [field $f MTF_TRIES]]
    var olen [value fetch ($elAddr).mailbox::MITA_opaqueLen]
    echo -n {To: }
    pstring &($elAddr).mailbox::MITA_opaque+$olen
    if {$olen != 0} {
	echo Opaque data:
	var t [type make array $olen [type byte]]
	var b [value fetch ($elAddr).mailbox::MITA_opaque $t]
	type delete $t
	fmt-bytes $b 0 $olen 4
    }
    return 0
}]

    
    
[defcommand track-refs {{mode on}} top.clavin
{Usage:
    track-refs (on|off)

Examples:
    "track-refs on"	Turns on debugging info showing each reference being
			added or removed to any Clavin message
    "track-refs off"   	Turns off debugging info

Synopsis:
    Provides the information needed to find what is leaving around references to
    Clavin messages. It prints out what routine (outside the DBQ module) is
    causing each reference to be added or removed. You can pair them up to
    find which is missing the required DBQDelRef call.

See also:
    msgq.
}
{
    global track-refs-bps
    
    if {${track-refs-bps} != {}} {
    	eval [concat brk clear ${track-refs-bps}]
	var track-refs-bps {}
    }
    if {$mode == on} {
    	var track-refs-bps [list [brk mailbox::DBQAddRef track-ref-add]
				 [brk mailbox::DBQDelRef track-ref-del]]
    }
}]

[defsubr track-ref-add {}
{
    track-ref-common Adding to 1
    return 0
}]

[defsubr track-ref-del {}
{
    track-ref-common Removing from -1
    return 0
}]

[defsubr track-ref-common {verb prep diff}
{
    var admin [clavin-get-admin-file]
    var grp [read-reg dx] item [read-reg ax]
    
    # run through the db structures to get to the item block for the message
    require map-db-item-to-addr db
    var msg [map-db-item-to-addr $admin $grp $item]

    # make sure the item block is in memory so we can get to the message data
    ensure-vm-block-resident $admin [index $msg 0]
    
    var a [addr-preprocess *(^v$admin:[index $msg 0]):[index $msg 3] s o]

    var subj [getstring *$s:$o.mailbox::MMD_subject 30]

    echo [format {%s reference %s %04xh %04xh (new = %d): %s} $verb $prep
	   $grp $item
	   [expr [value fetch $s:$o.mailbox::MMD_dbqData.DBQD_refCount]+$diff]
	   $subj]
    echo -n {    }
    [for {var f [frame top]
    	  var n [frame function $f]]}
    	 {[symbol name [symbol scope [frame funcsym $f]]] == DBQ ||
	  [string match $n HugeArray*] ||
	  [string match $n ChunkArray*] ||
	  $n == ResourceCallInt}
	 {var f [frame next $f]
	  var n [frame function $f]}
    {
    	[if {$n != ResourceCallInt && 
	     $n != HugeArrayEnumCallback && 
	     $n != ChunkArrayEnumCommon}
    	{
    	    echo -n $n {<- }
    	}]
    }]
    echo $n
}]

[defcommand cpanels {which} top.clavin
{Usage:
    cpanels <which>

Examples:
    "cpanels -o"	Print the list of control panels up for the outbox
    "cpanels -i"	Print the list of control panels up for the inbox

Synopsis:
    Prints a description of the control panels currently on-screen for one of
    the boxes

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    [case $which in
    	-o  {var v MAI_outPanels}
	-i  {var v MAI_inPanels}
	default {error [format {unknown panel type %s} $which]}]

    addr-preprocess [appobj mailbox] s o
    var o [expr $o+[value fetch $s:$o.ui::Gen_offset]]
    
    require fmtoptr print
    var dt [symbol find type mailbox::MailboxDisplayPanelType]
    var coff [getvalue mailbox::MADP_criteria]

    var sys [value fetch $s:$o.mailbox::$v.mailbox::MPBD_system]
    [for {var head [value fetch $s:$o.mailbox::$v.mailbox::MPBD_panels]}
    	 {$head != 0}
	 {var head [value fetch (*$s:$head).mailbox::MADP_next]}
    {
    	addr-preprocess (*$s:$head) ps po
    	var h [value fetch $ps:$po.mailbox::MADP_panel.handle]
	var c [value fetch $ps:$po.mailbox::MADP_panel.chunk]
	var nt [value fetch $ps:$po.mailbox::MADP_type]
	fmtoptr $h $c
    	echo
	
	var t [type emap $nt $dt]

	[case $t in
	    MDPT_BY_APP_TOKEN {
	    	cpanel-print-app-token-criteria $ps [expr $po+$coff]
	    }
	    MDPT_BY_MEDIUM {
	    	cpanel-print-medium-criteria $ps [expr $po+$coff]
	    }
	    MDPT_BY_TRANSPORT {
	    	cpanel-print-transport-criteria $ps [expr $po+$coff]
		cpanel-print-medium-criteria $ps [expr $po+$coff+[value fetch ($ps:$po+$coff).mailbox::MDBTD_addrSize]+[type size [symbol find type mailbox::MailboxDisplayByTransportData]]]
	    }
	    MDPT_ALL {
	    	echo {  ALL MESSAGES}
	    }
	    default {
	    	echo {  Invalid type:} $nt
	    }]
    }]
}]

[defsubr cpanel-print-app-token-criteria {s o}
{
        echo -n {  By App Token: }
	fmtstruct-GeodeToken {} [value fetch $s:$o.mailbox::MDBAD_token] 0 0
	echo
}]
    
[defsubr cpanel-print-medium-criteria {s o}
{
    echo {  By Medium: }
    echo -n {     Transport: }
    fmtstruct-MailboxTransport {} [value fetch $s:$o.mailbox::MDBMD_transport] 0 0
    echo [format { #%d} [value fetch $s:$o.mailbox::MDBMD_transOption]]
    echo -n {     Medium: }
    fmtstruct-MediumType {} [value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_medium] 0 0
    echo -n { Unit: }
    [case [type emap
		[value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_unitType]
		[symbol find type mailbox::MediumUnitType]] in
    	MUT_ANY {echo Any}
	MUT_INT {echo [value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_unit word]}
	MUT_NONE {echo n/a}
	MUT_MEM_BLOCK {
	    var l [value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_unitSize]
	    var bt [type make array $l [type byte]]
	    var b [value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_unit $bt]
	    type delete $bt
	    echo {Data:}
	    require fmt-bytes memory
	    fmt-bytes $b 0 $l 5
    	}
    	default {
	    echo ??? ([value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_unitType])
    	}
    ]
}]
    
[defsubr cpanel-print-transport-criteria {s o}
{
    echo {  By Transport: }
    echo -n {     Transport: }
    fmtstruct-MailboxTransport {} [value fetch $s:$o.mailbox::MDBMD_transport] 0 0
    echo [format { #%d} [value fetch $s:$o.mailbox::MDBMD_transOption]]
    echo -n {     Medium: }
    fmtstruct-MediumType {} [value fetch $s:$o.mailbox::MDBMD_medium.mailbox::MMD_medium] 0 0
    echo
    echo {     Address: }
    var l [value fetch $s:$o.mailbox::MDBTD_addrSize]
    var bt [type make array $l [type byte]]
    var b [value fetch $s:$o.mailbox::MDBTD_addr $bt]
    type delete $bt
    require fmt-bytes memory
    fmt-bytes $b 0 $l 5
}]
    
[defcommand cprog {which} top.clavin
{Usage:
    cprog <which>

Examples:
    "cprog -o"	    	Print the list of progress boxes for transmission
    "cprog -i"	    	Print the list of progress boxes for reception

Synopsis:
    Prints the array of progress boxes for transmission or reception.

See also:
    cpanels.
}
{
    [case $which in
    	-o  {var v MAI_outPanels}
	-i  {var v MAI_inPanels}
	default {error [format {unknown progress type %s} $which]}]

    addr-preprocess [appobj mailbox] s o
    var o [expr $o+[value fetch $s:$o.ui::Gen_offset]]
    var a [value fetch $s:$o.mailbox::$v.mailbox::MPBD_progressBoxes]
    if {$a == 0} {
    	echo no progress boxes registered
    } else {
	require fmtoptr print
	carray-enum *$s:$a cprog-callback {}
    }
}]

[defsubr cprog-callback {elNum elAddr elSz args}
{
    echo -n [format {#%2d: } $elNum]
    fmtoptr [value fetch ($elAddr).handle] [value fetch ($elAddr).chunk]
    echo
    return 0
}]

[defsubr clavin-get-map-word {name}
{
    var admin [clavin-get-admin-file]

    # make sure the header block is in so we can get the map block handle
    require ensure-vm-block-resident vm
    ensure-vm-block-resident $admin 32

    var map [value fetch (^v$admin:32).geos::VMH_mapBlock]
    ensure-vm-block-resident $admin $map
    return [list $admin [value fetch (^v$admin:$map).mailbox::AMB_$name]]
}]

[defcommand cmedia {what} {top.clavin}
{Usage:
    cmedia -s [<manuf> <id>]
    cmedia -t [<manuf> <id>]
    cmedia -o

Examples:
    "cmedia -s"	Shows the currently available/connected media units.
    "cmedia -t"	Shows the media -> transport driver mapping
    "cmedia -o" Lists all the media/transport/transOption tuples for messages
		in the outbox

Synopsis:
    Prints out information about transport media, as stored in the Mailbox
    library's administrative file.

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    [case $what in
    	-t {
	    var trans [clavin-get-map-word mediaTrans]
	    var admin [index $trans 0] trans [index $trans 1]

	    ensure-vm-block-resident $admin $trans
	    echo All Transport Capabilities:
	    echo -n {    }
    	    require fmtrecord print
	    [fmtrecord [symbol find type mailbox::MailboxTransportCapabilities]
		[value fetch (^v$admin:$trans).mailbox::MTH_allCaps] 4]
	    echo
	    addr-preprocess ^v$admin:$trans s o
	    var mref [symbol find type mailbox::MediaTransportMediaRef]
	    var mtrans [symbol find type mailbox::MediaTransportElement]
	    [carray-enum *$s:[value fetch $s:LMBH_offset] cmedia-media-trans-callback
	     [list [type size $mref] [getvalue mailbox::MTME_transports] $mref $mtrans]]
    	}
	-s {
	    var stat [clavin-get-map-word media]
	    var admin [index $stat 0] stat [index $stat 1]
    	    if {[null [symbol find var mailbox::dgroup::inboxDirMap]]} {
	    	# status map is in the admin file
	    	ensure-vm-block-resident $admin $stat
	    	addr-preprocess ^v$admin:$stat s o
    	    } else {
	    	# handle is actually a memory block
		addr-preprocess ^h$stat s o
    	    }
	    [carray-enum *$s:[value fetch $s:LMBH_offset] cmedia-status-callback
	    	[getvalue mailbox::MSE_unitData]]
	}
	-o {
	    var om [clavin-get-map-word outboxMedia]
	    var admin [index $om 0] om [index $om 1]

	    ensure-vm-block-resident $admin $om
	    addr-preprocess ^v$admin:$om s o
	    [carray-enum *$s:[value fetch $s:LMBH_offset] cmedia-om-callback
	    	?]
    	}
	-ou {
	    var om [clavin-get-map-word outboxMedia]
	    var admin [index $om 0] om [index $om 1]
	    ensure-vm-block-resident $admin $om
	    addr-preprocess ^v$admin:$om s o
	    [carray-enum *$s:[expr [value fetch $s:LMBH_offset]+2] cmedia-omu-callback]
        }
    ]
}]

[defsubr cmedia-om-callback  {elNum elAddr elSize extra}
{
    echo -n [format {%3d: } $elNum]
    if {[value fetch ($elAddr).mailbox::OMTP_meta.REH_refCount.WAAH_high] == 0xff} {
    	echo FREE ENTRY
    } else {
	fmtstruct-MailboxTransport {} [value fetch ($elAddr).mailbox::OMTP_transport] 0 0
	echo -n , #[value fetch ($elAddr).mailbox::OMTP_transOption] {via }
	fmtstruct-MediumType {} [value fetch ($elAddr).mailbox::OMTP_medium] 0 0
	var refs [value fetch ($elAddr).mailbox::OMTP_meta.REH_refCount.WAAH_low]
	echo , $refs [pluralize message $refs]
    }
    return 0
}]

[defsubr cmedia-omu-callback  {elNum elAddr elSize extra}
{
    echo -n [format {%2d: } $elNum]
    if {[value fetch ($elAddr).mailbox::OMU_meta.REH_refCount.WAAH_high] == 0xff} {
    	echo FREE ENTRY
    } else {
    	fmtstruct-MediumType {} [value fetch ($elAddr).mailbox::OMU_data.MMD_medium] 0 0
	var refs [value fetch ($elAddr).mailbox::OMU_meta.REH_refCount.WAAH_low]
	echo , $refs [pluralize message $refs]
	[case [clavin-map-enum [value fetch ($elAddr).mailbox::OMU_data.MMD_unitType]
		    mailbox::MediumUnitType] in
	  MUT_NONE {}
	  MUT_INT {
	    echo [format {    Unit: %d} [value fetch ($elAddr).mailbox::OMU_data.MMD_unit
					       word]]
	  }
	  MUT_MEM_BLOCK {
	    var bt [type make array [value fetch ($elAddr).mailbox::OMU_data.MMD_unitSize] [type byte]]
	    var b [value fetch ($elAddr).mailbox::OMU_data.MMD_unit $bt]
	    echo {    Unit:}
	    fmt-bytes $b 0 [type size $bt] 4
	    type delete $bt
	 }
	 default {
	    echo {    Unit type unknown}
	 }
	]
    }
    return 0
}]

[defsubr cmedia-status-callback {elNum elAddr elSize udOff}
{
    var flags [value fetch ($elAddr).mailbox::MSE_flags]
    echo -n [format {%-4s} [format {%s%s}
    	    	[if {[field $flags MSF_AVAILABLE]} {format A}]
		[if {[field $flags MSF_CONNECTED]} {format C}]]]
    fmtstruct-MediumType {} [value fetch ($elAddr).mailbox::MSE_medium] 0 0
    echo
    [case [clavin-map-enum [value fetch ($elAddr).mailbox::MSE_unitType]
    	    	mailbox::MediumUnitType] in
      MUT_NONE {}
      MUT_INT {
      	echo [format {    Unit: %d} [value fetch ($elAddr).mailbox::MSE_unitData
					   word]]
      }
      MUT_MEM_BLOCK {
      	var bt [type make array [expr $elSize-$udOff] [type byte]]
	var b [value fetch ($elAddr).mailbox::MSE_unitData $bt]
	echo {    Unit:}
	fmt-bytes $b 0 [type size $bt] 4
	type delete $bt
     }
     default {
     	echo {    Unit type unknown}
     }
    ]
    var addr [value fetch ($elAddr).mailbox::MSE_addrs]

    if {[field $flags MSF_CONNECTED] && $addr} {
    	echo -n {    Connected to: }
    	for {} {$addr} {var addr [value fetch (*$s:$addr).mailbox::MCD_next]} {
	    addr-preprocess $elAddr s o
	    fmtstruct-MailboxTransport {} [value fetch (*$s:$addr).mailbox::MCD_data.MDBTD_transport] 0 0
	    echo , #[value fetch (*$s:$addr).mailbox::MCD_data.MDBTD_transOption]
	    var asize [value fetch (*$s:$addr).mailbox::MCD_data.MDBTD_addrSize]
	    if {$asize} {
		var bt [type make array $asize [type byte]]
		var b [value fetch (*$s:$addr).mailbox::MCD_data.MDBTD_addr $bt]
		fmt-bytes $b 0 $asize 4
		type delete $bt
	    }
    	}
    }
    var reason [value fetch ($elAddr).mailbox::MSE_reason]
    if {![field $flags MSF_AVAILABLE] && $reason} {
    	addr-preprocess $elAddr s o
    	echo {    Reason:} [getstring *$s:$reason]
    }
    return 0
}]

[defsubr cmedia-media-trans-callback {elNum elAddr elSize extra}
{
    echo -n {Medium: }
    fmtstruct-MediumType {} [value fetch $elAddr.mailbox::MTME_medium] 0 0
    echo
    addr-preprocess $elAddr s o
    var mref [index $extra 2] mrefsize [index $extra 0] mtrans [index $extra 3]
    [for {var i [index $extra 1]}
	 {$i < $elSize}
	 {var i [expr $i+$mrefsize]}
    {
    	var t [value fetch $s:$o+$i $mref]
	var pref [format {    #%d: } [field $t MTMR_transport]]
	echo -n $pref
	var trans [field $t MTMR_transport]
	
    	var te [carray-get-element *($s:([value fetch $s:LMBH_offset]+2)) 
				  $trans $mtrans]

	fmtstruct-MailboxTransport {} [field $te MTE_transport] 0 0
	echo , #[field $te MTE_transOption]
	if {[field $t MTMR_verb]} {
	    var verb [getstring *$s:[field $t MTMR_verb]]
	} else {
	    var verb ???
    	}
	if {[field $t MTMR_abbrev]} {
	    var abbr [getstring *$s:[field $t MTMR_abbrev]]
	} else {
	    var abbr ???
    	}
	echo [format {%*sVerb: "%s", Abbr: "%s", SigAddrBytes = %d}
	    	     [length $pref char] {}
		     $verb $abbr [field $t MTMR_sigAddrBytes]]
	    	    
    }]
    return 0
}]
    	 
    
[defcommand dmap {which} top.clavin
{Usage:
    dmap (-t | -d)

Examples:
    "dmap -t"	Print out the transport driver map
    "dmap -d" 	Print out the data driver map

Synopsis:
    Displays the contents of the driver maps for the transport and data drivers

Notes:

See also:
    cmedia
}
{
    [case $which in 
     	-t  {
	    var dmap [clavin-get-map-word transMap]
	    var ttype [symbol find type mailbox::MailboxTransport]
	    var atype [symbol find type mailbox::MailboxTransportCapabilities]
	}
	-d  {
	    var dmap [clavin-get-map-word dataMap]
	    var ttype [symbol find type mailbox::MailboxStorage]
	    var atype [symbol find type mailbox::MailboxDataCapabilities]
    	}
	default {error [format {unknown dmap: %s} $which]}]
    
    var admin [index $dmap 0] dmap [index $dmap 1]
    ensure-vm-block-resident $admin $dmap
    addr-preprocess ^v$admin:$dmap s o

    echo -n {Token: }
    fmtstruct-GeodeToken {} [value fetch $s:mailbox::DMH_token] 0 0
    echo [format { Path: %s} 
		 [getstring $s:mailbox::DMH_sysPath 32]]
    echo -n [format {Protocol: %d.%d, Flags: }
    	    	[value fetch $s:mailbox::DMH_protocol.PN_major]
		[value fetch $s:mailbox::DMH_protocol.PN_minor]]
    require fmtrecord print
    [fmtrecord [symbol find type mailbox::DriverMapFlags]
    	[value fetch $s:mailbox::DMH_flags] 4]
    echo

    [carray-enum *$s:[value fetch $s:LMBH_offset] dmap-print
    	[list [symbol find type mailbox::DriverMapEntry] $ttype $atype]]

    if {[value fetch $s:mailbox::DMH_callbacks]} {
    	echo Callbacks:
	[carray-enum *$s:[value fetch $s:mailbox::DMH_callbacks] dmap-print-cb 
	    [list 
	     [handle id [index [patient resources [patient find mailbox]] 0]]
	     $ttype]]
    }
}]

[defsubr dmap-fmt-token {n type}
{
    var flds [type fields $type] tname [symbol name $type]

    var tval [map i $flds {
    	var f [expr $n&0xffff]
	var n [expr $n>>16]
	list [index $i 0] [index $i 3] $f
    }]
    
    fmtstruct-[symbol name $type] {} $tval 0 0
}]

[defsubr dmap-print-cb {elNum elAddr elSize data}
{
    dmap-fmt-token [value fetch ($elAddr).mailbox::DMC_token] [index $data 1]
    var rout [value fetch ($elAddr).mailbox::DMC_routine]
    var raddr [value fetch ^h[index $data 0].geos::GH_exportLibTabOff\[$rout\]]

    var s [expr ($raddr>>16)&0xffff] o [expr $raddr&0xffff]
    if {$s >= 0xf000} {
    	var r [symbol faddr proc ^h[expr ($s&0xfff)<<4]:$o]
    } else {
    	var r [symbol faddr proc $s:$o]
    }
    echo [format {, %s(%04xh, %04xh)} [symbol name $r]
    	    [value fetch ($elAddr).mailbox::DMC_cx]
    	    [value fetch ($elAddr).mailbox::DMC_dx]]

    return 0
}]

[defsubr dmap-print {elNum elAddr elSize types}
{
#    echo -n @[value hstore [concat [range [addr-parse $elAddr] 0 1] [list [index $types 0]]]]

    var d [value fetch $elAddr [index $types 0]]
    echo -n [format {#%d: } $elNum]
    dmap-fmt-token [field $d DME_token] [index $types 1]
    echo [format {%s, "%s"} 
	  [if {[field $d DME_handle]}
	      {[format { (%04xh)} [field $d DME_handle]]}]
    	  [mapconcat c [field $d DME_name] {
	    if {[string match $c {\\*}]} {
	    	break
    	    } else {
	    	var c
    	    }}]]

    foreach f [cvtrecord [index $types 2] [field $d DME_attrs]] {
    	if {[index $f 2]} {
	    echo [format {        %s} [index $f 0]]
    	}
    }

    return 0
}]

    
[defcommand vms {{what -a}} top.clavin
{Usage:
    vms -a
    vms -o

Examples:
    "vms -a"	Print a description of all the files in the VM store
    "vms -o"	Print a description of all open files in the VM store

Synopsis:
    Prints info about the VM store

Notes:

See also:
    msgq, cmedia, cpanels
}
{
    var vms [clavin-get-map-word vmStore]
    
    var admin [index $vms 0] vms [index $vms 1]
    ensure-vm-block-resident $admin $vms
    
    [carray-enum *(^v$admin:$vms):[value fetch (^v$admin:$vms).LMBH_offset]
    	vms-print $what]
}]

[defsubr vms-print {elNum elAddr elSize what}
{
    if {[value fetch ($elAddr).mailbox::VMSE_meta.NAE_meta.REH_refCount.WAAH_high] == 0xff} {
    	echo FREE ENTRY
	return 0
    }
    if {$what == {-o} && [value fetch ($elAddr).mailbox::VMSE_handle] == 0} {
    	return 0
    }
    var name [getstring ($elAddr).mailbox::VMSE_name 32]
    echo [format {%s%s:} $name
    	    [if {[value fetch ($elAddr).mailbox::VMSE_handle] != 0}
		{format { (%04xh)} [value fetch ($elAddr).mailbox::VMSE_handle]}]]
    echo [format {    References: %3d, Status = %s}
    	    [value fetch ($elAddr).mailbox::VMSE_refCount]
	    [type emap [value fetch ($elAddr).mailbox::VMSE_vmStatus]
	    	[symbol find type geos::VMStatus]]]
    echo [format {    Used: %4d, Free %4d, Size %5d}
    	    [value fetch ($elAddr).mailbox::VMSE_usedBlocks]
    	    [value fetch ($elAddr).mailbox::VMSE_freeBlocks]
    	    [value fetch ($elAddr).mailbox::VMSE_fileSize]]

    return 0
}]

[defcommand cthread {args} top.clavin
{Usage:
    cthread [-i | -o] [<thread-handle> | :<thread-num>]

Examples:
    "cthread"	    Prints info for all transmit threads
    "cthread -i"    Prints info for all registered receive threads
    "cthread bx"    Prints info for the transmit/receive thread whose handle is
		    in bx
    "cthread :2"    Prints info for the transmit/receive thread known as 
		    mailbox:2

Synopsis:
    Prints a summary of what each transmit or receive thread is 

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    var type -1 d mailbox::MainThreadData
    for {} {[length $args] > 0} {var args [range $args 1 end]} {
    	[case [index $args 0] in
	 -i {
	    var type [getvalue mailbox::MTT_RECEIVE]
	    var d mailbox::InboxThreadData
    	 }
	 -o {
	    var type [getvalue mailbox::MTT_TRANSMIT]
	    var d mailbox::OutboxThreadData
    	 }
	 default {
	    var tid [index $args 0]
	    break
    	 }]
    }
    if {![null $tid]} {
    	if {[string match $tid :*]} {
	    var tid [range $tid 1 end char]
	    foreach t [patient threads [patient find mailbox]] {
		if {[thread number $t] == $tid} {
		    var tid [thread id $t]
		    break
		}
	    }
    	} else {
	    var tid [getvalue $tid]
    	}
    }
    echo { @    TID   #  Transport/Medium}
    echo {---  -----  -  -----------------------------------------------}
    carray-enum *mailbox::mainThreads cthread-callback [list $tid $type $d]
}]

[defsubr cthread-callback {elNum elAddr elSize data}
{
    var tid [index $data 0] type [index $data 1] d [index $data 2]
    var id [value fetch $elAddr.mailbox::MTD_thread]
    [if {($type == -1 || [value fetch $elAddr.mailbox::MTD_type] == $type) &&
     	 ([null $tid] || $id == $tid)}
    {
    	var n [value hstore [addr-parse {$d $elAddr}]]
	foreach t [patient threads [patient find mailbox]] {
	    if {[thread id $t] == $id} {
	    	var tnum [thread number $t]
		break
    	    }
    	}
	echo -n [format {%3d  %04xh  %d  } $n $id $tnum]
	fmtstruct-MailboxTransport {} [value fetch $elAddr.mailbox::MTD_transport] 0 0
	echo -n #[value fetch $elAddr.mailbox::MTD_transOption]/
	[case $d in
	    *Inbox* {
	    	fmtstruct-MediumType {} [value fetch $elAddr.mailbox::ITD_medium] 0 0
		echo
    	    }
	    *Outbox* {
	    	echo [value fetch $elAddr.mailbox::OTD_medium]
    	    }
	    default {
	    	echo ?
    	    }
    	]
    }]
    return 0
}]

[defcommand capps {} top.clavin
{Usage:
    capps

Examples:
    "capps"	Prints out the table of applications about which Clavin knows.

Synopsis:
    Displays the mapping from token to name that Clavin maintains for
    applications.

Notes:
    * The token -> name mapping doubles as the thing that knows whether there
      are any messages for a particular token. This info is also printed out
      for you.

See also:
    msgq.
}
{
    var apps [clavin-get-map-word appTokens]
    var admin [index $apps 0] apps [index $apps 1]

    ensure-vm-block-resident $admin $apps
    
    addr-preprocess (^v$admin:$apps):[expr [value fetch (^v$admin:$apps).LMBH_offset]+2] s o

    [carray-enum *(^v$admin:$apps):[value fetch (^v$admin:$apps).LMBH_offset]
    	capps-print [list $s:$o [symbol find type geos::NameArrayElement]
	    	    	[getvalue geos::NAE_data]]]
}]

[defsubr capps-print {elNum elAddr elSize nameArray}
{
    [if {[value fetch ($elAddr).mailbox::IAD_meta.REH_refCount.WAAH_high]==0xff}
    {
    	echo FREE ENTRY?!
	return 0
    }]
    #
    # Print out the application's token, first, along with any interesting flags
    #
    echo -n [format {#%2d(@%d): } $elNum [value hstore [addr-parse {mailbox::InboxAppData $elAddr}]]]
    fmtstruct-GeodeToken {} [value fetch ($elAddr).mailbox::IAD_token] 0 0
    var flags [value fetch ($elAddr).mailbox::IAD_flags]
    echo -n [format { (%s%s)}
    	    	[if {[field $flags IAF_DONT_QUERY_IF_FOREGROUND]} 
		    {format Q}]
		[if {[field $flags IAF_DONT_TRY_TO_LOCATE_SERVER_AGAIN]}
		    {format S}]]
		    
    #
    # Figure if it's an alias or a real entry.
    #
    if {[field $flags IAF_IS_ALIAS]} {
    	#
	# Just say what it's an alias for.
	#
    	echo [format {, is alias for #%d} 
	    	[value fetch ($elAddr).mailbox::IAD_nameRef.IAN_aliasFor]]
    } else {
    	#
	# See if we've found the name for it yet.
	#
    	var num [value fetch ($elAddr).mailbox::IAD_nameRef.IAN_name]
	if {$num == 0xffff} {
	    echo {, name not found yet}
    	} else {
    	    #
	    # We have. Extract and print the name.
	    #
            var e [carray-get-element-addr *[index $nameArray 0] $num
	    	    [index $nameArray 1]]
    	    echo [format {, "%s"} [getstring $e.geos::NAE_data
	    	    	    	    [expr [carray-get-element-size *[index $nameArray 0] $num]-[index $nameArray 2]]]]
    	}
    }
    #
    # Let the user know how many messages there are for the thing. There is 
    # always one more reference than message.
    #
    var refs [expr ([value fetch ($elAddr).mailbox::IAD_meta.REH_refCount.WAAH_high]<<16)+[value fetch ($elAddr).mailbox::IAD_meta.REH_refCount.WAAH_low]]
    echo [format {    %s message%s}
    	    [if {$refs > 1} {expr $refs-1} {format no}]
	    [if {$refs != 2} {format s}]]
    return 0
}]
##############################################################################
#
#		   WARNING AND ERROR INFO ROUTINES
#

[defsubr clavin-map-ax {type}
{
    return [clavin-map-enum [read-reg ax] $type]
}]

[defsubr clavin-file-error {op}
{
    var err [clavin-map-ax geos::FileError]
    echo $op Error = $err
}]

[defsubr mailbox::MAILBOX_CANNOT_OPEN_OR_DELETE_ADMIN_FILE {}
{
    clavin-file-error Delete
    pwd
}]

[defsubr mailbox::MAILBOX_CANNOT_OPEN_ADMIN_FILE {}
{
    var err [clavin-map-ax geos::VMStatus]
    echo VMOpen Error = $err
    pwd
}]

[defsubr mailbox::ADMIN_FILE_HAS_NO_PROTOCOL {}
{
    clavin-file-error GetExtAttrs
}]

[defsubr clavin-protocol-err {}
{
    echo Actual = [read-reg ax].[read-reg cx]
    echo Desired = [symbol get [symbol find const mailbox::ADMIN_PROTO_MAJOR]].[symbol get [symbol find const mailbox::ADMIN_PROTO_MINOR]]
}]

[defsubr mailbox::ADMIN_FILE_HAS_LATER_MAJOR_PROTOCOL {}
{
    clavin-protocol-err
}]

[defsubr mailbox::ADMIN_FILE_HAS_LATER_MINOR_PROTOCOL {}
{
    clavin-protocol-err
}]

[defsubr mailbox::UNABLE_TO_LOAD_TRANSPORT_DRIVER_WHEN_ADDING_MEDIUM {}
{
    echo load error = [clavin-map-ax geos::GeodeLoadError]
    
    global clavin-transport-types
    var trans [clavin-get-names ${clavin-transport-types} [read-reg cx] 
				[read-reg dx]]
    echo loading [index $trans 0]::[index $trans 1]
}]

[defsubr clavin-vm-with-name-warning {}
{
    echo error = [clavin-map-ax geos::VMStatus]
    echo file = [getstring ds:dx]
}]

[defsubr mailbox::UNABLE_TO_OPEN_EXISTING_VMSTORE_FILE {}
{
    clavin-vm-with-name-warning
}]

[defsubr mailbox::UNABLE_TO_CREATE_VMSTORE_FILE {}
{
    clavin-vm-with-name-warning
}]

[defsubr mailbox::UNABLE_TO_DELETE_EXISTING_BAD_VMSTORE_FILE {}
{
    clavin-file-error Delete
    echo file = [getstring ds:dx]
}]

[defsubr mailbox::UNABLE_TO_DELETE_EMPTY_VMSTORE_FILE {}
{
    clavin-file-error Delete
    echo file = [getstring ds:dx]
}]

[defsubr mailbox::COULD_NOT_LOAD_DRIVER_FROM_XIP_IMAGE {}
{
    echo error = [clavin-map-ax geos::GeodeLoadError]
    echo loading [getstring ds:si]
}]

[defsubr mailbox::UNABLE_TO_LOAD_DATA_DRIVER {}
{
    echo error = [clavin-map-ax geos::GeodeLoadError]
    global clavin-storage-types
    var data [clavin-get-names ${clavin-storage-types} [read-reg cx] 
				[read-reg dx]]
    echo loading [index $data 0]::[index $data 1]
}]

[defsubr mailbox::OVERWRITING_EXISTING_ADDRESS_MARK {}
{
    if {[null [symbol find locvar talID]]} {
    	var new [value fetch ss:bp-2 word]
    } else {
    	var new [value fetch talID]
    }
    echo [format {new = %xh, old = %xh} $new
    	    [value fetch ds:di.mailbox::MITA_addrList]]
}]

[defsubr mailbox::MISSING_CALL_TO_MailboxDoneWithVMFile {}
{
    var refs [value fetch ds:di.mailbox::VMSE_refCount]
    echo [format {%d %s remaining on %s}
    	    $refs
	    [pluralize reference $refs]
	    [getstring ds:di.VMSE_name]]
}]

[defsubr mailbox::INVALID_START_TIME {}
{
    print FileDateAndTime ds:si
}]

[defsubr mailbox::INVALID_END_TIME {}
{
    print FileDateAndTime ds:si
}]

[defsubr mailbox::UNABLE_TO_ALLOCATE_UNIT_DATA_BLOCK {}
{
    print MediaStatusElement ds:di
}]

[defsubr mailbox::CANNOT_CHANGE_SIGNIFICANT_ADDRESS_BYTES {}
{
    # sp -> far return from AppFatalError
    #	    di	(MITA base)
    #	    si	(address array)
    # bx = passed # bytes
    # es:dx = passed address
    # ax = # sig addr bytes (0xffff == all significant)
    
    var mita [value fetch ss:sp+4 word]
    var diff [expr [read-reg di]-[read-reg dx]-1]
    var sig [read-reg ax]
    if {$diff == -1} {
    	# death before byte-compare took place
    	if {[read-reg bx] < [read-reg cx]} {
	    echo You've passed fewer bytes than were there before.
    	} else {
    	    echo You've passed more bytes than were there before.
    	}
    } else {
    	echo Addresses differ $diff [pluralize byte $diff] in.
    }
    echo Existing (significant bytes, only):
    var n [read-reg cx]
    var t [type make array $n [type byte]]
    var b [value fetch ds:$mita.mailbox::MITA_opaque $t]
    fmt-bytes $b 0 $n 4

    echo
    echo New (significant bytes, only):
    var n [read-reg bx]
    if {$sig != 0xffff && $n > $sig} {
    	var n $sig
    }    
    var t [type make array $n [type byte]]
    var b [value fetch es:dx $t]
    fmt-bytes $b 0 $n 4
}]
