##############################################################################
#
# 	Copyright (c) GeoWorks 1995 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	socket.tcl
# AUTHOR: 	Adam de Boor, Jan 26, 1995
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/26/95		Initial Revision
#
# DESCRIPTION:
#	Functions for printing out Socket library data structures
#
#	$Id: socket.tcl,v 1.4 96/12/04 12:45:59 weber Exp $
#
###############################################################################

#
# like penum, but returns the number, not nil, if the thing's not in the type
#
[defsubr socket-map-enum {num typename}
{
    return [socket-map-enum-type $num [symbol find type $typename]]
}]

[defsubr socket-map-enum-type {num type}
{
    var res [type emap $num $type]
    if {[null $res]} {
    	var res $num
    }
    return $res
}]


[defsubr socket-get-manufacturer {num}
{
    var mname [type emap $num [symbol find type geos::ManufacturerID]]
    if {[null $mname]} {
    	var mname $num
    } elif {[string match $mname MANUFACTURER_ID_*]} {
    	var mname [range $mname 16 end char]
    }
    return $mname
}]

[defsubr socket-find-domain {name}
{
    return [carray-enum *socket::SocketDomainArray socket-find-domain-callback
    	    	$name]
}]

[defsubr socket-domain-name {domain}
{
    addr-preprocess *socket::SocketControl:$domain s o
    return [getstring $s:$o.socket::DI_name
    	    	[value fetch $s:$o.socket::DI_nameSize]]
}]

[defsubr socket-find-domain-callback {elNum elAddr elSize name}
{
    addr-preprocess $elAddr s o
    var c [value fetch $s:$o word]
    var dname [getstring (*$s:$c).socket::DI_name 
    	    	[value fetch (*$s:$c).socket::DI_nameSize]]
    if {$name == $dname} {
    	return $c
    } else {
    	return 0
    }
}]

[defsubr socket-hstore {addr type}
{
    return [value hstore [concat [range [addr-parse $addr] 0 1] 
				 [list $type]]]
}]

[defsubr socket-format-port {p domain}
{
    if {$domain != 0} {
	return [format {(%s, %d in "%s")}
	    	    [socket-get-manufacturer [field $p SP_manuf]]
		    [field $p SP_port] [socket-domain-name $domain]]
    } else {
	return [format {(%s, %d)}
	    	    [socket-get-manufacturer [field $p SP_manuf]]
		    [field $p SP_port]]
    }
}]

[defsubr socket-format-dr-error {err}
 {
     if {[null [patient find socket]]} {
	 error {socket library not loaded}
     }
     
     # get the actual value of the error
     var rawval [addr-parse $err 0]
     if {[string c [index $rawval 0] value] == 0} {
	 # $err is a constant or register
	 var val [index $rawval 1]
     } else {
	 # $err is an address
	 var val [value fetch $err [type word]]
     }

     # break it into it's two components
     var generr [socket-map-enum [expr {$val & 00ffh}] socket::SocketDrError]
     var specerr [socket-map-enum [expr {$val & 0ff00h}] socket::SpecSocketDrError]
     return [format {%s/%s} $generr $specerr]
 }
]
     
[defsubr socket-format-socket-error {err}
 {
     if {[null [patient find socket]]} {
	 error {socket library not loaded}
     }

     # get the actual value of the error
     var rawval [addr-parse $err 0]
     if {[string c [index $rawval 0] value] == 0} {
	 # $err is a constant or register
	 var val [index $rawval 1]
     } else {
	 # $err is an address
	 var val [value fetch $err [type word]]
     }

     # break it into it's two components
     var generr [socket-map-enum [expr {$val & 00ffh}] socket::SocketError]
     var specerr [socket-map-enum [expr {$val & 0ff00h}] socket::SpecSocketDrError]
     return [format {%s/%s} $generr $specerr]
 }
]
     
     
     

