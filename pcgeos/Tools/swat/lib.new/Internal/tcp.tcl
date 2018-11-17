#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:  	Socket
# MODULE:   	Swat System Library -- Tcp Driver
# FILE:		tcp.tcl
# AUTHOR:	Jennifer Wu, Apr 21, 1995
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	ptcp	    	    	Print out brief info about all TCP connections
#   	ptcpcon	        	Print out detailed info about a TCP connection
#   	ptcb	    	    	Print out TCB info for a TCP connection
#   	
#   	plink	    	    	Prints info about link(s) Tcp is using
#
#   	tcplog	    	    	Turns Tcp packet header logging on and off
#   	logPacket   	    	Log a packet.
#
#   	ntoh	    	    	Convert word from network to host format
#   	ntohdw	    	    	Convert dword from network to host format
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/21/95		Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to print out information about
#   	Tcp connections and links.
#
#	$Id: tcp.tcl,v 1.3 95/12/14 13:57:55 jwu Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

##############################################################################
#				ptcp
##############################################################################
#
# SYNOPSIS:	Prints general information about all Tcp connections.
#
# CALLED BY:	the user
# PASS:		nothing
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/21/95	    	Initial Revision
#
##############################################################################
[defcommand ptcp {} top.socket.tcp
{Usage: 
    ptcp

Synopsis:
    Prints out information about all TCP  connections.  
    Information printed includes connection handle, local port,
    remote port, remote IP address, local IP address and TCP state.

See also:
    ptcpcon, ptcb
}    
{

    var sblk [getvalue socketBlock]
    var slist [getvalue socketList]

    #
    # First determine if there are any Tcp connections.
    #
    var total [value fetch ^l$sblk:$slist.CAH_count]
    if { $total == 0} {
    	echo {TCP has no connections.}
    	return
    }
    
    #
    # Print out the banner
    #
    echo {HANDLE   LPORT  RPORT  REMOTE ADDRESS    LOCAL ADDRESS    SOCKET STATE}
    echo {----------------------------------------------------------------------------}

    #
    # Print out the information for each element.
    #
    var dataOff [size ChunkArrayHeader]
    var connHan 0

    var raddr {}
    var laddr {}

    for {var el 0} {$el < $total} {var el [expr $el+1]} {

    	var connHan [value fetch ^l$sblk:$slist+$dataOff word]

    	[var raddr [format {%u.%u.%u.%u}
    	    	    [value fetch ^l$sblk:$connHan.TS_remoteAddr byte]
    	    	    [value fetch ^l$sblk:$connHan.TS_remoteAddr+1 byte]
    	    	    [value fetch ^l$sblk:$connHan.TS_remoteAddr+2 byte]
    	    	    [value fetch ^l$sblk:$connHan.TS_remoteAddr+3 byte]]]
    
    	[var laddr [format {%u.%u.%u.%u}
    	    	    [value fetch ^l$sblk:$connHan.TS_localAddr byte]
    	    	    [value fetch ^l$sblk:$connHan.TS_localAddr+1 byte]
    	    	    [value fetch ^l$sblk:$connHan.TS_localAddr+2 byte]
    	    	    [value fetch ^l$sblk:$connHan.TS_localAddr+3 byte]]]

    	var tcpState [value fetch ^l$sblk:$connHan.TS_state byte] 

    	[echo [format {%04xh    %-7u%-7u%-16s  %-16s %-s} 
    	    	$connHan 
    	    	[value fetch ^l$sblk:$connHan.TS_localPort word]
    	    	[value fetch ^l$sblk:$connHan.TS_remotePort word]
    	    	$raddr $laddr
    	    	[range [penum TcpSocketState 
    	    	    	    	[value fetch ^l$sblk:$connHan.TS_state byte]] 
    	    	       4 end chars]]]

    	var dataOff [expr $dataOff+2]
    }

}]

