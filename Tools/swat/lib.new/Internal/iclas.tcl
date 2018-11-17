##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ICLAS Library
# FILE: 	iclas.tcl
# AUTHOR: 	Martin Turon, Aug 25, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	8/25/92		Initial Revision
#
# DESCRIPTION:
#	
#	$Id: iclas.tcl,v 1.15.12.1 97/03/29 11:25:09 canavese Exp $
#
###############################################################################

[defhelp iclas lib_app_driver
{Commands relating to the iclas library}]

##############################################################################
#			DEFINE ANY SHORTCUTS
##############################################################################

[defhelp useful_aliases lib_app_driver.iclas
{Note the following handy aliases, which are already set up for use:

    alias	ilstat	{display 2 {pitemname}}
    alias	pwot	{print WShellObjectType}
}]

alias	ilstat	{display 2 {pitemname}}
alias	pwot	{print WShellObjectType}


##############################################################################
#			LOAD ANY REQUIRED FILES
##############################################################################
load	setcc


##############################################################################
#				phfile
##############################################################################
#
# SYNOPSIS:	Prints out a HugeFile header.
#
# PASS:		seg	= segment containing huge file
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	8/25/92   	Initial version
#
##############################################################################
[defcommand phfile {{seg es}} lib_app_driver.iclas
{Usage:
    phfile [<address>]

Examples:
    "phfile"	    	    	print the HugeFileInfoStruct at es:0

Synopsis:
    Print out a HugeFile read buffer.

Notes:
    * The address argument is the address of the HugeFileInfoStruct
      This defaults to es:0.  

See also:
}

{
    print word $seg:HFIS_fileHandle
    print word $seg:HFIS_bufferHandle
    print word $seg:HFIS_offset
    print word $seg:HFIS_nextLine
    bytes $seg:HFIS_buffer 200
}]


##############################################################################
#				moniterIclas
##############################################################################
#
# SYNOPSIS:	Sets a slew of breakpoints to print informative
#		messages about the status of various iclas operations.
#
# CALLED BY:	Utility
#
# PASS:		flags
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dloft	??		Initial version
#	martin	11/16/92   	Added ability to handle flags passed in
#
##############################################################################
[defcommand monitorIclas {{flags -c}} lib_app_driver.iclas
{Usage:
    monitorIclas <flags>

Examples:
    "monitorIclas"	   	monitor class operations
    "monitorIclas -f"		monitor file traffic
    "monitorIclas -Vl"		monitor link verification in *every* way.

Synopsis:
	Print messages at various points in the execution of the iclas
	library code.

Notes:
	Flags are as follows:
		-c	class operations
		-l	link verification code
		-f	file traffic
		-b	bookmarks (not supported yet)
		-i	item line code
	
		-V	Verbose (give me all you've got)
		-M	Minimize (only super-critical messages)

See also:
}
{
    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     	c {
		  monitor-iclas-class-operations
		}
	     	l {
		  monitor-link-verification-code $flags
		}
	     	f {
		  fileTraffic
		}
	     	b {
		  monitor-iclas-bookmarks $flags
		}
	     	i {
		  monitor-item-line-code $flags
		}
	     ]
	}
    }
}]