##############################################################################
#				domains
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
#	ardeb	1/26/95		Initial Revision
#
##############################################################################
[defcommand domains {{opts {}}} top.socket
{Usage:
    domains [-l]

Examples:
    "usage"	Explanation

Synopsis:
    short description of command's purpose

Notes:
    * The output of domains -l differs for data and link drivers. For data
      drivers, each "link" is shown as
    	h=xxxxh socket=yyyyh
      h= gives the CI_handle field (whatever that is), while socket= gives
      the handle of the connected socket.

      For a link driver, the link shows
    	nn  h=xxxxh i=yyyyh s=state r=mm
      and is followed by a hex/ascii dump of the address for the link. h= is
      the handle supplied by the driver for the link. i= is the ID assigned the
      link by the Socket library. state is the connection state. r= is the
      reference count. nn is the value history number for looking at the 
      LinkInfo structure yourself.
    	
See also:
    comma-separated list of related commands
}
{
    require carray-enum chunkarr
    
    echo { @   Hndl  Domain name       Type   State         Driver    Links}
    echo {---  ----  ----------------  -----  ------------  --------  -----}
    [carray-enum *socket::SocketDomainArray domains-callback 
    	    [list [symbol find type socket::DomainInfo]
		  [symbol find type socket::OpenCloseState]
		  $opts
		  [symbol find type socket::LinkInfo]
		  [symbol find type socket::SocketDriverType]
		  [symbol find type socket::ConnectionInfo]]]
}]

[defsubr domains-callback {elNum elAddr elSize types}
{
    addr-preprocess $elAddr s o
    # fetch DomainInfo chunk
    var c [value fetch $s:$o word]
    var d [value fetch *$s:$c [index $types 0]]
    var n [socket-hstore *$s:$c [index $types 0]]
    var name [getstring (*$s:$c).socket::DI_name [field $d DI_nameSize]]
    var h [handle find [expr ([field $d DI_entry]>>16)&0xffff]:0]
    if {[null $h]} {
    	var geode ?
    } else {
    	var geode [patient name [handle patient $h]]
    }

    var dt [socket-map-enum-type [field $d DI_driverType]
    	    	[index $types 4]]
    if {[range $dt 0 3 char] == {SDT_}} {
    	var dt [range $dt 4 end char]
    }
    echo [format {%3d  %04x  %-16.16s  %-5s  %-12s  %-8s  %3d} $n $c $name $dt
    	    [socket-map-enum-type [field $d DI_state] [index $types 1]]
	    $geode
	    [field [field $d DI_header] CAH_count]]
    if {[index $types 2] == {-l}} {
    	if {$dt == DATA} {
	    carray-enum *$s:$c domains-data-callback $types
    	} else {
    	    carray-enum *$s:$c domains-link-callback $types
    	}
    }
    return 0
}]

[defsubr domains-link-callback {elNum elAddr elSize types}
{
    var l [value fetch $elAddr [index $types 3]]
    var n [socket-hstore $elAddr [index $types 3]]
    echo [format {     %3d  h=%04xh, i=%04xh, s=%s, r=%d}
    	    	$n [field $l LI_handle] [field $l LI_id]
		[socket-map-enum-type [field $l LI_state] [index $types 1]]
		[field $l LI_refCount]]
    var max [field $l LI_addrSize]
    var t [type make array $max [type byte]]
    var bytes [value fetch ($elAddr).socket::LI_address $t]
    
    var numper 16

    if {$max > $numper} {
    	var e [expr $numper-1]
    } else {
    	var e [expr $max-1]
    }

    [for {var s 0}
	 {$s < $max}
	 {var s [expr $s+16]}
    {
    	#extract the bytes we want
    	var bs [range $bytes $s $e]
	var post [expr $numper-($e-$s+1)]

    	echo [format {%10s%s%*s   "%s%*s"}
    	    	{}
    	    	[map i $bs {format %02x $i}]
		[expr $post*3] {}
    	    	[mapconcat i $bs {
    	    	    if {$i >= 32 && $i < 127} {
		    	format %c $i
    	    	    } elif {$i >= 0xa0 && $i < 0xff} {
		    	format %c [expr $i-0x80]
		    } else {
		    	format .
		    }
	    	}]
		$post {}]
	var s [expr $e+1] e [expr $e+$numper]
	if {$e >= $max} {
    	    var e [expr $max-1]
	}
    }]
    return 0
}]

