##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	loadsyms.tcl
# FILE: 	loadsyms.tcl
# AUTHOR: 	Adam de Boor, Aug 21, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/21/90		Initial Revision
#
# DESCRIPTION:
#	a function to force the loading of all symbols after an attach -b
#
#	$Id: loadsyms.tcl,v 1.8.11.1 97/03/29 11:28:11 canavese Exp $
#
###############################################################################
[defcommand loadsyms {} obscure
{Force swat to read symbols for all geodes, and locate all existing threads.
To be used after invoking swat with the -b flag or performing an "attach -b"}
{
    [for {var h [value fetch geodeListPtr]}
	 {$h != 0}
	 {}
    {
	var h [value fetch kdata:$h word]
	var h [value fetch $h:GH_nextGeode]
    }]

    [for {var t [value fetch threadListPtr]}
	 {$t != 0}
  	 {var t [value fetch kdata:$t.HT_next]}
     {handle lookup $t}]

    step-patient
}]

##############################################################################
#				unignore_all
##############################################################################
#
# SYNOPSIS:	Simple function to locate all ignored geodes and offer the
#		user the chance to unignore it.
# PASS:		nothing
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/21/90		Initial Revision
#
##############################################################################
[defcommand unignore_all {} obscure
{A simple command to force swat to re-read symbols for a patient you ignored
when you first attached. It will find all ignored patients and offer you the
option to unignore each in turn. If you answer yes, the symbols for that
patient will be read}
{
    var h [value fetch loaderVars.KLV_handleBottomBlock]
    do {
	[if {[value fetch kdata:$h.HM_owner] == $h &&
	     [null [handle lookup $h]]}
	{
	    var s [value fetch kdata:$h.HM_addr]
	    var n [mapconcat c [value fetch [expr $s*16]+GH_geodeName] {var c}]
	    echo -n unignore $n? \[yn\](y)
	    var ans [read-char 1]
	    echo
	    [case $ans in
		{[Nn]} 	{#do nothing}
		default	{
		    assign [expr $s*16]+GH_geodeSerial 0
		    handle find $s:0
		}
	    ]
	}]
  	var h [value fetch kdata:$h.HM_next]
    } while {$h != [value fetch loaderVars.KLV_handleBottomBlock]}
}]
	    