##############################################################################
#			monitor-iclas-class-operations
##############################################################################
#
# SYNOPSIS:	Prints messages at various points in the execution of
#		the class-related iclas library code.
#
# CALLED BY:	monitorIclas
#
# PASS:		nothing
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dloft	???		Initial version
#	martin	11/16/92   	Pulled out of monitorIclas
#
##############################################################################
[defcommand monitor-iclas-class-operations {} lib_app_driver.iclas
{Usage:
    monitor-iclas-class-operations

Examples:
    "monitor-iclas-class-operations"	   	

Synopsis:
	Print messages at various points in the execution of the iclas
	library code.

Notes:

See also:
}
{
	[brk iclas::FilesReadIntoChunkArray::error
	  {print-string-and-enum-at {Error at FilesReadIntoChunkArray} ds:dx FileError ax}]

	[brk iclas::StudentTransferCommon
	  {print-enum-at {Entering StudentTransferCommon:} StudentTransferType al}]

	[brk iclas::IclasCreateClass {print-and-continue {Creating Class}}]

	[brk iclas::ClGetLowestClassID::IDFoundCleanup 
 	  {print-string-and-message-at ds:si {New Class Directory}}]

	[brk iclas::ClGetLowestClassID::IDErrorExit
	  {print-enum-halt {Error in ClGetLowestClassID} FileError ax}]

	[brk iclas::ClDeleteClassID::error
	  {print-enum-halt {Error in ClDeleteClassID} FileError ax}]

	[brk iclas::ClWriteBytesToFileWithDotCRLF::error
	  {print-enum-halt {Error in ClWriteBytesToFileWithDotCRLF} FileError ax}]

	[brk iclas::ClConstructItemFile::itemFileError
	  {print-enum-halt {Error in ClConstructItemFile} FileError ax}]

	[brk iclas::ClInitClassFilesAndRoster::oops
	  {echo "Error in ClInitClassFileAndRoster"}]

	[brk iclas::IclasGetTeacherClassArray::error
	  {echo "Error in IclasGetTeacherClassArray"}]

	[brk iclas::ClCreateClassDir::createDirError
	  {print-enum-halt {Error in ClCreateClassDir} FileError ax}]

#	[brk iclas::FilesUsefileEnum::error
#	  {echo "Error in FilesUsefileEnum"}]

#	[brk iclas::ClRemoveStudentFromClass
#	  {print-value-and-message-at ds:bx ClassUsefileLine {Removing student from class:}}]

	[brk iclas::IclasRemoveClass::error
	  {print-enum-halt {Error in IclasRemoveClass} FileError ax}]

	[brk iclas::IclasUsefileAddStudent::done
	  {ifCarrySet {echo "Error in IclasUsefileAddStudent"}}]

	[brk iclas::IclasUsefileRemoveStudent::error_close_file_and_boogie
	  {print-enum-halt {Error in IclasUsefileRemoveStudent} FileError ax}]

	[brk iclas::IclasUsefileRemoveStudent::errorCouldntOpenUsefile
	  {echo "Error in RemoveStudent, couldn't open .USE file"}]

	[brk iclas::IclasRemoveProgram::error
	  {print-enum-halt {Error in IclasRemoveProgram} FileError ax}]

	[brk iclas::MnuInsertInAppMenu::errorCond
	  {print-enum-halt {Error in MnuInsertInAppMenu} MnuErrorCodes ax}]

	[brk iclas::IclasInsertInMenu::errorCond
	  {print-enum-halt {Error in IclasInsertInMenu} MnuErrorCodes ax}]

	[brk iclas::IclasMnuRemoveItem::errorCond
	  {print-enum-halt {Error in IclasMnuRemoveItem} MnuErrorCodes ax}]

	[brk iclas::MnuRemoveFromAppMenu::errorCond
	  {print-enum-halt {Error in MnuRemoveFromAppMenu} MnuErrorCodes ax}]

	[brk iclas::IclasRemoveClass
	  {print-string-and-message-at es:di {Removing class...}}]

	[brk iclas::ClModifyClassItemFileDescription::error
	  {if {[read-reg ax] == 0} {echo Out of Memory!} {penum FileError ax}}]

	[brk iclas::ClModifyStudentMenuWithNewDescription::error
	  {echo "Error opening file in ClModifyStudentMenuWithNewDescription"}]

	[brk iclas::ClModifyStudentMenuWithNewDescription::errorUnlock
	  {echo "Error Removing Item in ClModifyStudentMenuWithNewDescription"}]

	[brk iclas::ClModifyStudentMenuWithNewDescription::errorClose
	  {echo "Error Inserting Item in ClModifyStudentMenuWithNewDescription"}]

	[brk iclas::ClRemoveClassFromTeacherMenu::errorFree
	  {echo "Error updating menu in ClRemoveClassFromTeacherMenu"}]

	[brk iclas::ClRemoveClassFromTeacherMenu::error
	  {echo "Error reading item file in ClRemoveClassFromTeacherMenu"}]

}]