[defsubr domains-data-callback {elNum elAddr elSize types}
{
    var d [value fetch $elAddr [index $types 5]]
    echo [format {     h=%04xh socket=%04xh} [field $d CI_handle]
    	    [field $d CI_socket]]
    return 0
}]

##############################################################################
#				ports
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
#	ardeb	1/26/95		Initial Revision
#
##############################################################################
[defcommand ports {args} top.socket
{Usage:
    ports [-s] [-l] [-q] [-d <domain>]

Examples:
    "usage"	Explanation

Synopsis:
    short description of command's purpose

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    require carray-enum chunkarr

    var restriction 0 sockets 0 loads 0 listenq 0

    for {} {[string match [index $args 0] -*]} {} {
    	[case [index $args 0] in
	 -d {
	    var dname [index $args 1]
	    var restriction [socket-find-domain $dname]
	    if {$restriction == 0} {
	    	error [format {domain %s not found} $dname]
    	    }
	    var args [range $args 2 end]
    	 }
	 -l {
	    var loads 1 args [range $args 1 end]
    	 }
	 -s {
	    var sockets 1 args [range $args 1 end]
    	 }
	 -q {
	    var listenq 1 args [range $args 1 end]
    	 }
	 default {
	    var args [range $args 1 end]
    	 }
    	]
    }
    [carray-enum *socket::SocketPortArray ports-callback
    	[list [symbol find type socket::PortInfo]
	      [symbol find type socket::PortArrayEntry]
	      $args
	      [symbol find type socket::SocketInfo]
	      [symbol find type socket::SocketDeliveryType]
	      [symbol find type socket::InternalSocketState]]]
}]

[defsubr ports-callback {elNum elAddr elSize types}
{
    addr-preprocess $elAddr s o
    var pae [value fetch $s:$o [index $types 1]]
    var c [field $pae PAE_info]
    var port [field $pae PAE_id]
    var pi [value fetch *$s:$c [index $types 0]]
    
    [if {[uplevel ports var restriction] &&
    	 [field $pi PI_restriction] != [uplevel ports var restriction]}
    {
    	# skip this port
    	return 0
    }]
    var n [socket-hstore *$s:$c [index $types 0]]
    echo [format {%3d  %s} $n 
    	    [socket-format-port [field $pi PI_number] [field $pi PI_restriction]]]

    if {[uplevel ports var sockets]} {
    	carray-enum *$s:$c ports-socket-callback $types
    }

    if {[uplevel ports var loads] && [field $pi PI_loadInfo]} {
    	var li [field $pi PI_loadInfo]
    	var lt [socket-map-enum [value fetch (*$s:$li).socket::LR_loadType]
	    	    socket::SocketLoadType]
    	require _disk_name fs
	var disk [_disk_name [value fetch (*$s:$li).socket::LR_disk]]
	var path [getstring (*$s:$li).socket::LR_path]
	
	echo [format {     %s of [%s] %s} $lt $disk $path]
    }
    
    if {[uplevel ports var listenq] && [field $pi PI_listenQueue]} {
    	var lq [field $pi PI_listenQueue]
	var lqmax [value fetch (*$s:$lq).socket::LQ_maxEntries]
	var lqcur [value fetch (*$s:$lq).socket::LQ_header.CAH_count]
	echo [format {     %d pending %s max, %d pending now}
	    	$lqmax [pluralize connection $lqmax]
		$lqcur [pluralize connection $lqcur]]
    	carray-enum *$s:$lq ports-listen-callback $types
    }
    	
    return 0
}]