##############################################################################
#				ptcpcon
##############################################################################
#
# SYNOPSIS:	Print out detailed information about a Tcp connection.
#
# CALLED BY:	the user
# PASS:		connection handle
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/24/95	    	Initial Revision
#
##############################################################################
[defcommand ptcpcon {han} top.socket.tcp
{Usage:
    ptcpcon <connection handle>
    
Examples:
    "ptcpcon 12h"   	    	print info for connection whose handle is 12h

Synopsis:
    Prints out detailed information about a Tcp connection.  Information 
    printed includes domain handle of link used for the connection, max
    size of the output queue, optr of the output queue, amount of data 
    waiting to be added to the output queue, optr of input queue, 
    whether a thread is waiting for an operation to complete for that 
    connection, destruct timeout, and error associated with connection.

See also:
    ptcp, ptcb
}
{
    var sblk [getvalue socketBlock]

    [echo [format {Link = %u\tError = %s\tTCB = ^l%04xh:%04xh} 
    	    	    [value fetch ^l$sblk:$han.TS_link]
        	    [penum SocketDrError [value fetch ^l$sblk:$han.TS_error]]
    	    	    [value fetch ^l$sblk:$han.TS_tcb.handle]
  	     	    [value fetch ^l$sblk:$han.TS_tcb.chunk]]]

    [echo [format {Output Queue = ^l%04xh:%04xh  Max Size = %u bytes  Pending = %u bytes}
    	    	    [value fetch ^l$sblk:$han.TS_output.handle]
        	    [value fetch ^l$sblk:$han.TS_output.chunk]
    	    	    [value fetch ^l$sblk:$han.TS_maxData word]
    	    	    [value fetch ^l$sblk:$han.TS_pendingData word]]]

    var inputHan [value fetch ^l$sblk:$han.TS_input.handle]
    if {$inputHan != 0} {
    	[echo -n [format {Input Queue = ^l%04xh:%04xh\t}
    	    	    	    $inputHan 
    	    	    	    [value fetch ^l$sblk:$han.TS_input.chunk]]]
    }

    [echo -n [format {Waiter = %s} 
    	[if {[value fetch ^l$sblk:$han.TS_waiter byte] == [getvalue TCPIP_WAITER_EXISTS]} {list WAITER EXISTS} else {list NO WAITER }]]]

    if {[value fetch ^l$sblk:$han.TS_state] == [getvalue TSS_DEAD]} {
    	[echo [format {  Destruct timeout = %u} 
    	    	    	[value fetch ^l$sblk:$han.TS_destructTime]]]
    } else {
    	    echo    {}
    }

}]


##############################################################################
#				ptcb
##############################################################################
#
# SYNOPSIS:	Print out detailed information from a Tcp connection's
#   	    	transmission control block (TCB).
#
# CALLED BY:	the user
# PASS:		connection handle
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/24/95	    	Initial Revision
#
##############################################################################
[defcommand ptcb {han} top.socket.tcp
{
Usage:
    ptcb <connection handle>

Examples:
    "ptcb 12h"   	    print TCB info for connection whose handle is 12h

Synopsis:
    Prints transmission control info about a Tcp connection.  Information
    printed includes Tcp state, send unacknowledged, send next, send urgent
    pointer, receive next, receive urgent pointer, send max, last ack sent,
    max segment size, max window size and timers.

See also:
    ptcp, ptcpcon

}
{
    #
    # Get the optr of the TCB
    #
    var sblk [getvalue socketBlock]
    [var tcb [format {^l%04xh:%04xh} [value fetch ^l$sblk:$han.TS_tcb.handle]
    	    	    	    	   [value fetch ^l$sblk:$han.TS_tcb.chunk]]]

    [var stateList {CLOSED LISTEN SYN_SENT SYN_RECEIVED ESTABLISHED CLOSE_WAIT 
    	    	    FIN_WAIT_1 CLOSING LAST_ACK FIN_WAIT_2 TIME_WAIT}]
    var state [value fetch {(struct tcpcb $tcb).t_state} word]
    var maxSeg [value fetch {(struct tcpcb $tcb).t_maxseg} word]
    var maxWin [value fetch {(struct tcpcb $tcb).t_maxwin} word]
    var timers [value fetch {(struct tcpcb $tcb).t_timer}]

    var sendUna [value fetch {(struct tcpcb $tcb).snd_una} dword]
    var sendNxt [value fetch {(struct tcpcb $tcb).snd_nxt} dword]
    var sendMax [value fetch {(struct tcpcb $tcb).snd_max} dword]
    var sendUp [value fetch {(struct tcpcb $tcb).snd_up} dword]
    
    var rcvNxt [value fetch {(struct tcpcb $tcb).rcv_nxt} dword]
    var rcvUp [value fetch {(struct tcpcb $tcb).rcv_up} dword]
    var lastAck [value fetch {(struct tcpcb $tcb).last_ack_sent} dword]

    #
    # Print out all the info.
    # 
    [echo [format {Tcp State = %s  Max Seg = %u  Max Win = %u\nTimers (in seconds): Retransmit = %u Persist = %u  Keep Alive = %u  2MSL = %u\nSender: Unacked = %u  Next = %u  Max = %u  Urgent Pointer = %u\nReceiver:  Next = %u  Urgent Pointer = %u  Last Ack = %u} 
    	    	    [index $stateList $state] $maxSeg $maxWin
    	    	    [expr [index $timers 0]/2]
    	    	    [expr [index $timers 1]/2]
    	    	    [expr [index $timers 2]/2]
    	    	    [expr [index $timers 3]/2]
    	    	    $sendUna $sendNxt $sendMax $sendUp
    	    	    $rcvNxt $rcvUp $lastAck]]
}]