##############################################################################
#	ifCarrySet
##############################################################################
#
# SYNOPSIS:	Perform an action if the CARRY flag is set.
# PASS:		action - list of Tcl commands to perform, in case of error
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	2/11/93   	Initial Revision
#
##############################################################################

[defsubr    ifCarrySet {action} {
    if { [getcc c] } {
    	return [$action]
    } else {
	return 0
    }
}]


[defsubr print-value-and-message-at {addr type message} {
	echo $message
	print $type $addr
	return 0
}]

[defsubr print-string-and-enum-at {message stringaddr etype reg} {
	print-enum-at $message $etype $reg
	pstring $stringaddr
	return 0
}]

[defsubr print-string-and-enum-halt {message stringaddr etype reg} {
	print-enum-at $message $etype $reg
	pstring $stringaddr
}]

[defsubr print-string-and-message-at {stringaddr message} {
	echo $message
	pstring $stringaddr
	return 0
}]

[defsubr print-enum-at {message etype reg} {
	echo $message:
	echo [penum $etype $reg]
	return 0
}]

[defsubr print-enum-halt {message etype reg} {
	echo $message:
	echo [penum $etype $reg]
}]

[defsubr print-and-continue {message} {
	echo $message
	return 0
}]

[defsubr run-command-at {message cmd} {
	echo $message
	$cmd
	return 0
}]

[defsubr print-handle {reg} {
	phandle $reg
	return 0
}]


##############################################################################
#		monitor-link-verification-code
##############################################################################
#
# SYNOPSIS:	Prints messages at various points in the execution of
#		the link verification-related library code.
#
# CALLED BY:	monitorIclas
#
# PASS:		nothing
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    monitor-link-verification-code {flags} 
{
	parse-monitor-iclas-flags $flags
		
     #
     # Define messages to be displayed in "minimal" mode
     #
	#
	# Print out any errors that occur when setting the WOT of the links. 
	#
#	     [brk iclas::IclasForceSetDesktopInfo::error 
#		    {print-message-and-file-error {Error setting WOT of }}]

     #
     # Define messages to be displayed in "normal" mode
     #
	if {$normal} {

	#
	# Print out any errors that occur when setting the WOT of the links.
	#

	#  [brk iclas::fixupIclasWOTType 
	#	    {print-message-then-string {Fixed-up WOT for: } ds:si}]

	#     [brk iclas::LinkDeleteAllInFileList::deleteOldIclasLink 
	#	    {print-message-then-string {Old link DELETED: } ds:bx}]

	     [brk iclas::LinkVerificationCallBack::createLink 
		    {print-message-then-itemname {New link CREATED: } es:di}]
	}

     #
     # Define messages to be displayed in "verbose" mode
     #
	if {$verbose} {
	     [brk FileSetCurrentPath::exit
		    {finish-and-do {pwd}}]

	     [brk FILEPOPDIR
		    {finish-and-do {pwd}}]
	}
}]


[defsubr print-file-info-if-carry {fname ferror} 
{
	[addr-preprocess $fname seg off]
	var ferror [index [addr-parse @$ferror 0] 1]

	if {[getcc C]} {
	   pstring $seg:$off 36
	   echo -n [penum FileError $ferror]
	   echo
	}
	return 0
}]


[defsubr print-message-then-string {message stringaddr} {
	echo -n $message
	pstring $stringaddr
	return 0
}]

[defsubr finish-and-do {command} {
	eval $command
	return 0
}]

[defsubr print-message-and-file-error {message} {
	if {[getcc C]} {
		echo -n $message
		print-file-info-if-carry ds:dx ax
	}
	return 0
}]

[defsubr print-message-then-itemname {message stringaddr} {
	echo -n $message
	pitemname $stringaddr
	return 0
}]

