##############################################################################
#
# 	(c) Copyright Geoworks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Socket
# MODULE:	Swat -- Telnet library
# FILE: 	telnet.tcl
# AUTHOR: 	Simon Auyeung, Aug  3, 1995
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	ptelnetinfo		Print out the TelnetInfo structure
#
#	ptelnetoptdesc		Print out TelnetOptionDescArray
#
#	telnetcmdwatch		Watch the telnet command received
#				and/or sent 
#	
#	telnetoptwatch		Watch the telnet option negotiation
#
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	simon	8/ 3/95   	Initial Revision
#
# DESCRIPTION:
#	Misc functions for displaying telnet connection info and
#	debugging telnet connections.
#
#	$Id: telnet.tcl,v 1.1 95/10/11 11:50:55 simon Exp $
#
###############################################################################

##############################################################################
#	ptelnetinfo
##############################################################################
#
# SYNOPSIS:	Print out the TelnetInfo structure
# PASS:		args	= address pointing to TelnetInfo structure
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/ 4/95   	Initial Revision
#
##############################################################################
[defcommand ptelnetinfo {args} top.socket.telnet
{Usage:
    ptelnetinfo [<expression>]

Examples:
    "ptelnetinfo es:di"         print the TelnetInfo at address specified in
                                ES:DI
    "ptelnetinfo"               Use default DS:SI as pointer to TelnetInfo 

Synopsis:
    Print TelnetInfo structure 

Notes:
    None

See also:
    ptelnetoptdesc
}
{
    # If no arg given, use default DS:SI
    if {[null $args]} {
	var args {ds:si}
    }
    print telnet::TelnetInfo $args
    #
    # Get TI_enabledOption. Print terminal type string if TOS_TERMINAL_TYPE
    # is enabled.
    #
    var optflags [value fetch ($args).telnet::TI_enabledLocalOptions]
    if {[field $optflags TOS_TERMINAL_TYPE]} {
	echo -n [concat TI_termType = ]
	pstring ($args).TI_termType
    }
}]

##############################################################################
#	ptelnetoptdesc
##############################################################################
#
# SYNOPSIS:	Print out TelnetOptionDescArray
# PASS:		args	= address pointing to TelnetOptionDescArray
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/14/95   	Initial Revision
#
##############################################################################
[defcommand    ptelnetoptdesc {args} top.socket.telnet 
{Usage:
    ptelnetoptdesc [<expression>]

Examples:
    "ptelnetoptdesc es:di"         print the TelnetOptionDescArray at
                                   address specified in ES:DI
    "ptelnetoptdesc"               Use default DS:SI as pointer to 
                                   TelnetOptionDescArray

Synopsis:
    Print TelnetOptionDescArray structure 

Notes:
    None

See also:
    ptelnetinfo
}
{
    # If no arg given, use default DS:SI
    if {[null $args]} {
	var args {ds:si}
    }

    # Get register pair
    var a [addr-parse $args]
    var s ^h[handle id [index $a 0]]
    var o [index $a 1]

    # Get number of option elements
    var optNum [value fetch $s:$o.telnet::TODA_numOpt]
    [for {var o [expr $o+[size TelnetOptionDescArray]]}
         {$optNum > 0} 
	 {var optNum [expr $optNum-1]} {
	    print telnet::TelnetOptionDesc $s:$o

	    # if it is a terminal type option, print specially
	    if {[value fetch $s:$o.TOD_option] == 
	           [getvalue TOID_TERMINAL_TYPE]} {
		       echo -n {    char *TOD_data = }
		       pstring $s:$o.TOD_data
		       # Add pointer past terminal type string
		       var o [expr $o+[length $s:$o.TOD_data]]
	    }
	    var o [expr $o+[size TelnetOptionDesc]]
       }]
}]


##############################################################################
#	telnetcmdwatch
##############################################################################
#
# SYNOPSIS:	Watch the telnet command received and/or sent
# PASS:		command	= option to manipulate telnet comand watch points
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	telnetcmdbrk_list is created to store the breakpoints at
#		telnet library routines to display info.
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/17/95   	Initial Revision
#
##############################################################################
[defcommand    telnetcmdwatch {{command clear}} top.socket.telnet
{Usage
    telnetcmdwatch sent
    telnetcmdwatch recv
    telnetcmdwatch all
    telnetcmdwatch clear
    telnetcmdwatch

Examples:
    "telnetcmdwatch sent"	Set watch points for any TelnetCommand sent
    "telnetcmdwatch recv"	Set watch points for any TelnetCommand
				received 
    "telnetcmdwatch all"	Set watch points for both TelnetCommand sent
				and received
    "telnetcmdwatch clear"	Remove all watch points of TelnetCommand

Synopsis:
    Set watch points of TelnetCommand send and/or received.

Notes:
    All option and suboption negotiation commands will not be displayed. To
    watch those negotation, you can use "telnetoptwatch" command.

    In summary the following commands will NOT be displayed:

	SE, SB, WILL, WONT, DO, DONT, IAC

See also:
    telnetoptwatch
}
{
    global telnetcmdbrk_list

    #
    # Set breakpoints
    #
    [case $command in 
     recv {
	 var tempb [brk aset telnet::TelnetExecIncomingCommand
	            print-telnet-recv-cmd]
     }
     sent {
	 var tempb [brk aset telnet::TelnetSendCommandSocket
	            print-telnet-sent-cmd]
     }
     all {
	 var tempb [brk aset telnet::TelnetExecIncomingCommand
	            print-telnet-recv-cmd]
	 #
	 # Add recv break point
	 #
	 var telnetcmdbrk_list [concat $telnetcmdbrk_list $tempb]
	 var tempb [brk aset telnet::TelnetSendCommandSocket
	            print-telnet-sent-cmd]
     }
     clear {
	 foreach i $telnetcmdbrk_list {
	     catch {brk delete $i}
	 }
	 var telnetcmdbrk_list {}
	 return
     }
     default {
	 error {invalid argument}
     }]

     #
     # Add breakpoints to a list
     #
     var telnetcmdbrk_list [concat $telnetcmdbrk_list $tempb]
}]