##############################################################################
#				plink
##############################################################################
#
# SYNOPSIS:	Print info about link(s) Tcp is using
# CALLED BY:	the user
# PASS:		nothing if complete link table should be printed, else
#   	    	a flag or link domain handle indicating what info to print
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/25/95	    	Initial Revision
#
##############################################################################
[defcommand plink {args} top.socket.tcp
{Usage:
    plink [<flag> | <link domain handle>]

Examples:
    "plink" 	       	    Print the complete link table
    "plink 0"	       	    Print info about link whose domain handle is 0
    "plink -l"	    	    Print info about the loopback link
    "plink -m"	    	    Print info about the main link used by Tcp
    "plink -c"	    	    Print the number of links Tcp knows about

Synopsis:
    Prints information about link(s) used by Tcp.
}
{
    #
    # Get number of links.
    #
    [var laddr [format {^l%04xh:%04xh} [value fetch linkTable.handle] 
    	    	    	    	     [value fetch linkTable.chunk]]]
    var count [value fetch $laddr.CAH_count]
    var start 0
    var end $count

    if {[length $args] > 1} {
    	echo [format {Usage: plink [<flag> | <link domain handle>]}]
    	return
    } elif {[length $args] == 1} {
    	if {[string m $args -*]} {
    	    [case [index $args 1 char] in 
    	    	   c { [echo $count] [return] }
    	    	   l { var end 1 }
    	    	   m { [var start 1] [var end 2]}
    	    ]
    	} else {
    	    var start $args
    	    var end [expr $args+1]
    	}
    }

    #
    # Print info about links from "start" to "end".
    #
    echo {HNDL  STATE  DRVR  STRATEGY       MTU   LOCAL IP ADDR   LINK ADDRESS}
    echo {----------------------------------------------------------------------}

    var elOff [value fetch $laddr.CAH_offset]
    for {var i $start} {$i < $end} {var i [expr $i+1]} {
    	var off [value fetch $laddr+[expr $i*2+$elOff] word]
    	var state [value fetch ($laddr+$off).LCB_state byte]
    	var drvr [value fetch ($laddr+$off).LCB_drvr word]
    	if { $drvr == 0 && $state == [getvalue LS_CLOSED]} {
    	    var stratName N/A
    	} else {
        	[var stratName [symbol fullname [symbol faddr proc 
    	    	    	  [format {%04xh:%04xh} 
    	    	    	    [value fetch ($laddr+$off).LCB_strategy.segment]
    	    	    	    [value fetch ($laddr+$off).LCB_strategy.offset]]]]]
    	    	[var stratName [range $stratName 
    	    	    	        [expr 2+[string last :: $stratName]] end chars]]
    	}
	var mtu [value fetch ($laddr+$off).LCB_mtu word]
    	[var ipAddr [format {%u.%u.%u.%u}
    	    	    	    [value fetch ($laddr+$off).LCB_localAddr byte]
    	    	    	    [value fetch ($laddr+$off).LCB_localAddr+1 byte]
    	    	    	    [value fetch ($laddr+$off).LCB_localAddr+2 byte]
    	    	    	    [value fetch ($laddr+$off).LCB_localAddr+3 byte]]]
    	[echo -n [format {%04xh %-6s %04xh %-15s%-5u %-15s }
    	    	$i [range [penum LinkState $state] 3 end char]
    	    	$drvr $stratName $mtu $ipAddr]]

    	var lSize [value fetch ($laddr+$off).LCB_linkSize word]
    	var lType [value fetch ($laddr+$off).LCB_linkAddr byte]
    	if { $lSize == 0} {
    	    echo N/A
    	} elif {$lType == [getvalue LT_ID]} {
    	    echo [format %u [value fetch ($laddr+$off+1).LCB_linkAddr word]]
    	} elif {$lType == [getvalue LT_ADDR]} {
    	    pstring -l [expr $lSize-1] ($laddr+$off+1).LCB_linkAddr
    	} else {
    	    echo Unknown
    	}
    }
}]



