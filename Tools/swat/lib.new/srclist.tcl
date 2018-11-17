##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Source Handling
# FILE: 	srclist.tcl
# AUTHOR: 	Adam de Boor, Feb  4, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	slist	    	    	List source lines
#   	view <filename>  	brings up any source file in the srcwin
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/ 4/90		Initial Revision
#
# DESCRIPTION:
#	Functions for handling source code.
#
#	$Id: srclist.tcl,v 3.33 97/04/29 20:23:30 dbaumann Exp $
#
###############################################################################

[defcmd slist {args} source
{Usage:
    slist [<args>]

Examples:
    "slist" 	    	    	list the current point of execution
    "slist foo.asm::15"	    	list foo.asm at line 15
    "slist foo.asm::15,45"  	list foo.asm from lines 15 to 45

Synopsis:
    List source file lines in swat.

Notes:
    * The <args> argument can be any of the following:
        <address>   	    Lists the 10 lines around the given address
    	<line>		    Lists the given line in the current file
    	<file>::<line>	    Lists the line in the given file
    	<line1>,<line2>	    Lists the lines between line1 and line2,
			    	inclusive, in the current file
    	<file>::<line1>,<line2>  Lists the range from <file>

      The default is to list the source lines around cs:ip.

See also:
    emacs, listi, istep, regs. 
}
{
    global src-last-line repeatCommand lastCommand

    if {[length $args] == 0} {
    	var fileLine [src-line-catch [get-address $args]]
	[if {[null $fileLine]}
	{
	    error {No line information available for current address}
	} else {
	    var file [file-mangle-for-dos [index $fileLine 0]]
	    var start [index $fileLine 1]
	    var end [expr $start+9]
	}]
    } else {
    	var cc [string first :: [index $args 0]]
	[if {$cc != -1 &&
	     [scan [range $args [expr $cc+2] end char] {%d,%d} start end] >= 1}
    	{
    	    var file [range $args 0 [expr $cc-1] char]
    	    if {[null $end]} {
		var end $start
	    }
	} else {
	    var i [scan [index $args 0] {%d,%d} start end]
	    if {$i == 0} {
    	    	var fileLine [src-line-catch $args]
    	    	[if {[null $fileLine]}
    	    	{
		    error [format {No line information available for %s}
		    	    	$args]
    	    	} else {
		    [var file [file-mangle-for-dos [index $fileLine 0]]
			 start [expr [index $fileLine 1]-4]]
		    var end [expr $start+9]
    	    	}]
	    } else {
		if {$i == 1} {
		    var end $start
		}
    	    	#XXX: record last file used...
    	    	var fileLine [src-line-catch [get-address {}]]
    	    	[if {[null $fileLine]}
		{
		    error {Cannot determine file you want}
    	    	} else {
		    var file [file-mangle-for-dos [index $fileLine 0]]
		}]
	    }
	}]
    }

#    var maxwidth [expr [columns]-6]
#    var truncfmt [format {%%4d: %%.%ds...} [expr $maxwidth-4]]

    [for {var i $start}
	 {$i <= $end}
	 {var i [expr $i+1]}
     {
    	if {[catch {src read $file $i} line] == 0} {
    	    echo [format {%4d: %.73s} $i $line]
    	} else {
	    break
    	}
     }]
    var repeatCommand [format {%s %s::%d,%d} [index $lastCommand 0]
    	    	    	    $file [expr $end+1] [expr $end+($end-$start)+1]]
}]


#############################################################################
#   view-default sets the default patient for view commands
#############################################################################

[defcmd view-default {{patient {}}} top.source
{Usage:
    view-default [patient]

Examples:
    "view-default spool"    Make spool the default patient for use by
    	    	    	    	the view command
    "view-default"    	    Print the name of the current view-default patient
    "view-default off"      Turn off the view default

Synopsis:
    Specify the patient from which the view command will automatically
    look for source files.

Notes:
    * The view command searches for source files in the patient
      specified by the view-default command; if none has been
      specified, the view command searches first in the current
      patient and then in the sym-default patient, if any.

See also:
    view, srcwin, find, tag, doc, sym-default, resize, line
}
{
    global	_view_default	

    if {[null $patient]} {
	if {![null $_view_default]} {
	    echo $_view_default
	}
    } elif {[string c $patient off] == 0} {
    	var _view_default {}
    } else {
        if {[null [patient find $patient]]} {
    	    error [format {Patient %s not loaded.} $patient]
    	}
    	var _view_default $patient
    	sd $patient
    }
}]

#############################################################################
#   view the current file from a specific line number	    	    	    
#############################################################################
[defsubr line {line}
{
    if {$line < 1} {
    	error {Line number must be greater than 0}
    	return
    }

    dss 0 $line
    # the second dss will align things nicely if the line number takes the
    # bottom of the screen beyond the end of the file...
    dss	
}]