##############################################################################
#				pitemname
##############################################################################
#
# SYNOPSIS:	Prints the longname of an item line
#
# CALLED BY:	monitor-link-verification-code
#
# PASS:		addr	= address of item line
#		itype	= register containing ItemLineType
#		fixsize	= number of characters to print
#
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	12/2/92   	Initial version
#
##############################################################################
[defsubr    pitemname {{addr es:di} {itype si} {fixsize 40}} 
{
    var a [addr-parse $addr]
    var s ^h[handle id [index $a 0]]
    var o [index $a 1]
    var term 0

    var cnt $fixsize

    [case [getvalue $itype] in
	[getvalue ILT_CLASS] { 
		var o [expr $o+2] 
		var term 94
	}

	[getvalue ILT_COURSEWARE] { 
		var o [expr $o+2] 
		var term 94
	}

	[getvalue ILT_SPECIAL_UTILITY] { 
		var o [expr $o+2] 
		var term 94
	}

	[getvalue ILT_STUDENT] {
		var term 40
	}
    ]



    [for {var c [value fetch $s:$o [type byte]]}
	 {($c != $term) && ($cnt > 0)}
	 {var c [value fetch $s:$o [type byte]]}
    {
	pchar $c
        var o [expr $o+1]
	var cnt [expr $cnt-1]
    }]

    if {$c != $term} {
	while { $cnt > 0 } { 
	  echo -n [format { }]
	  var cnt [expr $cnt-1]
	  }
    }
	
    echo

}]


##############################################################################
#				pchar
##############################################################################
#
# SYNOPSIS:	Prints a single character:
#			Alpha-numeric are printed as they are
#			prints NULLS as a reverse O
#			prints 0xCC  as a reverse C
#			prints other random characters as a reverse R
#
# CALLED BY:	pitemname
#
# PASS:		c	= character
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	12/3/92   	Initial version
#
##############################################################################
[defsubr    pchar {c} 
{
	[case $c in 
		0	{var c 15}	# NULL = reverse O
		204	{var c 3}	# 0xcc = reverse C	
	]

        echo -n [format %c $c]
}]


##############################################################################
#		parse-monitor-iclas-flags
##############################################################################
#
# SYNOPSIS:	Parses the flags passed into monitorIclas
#
# CALLED BY:	monitor-link-verification-code
#
# PASS:		flags
# RETURN:	verbose, normal defined in caller's scope:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/17/92   	Initial version
#
##############################################################################
[defsubr    parse-monitor-iclas-flags {flags} 
{
    var normal  1
    var verbose 0

    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     	V {
		  var verbose 1
		}
		M {
		  var normal 0
		}
	     ]
	}
    }
    uplevel 1 var verbose $verbose normal $normal
}]




##############################################################################
#			monitor-iclas-bookmarks
##############################################################################
#
# SYNOPSIS:	Prints messages at various points in the execution of
#		the bookmarks-related iclas library code.
#
# CALLED BY:	monitorIclas
#
# PASS:		nothing
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    monitor-iclas-bookmarks {flags} 
{

}]



##############################################################################
#				fileTraffic
##############################################################################
#
# SYNOPSIS:	
#
# CALLED BY:	
#
# PASS:		
# RETURN:	
#
# SIDE EFFECTS:	
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dloft	11/17/92	Initial version
#
##############################################################################
[defcommand fileTraffic {} lib_app_driver.iclas
{Usage:
	fileTraffic
}
{
	[brk FileClose {print-handle bx}]
	[brk FileOpen {print-string-and-message-at ds:dx {FileOpen:}}]
}]


##############################################################################
#			monitor-item-line-code
##############################################################################
#
# SYNOPSIS:	
#
# CALLED BY:	
#
# PASS:		
# RETURN:	
#
# SIDE EFFECTS:	
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/30/92   	Initial version
#
##############################################################################
[defsubr    monitor-item-line-code {flags} 
{

}]