##############################################################################
#				tcplog
##############################################################################
#
# SYNOPSIS:	Turns Tcp packet header logging on and off.
# CALLED BY:	the user
# PASS:		nothing, on, or off
# RETURN:	nothing
# STRATEGY
#   	    Log output will be written to a file in users home directory.
#   	    ~/tcplog
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/25/95	Initial Revision
#
##############################################################################
defvar tcpToken 0   	    	    
defvar b1 0
defvar b2 0

[defcommand tcplog {args} top.socket.tcp
{Usage:
    tcplog {args}

Examples:
    "tcplog"	    	report on Tcp's logging status
    "tcplog on"	    	turn on Tcp packet header logging
    "tcplog off"    	turn off Tcp packet header logging

Synopsis:
    Allow automatic Tcp packet header logging.  Log output will be 
    written to the file "tcplog" in the users home directory.

Notes:
    * The argument can be one of the following:
    	on  	    header of every packet sent and received will be logged
    	off 	    disables packet header logging
    	
    * If no argument is passed, tcplog displays the current logging state.

    * Not needed if Tcp has been compiled with logging enabled.  This command
      will duplicates Tcp logging, except packets sent on the loopback link
      will only be logged during receipt.

    * Log file will be created if it does not already exist.  Else it will
      be created.

}
{
    global tcpToken
    global b1
    global b2

    if {[null $args]} {
    	if {$tcpToken == 0} {
            echo off
        } else {
            echo on
        }
    } elif {[string m $args on]} {
       	if {$tcpToken == 0} {
            var tcpToken [stream open [getenv HOME]/tcplog w]
       	    [var b1 [brk tcpip::LINKSENDDATA::logBrkPt 
  	    	    	    	{[logPacket 0 es:di][expr 0]}]]
            [var b2 [brk tcpip::TcpipReceivePacket::logBrkPt 
   	    	    	    	{[logPacket 1 es:di][expr 0]}]]
       	}
    } elif {[string m $args off]} {
       	if {$tcpToken != 0} {
       	    stream close $tcpToken
       	    var tcpToken 0
       	    brk delete $b1
       	    brk delete $b2
       	}
    }

}]


