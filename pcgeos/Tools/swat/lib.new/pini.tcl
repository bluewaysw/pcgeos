##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	pini.tcl
# FILE: 	pini.tcl
# AUTHOR: 	Adam de Boor, Mar 24, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#       pini
#       iniwatch
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/24/92		Initial Revision
#
# DESCRIPTION:
#	Functions to print out the current contents of the .ini file.
#
#	$Id: pini.tcl,v 1.20 97/04/29 19:55:50 dbaumann Exp $
#
###############################################################################

##############################################################################
#				pini
##############################################################################
#
# SYNOPSIS:	    Print out the contents of the ini file(s) currently active
# PASS:		    nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defcommand pini {args} {system.misc}
{Usage:
    pini [-f <file>] [<category>]

Examples:
    "pini Lights Out"	    Print out the contents of the Lights Out category
    	    	    	    in each .ini file
    "pini"  	    	    Print out each currently loaded .ini file.
    "pini -f 0 Lights Out"  Print out the contents of the Lights Out category
    	    	    	    in the first (local) .ini file
    "pini -f 1"		    Print out the second .ini file.

Synopsis:
    Provides you with the contents of one or all of the .ini files being
    used by the current GEOS session.

Notes:
    * <category> may contain spaces and other such fun things. In fact, if you
      attempt to quote the argument (e.g. "pini {Lights Out}"), this will not
      find the category.

See also:
    none.
}
{
    var fileBegin 0
    var fileEnd 3

    while {[string m [index $args 0] -*]} {
	var flag [index $args 0]
	var args [range $args 1 end]
	[case $flag in
	    -f* {
		var fileBegin [index $args 0]
		var fileEnd $fileBegin
		var args [range $args 1 end]
	    }
	   ]
    }
    if {[not-1x-branch]} {
	for {var i $fileBegin} {$i <= $fileEnd} {var i [expr $i+1]} {
    	    	echo [format {*** ini file #%d ***} $i]
		pini-low [value fetch {loaderVars.KLV_initFileBufHan[$i]}] $args
    	    	echo
	}
    } else {
	pini-low [value fetch initFileBufHan] $args
    }
}]

##############################################################################
#				pini-low
##############################################################################
#
# SYNOPSIS:	    Print out an ini buffer, taking care to quote obnoxious
#		    chars appropriately.
# PASS:		    handle  = handle id of block holding the text of the file
# CALLED BY:	    pini
# RETURN:	    nothing
# SIDE EFFECTS:	    all chars in the buffer are echoed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defsubr pini-low {handle {category {}}}
{
    if {$handle == 0} {
	return
    }

    # prevent cntl-c in this subroutine, otherwise swat can crash
    irq no
    var t [type make array [expr [value fetch kdata:$handle.HM_size]<<4] [type char]]
    if {[null $category]} {
	echo [format [mapconcat i [value fetch ^h$handle $t]
		     {[case $i in
			    {\\\\r} {}
			    {\\\\[0-9]*} {format {\\%s} $i}
			    {%} {concat %%}
			    default {var i}]}]]
    } else {
    	var str [concat {{\n}} [value fetch ^h$handle $t]]
    	var pat [format {{\\n} %s{\\r} {\\n}}
	    	    [mapconcat c [explode [format {[%s]} $category]]
    	    	     {if {[string c $c \{] && [string c $c \}]} {
		         format {{%s} } $c
	    	      }
		     }]]

	var idx [string first $pat $str no_case]
    	if {$idx != -1} {
	    var str [range $str [expr $idx+4] end char]
	    var idx [string first {{\n} {[}} [range $str 1 end char]]
    	    if {$idx != -1} {
	    	var str [range $str 0 $idx char]
    	    }
	    echo [format [mapconcat i $str
			 {[case $i in
				{\\\\r} {}
				{\\\\[0-9]*} {format {\\%s} $i}
				{%} {concat %%}
				default {var i}]}]]
    	}
    }
    # allow cntl-c again
    irq yes
}]


##############################################################################
#	showCategoryAndKey
##############################################################################
#
# SYNOPSIS:	format a category and key, leaving an '=' sign after
#   	    	the key
# PASS:		ds:si - category, cx:dx - key
# CALLED BY:	iniwatch
# SIDE EFFECTS:	leaves cursor on same line as key
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showCategoryAndKey {} {
    showCategory
    echo -n [format {%s = }
	    [getstring cx:dx]
    ]
}]


##############################################################################
#	showCategory
##############################################################################
#
# SYNOPSIS:	Display the category at ds:si in square brackets
# PASS:		ds:si - category string, null-terminated
# CALLED BY:	showCategoryAndKey, showWrite, showDeleteCategory
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	7/ 8/93   	Initial Revision
#
##############################################################################
[defsubr    showCategory {} {
    echo [format {[%s]}
      [getstring ds:si]
    ]
}]