##############################################################################
#	print-telnet-sent-cmd
##############################################################################
#
# SYNOPSIS:	Print out the telnet command set
# PASS:		nothing
# CALLED BY:	breakpoint module set by telnetcmdwatch
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/17/95   	Initial Revision
#
##############################################################################
[defsubr    print-telnet-sent-cmd {} {
    #
    # Display sent command information
    #
    var sentCmd [type emap [getvalue al] [sym find type TelnetCommand]]
    echo -n {TelnetCommand SENT } 
    #
    # If an unknown command comes in just print the number
    #
    if {[null $sentCmd]} {
	echo [getvalue al]
    } else {
	echo [range $sentCmd 3 end chars]
    }
    return TCL_OK
}]

##############################################################################
#	print-telnet-recv-cmd
##############################################################################
#
# SYNOPSIS:	Print out the telnet command received
# PASS:		nothing
# CALLED BY:	breakpoint module set by telnetcmdwatch
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/17/95   	Initial Revision
#
##############################################################################
[defsubr    print-telnet-recv-cmd {} {
    #
    # Display sent command information
    #
    var recvCmd [type emap [getvalue al] [sym find type TelnetCommand]]
    echo -n {TelnetCommand RECV } 
    #
    # If an unknown command comes in just print the number
    #
    if {[null $recvCmd]} {
	echo [getvalue al]
    } else {
	echo [range $recvCmd 3 end chars]
    }
    return TCL_OK
}]

##############################################################################
#	telnetoptwatch
##############################################################################
#
# SYNOPSIS:	Watch the telnet option negotiation
# PASS:		command	= option to manipulate telnet option watch points
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	telnetoptbrk_list is created to store the breakpoints at
#		telnet library routines to display info.
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/ 3/95   	Initial Revision
#
##############################################################################
[defcommand    telnetoptwatch {{command clear}} top.socket.telnet
{Usage:
    telnetoptwatch sent
    telnetoptwatch recv
    telnetoptwatch all
    telnetoptwatch clear
    telnetoptwatch

Examples:
    "telnetoptwatch sent"	Set watch points for any Telnet options sent
    "telnetoptwatch recv"       Set watch points for any Telnet options
                                received 
    "telnetoptwatch all"        Set watch points for both Telnet options sent
                                and received
    "telnetoptwatch clear"      Remove all watch points of Telnet options
    "telnetoptwatch"            Same as "telnetoptwatch clear"

Synopsis:
    Set watch points on Telnet options sent and/or received.

Notes:
    None

See also:
    telnetcmdwatch
}
{
    global telnetoptbrk_list

    #
    # Set breakpoints
    #
    [case $command in 
     recv {
	 var tempb [brk aset telnet::TelnetHandleIncomingOption 
	            print-telnet-recv-opt]
     }
     sent {
	 var tempb [brk aset telnet::TelnetSendOptionReal 
	            print-telnet-sent-opt]
     }
     all {
	 var tempb [brk aset telnet::TelnetHandleIncomingOption 
	            print-telnet-recv-opt]
	 #
	 # Add recv break point
	 #
	 var telnetoptbrk_list [concat $telnetoptbrk_list $tempb]
	 var tempb [brk aset telnet::TelnetSendOptionReal 
	            print-telnet-sent-opt]
     }
     clear {
	 foreach i $telnetoptbrk_list {
	     catch {brk delete $i}
	 }
	 var telnetoptbrk_list {}
	 return
     }
     default {
	 error {invalid argument}
     }]

     #
     # Add breakpoints to a list
     #
     var telnetoptbrk_list [concat $telnetoptbrk_list $tempb]
}]

##############################################################################
#	print-telnet-sent-opt
##############################################################################
#
# SYNOPSIS:	Print out the telnet option sent
# PASS:		nothing
# CALLED BY:	breakpoint module set by telnetoptwatch
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/ 3/95   	Initial Revision
#
##############################################################################
[defsubr    print-telnet-sent-opt {} {
    #
    # Display information
    #
    echo -n {SENT }
    print-telnet-opt [getvalue al] [getvalue cl]
    return TCL_OK
}]

##############################################################################
#	print-telnet-recv-opt
##############################################################################
#
# SYNOPSIS:	Print out the telnet option received
# PASS:		nothing
# CALLED BY:	breakpoint module set by telnetoptwatch
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/ 3/95   	Initial Revision
#
##############################################################################
[defsubr    print-telnet-recv-opt {} {
    #
    # Display information
    #
    echo -n {RECV }
    print-telnet-opt [value fetch ds:si.TI_currentCommand] [getvalue al]
    return TCL_OK
}]

##############################################################################
#	print-telnet-opt
##############################################################################
#
# SYNOPSIS:	Print out the telnet option negotiation values
# PASS:		request = TelnetOptionRequest
#               option  = TelnetOptionID
# CALLED BY:	telnetoptwatch
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/ 3/95   	Initial Revision
#
##############################################################################
[defsubr    print-telnet-opt {req opt} {

    #
    # Display the request
    #
    echo -n [range [type emap $req [sym find type TelnetOptionRequest]]
                   4 end chars]
    echo -n { }
    
    #
    # Display the option. Display numbers if opt not in TelnetOptionID
    #
    var topt [type emap $opt [sym find type TelnetOptionID]]
    if {[null $topt]} {
	echo $opt
    } else {
	echo [range $topt 5 end chars]
    }
}]

