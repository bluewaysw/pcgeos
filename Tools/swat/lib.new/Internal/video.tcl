##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	video.tcl
# AUTHOR: 	Tony, Oct 29, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	videolog		Print video logging test info
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	10/29/90	Initial Revision
#
# DESCRIPTION:
#	Functions for examining video stuff
#
#	$Id: video.tcl,v 1.7.12.1 97/03/29 11:25:16 canavese Exp $
#
###############################################################################

[defcmd videolog {{startat -1}} lib_app_driver.video
{Prints video logging test info}
{
    if {[null [sym find var CharLog]]} {
    	echo {vidmem must have LOGGING turned on for this}
    	return
    }
    var ptr [value fetch logPtr]
    var LOGSIZE [sym get [sym find const CHAR_LOG_SIZE]]
    var arrayStart [sym addr [sym find var CharLog]]
    var arraySize [expr $LOGSIZE*[size CharLogEntry]]
    var printing 0
    var count [value fetch numCharsLogged]
    if {$count > $LOGSIZE} {
    	var count $LOGSIZE
    }
    for {var i 0} {$i < $count} {} {
    	#
    	# Search backwards for the start of a string
    	#
    	var xpos 99999 sxpos 99999
    	var sstart $ptr
    	var str {}
    	while {$sxpos <= $xpos} {
    	    # move back a char
    	    if {$sstart == $arrayStart} {
    	    	var sstart [expr $arrayStart+$arraySize]
    	    }
    	    var sstart [expr $sstart-[size CharLogEntry]]
    	    var xpos $sxpos
    	    var sxpos [value fetch Mono:$sstart.CLE_pos.P_x]
    	    if {$sxpos <= $xpos} {
   	    	var ch [value fetch Mono:$sstart.CLE_char byte]
    	    	if {$ch > 126} {
    	    	    var ch 45
    	    	}
   	    	var str [format {%c%s} $ch $str]
    	    }
    	    var i [expr $i-1]
    	}
    	var sstart [expr $sstart+[size CharLogEntry]]
    	#
    	# sstart is the start of the string
    	#
    	if {$startat == -1} {
    	    echo **********************************
       	    echo [format {String is <%s>} $str]
    	    echo [format {Offset is %d} $sstart]
    	} else {
    	    if {$startat == $sstart} {
    	    	var printing 1
    	    }
    	    if {$printing} {
        	echo **********************************
        	echo [format {String is <%s>} $str]
    	    	[for {var j $sstart} {$j < $ptr}
    	    	    {var j [expr $j+[size CharLogEntry]]} {
    	    	    	_print CharLogEntry Mono:$j
    	    	}]
    	    }
    	}

    	var ptr $sstart
    }
}]

[defcmd oldvideolog {{count 10}} lib_app_driver.video
{Prints video logging test info}
{
    if {[null [sym find var vidmem::CharLog]]} {
    	echo {vidmem must have LOGGING turned on for this}
    	return
    }
    echo [format {Last %d calls to CharLowRegion (in reverse order) are:}
    	    	    	$count]
    var ptr [value fetch vidmem::logPtr]
    var arrayStart [sym addr [sym find var vidmem::CharLog]]
    var arraySize [expr [sym get [sym find const vidmem::CHAR_LOG_SIZE]]*[type
    	    	    	    	size [sym find type vidmem::CharLogEntry]]]
    for {var i 0} {$i < $count} {var i [expr $i+1]} {
    	if {$ptr == $arrayStart} {
    	    var ptr [expr $arrayStart+$arraySize]
    	}
    	var ptr [expr $ptr-[type size [sym find type vidmem::CharLogEntry]]]
    	p CharLogEntry vidmem::Mono:$ptr
    }
}]