#############################################################################
#   convert a pathname to use "/" rather than "\"
#############################################################################

[defsubr convert-backslashes {path}
{
    var path [string subst $path \b /b global]
    var path [string subst $path \e /e global]
    var path [string subst $path \f /f global]
    var path [string subst $path \n /n global]
    var path [string subst $path \r /r global]
    var path [string subst $path \t /t global]
##    var path [string subst $path \\ / global]
    return $path
}]

#############################################################################
#   return an error message from view
#############################################################################

[defsubr view-error {}
{
    error {File must belong to the current patient or to a loaded view-default
or sym-default patient, or must have a full pathname specified.}
}]

alias view-size {resize view $1}


[defsubr find-installed-file {file}
{
    var	lr [getenv LOCAL_ROOT]

    if {[null $lr]} {
    	return $lr
    }
    var lr [string subst $lr \\ / global]
    var rd [getenv ROOT_DIR]
    var rd [string subst $rd \\ / global]

    var file [string subst $file $lr $rd]
    return $file
}]
    

#############################################################################
#   view a file in the srcwin	    	    	    	    	    	    
#############################################################################

[defcmd view {{file {}} {startline -1} {show_linenums 1}} top.source
{Usage:
    view [<file>] [<startLine>]

Examples:
    "view c:\pcgeos\include\pen.goh"
    	    	    	Brings up c:\pcgeos\include\pen.goh in a 25 line
                            window.
    "view foo.asm"    	Brings up foo.asm in the source window if foo.asm
    	    	    	    belongs either to the current patient or to a
    	    	    	    loaded view-default or sym-default patient.
    "view foo.asm 80"  	Brings up foo.asm with the code around line 80
    	    	    	    centered in the source window.
    "view"  	    	Brings up the source file for the current point
    	    	    	    of execution if it's available.
    "resize view 15"    Resizes the source window to 15 lines.
    "view off"    	Turns off the source window.

Synopsis:
    View a file in the source window.

Notes:
    * The optional <file> argument is the name of the file to view.
      The default file is the one containing the code for the current
      point of execution. If the file name, but not the full path,
      is specified, the view command searches for the file first in
      the view-default patient, if any, then in the current patient,
      and finally in the sym-default patient, if any.

    * The optional <startline> argument is the line which should be
      centered in the source window when the file comes up.

    * The default size of the source window is 25 lines. To resize it,
    use the resize command.

See also:
    view-default, sym-default, resize, srcwin, line, tag, find, doc
}
{
    global  srcwindisp srcwincurpos srcwinmode viewpatient
    global  _view_default attached found_line
    global  repeatCommand lastCommand atBreakpoint

    # turn off the found line since this is a new file
    var	found_line 0
    #
    # Just turn off the view if we've been told to.
    # 
    if {[string c $file off] == 0} {
	if {![null $srcwindisp]} {
	    srcwin off
	}
	return
    }
    #
    # Set $srcwinmode for future use by _display_source and dss, which refresh
    # the display on every FULLSTOP event. $srcwinmode must be _viewwin or _docwin
    # for the file passed to view to be displayed; if the line numbers should be
    # left out, $srcwinmode must be _docwin.
    # 
    if {$show_linenums} {
	var srcwinmode _viewwin
    } else {
	var srcwinmode _docwin
    }

    #
    # If no file name was passed, try to use the current point of execution.
    #
    if {[null $file]} {
    	var fileLine [src-line-catch cs:ip]
        if {[null $fileLine]} {
	    echo {Source file for the current point of execution is not available}
    	    return
    	} else {
	    #
	    # If there's no srcwin, all we have to do is put one up; it will
	    # automatically show the current point of execution. Otherwise, we
	    # set the global $srcwincurpos variable and call dss to bring up
	    # the right code.
	    #
	    if {[null $srcwindisp]} {
		srcwin 25 view
	    } else {
		var srcwincurpos [concat $fileLine 0]
		dss 0 0
	    }
	    return
    	}
    }
    #
    # We've been passed a file name. If we're presently sitting at a breakpoint,
    # we make sure $atBreakpoint is set so our file will not be superseded by
    # the source code for the current point of execution when _display_source
    # eventually gets called.
    # Note: atBreakpoint is set to TRUE both here and by _display_source
    # when appropriate. It gets reset to NULL in continue-patient, called
    # from cont, go, spawn...
    #
    if {$attached != 0} {
        if {[brk isset cs:ip]} {
    	    var atBreakpoint TRUE
    	}
    }
    #
    # Convert backslashes now if the file name contains any.
    #
    var file [convert-backslashes $file]

    var curpatient [patient name]
    var curpatientthread [index [patient data] 2]
    #
    # If the user has specified a view-default and if it's loaded,
    # try finding file there first.
    #
    if {![null [patient find $_view_default]]} {
    	sw $_view_default
    	if {[catch {[src size $file]}] != 0} {
    	    sw $curpatient
    	}
    } 
    #
    # If the file can't be found using the view-default or the current
    # patient, check if it belongs to the sym-default patient, which
    # must, of course, be loaded in order to do any good.
    #
    if {[catch {[src size $file]}] != 0} {
    	var s_default [sym-default]
    	if {[null [patient find $s_default]]} {
    	    view-error
    	} else {
    	    sw $s_default
    	    if {[catch {[src size $file]}] != 0} {
    	    	view-error
    	    }
    	}
    }
    #
    # If the full path isn't already included in the file name, put it in.
    # We don't need it right now if the file happens to belong to the
    # current patient, but if we don't put it into the $srcwincurpos variable
    # for future use by dss, life will be sad for the user.
    #
    if {[string first : $file] == -1} {
    	var fc [range $file 0 0 chars]
    	var fc2 [range $file 1 1 chars]
    	if {$fc != [format {%s} /] && $fc != [format {%s} \\] && $fc2 != :} {
            var path [range [patient path] 0 [string last / [patient path]] chars]
    	    var file [format {%s%s} $path $file]
    	}
    	if {![file exists $file]} {
    	    var file [find-installed-file $file]
    	}
    }	

    #
    # Make sure we have a srcwin.
    #
    if {[null $srcwindisp]} {
	srcwin 25 view
    }
    var disp [get-display-source-display]
    var lines [index $disp 4]
    #
    # Set up the global variable, $srcwincurpos, and call dss to
    # bring up the file in the srcwin.
    #
    if {$startline != -1} {
	var srcwincurpos [list $file $startline 0]
    } else {
	var srcwincurpos [list $file [expr $lines/2] 0]
    }
    dss 0 0

    #
    # Make sure the patient that was current when "view" was called is
    # still current.
    #
    if {$attached != 0} {
    	if {[null $curpatientthread]} {
            sw $curpatient
    	} else {
            sw $curpatient:$curpatientthread
    	}
    }
}]