##############################################################################
[defcommand    iniwatch {{flags {}}} system.misc
{Usage:
    iniwatch <flags>

 Examples:
    iniwatch -r:  show init file reads
    iniwatch -w:  show init file writes
    iniwatch -rw: show both reads and writes
    iniwatch  (no arguments)  stop init file watching

 Synopsis:

    iniwatch is used to monitor reading and writing using the InitFile
    routines. 

 Notes:
 

 See Also:
    pini
}
{
    require getstring  cwd
    require getcc      setcc
    require remove-brk showcall

    global  ini-read ini-write

    remove-brk ini-read 
    remove-brk ini-write

    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     r {
		 var ini-read [list 
			[brk InitFileReadString {showReadString}]
			[brk InitFileReadString::done {showReadStringResult}]
			[brk InitFileReadInteger {showReadInt}]
			[brk InitFileReadInteger::exit {showReadIntResult}]
			[brk InitFileReadBoolean {showReadBoolean}]
			[brk InitFileReadBoolean::exit {showReadBooleanResult}]
		]
	     }   
	     w {
		 var ini-write [list 
		    [brk InitFileWrite {showWrite}]
		    [brk InitFileWrite::insertBody {showWriteValue}]
		    [brk InitFileDeleteCategory {showDeleteCategory}]
			   ]
		 }
	     default {
		 error [list Unrecognized flag $i]
		 }
	 ]}
	}
}]

##############################################################################
#	showDeleteCategory
##############################################################################
#
# SYNOPSIS: 	Print out the category name that's being deleted	
# PASS:		ds:si - category string
# CALLED BY:	iniwatch
# RETURN:	0
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	6/24/93   	Initial Revision
#
##############################################################################
[defsubr    showDeleteCategory {} {
    echo 
    echo DELETE CATEGORY
    showCategory
    return 0
}]

##############################################################################
#	showWrite
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
#       chrisb 	7/ 8/93   	Initial Revision
#
##############################################################################
[defsubr    showWrite {} {
    echo WRITE
    showCategory
    return 0
}]


##############################################################################
#	showWriteValue
##############################################################################
#
# SYNOPSIS:	Print out the value of a write operation
# PASS:		body - body of key
# CALLED BY:	iniwatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showWriteValue {} {
    var seg [value fetch kdata::buildBufAddr]
    var str [getstring $seg:0]

    # strip out all the carriage returns, replacing them with a
    # variable initialized to nothing

    var foo
    var newString [string subst $str \r $foo global]
    echo $newString
    return 0
}]



##############################################################################
#	showReadString
##############################################################################
#
# SYNOPSIS:	display the value returned by InitFileReadString
# CALLED BY:	iniwatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showReadString {} {

    global iniStrSize
    var readFlags [read-reg bp]
    var iniStrSize [expr $readFlags&0x0fff]
    echo
    echo READ STRING
    showCategoryAndKey
    return 0
}]

##############################################################################
#	showReadStringResult
##############################################################################
#
# SYNOPSIS: 	if carry is clear -- print out string, otherwise, bail	
# PASS:		nothing 
# CALLED BY:	iniwatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showReadStringResult {} {

    global  iniStrSize


    if {[getcc c]} {
	echo (not found)
    } else {
	
	if {$iniStrSize==0} {
	    echo-ini-string [getstring ^hbx]
	} else  {
	    echo-ini-string [getstring es:di]
	}
    }
    return 0
}]

##############################################################################
#	showReadInt
##############################################################################
#
# SYNOPSIS:	Display the value returned by InitFileReadInteger
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showReadInt {} {
    echo
    echo READ INTEGER
    showCategoryAndKey
    return 0

}]

##############################################################################
#	showReadIntResult
##############################################################################
#
# SYNOPSIS: 	display results of integer read	
# PASS:		nothing 
# CALLED BY:	iniwatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showReadIntResult {} {
    if {[getcc c]} {
	echo (not found)
    } else {
	echo [read-reg ax]
    }
    return 0
}]

##############################################################################
#	showReadBoolean
##############################################################################
#
# SYNOPSIS: 	display value returned from InitFileReadBoolean	
# PASS:		nothing 
# CALLED BY:	iniwatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showReadBoolean {} {
    echo
    echo READ BOOLEAN
    showCategoryAndKey
    return 0
}]


##############################################################################
#	showReadBooleanResult
##############################################################################
#
# SYNOPSIS:	display result of boolean read
# PASS:		nothing 
# CALLED BY:	iniwatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    showReadBooleanResult {} {
    if {[getcc c]} {
	echo (not found)
    } else {
	if {[read-reg ax]} {
	    echo TRUE
	} else {
	    echo FALSE
	}
    }
    return 0
}]

##############################################################################
#	echo-ini-string
##############################################################################
#
# SYNOPSIS:	Echo an initfile string, taking care of carriage returns
# PASS:		str -- string to output
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#   	If there are no carriage returns, then just print the thing
#   out.  Otherwise, print it out as a "blob", enclosed in curly braces
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/10/92   	Initial Revision
#
##############################################################################
[defsubr    echo-ini-string {str} {

    if {[string first \r $str]== -1} {
	echo $str
    } else {
	echo \{
	# strip out all the carriage returns, replacing them with a
	# variable initialized to nothing
	var foo
	var newString [string subst $str \r $foo global]
	echo $newString
	echo \}
    }
}]