##############################################################################
#				logPacket
##############################################################################
#
# SYNOPSIS:	Log the header of an IP packet.
# CALLED BY:	breakpoints set by tcplog
# PASS:     	in	= non-zero if packet is incoming, 0 if outgoing
#   	    	addr	= address of PacketHeader 
# RETURN:	nothing
#
# STRATEGY:
#   	    Concatenate all the info into a single string and then
#   	    do a single write to the log file.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jwu	4/25/95	Initial Revision
#
##############################################################################
[defsubr logPacket {in addr}
{
    global tcpToken

    var data {}
    var off [value fetch $addr.PH_dataOffset word]
    var dataSize [ntoh [value fetch ($addr+$off).IH_length word]]

    if {$in} {
    	var data [format {Receiving:\n}]
    } else {
    	var data [format {Sending:\n}]
    } 
    	
    #  
    # IP addresses, identification and protocol.  Addresses are in 
    # network order.
    #
    [var data [concat $data [format {IP Source Addr:  %u.%u.%u.%u\t}
    	    	    	[value fetch ($addr+$off).IH_source byte]
    	    	    	[value fetch ($addr+$off).IH_source+1 byte]
    	    	    	[value fetch ($addr+$off).IH_source+2 byte]
    	    	    	[value fetch ($addr+$off).IH_source+3 byte]]]]

    [var data [concat $data [format { IP Destination Address:  %u.%u.%u.%u\n}
    	    	    	[value fetch ($addr+$off).IH_dest byte]
    	    	    	[value fetch ($addr+$off).IH_dest+1 byte]
    	    	    	[value fetch ($addr+$off).IH_dest+2 byte]
    	    	    	[value fetch ($addr+$off).IH_dest+3 byte]]]]
    
    [var data [concat $data [format {Identification: %u\t}
    	    	    	[ntoh [value fetch ($addr+$off).IH_id word]]]]]

    var proto [value fetch ($addr+$off).IH_protocol byte]
    [var data [concat $data [format {  IP Protocol: %s\n}
    	    	    [ case  $proto in 
    	    	    	0 { list IP }
    	    	    	1 { list ICMP }
    	    	    	6 { list TCP }
    	    	    	17 { list UDP }
    	    	    	255 { list Raw IP }
    	    	    ]]]]
    #
    # Adjust data size to exclude IP header.  Advance offset to 
    # point to subprotocol's data in packet.
    #
    var hlen [expr {([value fetch ($addr+$off).IH_hlAndVer.IHAV_hdrLen] << 2)}]
    var dataSize [expr $dataSize-$hlen]
    var off [expr $off+$hlen]

    if {$proto == 1} {
    	#
    	# Log ICMP header.  Header size of 4 accounts for type, code and 
    	# checksum part only.  Only some are logged.  The rest simply
    	# print out the Icmp type and code.  Why?  Because I got tired
    	# of typing!
    	#
    	    var hlen 4	    	
    	    var icmpType [value fetch {(struct icmp $addr+$off).icmp_type} byte]
    	    var icmpCode [value fetch {(struct icmp $addr+$off).icmp_code} byte]
    	    var id [ntoh [value fetch {($addr+$off)+4} word]]
    	    var seq [ntoh [value fetch {($addr+$off)+6} word]]

    	    [case $icmpType in 
    	    	0 {[var data [concat $data [format {Icmp echo reply\n ID: %u\t Seq: %u\n} $id $seq]]] [var hlen 8]}
    	    	8 {[var data [concat $data [format {Icmp echo request\n ID: %u\t Seq: %u\n} $id $seq]]] [var hlen 8]}
    	    	13 {[var data [concat $data [format {Icmp timestamp request\n ID: %u\t Seq: %u\t\n} $id $seq]]] [var hlen 20]}
    	    	14 {[var data [concat $data [format {Icmp timestamp reply\n ID: %u\t Seq: %u\t\n}  $id $seq]]] [var hlen 20]}
    	    	3 {[var data [concat $data [format {Icmp destination unreachable, code: %u\n} $icmpCode]]] [var hlen 8]}
    	    	11 {[var data [concat $data [format {Icmp time exceeded, code: %u\n} $icmpCode]]] [var hlen 8]}
    	    	4 {[var data [concat $data [format {Icmp source quench\n}]]]}
    	    	12 {[var data [concat $data [format {Icmp parameter problem, code: %u\n} $icmpCode]]]}
    	    	default {[var data [concat $data [format {Icmp type: %u\t Icmp code: %u\n} $icmpType $icmpCode]]]}
    	    ]

   } elif {$proto == 6 } {
    	#
    	# Log TCP header.  
    	#
    	var hlen [expr {([value fetch {(struct tcphdr $addr+$off).th_off} byte] >> 2)}]

    	[var data [concat $data [format {Source Port: %u\t Destination Port: %u\n Seq: %u\t Ack: %u\t Window: %u\n}    	   
    	    [ntoh [value fetch {(struct tcphdr $addr+$off).th_sport} word]]
    	    [ntoh [value fetch {(struct tcphdr $addr+$off).th_dport} word]]
    	    [ntohdw [value fetch {(struct tcphdr $addr+$off).th_seq} dword]]
    	    [ntohdw [value fetch {(struct tcphdr $addr+$off).th_ack} dword]]
    	    [ntoh [value fetch {(struct tcphdr $addr+$off).th_win} word]]]]]

    	var flags [value fetch {(struct tcphdr $addr+$off).th_flags} byte]
    	[var data [concat $data [format {Flags: %s%s%s%s%s%s\n}
    	    [if {$flags & 0x1} {concat FIN { }}]
    	    [if {$flags & 0x2} {concat SYN { }}]
    	    [if {$flags & 0x4} {concat RST { }}]
   	    [if {$flags & 0x8} {concat PUSH { }}]
    	    [if {$flags & 0x10} {concat ACK { }}]
    	    [if {$flags & 0x20} {list URG}]]]]
    	    
    	if {$flags & 0x20} {[var data [concat $data [format {Urgent Pointer: %u\n} [ntoh [value fetch {(struct tcphdr $addr+$off).th_urp} word]]]]]}

    	if {$hlen > [size {struct tcphdr}]} {
    	    	var optSize  [expr $hlen-[size {struct tcphdr}]]
    	    	var off [expr $off+[size {struct tcphdr}]]
    	    	var data [concat $data [format {Tcp Options: }]]
    	    	for {} {$optSize > 0} {[var optSize [expr $optSize-$optLen]] [var off [expr $off+$optLen]]} {
    	    	    	var optCode [value fetch $addr+$off byte]
           	    	if {$optCode == 0} {break}
        	    	if {$optCode == 1} {
    	    	    	    var optLen 1
    	    	    	} else {
    	    	    	    var optLen [value fetch {($addr+$off)+1} byte]
        	    	    if {$optLen <= 0} {break}    	 
    	    	    	}

    		    	[case $optCode in 
    	        	    2 {var data [concat $data [format {\tMaximum Segment Size of %u} [ntoh [value fetch {($addr+$off)+2} word]]]]}
   	    		    default {[var data [concat $data [format {\tUnknown option}]]] [continue]}
        	    	]
    	    	}
    	    	var data [concat $data [format {\n}]]
    	}

    } elif {$proto == 17 } {
    	#
    	# Log UDP header.
    	#
    	var hlen 8
    	[var data [concat $data [format {Source Port: %u\t Destination Port: %u\n} [ntoh [value fetch {(struct udphdr $addr+$off).uh_sport} word]]
  [ntoh	[value fetch {(struct udphdr $addr+$off).uh_dport} word]]]]]
    } 

    var dataSize [expr $dataSize-$hlen]
    var data [concat $data [format {Data Size = %u\n\n} $dataSize]]

    stream write $data $tcpToken
    stream flush $tcpToken

}]


#######################################################################
#   	    	ntoh/ntohdw
#######################################################################
#
# SYNOPSIS:  Convert a word or dword from network to host format.
#
# CALLED BY: logPacket
#
# PASS:	    the value to convert
# RETURN:   the converted value
#
#######################################################################

[defsubr ntoh {nword}
{
    return [expr {($nword >> 8) | (($nword & 0x00ff) << 8)}]

}]

[defsubr ntohdw {ndw}
{
    var high [ntoh [expr {$ndw & 0x0000ffff}]]
    var low [ntoh [expr {($ndw >> 16) & 0x0000ffff}]]
    return [expr {($high << 16) | $low}]
}]