[defsubr ports-socket-callback {elNum elAddr elSize types}
{
    sockets-callback $elNum $elAddr $elSize [range $types 3 end]
}]

[defsubr ports-listen-callback {elNum elAddr elSize types}
{
    echo [format {     port=%s, link=%04xh, domain=%s}
    	    [socket-format-port [value fetch ($elAddr).socket::CE_port] 0]
	    [value fetch ($elAddr).socket::CE_link]
	    [socket-domain-name [value fetch ($elAddr).socket::CE_domain]]]
    return 0
}]

##############################################################################
#	sockets
##############################################################################
#
# SYNOPSIS:	
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
#       EW 	3/ 7/96   	Initial Revision
#
##############################################################################
[defcommand sockets {args} top.socket
{Usage:
    sockets

Examples:
    "usage"	Explanation

Synopsis:
    short description of command's purpose

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    [carray-enum *socket::SocketSocketArray sockets-callback
    	[list [symbol find type socket::SocketInfo]
	      [symbol find type socket::SocketDeliveryType]
	      [symbol find type socket::InternalSocketState]]]
}]

[defsubr sockets-callback {elNum elAddr elSize types}
 {
    addr-preprocess $elAddr s o
    # fetch SocketInfo chunk
    var c [value fetch $s:$o word]
    var n [socket-hstore *$s:$c [index $types 0]]
    [case [socket-map-enum-type [value fetch (*$s:$c).socket::SI_delivery]
    	    	    [index $types 1]]
    	SDT_DATAGRAM {var del D}
	SDT_SEQ_PACKET {var del P}
	SDT_STREAM {var del S}
	default {var del ?}]
    [case [socket-map-enum-type [value fetch (*$s:$c).socket::SI_state]
    	    	    [index $types 2]]
    	ISS_UNCONNECTED {var st UNCON}
	ISS_LISTENING 	{var st lisn}
	ISS_ACCEPTING 	{var st acc}
	ISS_CONNECTING 	{var st con}
	ISS_CONNECTED 	{var st est}
	ISS_CLOSING	{var st cls}
	ISS_ERROR   	{var st err}
	default	    	{var st ?}]
    var f [value fetch (*$s:$c).socket::SI_flags]
    var flags [format {%1s%1s%1s%1s%1s%1s}
    	    	[if {[field $f SF_INTERRUPTIBLE]} {format i}]
		[if {[field $f SF_INTERRUPT]} {format I}]
		[if {[field $f SF_SEND_ENABLE]} {format s}]
		[if {[field $f SF_RECV_ENABLE]} {format r}]
		[if {[field $f SF_FAILED]} {format F}]
		[if {[field $f SF_LINGER]} {format L}]]
    echo [format {     %3d  %04xh: %s  %-5s  %-6s  q=%04xh  o=%04xh  w=%04xh}
    	     $n $c $del $st $flags
	     [value fetch (*$s:$c).socket::SI_dataQueue]
	     [value fetch (*$s:$c).socket::SI_dataOffset]
	     [value fetch (*$s:$c).socket::SI_waitSem]]
    return 0
}]     
     
##############################################################################
#				tcpconn
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
#	ardeb	2/ 7/95		Initial Revision
#
##############################################################################
[defcommand tcpconn {} top.socket
{Usage:
    syntax diagram
    syntax diagram

Examples:
    "usage"	Explanation

Synopsis:
    short description of command's purpose

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    var h [value fetch tcpip::socketBlock] c [value fetch tcpip::socketList]
    pcarray -ttcpip::TcpSocketElt ^l$h:$c
}]

[defsubr fmtstruct-IPAddr {type val offset space}
{
    var n [map i $val {
    	scan [format $i] %c q
	var q
    }]
    echo -n [index $n 0].[index $n 1].[index $n 2].[index $n 3]
    return 1
}]