#############################################################################
#   view the source code for a procedure in the srcwin	    	    	    
#############################################################################
[defcmd tag {myproc} top.source
{Usage:
    tag <routine>

Examples:
    "tag Foo"  	view source code for routine Foo, which belongs to
    	    	    	 the current patient
    "tag Foo"	  	same as "vroutine Foo"

    "view-default hello" make "hello" the view-default patient and
    "tag HelloDraw"  	  then look at its routine, HelloDraw

Synopsis:
    View the source code for a routine belonging to the current
    patient or the view-default patient.

See also:
    view, view-default, sym-default, srcwin, resize, line, find, doc
}
{
    global  srcwincurpos srcwinmode

    if {[catch {src line $myproc} f] != 0} {
    	# if we couldn't find the thing try docing it.
    	doc $myproc
    } elif {[null $f]} {
    	# if we couldn't find the thing try docing it.
    	doc $myproc
    } else {
    	var file [index $f 0]
    	var srcwinmode _srcwin


    	# if they are using the value history for the address, try to
    	# get the name we should be using   
    	if {[string match $myproc [format {@[0-9]}] ]} {
    	    var myproc [sym name [sym faddr any $myproc]]
    	}

    	# set up srcwincurpos as if we were displaying correct file
    	# at correct line, then do a find which will bring up the file
    	# and do the highlighting very nicely...

    	# this is a little tricky, but if the thing is a normal procedure
    	# then than name will be exactly as found in $mypoc on the first
    	# or second line since the first line might just be the type
    	# since we want to highlight the name and not the type we check
    	# to make sure we get the right thing

    	# if its a method then the name will be mangled beyond recognition
    	# but will always be on the same line due to the @method syntax, so
    	# we can just highlight that whole line

    	# of course if the thing is an assembly routine then we want to
    	# search upwards until we find the name of the routine

    	if {[null [get-display-source-display]]} {
    	    view $file
    	}    	

    	var srcwincurpos [list $file [index [src line $myproc] 1] 0]
    	if {[string match $file *.asm] || [string match $file *.ASM]} {
    	    search_internal $myproc -1 {} {}
    	    return
    	}

    	var srcwincurpos [list $file [expr {[index [src line $myproc] 1] - 2}] 0]
    	var text1 [src read [index $srcwincurpos 0] [expr [index $srcwincurpos 1]+1]]
    	var text2 [src read [index $srcwincurpos 0] [expr [index $srcwincurpos 1]+2]]
    	var pat [format {*%s*} $myproc]

    	if {[string match $text1 $pat] == 1} {
    	    search_internal $myproc 1 {} {}
    	} elif {[string match $text2 $pat] == 1} {
    	    search_internal $myproc 1 {} {}
    	} else {
    	    search_internal $text1 1 {} {}
    	}
    }
}]





