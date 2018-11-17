##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- File module error handling
# FILE: 	file-err.tcl
# AUTHOR: 	Adam de Boor, Aug 14, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	file-err    	    	Locates a file
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/14/89		Initial Revision
#
# DESCRIPTION:
#	Routines for use by the File module when searching for a patient.
#
#	$Id: file-err.tcl,v 3.186 97/11/24 20:35:16 simon Exp $
#
###############################################################################

#
# Variable holding the pattern against which to compare a path to see if it's
# absolute.
#
defvar file-abspat {}

#
# Set up the initial load-path variable inside a subroutine to avoid leaving
# extra variables lying around. Makes sure the lib directory appears at the
# end of the path.
#
[defsubr setup-load-path {}
{
    global load-path file-devel-dir file-syslib-dir file-root-dir file-os

    if {[string c ${file-os} win32] == 0} {
    	# change initial value to reg value SYSLIB_OVERRIDE_PATH
    	var lp [getenv SYSLIB_OVERRIDE_PATH]
    } else {
	var lp [getenv SWATPATH] load-path {}
    }

    if {[string c ${file-os} unix] != 0} {
    	# translate backslashes to forward slashes from DOS
    	var lp [string subst $lp \\ / global]
    }

    for {} {![null $lp]} {} {
    	if {[string c ${file-os} unix] == 0} {
    	    var colon [string first : $lp]
    	} else {
	    var colon [string first ; $lp]
    	}
	if {$colon < 0} {
	    var load-path [concat ${load-path} [file expand $lp]]
	    break
	} else {
	    var load-path [concat ${load-path} 
				  [file expand 
				    [range $lp 0 [expr $colon-1] chars]]]
	    var lp [range $lp [expr $colon+1] end chars]
	}
    }
    global file-abspat
    if {[string c ${file-os} unix] == 0} {
    	var file-abspat /*
    } else {
    	var file-abspat {?:[\\/]*}
    }

    if  {[string c ${file-os} win32] == 0} {
	var load-path [concat ${load-path}
	                      ${file-syslib-dir}]
    } elif {[string match ${file-syslib-dir} ${file-abspat}]} {
    	#
	# If file-syslib-dir is absolute, but actually within our
	# domain (it starts with file-root-dir), see if there's one in the
	# user's development tree at which we should be looking.
	#
	if {[string first ${file-root-dir} ${file-syslib-dir}] == 0} {
    	    #
	    # Yup. Figure the subdirectory below the root and see if that
	    # subdirectory exists in the development tree.
	    #
    	    var subdir [range ${file-syslib-dir}
	    	    	    [length ${file-root-dir} chars]
			    end chars]
	    var dir ${file-devel-dir}${subdir}
	    if {[string c ${file-os} win32] == 0} {
		# translate backslashes to forward slashes from DOS
		var dir [string subst $dir \\ / global]
	    }
	    if {[file exists $dir]} {
    	    	#
		# Yup. Tack it onto the end of the load path.
		#
	    	var load-path [concat ${load-path} ${dir}]
    	    } else {
    	    	#
		# Trim off the first component and try again. file-syslib-dir
		# may be in a branch tree.
		#
	    	var subdir [range ${subdir}
				   [expr [string first /
						 [range $subdir 1 end chars]]+1]
				   end chars]
		var dir ${file-devel-dir}${subdir}
		if {[string c ${file-os} win32] == 0} {
		    # translate backslashes to forward slashes from DOS
		    var dir [string subst $dir \\ / global]
		}
		if {[file exists $dir]} {
		    var load-path [concat ${load-path} ${dir}]
    	    	}
    	    }
    	}
    	var load-path [concat ${load-path} ${file-syslib-dir}]
    } elif {[null ${file-devel-dir}]} {
	var load-path [concat ${load-path} ${file-root-dir}/${file-syslib-dir}]
    } else {
	var load-path [concat ${load-path}
	                      ${file-devel-dir}/${file-syslib-dir}
	                      ${file-root-dir}/${file-syslib-dir}]
    }
}]
setup-load-path


##############################################################################
#				get-load-path
##############################################################################
#
# SYNOPSIS:	    Return the list of directories in which to search for
#   	    	    a .tcl file. This exists so users can dynamically
#		    alter the load-path based on the current patient.
# PASS:		    nothing
# CALLED BY:	    load
# RETURN:	    list of directories in which to search
# SIDE EFFECTS:	    none
#
# STRATEGY
#   	    The default behaviour of this command is to simply return
#   	    the load-path variable's value.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defsubr get-load-path {}
{
    global load-path
    return ${load-path}
}]

##############################################################################
#				load
##############################################################################
#
# SYNOPSIS:	Load a file of Tcl commands
# PASS:		file	= name of file to load
# CALLED BY:	user
# RETURN:	whatever the source command returns.
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defcommand load {file} {swat_prog.load swat_prog.file}
{Usage:
    load <file>

Examples:
    "load print"    	Searches for a file called "print" or "print.tcl"
			and loads it.

Synopsis:
    This loads a file of Tcl commands, evaluating each command in turn until
    the last is evaluated, or an error is detected.

Notes:
    * The directories in which this command searches are the elements of the
      list returned by the "get-load-path" command. Unless you've redefined
      this command, this list is taken from the global "load-path" variable.

    * The load-path variable is initialized from the SWATPATH environment
      variable, which is in the form <dir1>:<dir2>:...:<dirn>. The Swat
      system library directory (both in your development tree and in the
      installed source tree) is automatically appended to this path, so you
      needn't include it yourself.

    * Directories may contain ~ or ~<user-name> at their start. (UNIX only)

    * When searching, both <file> and <file>.tcl are checked for.

See also:
    autoload, source
}
{
    #
    # If the file is absolute, then pass it to source as-is. Note that we
    # use "uplevel 0" to make sure the file being loaded is operating in
    # the global context at all times.
    #
    global file-os file-abspat

    [if {[string match $file /*] ||
	 ([string c ${file-os} unix] != 0 && [string match $file ?:*])}
    {
    	return [uplevel 0 [format {source %s} $file]]
    }]
    #
    # Loop through all the directories returned by get-load-path, trying the
    # file as-is (i.e. from Swat's current directory) first.
    #
    if {[string match $file *.tcl]} {
    	var cfile [file rootname $file].tlc
    } else {
    	var cfile $file.tlc
    }

    foreach dir [concat . [get-load-path]] {
    	var dir [file expand $dir]
	var f [file-mangle-for-dos $dir/$file]
	var cf [file-mangle-for-dos $dir/$cfile]
    	[if {[file isfile $f] && [file readable $f]} {
    	    #
	    # The file is there and readable, so source it in the global
	    # context.
	    #
    	    if {[file isfile $cf] && [file newer $cf $f]} {
	    	return [uplevel 0 bc fload $cf]
	    } else {
	    	return [uplevel 0 source $f]
    	    }
    	} elif {[file isfile $f.tcl] && [file readable $f.tcl]}
    	{
    	    #
	    # The file.tcl is there and readable, so source it in the global
	    # context.
	    #
	    if {[file isfile $f.tlc] && [file newer $f.tlc $f.tcl]} {
	    	return [uplevel 0 bc fload $f.tlc]
    	    } else {
	    	return [uplevel 0 source $f.tcl]
    	    }
    	} elif {[file isfile $cf] && [file readable $cf]} {
    	    # if there is only a tlc file the use it
    	    	return [uplevel 0 bc fload $cf]
    	} elif {[file isfile $f.tlc] && [file readable $f.tlc]} {
    	    # if there is only a tlc file the use it
    	    	return [uplevel 0 bc fload $f.tlc]
    	}]
    }
    error [format {load: can't find %s} $file]
}]

##############################################################################
#				file-mangle-for-dos
##############################################################################
#
# SYNOPSIS:	Ensure the file name is 8.3, so DOS doesn't reject it
#   	    	spuriously.
# PASS:		file	= absolute path of file
# CALLED BY:	INTERNAL
# RETURN:	path with all things trimmed to be 8.3 names
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/14/92		Initial Revision
#
##############################################################################
[defsubr file-mangle-for-dos {file}
{
    global file-os
    
    if {[string c ${file-os} unix] == 0} {
    	# no mangling required
	return $file
    } elif {[string c ${file-os} win32] == 0} {
    	return [string subst $file \\ / global]
    } else {
    	return [mapconcat f [explode $file /\\] {
	    if {[string match $f *:]} {
	    	var f
    	    } else {
	    	[format {/%s%s} [range [file root $f] 0 7 char]
		    [range [file ext $f] 0 3 char]]
    	    }
    	}]
    }
}]
		

##############################################################################
# Error-handling routine for File module when a patient's executable cannot
# be located. Prompts for the location, with file-name completion, and
# returns either the name of an existing file or the null string, if the
# user has requested we ignore the thing.
#
[defsubr file-err {patient maydetach mayignore}
{
    require top-level-read toplevel
    global file-init-dir file-devel-dir file-os file-abspat

    # Figure the name of the patient w/o the extension or trailing spaces
    var pname [index [range $patient 0 7 char] 0]

    # If the patient is listed in the "SWATIGNORE" envariable, ignore it,
    # since we can't seem to locate it.
    foreach i [getenv SWATIGNORE] {
	if {[string c $i $pname] == 0} {
	    return {}
	}
    }

    echo Can't find symbol file for "$patient" (version mismatch?)
    echo Answer "quit" to exit to the shell
    if {$maydetach} {echo Answer "detach" to detach and return to top level}
    if {$mayignore} {echo Answer "ignore" to ignore this patient}
    if {$mayignore} {echo Answer "Ignore" to ignore this patient always (see nuke-symdir-entry)}
    
    for {} {1} {} {
	if {[string compare ${file-os} win32] == 0} {
	    var file [top-level-read {Where is it? } ${file-devel-dir}/ 0]
	} else {
	    var file [top-level-read {Where is it? } ${file-init-dir}/ 0]
	}
    	#
	# Handle lazy initial-value override, looking for any double slash,
	# which indicates a switch to a different absolute path, or a /~,
    	# which indicates a switch to someone's home directory. $i is left
	# holding the index of the first character to use in $file, defaulting
	# to 0 if neither // nor /~ is present.
	#
    	var // [string last // $file] /~ [string last /~ $file] i 0
    	if {${//} >= 0} {
	    if {${//} > ${/~}} {
	    	var i ${//}
	    } else {
	    	var i ${/~}
	    }
	} elif {${/~} >= 0} {
	    var i ${/~}
	}
	
    	#
	# Deal with any home-directory specs in the file as well as trimming the
	# file as indicated by the above checks.
	#
    	var file [file expand [range $file $i end char]]

    	#
	# Deal with drive specifier under DOS and WIN32
	#
    	if {[string c ${file-os} unix] != 0} {
	    var i [string last : $file]
	    if {$i > 0} {
	    	var file [range $file [expr $i-1] end char]
    	    }
    	}

    	#
	# See if the line given is one of the special commands we accept
	#
    	var check {}
    	[case [index $file 0] in
    	 q* {var check quit}
	 d* {var check detach}
	 i* {var check ignore}
    	 I* {var check Ignore}]

    	if {![null $check] && [string compare ${file-os} dos] == 0} {
    	    if {[string first : $check] != -1} {
    	    	var check {}
    	    }
    	}
	if {![null $check]} {
    	    #
	    # Restrict the special command to the length of the first element
	    # of the input line (which should be the command).
	    #
	    var check [range $check 0
	    	    	     [expr [length [index $file 0] char]-1] char]
    	    #
	    # Make sure the first element matches the command in all its
	    # particulars.
	    #
	    if {[string c $check [index $file 0]] == 0} {
    	    	#
		# Is a special command -- perform the appropriate action.
		#   quit    	just eval the command -- we'll exit stage left
		#   detach  	eval the command and return to top level
		#   ignore  	just return empty -- caller should expect
		#   	    	that as a signal to return empty.
    	    	#   Ignore  	ignore the patient, but return Ignore so
    	    	#   	    	that it can be added to the symdir cache
    	    	[case $check in
		 q* {eval [concat quit [range $file 1 end]]}
		 d* {
		    if {$maydetach} {
    	    	    	eval [concat detach [range $file 1 end]]
			return {}
		    } else {
		    	echo Detaching not allowed.
			continue
	    	    }
    	    	 }
		 i* {
		    if {$mayignore} {
		    	return {}
		    } else {
		    	echo Ignoring this patient is not allowed.
			continue
		    }
    	    	}
		I* {
		    if {$mayignore} {
		    	return Ignore
		    } else {
		    	echo Ignoring this patient is not allowed.
			continue
		    }
		 }]
    	    }
	}	 
	#
	# Check for the existence of the file -- the caller will have to
	# figure out about serial numbers and whatnot.
	#
    	var rfile [file-mangle-for-dos $file]
    	if {[string match $rfile /*] || [string match $rfile ${file-abspat}]} {
	    if {[file readable $rfile]} {
	    	return $rfile
	    }
    	}
	var rfile [file-mangle-for-dos ${file-init-dir}/${file}]
	if {[file readable ${rfile}]} {
	    #
	    # Given relative to initial directory
	    #
	    return ${rfile}
	}
	echo $file not readable. Try again.
    }
}]

##############################################################################
#				file-locate-geode
##############################################################################
#
# SYNOPSIS:	Perform a quick lookup to locate a geode given its name and
#   	    	geodeFileType. This one uses the global variable
#		file-geode-list.
# PASS:		geode	= 2-list of the form {geodeType name.ext}
# CALLED BY:	File_FindGeode
# RETURN:	Path of possible match if known.
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/14/91		Initial Revision
#
##############################################################################
[defsubr file-locate-geode {geode}
{
    if {[catch {file-locate-geode-common [index $geode 0] [index $geode 1] 0} result]} {
    	echo file-locate-geode: error: $result
	return
    } else {
    	return $result
    }
}]

[defsubr file-locate-ecgeode {geode}
{
    var type [index $geode 0] name [index $geode 1]
    
    var dot [string first . $name]
    var pat [range $name 0 [expr $dot-1] chars].[range $name [expr $dot+2] end char]*
    if {[catch {file-locate-geode-common $type $pat 1} result]} {
    	echo file-locate-ecgeode: error: $result
	return
    } else {
    	return $result
    }
}]

[defsubr file-locate-geode-common {type pattern index}
{
    global file-geode-list-$type file-devel-dir file-default-dir file-os
    
    var result {}
    
    foreach i [var file-geode-list-$type] {
    	if {[string match [index $i 0] $pattern]} {
	    var files [range $i 1 end]
	    #
	    # If nothing for the index (currently ec or non-ec) in the list,
	    # use the previous index (i.e. use the non-ec filename if there's 
	    # no ec version)
	    #
	    for {} {[null [index $files $index]]} {} {
		var index [expr $index-1]
	    }
	    #
	    # Pluck out the proper file, based on the index we were given.
	    #
	    var file [index $files $index]

	    #
	    # If file has more than one element, the first one is for UNIX and
	    # the second is for DOS
	    #
	    if {[length $file] > 1} {
		[case ${file-os} in
		 unix {
		    var file [index $file 0]
		 }
		 dos {
		    var file [index $file 1]
		 }
		 win32 {
		    var file [index $file 1]
		 }
		]
	    }
	    #
	    # If there's a development directory, tell caller to check the file
	    # there first.
	    #
    	    if {![null ${file-devel-dir}]} {
		if {![null [info command file-build-devel-path]]} {
		    #
		    # Use user-defined procedure to create development version
		    # path
		    #
		    var result [concat $result
				[file-build-devel-path $file]]
		} else {
		    var result [concat $result
				[file-mangle-for-dos ${file-devel-dir}/$file]]
		}
    	    }
	    var result [concat $result
		    	[file-mangle-for-dos ${file-default-dir}/$file]]
    	}
    }
    return $result
}]

#
# The lists for the different geodes, themselves.
#
# There exists one global list for each geode type (1-5, currently). Each
# element of the list is structured like:
#   {<permname> <non-ec-file> [<ec-file>]}
#
# each of <non-ec-file> and <ec-file> may be either a single path, or
# a list of two paths, where the first is as it appears on UNIX, and the second
# is as it appears on DOS (where Novell transmutes duplicate 8.3 names into
# a 7+digit.3 name). If no <ec-file> is given, <non-ec-file> will be used
# instead.
#

#############################################################################
#
#			     APPLICATIONS
#
# YO - don't forget to add geodes to this list in alphabetical order
#
defvar file-geode-list-1 {
    {addrbk.app
	Appl/Palm/AddrBook/addrbk.geo
	Appl/Palm/AddrBook/addrbkec.geo}
    {addrBook.app
	../Palm/Installed/Appl/AddrBook/addrbook.geo
	{../Palm/Installed/Appl/AddrBook/addrbookec.geo
	 ../Palm/Installed/Appl/AddrBook/addrboo0.geo}}
    {alarm.app
	Appl/Palm/Alarm/alarm.geo
	Appl/Palm/Alarm/alarmec.geo}
    {amateur.app
	Appl/Games/Amateur/amateur.geo
	Appl/Games/Amateur/amateurec.geo}
    {apptbk.app
	Appl/Jedi/ApptBk/apptbk.geo
	Appl/Jedi/ApptBk/apptbkec.geo}
    {autologi.app
	Appl/Iclas/Autologin/autolog.geo
	{Appl/Iclas/Autologin/autologec.geo
	 Appl/Iclas/Autologin/autologe.geo}}
    {backrst.app
	Appl/FApps/SApps/Backrest/backrest.geo
	Appl/FApps/SApps/Backrest/backrestec.geo}
    {bigcalc.app
	Appl/BigCalc/bigcalc.geo
	Appl/BigCalc/bigcalcec.geo}
    {bjack.app
	Appl/Games/BJack/bjack.geo
	Appl/Games/BJack/bjackec.geo}
    {blank.lib
	Appl/Saver/Blank/blank.geo
	Appl/Saver/Blank/blankec.geo}
    {bmanager.app
	Appl/FileMgrs/BManager/bmanager.geo
	Appl/FileMgrs/BManager/bmanagerec.geo}
    {bobbin.lib
	Appl/Saver/Bobbin/bobbin.geo
	Appl/Saver/Bobbin/bobbinec.geo}
    {bookmark.app
	Appl/Iclas/Bookmark/bookmrk.geo
	{Appl/Iclas/Bookmark/bookmrkec.geo
	 Appl/Iclas/Bookmark/bookmrke.geo}}
    {bstartup.app
	Appl/Startup/BStartup/bstartup.geo
	Appl/Startup/BStartup/bstartupec.geo}
    {calx.app
	Appl/FApps/SApps/CalX/calx.geo
	Appl/FApps/SApps/CalX/calxec.geo}
    {changepw.app
	Appl/Iclas/ChangePW/changepw.geo
	{Appl/Iclas/ChangePW/changepwec.geo
	 Appl/Iclas/ChangePW/changep0.geo}}
    {charmap.uti
	Appl/Util/CharMap/charmap.geo
	Appl/Util/CharMap/charmapec.geo}
    {circles.lib
	Appl/Saver/Circles/circles.geo
	Appl/Saver/Circles/circlesec.geo}
    {clrfax.geo
	Appl/FApps/ClrFax/clrfax.geo
	Appl/FApps/ClrFax/clrfaxec.geo}
    {command.app
	Appl/Tools/Command/command.geo
	Appl/Tools/Command/commandec.geo}
    {concen.app
	Appl/Games/Concen/concen.geo
	Appl/Games/Concen/concenec.geo}
    {consum.app
	../Palm/Installed/Appl/Consum/consum.geo
	../Palm/Installed/Appl/Consum/consumec.geo}
    {contact.app
	Appl/Responder/Contact/contact.geo
	Appl/Responder/Contact/contactec.geo}
    {csplist.app
	Appl/Iclas/CSPList/csplist.geo
	Appl/Iclas/CSPList/csplistec.geo}
    {cword.app
	Appl/Games/Cword/cword.geo
	Appl/Games/Cword/cwordec.geo}
    {date.app
	Appl/Palm/Date/date.geo
	Appl/Palm/Date/dateec.geo}
    {datebook.app
	../Palm/Installed/Appl/DateBook/datebook.geo
	{../Palm/Installed/Appl/DateBook/datebookec.geo
	 ../Palm/Installed/Appl/DateBook/dateboo0.geo}}
    {debug.app
	Appl/Tools/Debug/debug.geo
	Appl/Tools/Debug/debugec.geo}
    {dict.app
	Appl/Palm/Dict/dict.geo
	Appl/Palm/Dict/dictec.geo}
    {dm.app
	Appl/Jedi/DM/dm.geo
	Appl/Jedi/DM/dmec.geo}
    {dosexec.app
    	Appl/Test/DosExec/dosexec.geo
	Appl/Test/DosExec/dosexecec.geo}
    {draw.app
	Appl/GeoDraw/draw.geo
	Appl/GeoDraw/drawec.geo}
    {dribble.lib
	Appl/Saver/Dribble/dribble.geo
	Appl/Saver/Dribble/dribbleec.geo}
    {dust.lib
	Appl/Saver/Dust/dust.geo
	Appl/Saver/Dust/dustec.geo}
    {eprefmgr.app
	Appl/Preferences/EPrefMgr/eprefmgr.geo
	Appl/Preferences/EPrefMgr/eprefmgrec.geo}
    {etw.app
	Appl/ETW/etw.geo
	Appl/ETW/etwec.geo}
    {expo.app
	Appl/Email/Expo/expo.geo
	Appl/Email/Expo/expoec.geo}
    {extras.app
	Appl/FApps/Extras/extras.geo
	Appl/FApps/Extras/extrasec.geo}
    {fades.lib
	Appl/Saver/Fades/fades.geo
	Appl/Saver/Fades/fadesec.geo}
    {faxinstl.app
    	Appl/Fax/Install/install.geo
    	Appl/Fax/Install/installec.geo}
    {faxmon.util
    	Appl/Tools/FaxMon/faxmon.geo
	Appl/Tools/FaxMon/faxmonec.geo}
    {faxrec.app
    	Appl/Fax/Faxview/faxreceive.geo
    	Appl/Fax/Faxview/faxreceiveec.geo}
    {faxspool.app
    	Appl/Fax/Spool/faxspool.geo
    	Appl/Fax/Spool/faxspoolec.geo}
    {faxview.app
    	Appl/Fax/Faxview/faxview.geo
    	Appl/Fax/Faxview/faxviewec.geo}
    {fcalc.app
	Appl/Palm/FCalc/fcalc.geo
	Appl/Palm/FCalc/fcalcec.geo}
    {filebox.app
	Appl/TestUI/FileBox/filebox.geo}
    {fileprnt.util
	Appl/Tools/FilePrint/fileprint.geo}
    {fileremo.app
	Appl/Iclas/FileRemove/flremo.geo
	Appl/Iclas/FileRemove/flremoec.geo}
    {finance.app
	Appl/Jedi/Finance/finance.geo
	Appl/Jedi/Finance/financeec.geo}
    {finstall.app
	Appl/Tools/FInstall/finstall.geo
	Appl/Tools/FInstall/finstallec.geo}
    {gandalf.app
	Appl/Legos/Gandalf/gandalf.geo
	{Appl/Legos/Gandalf/gandalfec.geo
	Appl/Legos/Gandalf/gandalfe.geo}}
    {gentestc.app
	Appl/CTest/GenTest/gentest.geo}
    {geocalc.app
	Appl/GeoCalc/geocalc.geo
	Appl/GeoCalc/geocalcec.geo}
    {geocalc2.app
	Appl/GeoCalc2/geocalc2.geo
	Appl/GeoCalc2/geocalc2ec.geo}
    {geodex.app
	Appl/GeoDex/geodex.geo
	Appl/GeoDex/geodexec.geo}
    {geofile.app
	Appl/GeoFile/geofile.geo
	Appl/GeoFile/geofileec.geo}
    {geoplann.app
	Appl/Calendar/geoplan.geo
	Appl/Calendar/geoplanec.geo}
    {gsprint.app
    	Appl/Tools/GSPrint/gsprint.geo
	Appl/Tools/GSPrint/gsprintec.geo}
    {gtelnet.app
	Appl/Socket/GTelnet/gtelnet.geo
	Appl/Socket/GTelnet/gtelnetec.geo}
    {gwpoker.app
	Appl/Games/GWPoker/gwpoker.geo
	Appl/Games/GWPoker/gwpokerec.geo}
    {hearts.app
	Appl/Games/Hearts/hearts.geo
	Appl/Games/Hearts/heartsec.geo}
    {hibtest.app
	Appl/Test/HardIconBar/hardiconbarec.geo}
    {hmanager.app
	Appl/FileMgrs/HManager/hmanager.geo}
    {homescre.app
	Appl/Jedi/HomeScreen/homescreen.geo
	Appl/Jedi/HomeScreen/homescreenec.geo}
    {homescree.app
	Appl/Jedi/HomeScreen/homescreen.geo
	Appl/Jedi/HomeScreen/homescreenec.geo}
    {hpcalc.app
	Appl/Jedi/HPCalc/hpcalc.geo
	Appl/Jedi/HPCalc/hpcalcec.geo}
    {ihelp.app
	Appl/Iclas/Help/help.geo}
    {indicato.app
	Appl/FApps/OEM/indicato/indicato.geo
	Appl/FApps/OEM/indicato/indicate.geo}
    {ini.app
	Appl/Tools/Ini/ini.geo
	Appl/Tools/Ini/iniec.geo}
    {istartup.app
	Appl/Startup/IStartup/istartup.geo
	{Appl/Startup/IStartup/istartupec.geo
	 Appl/Startup/IStartup/istartu0.geo}}
    {japp.app
	Appl/Jedi/JApp/japp.geo
	Appl/Jedi/JApp/jappec.geo}
    {jdemo.app
	Appl/Jedi/JDemo/jdemo.geo
	Appl/Jedi/JDemo/jdemoec.geo}
    {jpref.app
	Appl/Jedi/JPref/jpref.geo
	Appl/Jedi/JPref/jprefec.geo}
    {jstartup.app
	Appl/Startup/JStartup/jstartup.geo
	Appl/Startup/JStartup/jstartupec.geo}
    {k2shell.app
	Appl/Iclas/K2Shell/k2shell.geo
	Appl/Iclas/K2Shell/k2shellec.geo}
    {langx.app
	Appl/Palm/LangX/langx.geo
	Appl/Palm/LangX/langxec.geo}
    {letter.lib
	Appl/Saver/Letter/letter.geo
	Appl/Saver/Letter/letterec.geo}
    {linktest.app
	Appl/Test/Linktest/linktest.geo
	{Appl/Test/Linktest/linktest.geo
	 Appl/Test/Linktest/linktes0.geo}}
    {login.app
	Appl/Iclas/Login/login.geo
	Appl/Iclas/Login/loginec.geo}
    {lol.hack
	Appl/LOL/lol.geo}
    {lview.app
	Appl/Legos/LView/lview.geo
	Appl/Legos/LView/lviewec.geo}
    {makeDisk.util
	Appl/Tools/MakeDisk/makedisk.geo
	{Appl/Tools/MakeDisk/makediskec.geo
	 Appl/Tools/MakeDisk/makedis0.geo}}
    {manager.app
	Appl/FileMgrs/GeoManager/manager.geo
	Appl/FileMgrs/GeoManager/managerec.geo}
    {melt.lib
	Appl/Saver/Melt/melt.geo
	Appl/Saver/Melt/meltec.geo}
    {myopt.app
	Appl/Preferences/Myopt/myopt.geo
	Appl/Preferences/Myopt/myoptec.geo}
    {netmsg.app
	Appl/Net/Netmsg/netmsg.geo
	Appl/Net/Netmsg/netmsgec.geo}
    {nikemenu.app
	Appl/Nike/NikeMenu/nikemenu.geo
	Appl/Nike/NikeMenu/nikemenuec.geo}
    {note.app
	Appl/Palm/Note/note.geo
	Appl/Palm/Note/noteec.geo}
    {notebk.app
	Appl/FApps/Notebook/nbook.geo
	Appl/FApps/Notebook/nbookec.geo}
    {notepad.app
	Appl/NotePad/notepad.geo}
    {ntaker.app
	Appl/NTaker/ntaker.geo
	Appl/NTaker/ntakerec.geo}
    {patch.app
	Appl/Test/Patch/patch.geo
	Appl/Test/Patch/patchec.geo}
    {phone.app
	Appl/Jedi/Phone/phone.geo
	Appl/Jedi/Phone/phonec.geo}
    {pieces.lib
	Appl/Saver/Pieces/pieces.geo
	Appl/Saver/Pieces/piecesec.geo}
    {pitest.app
	Appl/Test/PenInputTest/peninputtest.geo
	Appl/Test/PenInputTest/peninputtestec.geo}
    {prefmgr.app
	Appl/Preferences/PrefMgr/prefmgr.geo
	Appl/Preferences/PrefMgr/prefmgrec.geo}
    {qix.lib
	Appl/Saver/Qix/qix.geo
	Appl/Saver/Qix/qixec.geo}
    {reddex.app
	Appl/RedDex/geodex.geo
	Appl/RedDex/geodexec.geo}
    {reports.app
	Appl/Iclas/Reports/report.geo
	Appl/Iclas/Reports/reportec.geo}
    {resedit.app
	Appl/Tools/Localize/localize.geo
	Appl/Tools/Localize/localizeec.geo}
    {sand.lib
	Appl/Saver/Sand/sand.geo
	Appl/Saver/Sand/sandec.geo}
    {scrapbk.app
	Appl/ScrapBk/scrapbk.geo
	Appl/ScrapBk/scrapbkec.geo}
    {scrndmp.app
	Appl/Jedi/ScreenDump/screendump.geo
	Appl/Jedi/ScreenDump/screendumpec.geo}
    {services.app
	Appl/FApps/Services/services.geo
	Appl/FApps/Services/servicesec.geo}
    {setup.app
	Appl/Preferences/Setup/setup.geo
	Appl/Preferences/Setup/setupec.geo}
    {slurker.app
    	Appl/SLurker/slurker.geo
	Appl/SLurker/slurkerec.geo}
    {sms.app
	Appl/Responder/SMS/sms.geo
	Appl/Responder/SMS/smsec.geo}
    {solitair.app
	Appl/Games/Solitaire/soli.geo
	Appl/Games/Solitaire/soliec.geo}
    {stars.lib
	Appl/Saver/Stars/stars.geo
	Appl/Saver/Stars/starsec.geo}
    {swarm.lib
	Appl/Saver/Swarm/swarm.geo
	Appl/Saver/Swarm/swarmec.geo}
    {swdemo.app
	Appl/SWDemo/swdemo.geo}
    {sys.app
	Appl/FApps/System/system.geo
	Appl/FApps/System/systemec.geo}
    {tedit.app
	Appl/TEdit/tedit.geo
	Appl/TEdit/teditec.geo}
    {textui.app
	Appl/Test/TextUI/textuiec.geo}
    {tickerta.lib
	Appl/Saver/Tickertape/tickertape.geo
	{Appl/Saver/Tickertape/tickertapeec.geo
	 Appl/Saver/Tickertape/tickert0.geo}}
    {tiles.lib
	Appl/Saver/Tiles/tiles.geo
	Appl/Saver/Tiles/tilesec.geo}
    {trans.app
	Appl/Jedi/Transfer/trans.geo
	Appl/Jedi/Transfer/transec.geo}
    {transfr.app
	Appl/FApps/SApps/Transfer/transfr.geo
	Appl/FApps/SApps/Transfer/transfrec.geo}
    {useheap.app
	Appl/Test/UseHeap/useheap.geo}
    {usinfo.app
	../Palm/Installed/Appl/USinfo/usinfo.geo
	../Palm/Installed/Appl/USinfo/usinfoec.geo}
    {wclock.app
	Appl/Palm/WorldClock/wclock.geo
	Appl/Palm/WorldClock/wclockec.geo}
    {welcome.app
	Appl/Startup/Welcome/welcome.geo
	Appl/Startup/Welcome/welcomeec.geo}
    {winfo.app
	../Palm/Installed/Appl/Winfo/winfo.geo
	../Palm/Installed/Appl/Winfo/winfoec.geo}
    {worldtime.app
	Appl/Jedi/WorldTime/worldtime.geo
	Appl/Jedi/WorldTime/worldtimeec.geo}
    {worms.lib
	Appl/Saver/Worms/worms.geo
	Appl/Saver/Worms/wormsec.geo}
    {write.app
	Appl/GeoWrite/write.geo
	Appl/GeoWrite/writeec.geo}
    {wshell.app
	Appl/FileMgrs/WShell/wshell.geo
	Appl/FileMgrs/WShell/wshellec.geo}
    {wshellba.app
	Appl/FileMgrs/WShellBA/wshellb.geo
	Appl/FileMgrs/WShellBA/wshellbec.geo}
    {zmanager.app
	Appl/FileMgrs/ZManager/zmanager.geo
	Appl/FileMgrs/ZManager/zmanagerec.geo}
    {zprefmgr.app
	Appl/Preferences/ZPrefMgr/zprefmgr.geo
	{Appl/Preferences/ZPrefMgr/zprefmgrec.geo
	 Appl/Preferences/ZPrefMgr/zprefmg0.geo}}
    {zsetup.app
	Appl/Preferences/ZSetup/zsetup.geo
	Appl/Preferences/ZSetup/zsetupec.geo}
}
#
# YO - don't forget to add geodes to this list in alphabetical order
#


#############################################################################
#
#			      LIBRARIES
#
#
# YO - don't forget to add geodes to this list in alphabetical order
#
defvar file-geode-list-2 {
    {accpnt.lib
	Library/AccPnt/accpnt.geo
	Library/AccPnt/accpntec.geo}
    {ansic.lib
	Library/AnsiC/ansic.geo
	Library/AnsiC/ansicec.geo}
    {ascii.lib
	Library/Translation/Text/Ascii/ascii.geo
	Library/Translation/Text/Ascii/asciiec.geo}
    {attels.lib
	Library/Email/ExpoAtt/attels.geo
	Library/Email/ExpoAtt/attelsec.geo}
    {bitmap.lib
	Library/Bitmap/bitmap.geo
	Library/Bitmap/bitmapec.geo}
    {blib.lib
	Library/Bullet/blib.geo
	Library/Bullet/blibec.geo}
    {book.lib
	Library/Palm/Book/book.geo
	Library/Palm/Book/bookec.geo}
    {borlandc.lib
	Library/Math/Compiler/BorlandC/borlandc.geo
	{Library/Math/Compiler/BorlandC/borlandcec.geo
	 Library/Math/Compiler/BorlandC/borland0.geo}}
    {bprefcn.lib
	Library/Pref/BulletCN/bprefcn.geo
	Library/Pref/BulletCN/bprefcnec.geo}
    {bprefdz.lib
	Library/Pref/BulletDZ/bprefdz.geo
	Library/Pref/BulletDZ/bprefdzec.geo}
    {bprefhi.lib
	Library/Pref/BulletHI/bprefhi.geo
	Library/Pref/BulletHI/bprefhiec.geo}
    {bprefhw.lib
	Library/Pref/BulletHW/bprefhw.geo
        Library/Pref/BulletHW/bprefhwec.geo}
    {bpreflm.lib
	Library/Pref/BulletLM/bpreflm.geo
	Library/Pref/BulletLM/bpreflmec.geo}
    {bprefmm.lib
	Library/Pref/BulletMM/bprefmm.geo
	Library/Pref/BulletMM/bprefmmec.geo}
    {bprefpm.lib
	Library/Pref/BulletPM/bprefpm.geo
        Library/Pref/BulletPM/bprefpmec.geo}
    {bprefpt.lib
	Library/Pref/BulletPT/bprefpt.geo
	Library/Pref/BulletPT/bprefptec.geo}
    {bprefpw.lib
	Library/Pref/BulletPW/bprefpw.geo
        Library/Pref/BulletPW/bprefpwec.geo}
    {bulldemo.lib
	Library/BullDemo/bulldemo.geo
	Library/BullDemo/bulldemoec.geo}
    {cardid.lib
	Library/CardID/cardid.geo
	Library/CardID/cardidec.geo}
    {cell.lib
	Library/Cell/cell.geo
	Library/Cell/cellec.geo}
    {chart.lib
	Library/Chart/chart.geo
	Library/Chart/chartec.geo}
    {color.lib
	Library/Color/color.geo
	Library/Color/colorec.geo}
    {config.lib
        Library/Config/config.geo
        Library/Config/configec.geo}
    {contact.lib
        Library/Contact/contact.geo
        Library/Contact/contactec.geo}
    {contdb.lib
	Library/Foam/Contdb/contdb.geo
	Library/Foam/Contdb/contdbec.geo}
    {contlog.lib
	Library/Foam/ContLog/contlog.geo
	Library/Foam/ContLog/contlogec.geo}
    {convert.lib
	Library/Convert/convert.geo
	Library/Convert/convertec.geo}
    {coverpg.lib
    	Library/Fax/CoverPg/coverpg.geo
    	Library/Fax/CoverPg/coverpgec.geo}
    {crunch.fmtl
	Library/FMTools/Crunch/crunch.geo
	Library/FMTools/Crunch/crunchec.geo}
    {csv.lib
	Library/Translation/Database/CSV/csv.geo
	Library/Translation/Database/CSV/csvec.geo}
    {cvttool.fmtl
	Library/FMTools/CvtTool/cvttool.geo
	Library/FMTools/CvtTool/cvttoolec.geo}
    {crunch.fmtl
	Library/FMTools/Crunch/crunch.geo
	Library/FMTools/Crunch/crunchec.geo}
    {linktool.fmtl
	Library/FMTools/Linktool/linktool.geo
	Library/FMTools/Linktool/linktoolec.geo}
    {datepick.lib
	Library/DatePick/datepick.geo
	{Library/DatePick/datepickec.geo
	 Library/DatePick/datepic0.geo}}
    {db.lib
	Library/Jedi/DB/db.geo
	Library/Jedi/DB/dbec.geo}
    {dbase3.lib
	Library/Translation/Database/dbase3/dbase3.geo
	Library/Translation/Database/dbase3/dbase3ec.geo}
    {dib.lib
	Library/Translation/Graphics/Bitmap/Dib/dib.geo
	Library/Translation/Graphics/Bitmap/Dib/dibec.geo}
    {dwrite.lib
	Library/Translation/Text/DisplayWrite/dwrite.geo
	Library/Translation/Text/DisplayWrite/dwriteec.geo}
    {eps.lib
	Library/Translation/Graphics/Vector/EPS/eps.geo
	Library/Translation/Graphics/Vector/EPS/epsec.geo}
    {faxctrl.lib
    	Library/Fax/Ctrl/faxctrl.geo
    	Library/Fax/Ctrl/faxctrlec.geo}
    {faxfile.lib
    	Library/Fax/File/faxfile.geo
    	Library/Fax/File/faxfileec.geo}
    {ffile.lib
	Library/FlatFile/ffile.geo
	Library/FlatFile/ffileec.geo}
    {float.lib
	Library/Float/float.geo
	Library/Float/floatec.geo}
    {foam.lib
	Library/Foam/Foam/foam.geo
	Library/Foam/Foam/foamec.geo}
    {foamdb.lib
	Library/Foam/DB/foamdb.geo
	Library/Foam/Foam/foamdbec.geo}
    {gadgets.lib
	Library/Extensions/Gadgets/gadgets.geo
	Library/Extensions/Gadgets/gadgetsec.geo}
    {geopm.spui
	Library/SpecUI/GeoPM/geopm.geo
	Library/SpecUI/GeoPM/geopmec.geo}
    {geos.kern
	Library/Kernel/geos.geo
	Library/Kernel/geosec.geo}
    {grobj.lib
	Library/GrObj/grobj.geo
	Library/GrObj/grobjec.geo}
    {hpmlib.lib
	Library/Jedi/HPMLib/hpmlib.geo
	Library/Jedi/HPMLib/hpmlibec.geo}
    {hprefcn.lib
	Library/Pref/HPrefCN/hprefcn.geo
	Library/Pref/HPrefCN/hprefcnec.geo}
    {hwrrom.lib
	../Palm/Installed/Library/HWRRom/hwrrom.geo}
    {im.lib
	Library/IM/im.geo
	Library/IM/imec.geo}
    {impex.lib
	Library/Impex/impex.geo
	Library/Impex/impexec.geo}
    {int8087.lib
	Library/CoProcessor/Int8087/int8087.geo
	Library/CoProcessor/Int8087/int8087ec.geo}
    {intx87.lib
	Library/CoProcessor/Intx87/intx87.geo
	Library/CoProcessor/Intx87/intx87ec.geo}
    {jedidemo.lib
	Library/Jedi/JediDemo/jedidemo.geo
	Library/Jedi/JediDemo/jedidemoec.geo}
    {jedit.lib
	Library/Jedi/JEdit/jedit.geo
	Library/Jedi/JEdit/jeditec.geo}
    {jerror.lib
	Library/Jedi/JError/jerror.geo    
	Library/Jedi/JError/jerrorec.geo}
    {jlib.lib
	Library/Jedi/JLib/jlib.geo
	Library/Jedi/JLib/jlibec.geo}
    {jmotif.spui
	Library/SpecUI/JMotif/jmotif.geo
	Library/SpecUI/JMotif/jmotifec.geo}
    {jotter.lib
	Library/Jedi/JediUI/jotter.geo
	Library/Jedi/JediUI/jotterec.geo}
    {jtable.lib
	Library/Jedi/JTable/jtable.geo
	Library/Jedi/JTable/jtableec.geo}
    {jutils.lib
	Library/Jedi/JUtils/jutils.geo
	Library/Jedi/JUtils/jutilsec.geo}
    {jwtime.lib
	Library/Jedi/JWTime/jwtime.geo
	Library/Jedi/JWTime/jwtimec.geo}
    {key.lib
	Library/HWR/Key/key.geo
	Library/HWR/Key/keyec.geo}
    {linktool.fmtl
    	Library/FMTools/Linktool/linktool.geo
    	Library/FMTools/Linktool/linktoolec.geo}
    {lot123.lib
	Library/Translation/Text/Lotus123/lot123.geo
	Library/Translation/Text/Lotus123/lot123ec.geo}
    {mailbox.lib
	Library/Mailbox/mailbox.geo
	Library/Mailbox/mailboxec.geo}
    {math.lib
	Library/Math/math.geo
	Library/Math/mathec.geo}
    {mmate.lib
	Library/Translation/Text/MultiMate/mmate.geo
	Library/Translation/Text/MultiMate/mmateec.geo}
    {motif.spui
	Library/SpecUI/Motif/motif.geo
	Library/SpecUI/Motif/motifec.geo}
    {mppc.lib
	Library/MPPC/mppc.geo
	Library/MPPC/mppcec.geo}
    {msmfile.lib
	Library/Translation/Text/MSMFile/msmfile.geo
	Library/Translation/Text/MSMFile/msmfileec.geo}
    {mtable.lib
	Library/Extensions/MTable/mtable.geo
	Library/Extensions/MTable/mtableec.geo}
    {net.lib
	Library/Net/net.geo
	Library/Net/netec.geo}
    {netutils.lib
	Library/NetUtils/netutils.geo
	Library/NetUtils/netutilsec.geo}
    {notes.lib
	Library/Jedi/Notes/notes.geo
	Library/Jedi/Notes/notesec.geo}
    {obex.lib
	Library/Obex/obex.geo
	Library/Obex/obexec.geo}
    {pabapi.lib
	Library/AddressBook/PalmAddrBookApi/pabapi.geo
	Library/AddressBook/PalmAddrBookApi/pabapiec.geo}
    {palm.lib
	{../Palm/Installed/Library/PalmHWR/palm.geo
    	 Library/PalmHWR/palm.geo}
	{../Palm/Installed/Library/PalmHWR/palmec.geo
    	 Library/PalmHWR/palmec.geo}}
    {palmp3.lib
	Library/HWR/Graffiti/palmp3.geo
	Library/HWR/Graffiti/palmp3ec.geo }
    {palmui.lib
	Library/Palm/PalmUI/palmui.geo
	Library/Palm/PalmUI/palmuiec.geo}
    {parse.lib
	Library/Parse/parse.geo
	Library/Parse/parseec.geo}
    {pccom.lib
	Library/PCCom/pccom.geo
	Library/PCCom/pccomec.geo}
    {pcmcia.lib
	Library/PCMCIA/pcmcia.geo
	Library/PCMCIA/pcmciaec.geo}
    {pcx.lib
	Library/Translation/Graphics/Bitmap/Pcx/pcx.geo
	Library/Translation/Graphics/Bitmap/Pcx/pcxec.geo}
    {pdafs.lib
	Library/Email/PdaFileSys/pdafs.geo
	Library/Email/PdaFileSys/pdafsec.geo}
    {pen.lib
	Library/Pen/pen.geo
	Library/Pen/penec.geo}
    {pim.lib
	Library/Palm/PIM/pim.geo
	Library/Palm/PIM/pimec.geo}
    {pm.spui
	Library/SpecUI/PM/pm.geo
	Library/SpecUI/PM/pmec.geo}
    {pmba.spui
	Library/SpecUI/PMBA/pmba.geo
	Library/SpecUI/PMBA/pmbaec.geo}
    {prefbg.lib
	Library/Pref/Prefbg/prefbg.geo
	Library/Pref/Prefbg/prefbgec.geo}
    {prefcomp.lib
	Library/Pref/Prefcomp/prefcomp.geo
	{Library/Pref/Prefcomp/prefcompec.geo
	 Library/Pref/Prefcomp/prefcom0.geo}}
    {preffax.lib
    	Library/Pref/Preffax/preffax.geo
    	Library/Pref/Preffax/preffaxec.geo}
    {preffont.lib
	Library/Pref/Preffont/preffont.geo
	{Library/Pref/Preffont/preffontec.geo
	 Library/Pref/Preffont/preffon0.geo}}
    {prefintl.lib
	Library/Pref/Prefintl/prefintl.geo
	{Library/Pref/Prefintl/prefintlec.geo
	 Library/Pref/Prefintl/prefint0.geo}}
    {prefkbd.lib
	Library/Pref/Prefkbd/prefkbd.geo
	Library/Pref/Prefkbd/prefkbdec.geo}
    {preflf.lib
	Library/Pref/Preflf/preflf.geo
	Library/Pref/Preflf/preflfec.geo}
    {preflfi.lib
	Library/Pref/Preflfi/preflfi.geo
	Library/Pref/Preflfi/preflfiec.geo}
    {preflink.lib
	Library/Pref/Preflink/preflink.geo
	{Library/Pref/Preflink/preflinkec.geo
	 Library/Pref/Preflink/preflin0.geo}}
    {preflo.lib
	Library/Pref/Preflo/preflo.geo
	Library/Pref/Preflo/prefloec.geo}
    {prefmous.lib
	Library/Pref/Prefmous/prefmous.geo
	Library/Pref/Prefmous/prefmousec.geo}
    {prefos.lib
	Library/Pref/Prefos/prefos.geo
	Library/Pref/Prefos/prefosec.geo}
    {prefperm.lib
	Library/Pref/Prefperm/prefperm.geo
	{Library/Pref/Prefperm/prefpermec.geo
	 Library/Pref/Prefperm/prefper0.geo}}
    {prefsnd.lib
	Library/Pref/Prefsnd/prefsnd.geo
	Library/Pref/Prefsnd/prefsndec.geo}
    {prefsock.lib
	Library/Pref/Prefsock/prefsock.geo
	Library/Pref/Prefsock/prefsockec.geo}
    {preftd.lib
	Library/Pref/Preftd/preftd.geo
	Library/Pref/Preftd/preftdec.geo}
    {prefts.lib
	Library/Pref/Prefts/prefts.geo
	Library/Pref/Prefts/preftsec.geo}
    {prefui.lib
	Library/Pref/Prefui/prefui.geo
	Library/Pref/Prefui/prefuiec.geo}
    {prefvid.lib
	Library/Pref/Prefvid/prefvid.geo
	Library/Pref/Prefvid/prefvidec.geo}
    {ps.lib
	Library/Translation/Graphics/PS/ps.geo
	Library/Translation/Graphics/PS/psec.geo}
    {redmotif.spui
	Library/SpecUI/RedMotif/redmtf.geo
	Library/SpecUI/RedMotif/redmtfec.geo}
    {rtcm.lib
	Library/RTCM/rtcm.geo
	Library/RTCM/rtcmec.geo}
    {rtf.lib
	Library/Translation/Text/RTF/rtf.geo
	Library/Translation/Text/RTF/rtfec.geo}
    {rudy.spui
	Library/SpecUI/Rudy/rudy.geo
	Library/SpecUI/Rudy/rudyec.geo}
    {respdemo.lib
	Library/RespDemo/respdemo.geo
	Library/RespDemo/respdemo.geo}
    {respondr.lib
	Library/Respondr/respondr.geo
	Library/Respondr/respondrec.geo}
    {ruler.lib
	Library/Ruler/ruler.geo
	Library/Ruler/rulerec.geo}
    {saver.lib
    	Library/Saver/saver.geo
    	Library/Saver/saverec.geo}
    {security.lib
	Library/Foam/Security/security.geo
	Library/Foam/Security/securityec.geo}
    {searchsp.lib
	Library/SearchSp/searchsp.geo
	Library/SearchSp/searchspec.geo}
    {shell.lib
	Library/Shell/shell.geo
	Library/Shell/shellec.geo}
    {socket.lib
	Library/Socket/socket.geo
	Library/Socket/socketec.geo}
    {sound.lib
	Library/Sound/sound.geo
	Library/Sound/soundec.geo}
    {spell.lib
	Library/Spell/spell.geo
	Library/Spell/spellec.geo}
    {spline.lib
	Library/Spline/spline.geo
	Library/Spline/splineec.geo}
    {spool.lib
	Library/Spool/spool.geo
	Library/Spool/spoolec.geo}
    {ssheet.lib
	Library/Spreadsheet/ssheet.geo
	Library/Spreadsheet/ssheetec.geo}
    {ssmeta.lib
	Library/SSMeta/ssmeta.geo
	Library/SSMeta/ssmetaec.geo}
    {ssset.lib
	Library/Foam/OEM/ssset/ssset.geo
	Library/Foam/OEM/ssset/sssetec.geo}
    {streamc.app
	Library/StreamC/streamc.geo
	Library/StreamC/streamcec.geo}
    {styles.lib
	Library/Styles/styles.geo
	Library/Styles/stylesec.geo}
    {swap.lib
	Library/Swap/swap.geo
	Library/Swap/swapec.geo}
    {symfile.lib
    	Library/Symfile/symfile.geo
    	{Library/Symfile/symfileec.geo
    	Library/Symfile/symfilee.geo}}
    {table.lib
	Library/Extensions/Table/table.geo
	Library/Extensions/Table/tableec.geo}
    {telnet.lib
	Library/Telnet/telnet.geo
	Library/Telnet/telnetec.geo}
    {text.lib
	Library/Text/text.geo
	Library/Text/textec.geo}
    {ui.lib
	Library/User/ui.geo
	Library/User/uiec.geo}
    {viewer.lib
	Library/Foam/Viewer/viewer.geo
	Library/Foam/Viewer/viewerec.geo}
    {winword.lib
	Library/Translation/Text/WinWord/winword.geo
	Library/Translation/Text/WinWord/winwordec.geo}
    {wperf4.lib
	Library/Translation/Text/WordPerfect4X/wperf4.geo
	Library/Translation/Text/WordPerfect4X/wperf4ec.geo}
    {wperf5.lib
	Library/Translation/Text/WordPerfect5X/wperf5.geo
	Library/Translation/Text/WordPerfect5X/wperf5ec.geo}
    {xchars.lib
	Library/Text/Xchars/xchars.geo
	Library/Text/Xchars/xcharsec.geo}
    {zoomconn.lib
	Library/Pref/ZoomConn/zoomconn.geo
	{Library/Pref/ZoomConn/zoomconec.geo
	 Library/Pref/ZoomConn/zoomcon0.geo}}
    {zoomdgtz.lib
	Library/Pref/ZoomDgtz/zoomdgtz.geo
	{Library/Pref/ZoomDgtz/zoomdgtzec.geo
	 Library/Pref/ZoomDgtz/zoomdgt0.geo}}
    {zoomer.lib
	Library/Zoomer/zoomer.geo
	Library/Zoomer/zoomerec.geo}
    {zoomhw.lib
	Library/Pref/ZoomHW/zoomhw.geo
	Library/Pref/ZoomHW/zoomhwec.geo}
    {zoomintl.lib
	Library/Pref/ZoomIntl/zoomintl.geo
	{Library/Pref/ZoomIntl/zoomintlec.geo
	 Library/Pref/ZoomIntl/zoomint0.geo}}
    {zoomkbd.lib
	Library/Pref/ZoomKbd/zoomkbd.geo
	Library/Pref/ZoomKbd/zoomkbdec.geo}
    {zoomprnt.lib
	Library/Pref/ZoomPrnt/zoomprnt.geo
	{Library/Pref/ZoomPrnt/zoomprntec.geo
	 Library/Pref/ZoomPrnt/zoomprn0.geo}}
    {zoomtd.lib
	Library/Pref/ZoomTD/zoomtd.geo
	Library/Pref/ZoomTD/zoomtdec.geo}
    {zoomuser.lib
	Library/Pref/ZoomUser/zoomuser.geo
	{Library/Pref/ZoomUser/zoomuserec.geo
	 Library/Pref/ZoomUser/zoomuse0.geo}}
}
#
# YO - don't forget to add geodes to this list in alphabetical order
#



#############################################################################
#
#			    DEVICE DRIVERS
#
#
# YO - don't forget to add geodes to this list in alphabetical order
#
defvar file-geode-list-3 {
    {Comm.drv
	Driver/Net/Comm/comm.geo
	Driver/Net/Comm/commec.geo}
    {absgen.drvr
	Driver/Mouse/AbsGen/absgen.geo
	Driver/Mouse/AbsGen/absgenec.geo}
    {att6300.drvr
	Driver/Video/Dumb/ATT6300/att6300.geo
	Driver/Video/Dumb/ATT6300/att6300ec.geo}
    {bchip9.drvr
    	Driver/Printer/DotMatrix/Bchip9/bchip9.geo
    	Driver/Printer/DotMatrix/Bchip9/bchip9ec.geo}
    {bemm.drvr
	Driver/Swap/EMS/BullEMM/bemm.geo
	Driver/Swap/EMS/BullEMM/bemmec.geo}
    {bfs.ifsd
	Driver/IFS/GEOS/BullFS/bfs.geo
	Driver/IFS/GEOS/BullFS/bfsec.geo}
    {bitstrm.drvr
	Driver/Font/Bitstream/bitstrm.geo
	Driver/Font/Bitstream/bitstrmec.geo}
    {pzkanji.drvr
	Driver/Font/PzKanji/pzkanji.geo
	Driver/Font/PzKanji/pzkanjiec.geo}
    {bpen.drvr
    	Driver/Mouse/BulletPen/bpen.geo
	Driver/Mouse/BulletPen/bpenec.geo}
    {bpower.drvr
	Driver/Power/Bullet/bpower.geo
	Driver/Power/Bullet/bpowerec.geo}
    {canon48.drvr
    	{Driver/Printer/DotMatrix/Canon48/canon48.geo
	 Driver/Printer/DotMatri/Canon48/canon48.geo}
	{Driver/Printer/DotMatrix/Canon48/canon48ec.geo
	 Driver/Printer/DotMatri/Canon48/canon48e.geo}}
    {casiopen.drvr
	Driver/Mouse/CasioPen/casiopen.geo
	{Driver/Mouse/CasioPen/casiopenec.geo
	 Driver/Mouse/CasioPen/casiope0.geo}}
    {casiopwr.drvr
	Driver/Power/Casio/casiopwr.geo
	{Driver/Power/Casio/casiopwrec.geo
	 Driver/Power/Casio/casiopw0.geo}}
    {casiosnd.drvr
	Driver/Sound/Casio/casio.geo
	Driver/Sound/Casio/casioec.geo}
    {casiovid.drvr
	Driver/Video/Dumb/Casio/casio.geo
	Driver/Video/Dumb/Casio/casioec.geo}
    {ccom.drvr
        Driver/Printer/Fax/CCom/ccom.geo
        Driver/Printer/Fax/CCom/ccomec.geo}
    {ccomrem.drvr
        Driver/Printer/Fax/CComRem/ccomrem.geo
        Driver/Printer/Fax/CComRem/ccomremec.geo}
    {cdrom.ifsd
	Driver/IFS/DOS/CDROM/cdrom.geo
	Driver/IFS/DOS/CDROM/cdromec.geo}
    {cga.drvr
	Driver/Video/Dumb/CGA/cga.geo
	Driver/Video/Dumb/CGA/cgaec.geo}
    {cidfs.drvr
	Driver/PCMCIA/CID/CIDFS/cidfs.geo
	Driver/PCMCIA/CID/CIDFS/cidfsec.geo}
    {cidser.drvr
	Driver/PCMCIA/CID/CIDSer/cidser.geo
	Driver/PCMCIA/CID/CIDSer/cidserec.geo}
    {citoh9.drvr
    	Driver/Printer/DotMatrix/Citoh9/citoh9.geo
    	Driver/Printer/DotMatrix/Citoh9/citoh9ec.geo}
    {class2.drvr
    	Driver/Fax/Output/Class2/class2.geo
    	Driver/Fax/Output/Class2/class2ec.geo}
    {diconix9.drvr
    	Driver/Printer/DotMatrix/Diconix9/diconix9.geo
    	Driver/Printer/DotMatrix/Diconix9/diconix9ec.geo}
    {disk.drvr
	Driver/Swap/Disk/disk.geo
	Driver/Swap/Disk/diskec.geo}
    {dri.ifsd
	Driver/IFS/DOS/DRI/dri.geo
	Driver/IFS/DOS/DRI/driec.geo}
    {dscga.drvr
	Driver/Video/Dumb/DSCGA/dscga.geo
	Driver/Video/Dumb/DSCGA/dscgaec.geo}
    {ega.drvr
	Driver/Video/VGAlike/EGA/ega.geo
	Driver/Video/VGAlike/EGA/egaec.geo}
    {emm.drvr
	Driver/Swap/EMS/EMM/emm.geo
	Driver/Swap/EMS/EMM/emmec.geo}
    {eplx9.drvr
    	Driver/Printer/DotMatrix/Eplx9/eplx9.geo
    	Driver/Printer/DotMatrix/Eplx9/eplx9ec.geo}
    {epmx9.drvr
    	Driver/Printer/DotMatrix/Epmx9/epmx9.geo
    	Driver/Printer/DotMatrix/Epmx9/epmx9ec.geo}
    {eprx9.drvr
    	Driver/Printer/DotMatrix/Eprx9/eprx9.geo
    	Driver/Printer/DotMatrix/Eprx9/eprx9ec.geo}
    {epshi24.drvr
	Driver/Printer/DotMatrix/Epshi24/epshi24.geo
	Driver/Printer/DotMatrix/Epshi24/epshi24ec.geo}
    {epson24.drvr
	Driver/Printer/DotMatrix/Epson24/epson24.geo
	Driver/Printer/DotMatrix/Epson24/epson24ec.geo}
    {epson48.drvr
	Driver/Printer/DotMatrix/Epson48/epson48.geo
	Driver/Printer/DotMatrix/Epson48/epson48ec.geo}
    {epson9.drvr
	Driver/Printer/DotMatrix/Epson9/epson9.geo
	Driver/Printer/DotMatrix/Epson9/epson9ec.geo}
    {extMem.drvr
	Driver/Swap/ExtMem/extmem.geo
	Driver/Swap/ExtMem/extmemec.geo}
    {fatfs.drvr
	Driver/PCMCIA/FATFS/fatfs.geo
	Driver/PCMCIA/FATFS/fatfsec.geo}
    {fep.drvr
    	Driver/Fep/PigLatin/fep.geo
    	Driver/Fep/PigLatin/fepec.geo}
    {faxsendt.drvr
    	Driver/Mailbox/Transport/FaxsendTD/faxsendtd.geo
    	Driver/Mailbox/Transport/FaxsendTD/faxsendtdec.geo}
    {filestr.drvr
    	Driver/Stream/Filestr/filestr.geo
	Driver/Stream/Filestr/filestrec.geo}
    {genmouse.drvr
	Driver/Mouse/GenMouse/genmouse.geo
	{Driver/Mouse/GenMouse/genmouseec.geo
	 Driver/Mouse/GenMouse/genmous0.geo}}
    {geojfep.drvr
    	Driver/Fep/Pizza/geojfep.geo
    	Driver/Fep/Pizza/geojfepec.geo}
    {geosts.drvr
	Driver/Task/GeosTS/geosts.geo
	Driver/Task/GeosTS/geostsec.geo}
    {group3.drvr
    	Driver/Printer/Fax/Group3/group3.geo
    	Driver/Printer/Fax/Group3/group3ec.geo}
    {geojfep.drvr
    	Driver/Fep/Pizza/geojfep.geo
    	Driver/Fep/Pizza/geojfepec.geo}
    {grpr9.drvr
    	Driver/Printer/DotMatrix/Grpr9/grpr9.geo
    	Driver/Printer/DotMatrix/Grpr9/grpr9ec.geo}
    {hgc.drvr
	Driver/Video/Dumb/HGC/hgc.geo
	Driver/Video/Dumb/HGC/hgcec.geo}
    {jkbd.drvr
	Driver/Keyboard/Jedi/jkbd.geo
	Driver/Keyboard/Jedi/jkbdec.geo}
    {jpen.drvr
	Driver/Mouse/JediPen/jpen.geo
	Driver/Mouse/JediPen/jpenec.geo}
    {jpwr.drvr
	Driver/Power/Jedi/jpwr.geo
	Driver/Power/Jedi/jpwrec.geo}
    {jvideo.drvr
	Driver/Video/Dumb/Jedi/jvideo.geo
	Driver/Video/Dumb/Jedi/jvideoec.geo}
    {kbd.drvr
	Driver/Keyboard/kbd.geo
	Driver/Keyboard/kbdec.geo}
    {kbmouse.drvr
	Driver/Mouse/KBMouse/kbmouse.geo
	Driver/Mouse/KBMouse/kbmouseec.geo}
    {logiBus.drvr
	Driver/Mouse/LogiBus/logibus.geo
	{Driver/Mouse/LogiBus/logibusec.geo
	Driver/Mouse/LogiBus/logibuse.geo}}
    {logiSer.drvr
	Driver/Mouse/LogiSer/logiser.geo
	{Driver/Mouse/LogiSer/logiserec.geo
	Driver/Mouse/LogiSer/logisere.geo}}
    {mSys.drvr
	Driver/Mouse/MSys/msys.geo
	Driver/Mouse/MSys/msysec.geo}
    {mcga.drvr
	Driver/Video/Dumb/MCGA/mcga.geo
	Driver/Video/Dumb/MCGA/mcgaec.geo}
    {mega.drvr
	Driver/Video/VGAlike/MEGA/mega.geo
	Driver/Video/VGAlike/MEGA/megaec.geo}
    {megafile.ifsd
	Driver/IFS/GEOS/MegaFile/megafile.geo
	{Driver/IFS/GEOS/MegaFile/megafileec.geo
	 Driver/IFS/GEOS/MegaFile/megafil0.geo}}
    {ms3.ifsd
	Driver/IFS/DOS/MS3/ms3.geo
	Driver/IFS/DOS/MS3/ms3ec.geo}
    {ms4.ifsd
	Driver/IFS/DOS/MS4/ms4.geo
	Driver/IFS/DOS/MS4/ms4ec.geo}
    {msBus.drvr
	Driver/Mouse/MSBus/msbus.geo
	Driver/Mouse/MSBus/msbusec.geo}
    {msSer.drvr
	Driver/Mouse/MSSer/msser.geo
	Driver/Mouse/MSSer/msserec.geo}
    {msnet.ifsd
	Driver/IFS/DOS/MSNet/msnet.geo
	Driver/IFS/DOS/MSNet/msnetec.geo}
    {nec24.drvr
	Driver/Printer/DotMatrix/Nec24/nec24.geo
	Driver/Printer/DotMatrix/Nec24/nec24ec.geo}
    {netware.ifsd
	Driver/IFS/DOS/NetWare/netware.geo
	Driver/IFS/DOS/NetWare/netwareec.geo}
    {nimbus.drvr
	Driver/Font/Nimbus/nimbus.geo
	Driver/Font/Nimbus/nimbusec.geo}
    {nonts.drvr
	Driver/Task/NonTS/nonts.geo
	Driver/Task/NonTS/nontsec.geo}
    {nopower.drvr
	Driver/Power/NoPower/nopower.geo
	Driver/Power/NoPower/nopowerec.geo}
    {nppcm.drvr
	Driver/Power/NoPowerPCMCIA/nppcm.geo
	Driver/Power/NoPowerPCMCIA/nppcmec.geo}
    {nw.drvr
	Driver/Net/NW/nw.geo
	Driver/Net/NW/nwec.geo}
    {oki9.drvr
    	Driver/Printer/DotMatrix/Oki9/oki9.geo
    	Driver/Printer/DotMatrix/Oki9/oki9ec.geo}
    {os2.ifsd
	Driver/IFS/DOS/OS2/os2.geo
	Driver/IFS/DOS/OS2/os2ec.geo}
    {parallel.drvr
	Driver/Stream/Parallel/parallel.geo
	{Driver/Stream/Parallel/parallelec.geo
	 Driver/Stream/Parallel/paralle0.geo}}
    {pcl4.drvr
    	Driver/Printer/HP/Pcl4/pcl4.geo
	Driver/Printer/HP/Pcl4/pcl4ec.geo}
    {pgfs.drvr
    	Driver/IFS/GEOS/PGFS/pgfs.geo
    	Driver/IFS/GEOS/PGFS/pgfsec.geo}
    {ppds24.drvr
	Driver/Printer/DotMatrix/Ppds24/ppds24.geo
	Driver/Printer/DotMatrix/Ppds24/ppds24ec.geo}
    {ppp.drvr
	Driver/Socket/PPP/ppp.geo
	Driver/Socket/PPP/pppec.geo}
    {prop9.drvr
    	Driver/Printer/DotMatrix/Prop9/prop9.geo
    	Driver/Printer/DotMatrix/Prop9/prop9ec.geo}
    {propx24.drvr
    	Driver/Printer/DotMatrix/Propx24/propx24.geo
    	Driver/Printer/DotMatrix/Propx24/propx24ec.geo}
    {ps2.drvr
	Driver/Mouse/PS2/ps2.geo
	Driver/Mouse/PS2/ps2ec.geo}
    {pscript.drvr
	Driver/Printer/PScript/pscript.geo
	Driver/Printer/PScript/pscriptec.geo}
    {pserial.drvr
	Driver/PCMCIA/PSerial/Zoomer/pserial.geo
	Driver/PCMCIA/PSerial/Zoomer/pserialec.geo}
    {rdkbd.drvr
	Driver/Keyboard/Respdemo/rdkbd.geo
	Driver/Keyboard/Respdemo/rdkbdec.geo}
    {redfs.ifsd
	Driver/IFS/GEOS/RedFS/redfs.geo
	Driver/IFS/GEOS/RedFS/redfsec.geo}
    {redmouse.drvr
	Driver/Mouse/RedMouse/redmouse.geo
	Driver/Mouse/RedMouse/redmouseec.geo}
    {red64.drvr
    	Driver/Printer/DotMatrix/Red64/red64.geo
    	Driver/Printer/DotMatrix/Red64/red64ec.geo}
    {rfsd.ifsd
	Driver/IFS/RFSD/rfsd.geo
	Driver/IFS/RFSD/rfsdec.geo}
    {rspwr.drvr
        Driver/IFS/rspwr.geo
        Driver/IFS/rspwrec.geo}
    {serial.drvr
	Driver/Stream/Serial/serial.geo
	Driver/Stream/Serial/serialec.geo}
    {slip.drvr
    	Driver/Socket/SLIP/slip.geo
    	Driver/Socket/SLIP/slipec.geo}
    {sockrecv.drvr
	Driver/Mailbox/Transport/SockRecv/sockrecv.geo
	Driver/Mailbox/Transport/SockRecv/sockrecvec.geo}
    {standard.drvr
	Driver/Sound/Standard/standard.geo
	{Driver/Sound/Standard/standardec.geo
	 Driver/Sound/Standard/standar0.geo}}
    {star9.drvr
    	Driver/Printer/DotMatrix/Star9/star9.geo
    	Driver/Printer/DotMatrix/Star9/star9ec.geo}
    {stream.drvr
	Driver/Stream/stream.geo
	Driver/Stream/streamec.geo}
    {svga.drvr
	Driver/Video/VGAlike/SVGA/svga.geo
	Driver/Video/VGAlike/SVGA/svgaec.geo}
    {taskmax.drvr
	Driver/Task/TaskMax/taskmax.geo
	Driver/Task/TaskMax/taskmaxec.geo}
    {tcpip.drvr
    	Driver/Socket/TCPIP/tcpip.geo
    	Driver/Socket/TCPIP/tcpipec.geo}
    {tosh24.drvr
    	Driver/Printer/DotMatrix/Tosh24/tosh24.geo
    	Driver/Printer/DotMatrix/Tosh24/tosh24ec.geo}
    {ucdriver.drvr
	Driver/uC/uc.geo
	Driver/uC/ucec.geo}
    {vga.drvr
	Driver/Video/VGAlike/VGA/vga.geo
	Driver/Video/VGAlike/VGA/vgaec.geo}
    {vga8.drvr
	Driver/Video/VGAlike/VGA8/vga8.geo
	Driver/Video/VGAlike/VGA8/vga8ec.geo}
    {vgfs.ifsd
	Driver/IFS/GEOS/VGFS/vgfs.geo
	Driver/IFS/GEOS/VGFS/vgfsec.geo}
    {vidmem.drvr
	Driver/Video/Dumb/VidMem/vidmem.geo
	Driver/Video/Dumb/VidMem/vidmemec.geo}
    {xms.drvr
	Driver/Swap/XMS/xms.geo
	Driver/Swap/XMS/xmsec.geo}
    {zoomfs.ifsd
	Driver/IFS/GEOS/ZoomFS/zoomfs.geo
	Driver/IFS/GEOS/ZoomFS/zoomfsec.geo}
    {zoomtd.drvr
	Driver/Mailbox/Transport/ZoomTD/zoomtd.geo
	Driver/Mailbox/Transport/ZoomTD/zoomtdec.geo}
}

#
# YO - don't forget to add geodes to this list in alphabetical order
#


#############################################################################
#
#			      ISV THINGS
#
defvar file-geode-list-5 {
    {db.lib
	Library/Foam/HPDB/hp.geo
	Library/Foam/HPDB/hpec.geo}
    {pq.app
	../Intuit/Installed/Appl/PQ/pq.geo
	../Intuit/Installed/Appl/PQ/pqec.geo}
    {pqdb.lib
	../Intuit/Installed/Library/PQDB/pqdb.geo
	../Intuit/Installed/Library/PQDB/pqdbec.geo}
    {rspwr.drv
	Driver/Power/Rspwr/N9000DEMO/rspwr.geo
	Driver/Power/Rspwr/N9000DEMO/rspwrec.geo}
    {rspwr.drv
	Driver/Power/Rspwr/RESPDEMO/rspwr.geo
	Driver/Power/Rspwr/RESPDEMO/rspwrec.geo}
    {vsstb.lib
	Library/Foam/OEM/Nokia_versions/VSStb/vsstb.geo
	Library/Foam/OEM/Nokia_versions/VSStb/vsstbec.geo}
}


if {[string c ${file-os} unix] == 0} {
    var	swatfile ~/.swat.files
} else {
    #on the PC try the current direcory, then the HOME direcory
    # and then the ROOT_DIR/bin directory looking for a swat.cfg file
    var swatfile swat.fil
    if {![file exists $swatfile] && ![null [getenv HOME]]} {
    	var swatfile [format {%s/swat.fil} [getenv HOME]]
    }
    if {![file exists $swatfile]} {
    	var swatfile [format {%s/bin/swat.fil} [getenv ROOT_DIR]]
    }
}

[if {[file exists $swatfile]} {
    if {[catch {source [file expand $swatfile]} res] != 0} {
        echo Warning: $swatfile: $res
    }    
}]

######################################################################
#   	    		unignore
#
#   	unignore a patient, even if it was "I"gnored 
#
######################################################################
[defcommand unignore {geode} {swat_prog.file}
{
Usage:	unignore    <patient name>

Example:
    	unignore    hello   	; unignores hello

Synopsis:
    	unignores patients whether they were ignore with 'i' or 'I'

See also:
    	nuke-symdir-entry
}
{
    nuke-symdir-entry $geode ignoreOnly
    sw $geode
}]


######################################################################
#   	add an ignore entry to the cache
######################################################################
[defcommand add-symdir-ignore-entry {geode type} {swat_prog.load swat_prog.file}
{
Usage:	add-symdir-ignore-entry <geode> <type>

Example:
    	add-symdir-ignore-entry hello app ; adds an ignore entry for hello
    	    	    	    	    	  ; to the symdir cache
    	add-symdir-ignore-entry text lib  ; adds an ignore entry for hello
    	    	    	    	    	  ; to the symdir cache

Synopsis:
    	if you want to ignore a patient everytime you run swat, you
    	can add an ignore entry to the cache that tells swat it ignore
        the patient everytime it goes to look for it. This is the same
        as ignoring a patient with "Ignore" or "I" rather than
    	"ignore" or "i"

See also:
    	nuke-symdir-entry
}
{
    global file-devel-dir file-os

    [case $type in
    	{l*} {var i 2}
    	{d*} {var i 3}
    	{a*} {var i 4}
    ]

    if {[string compare ${file-os} dos] == 0} {
    	if {![null [getenv LOCAL_ROOT]]} {
            var sdfilename [format {%s\\symdir.%d} [getenv LOCAL_ROOT] $i ]
    	} else {
            var sdfilename [format {%s\\BIN\\symdir.%d} [getenv ROOT_DIR] $i ]
    	}
    } elif {[null ${file-devel-dir}]} {
    	var sdfilename [format {%s/.symdir.%d} [getenv HOME] $i]
    } else {
    	var sdfilename [format {%s/.symdir.%d} ${file-devel-dir} $i]
    }
    var st [stream open $sdfilename a]
    stream write [format {%-9sIgnore\n} $geode] $st
    stream close $st
}]
    
######################################################################
#   	nuke an entry from the appropriate symdir file
######################################################################
[defcommand nuke-symdir-entry {geode {ignoreOnly {}}}  {swat_prog.load swat_prog.file}
{
Usage:	nuke-symdir-entry <geode>

Example:
    	nuke-symdir-entry text	    ; nukes the text entries

Note:	to "unignore" the patient, just switch to that patient, so
    	doing this:

    	nuke-symdir-entry <patient>
    	switch <patient>

    	will unignore a permanently ignored patient

Synopsis:
    	the symdir cache allows swat to remember where it finds symbol files
    	so it can quickly find it the next time it is run, geodes have entries
    	in the cache of places where it was found. By running nuke-symdir-entry
    	it will remove the entries for a given geode from the cache. This can
    	be useful if there is an entry for a gym file that is being found
    	before it gets a chance to find the right symfile somewhere else in the
    	tree. This is also useful if you have Ignored (capital I) a patient and
    	added an Ignore entry to the cache, and now you want it to search for
    	the symbol file for that geode

See also:
    	add-symdir-ignore-entry
}
{
    global  file-devel-dir file-os

    var nuked 0
    for {var i 1} {$i < 5} {var i [expr $i+1]} {     	
        if {[string compare ${file-os} dos] == 0} {
    	    if {![null [getenv LOCAL_ROOT]]} {
    	    	var sdfilename [format {%s\\symdir.%d} [getenv LOCAL_ROOT] $i ]
    	    	var tmpfilename [format {%s\\symdir.000} [getenv LOCAL_ROOT]]
    	    } else {
    	    	var sdfilename [format {%s\\BIN\\symdir.%d} [getenv ROOT_DIR] $i ]
    	    	var tmpfilename [format {%s\\BIN\\symdir.000} [getenv ROOT_DIR]]
    	    }
    	} elif {[null ${file-devel-dir}]} {
    	    var sdfilename [format {%s/.symdir.%d} [getenv HOME] $i]
    	    var tmpfilename [format {%s/.symdir.000} [getenv HOME]]
    	} else {
    	    var sdfilename [format {%s/.symdir.%d} ${file-devel-dir} $i]
    	    var tmpfilename [format {%s/.symdir.000} ${file-devel-dir}]
    	}
    	var fp [stream open $sdfilename r]
    	var tmpfp [stream open $tmpfilename w]
    	while {1} {
    	    var line [stream read line $fp]
    	    if {[null $line]} {
    	    	stream close $fp
    	    	stream close $tmpfp
    	    	break
    	    }
    	    var line [string subst $line \\n {} global]
    	    var nm [index $line 0]
    	    if {[string match $nm $geode] == 0} {
    	    	stream write [format {%s\n} $line] $tmpfp
    	    } elif {![null $ignoreOnly] && ![string match $line *Ignore*]} {
    	    	stream write [format {%s\n} $line] $tmpfp
    	    } else {
    	    	var nuked [expr $nuked+1]
    	    }
    	}

    	var fp [stream open $sdfilename w]
    	var tmpfp [stream open $tmpfilename r]
    	while {1} {
    	    var line [stream read line $tmpfp]
    	    if {[null $line]} {
    	    	stream close $fp
    	    	stream close $tmpfp
    	    	break
    	    }
            var line [string subst $line \\n {} global]
    	    stream write [format {%s\n} $line] $fp
        }
    }
    if {$nuked == 0} {
    	echo No entries found
    } else {
        echo All entries nuked ($nuked)
    }
}]
