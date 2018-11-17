##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	folder.tcl
# FILE: 	folder.tcl
# AUTHOR: 	Martin Turon, Jul 22, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	7/22/92		Initial version
#
# DESCRIPTION:
#	
#
#	$Id: gmgr.tcl,v 1.14 93/07/31 21:07:08 jenny Exp $
#
###############################################################################

#
# Define some shortcuts for debugging Filemanagers
#
alias	pfr	{print-folder-record-info}
alias	pfb	{print-folder-buffer}
alias	pp	{print-positions}

#
# clean-icon-positioning
#
alias	cip	{del 5-}
alias	mip	{monitor-icon-positioning}

##############################################################################
#				gmgr-parse-args
##############################################################################
#
# SYNOPSIS:	Parse the list of arguments into a string of flags and
#   	    	an address
# PASS:		args	= list of caller's args
#   	    	pattern	= class of characters that are valid flags for
#   	    	    	  the command.
#   	    	defaddr	= default value for $addr
# CALLED BY:	INTERNAL
# RETURN:	$addr and $flags in caller's scope are set to the appropriate
#   	    	parts of the decomposed argument list.
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/16/92	Initial Revision
#
##############################################################################
[defsubr gmgr-parse-args {args pattern defaddr}
{
    #
    # Construct actual pattern to use. All commands accept -D, -S, and -A to
    # select which folder records to print. Why do we check to make sure
    # the flags match a particular pattern? So we can use -c and things like
    # this to specify the object.
    #
    var pattern [format {-[DSA%s]*} $pattern]
    foreach a $args {
    	if {[string m $a $pattern]} {
	    var flags ${flags}[range $a 1 end chars]
    	} elif {[null $addr]} {
	    var addr $a
    	} else {
	    error [format {address "%s" already given} $addr]
    	}
    }
    if {[null $addr]} {
    	var addr $defaddr
    }
    
    #
    # Set the $addr and $flags variables in our caller's scope.
    #
    if {[null $flags]} {
    	# default to using display list
    	var flags D
    }
    uplevel 1 var addr [addr-with-obj-flag $addr] flags -$flags
}]

##############################################################################
#			print-folder-buffer
##############################################################################
#
# SYNOPSIS:	Prints the long name of each file in the folder buffer
#               of the given folder
#
# PASS:		flag	 = -D (display list)
#			   -S (selected list)
#			   -A (all records)
#		addr	 = pointer to FolderClass instance data
#
# CALLED BY:	Utility
# RETURN:	
# SIDE EFFECTS:	
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/3/92   	Initial version
#
##############################################################################
[defcommand print-folder-buffer {args} lib_app_driver.gmgr
{Usage:
    print-folder-buffer [<flags> <address>]

Examples:
    "pfb"   	    			print the display list of the
					folder at ds:si 
    "print-folder-buffer"		print the display list of the
					folder at ds:si 
    "print-folder-buffer -Anap"		prints the names, attributes,
					and positions of *all* FolderRecords,
    "print-folder-buffer -nwS ds:bx"	prints the names and
					WShellObjectTypes of all files
					in the selected list of 
					the folder at ds:bx 
	
Synopsis:
    Print out all the FolderRecords in the folder buffer of the given folder.

Notes:
    * The address argument is a pointer to FolderClass instance data.
      This defaults to ds:si.  

    * The flags are assigned as follows:
		-D	print file on the display list
		-S	print files on the selected list
		-A	all FolderRecords

		-n	print filenames
		-s	print sizes
		-p	print position of each file
		-t 	print GeosFileType of each file
		-w 	print WShellObjectType of each file
		-i 	print each file's icon token characters
    	    	-I  	print each file's 32-bit file ID
    	    	-o  	print each record's offset
    	    	-b  	print bounding box
		-a 	print FileAttrs & GeosFileHeaderFlags:

				A = archive
				D = directory
				V = volume
				S = DOS system file
				H = DOS hidden
				R = read-only

				L = link
				T = template

See also:
}
{
    gmgr-parse-args $args {nsptwiaIob} *ds:si

    echo
    print-folder-record-header $flags
    folder-record-enum print-folder-record-info $addr $flags
    echo
}]


##############################################################################
#			print-positions
##############################################################################
#
# SYNOPSIS:	Prints the positions of all the files in the given folder.
# PASS:		folder - pointer to FolderClass instance data
# CALLED BY:	Utility
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/10/92   	Initial version
#
##############################################################################
[defcommand print-positions {args} lib_app_driver.gmgr
{Usage:
    print-positions [-D | -S | -A] [<folder>]

Examples:
    "pp"    		    	    print the positions of all files in 
                                    the display list of the folder at *ds:si 
    "print-positions"	    	    print the positions of all files in 
                                    the display list of the folder at *ds:si 

Synopsis:
    Print out a all the bounding boxes of files in the given folder.

Notes:
    * The address argument is the address of FolderClass instance data.
      This defaults to *ds:si.  

See also:
    print-folder-buffer
}
{
    	gmgr-parse-args $args {} *ds:si
	echo
	echo ICON POSITIONS:
	folder-record-enum print-folder-record-position $addr $flags
	echo
	return 0
}]


##############################################################################
#				pfileids
##############################################################################
#
# SYNOPSIS:	Prints the file ID and name of all files in the given folder.
# PASS:		addr - pointer to FolderInstance instance data
# CALLED BY:	Utility
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/10/92   	Initial version
#
##############################################################################
[defcommand pfileids {args} lib_app_driver.gmgr
{Usage:
    pfileids [-D | -S | -A] [<folder>]

Examples:
    "pfileids"	    	    print the ID of all files in the display
			    list of the folder at *ds:si

Synopsis:
    Print out the file id (32-bit ID, and disk handle) for all files in the
    display list of the given folder.

Notes:
    * The address argument is the address of FolderClass instance data.
      This defaults to *ds:si.  

See also:
    print-folder-buffer
}
{
    gmgr-parse-args $args {} *ds:si
    folder-record-enum folder-record-print-file-id $addr $flags
}]


##############################################################################
#				getfmgr
##############################################################################
#
# SYNOPSIS:	returns the filemanager being used
#
# CALLED BY:	Internal - folder-record-enum
#
# PASS:		nothing
# RETURN:	p	= patient
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/23/92   	Pulled out of folder-record-enum
#
##############################################################################
[defsubr    getfmgr {} 
{
    #
    # Figure which file manager is active, so we can call these things from
    # any thread without having a sym-default active.
    #
	    if {![null [patient find manager]]} {
	    	var p manager::
	    } elif {![null [patient find wshell]]} {
	    	var p wshell::
	    } elif {![null [patient find wshellba]]} {
	    	var p wshellba::
	    }

	    uplevel 1 var p $p
}]


##############################################################################
#				folder-record-enum
##############################################################################
#
# SYNOPSIS:	Enumerate through all records for a given folder
#
# PASS:	        callback = routine to call for each FolderRecord
#		addr   	 = pointer to FolderClass instance data
#		flags	 = -D (display list)
#			   -S (selected list)
#			   -A (all records)
#
# TO CALLBACK:  address  = address of FolderRecord
#		flags	 = flags passed in
#   	    	p   	 = name of active file manager, followed by ::, for
#			   use in constructing field names that can be found
#			   from any thread.
#
# CALLED BY:	print-positions
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/10/92   	Initial version
#
##############################################################################
[defsubr folder-record-enum {callback {addr ds:si} {flags -D}}
{

    getfmgr

   #
   # Set the various variables that allow us to cope with the three different
   # things we can enumerate:
   #	$first	= command to execute to get the offset of the first record
   #	    	  to enumerate
   #	$done	= an expression to pass to "expr" that evaluates non-zero
   #		  if we're done enumerating
   #	$next	= command to execute to get the offset of the next record
   #		  to enumerate
   #
    [case $flags in
	{*D* default} {
	    var first {value fetch $seg:$off.${p}FOI_displayList}
	    var done {$rec == 65535}
	    var next {value fetch $buf:$rec.${p}FR_displayNext}
	}
	*S* {
	    var first {value fetch $seg:$off.${p}FOI_selectList}
	    var done {$rec == 65535}
	    var next {value fetch $buf:$rec.${p}FR_selectNext}
	}
	*A* {
	    var first {expr [size FolderBufferHeader]}
	    var done {$cnt == 0}
	    var next [format {expr $rec+%d} [size ${p}FolderRecord]]
	}
    ]

   #
   # Parse the address expression into something meaningful
   #
   [addr-preprocess $addr seg off]
   var buf ^h[value fetch $seg:$off.${p}FOI_buffer]
   var cnt [value fetch $seg:$off.${p}FOI_fileCount]

   #
   # Get the offset to the first FolderRecord depending on the flags
   # passed in.
   #
    var rec [eval $first]

   #
   # Now callback for each element
   #
	while { ![expr $done] } {
		uplevel 1 [list $callback $buf:$rec $flags $p]

    	    	var rec [eval $next] cnt [expr $cnt-1]
	}
}]


##############################################################################
#			print-folder-record-info
##############################################################################
#
# SYNOPSIS:	Prints out specific fields of a given FolderRecord
#
# CALLED BY:	print-folder-buffer (via folder-record-enum)
#
# PASS:		address = pointer to FolderRecord
#		flags	= -n (FileLongName)
#			  -a (FileAttrs & GeosFileHeaderFlags)
#			  -t (GeosFileType)
#			  -w (WShellObjectType)
#			  -p (x,y position)
#			  -i (Icon [token])
#			  -s (Size)
#			  -f (Flags - FR_state)
#			  -I (FileID)
#			  -o (offset)
#    	    	    	  -b (bounds)
#   	    	p   	= name of file manager patient, followed by ::
#
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    print-folder-record-info {{addr ds:di} {flags -nat} {p {}}} 
{
	[addr-preprocess $addr seg off]
	var fattrs	[value fetch $seg:$off.${p}FR_fileAttrs]
	var fflags	[value fetch $seg:$off.${p}FR_fileFlags]
	var fstate	[value fetch $seg:$off.${p}FR_state]
	var ftype	[value fetch $seg:$off.${p}FR_fileType word]
	var fdeskinfo	[value fetch $seg:$off.${p}FR_desktopInfo word]
	var x        	[getvalue $seg:$off.${p}FR_iconBounds.R_left]
	var y        	[getvalue $seg:$off.${p}FR_iconBounds.R_top]
	var fsize	[value fetch $seg:$off.${p}FR_size sdword]

    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     	n {
		  echo -n [format {%-36s} [folder-record-get-name $seg:$off $p]]
		}
	     	a {
	   	  print-file-attributes $fattrs
		  print-file-flags $fflags
		}
		t {
	   	  echo -n [penum GeosFileType $ftype]
		}
		w {
	   	  echo -n [penum ${p}WShellObjectType $fdeskinfo]
		}
		p {
		  echo -n [format {(%4d,%4d)} $x $y]
		}
		i {
		  print-token $seg:$off.${p}FR_token
		}
		s {
		  echo -n [format {%d bytes} $fsize]
		}
		I {
		  echo -n [format {%04xh:%08xh}
		    	    [value fetch $seg:$off.${p}FR_disk]
			    [value fetch $seg:$off.${p}FR_id]]
    	    	}
		o {
		  echo -n [format {%04xh } $off]
    	    	}
		f {
		  print-folder-record-state $fstate
    	    	}
		b {
		  echo -n [format {(%4d,%4d) to (%4d,%4d)}
	        	    [getvalue $seg:$off.${p}FR_boundBox.R_left]
	        	    [getvalue $seg:$off.${p}FR_boundBox.R_top]
	        	    [getvalue $seg:$off.${p}FR_boundBox.R_right]
	        	    [getvalue $seg:$off.${p}FR_boundBox.R_bottom]]
    	    	}
	    ]
  	    echo -n {   }
	}
      }		
     echo
}]


##############################################################################
#			print-folder-record-header
##############################################################################
#
# SYNOPSIS:	Prints a description line for the given flags
#
# CALLED BY:	print-folder-buffer (via folder-record-enum)
#
# PASS:		flags	= -n (FileLongName)
#			  -a (FileAttrs & GeosFileHeaderFlags)
#			  -t (GeosFileType)
#			  -w (WShellObjectType)
#			  -p (x,y position)
#			  -i (Icon [token])
#
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    print-folder-record-header {{flags -nat}} 
{
    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     	n {
		  echo -n {FileLongName                        }
		}
	     	a {
		  echo -n {Attrs   }
		}
		t {
		  echo -n {Type}
		}
		w {
		  echo -n {WOT}
		}
		p {
		  echo -n {Position   }
		}
		i {
		  echo -n {Icon   }
		}
		s {
		  echo -n {Size}
		}
		I {
		  echo -n { Disk:File ID  }
	    	}
		o {
		  echo -n {Offset}
    	    	}
		f {
		  echo -n {State Flags  }
    	    	}
		b {
		  echo -n {Bounding Box                }
    	    	}
	    ]
  	    echo -n {   }
	}
      }	
    echo

    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     	n {
		  echo -n {------------                        }
		}
	     	a {
		  echo -n {-----   }
		}
		t {
		  echo -n {----}
		}
		w {
		  echo -n {---}

		}
		p {
		  echo -n {-----------}

		}
		i {
		  echo -n {----   }
		}
		s {
		  echo -n {----}
		}
		I {
		  echo -n {---------------}
	    	}
		o {
		  echo -n {------}
    	    	}
		f {
		  echo -n {-------------}
    	    	}
		b {
		  echo -n {------------                }
    	    	}
	    ]
  	    echo -n {   }
	}
      }		
     echo


}]

##############################################################################
#				print-token
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
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    print-token {addr} 
{
	[addr-preprocess $addr s o]

	var tokenID	[getvalue $s:$o.GT_manufID]
	
        echo -n [format %c [value fetch $s:[expr $o+0] [type byte]]]
        echo -n [format %c [value fetch $s:[expr $o+1] [type byte]]]
        echo -n [format %c [value fetch $s:[expr $o+2] [type byte]]]
        echo -n [format %c [value fetch $s:[expr $o+3] [type byte]]]
	echo -n [format {,%3d} $tokenID ]	
}]


##############################################################################
#			print-folder-record-position
##############################################################################
#
# SYNOPSIS:	Prints the position of the given FolderRecord
#
# CALLED BY:	print-positions (via folder-record-enum)
#
# PASS:		address - pointer to FolderRecord
#		flags	-
#		p	- patient
#
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/10/92   	Initial version
#
##############################################################################
[defsubr print-folder-record-position {{addr ds:di} {flags {}} {p {}}}
{
	[addr-preprocess $addr seg off]
	var x        [getvalue $seg:$off.${p}FR_iconBounds.R_left]
	var y        [getvalue $seg:$off.${p}FR_iconBounds.R_top]
	var state    [value fetch $seg:$off.${p}FR_state]

	if {[field $state FRSF_UNPOSITIONED]}	{
		echo -n [format {(not positioned)  }]
	} else {
		echo -n [format {(positioned)      }]
	}
	echo -n [format {(%d,%d)\t%s} $x $y 
		 [folder-record-get-name $addr $p]]
	echo
}]


##############################################################################
#			print-folder-record-bounds
##############################################################################
#
# SYNOPSIS:	Prints the bounding boxes of the given FolderRecord
#
# CALLED BY:	print-positions (via folder-record-enum)
#
# PASS:		address - pointer to FolderRecord
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/12/92   	Initial version
#
##############################################################################
[defsubr    print-folder-record-bounds {{addr ds:di}}
{
	[addr-preprocess $addr seg off]

	pstring $seg:$off.${p}FR_name
	print	$seg:$off.${p}FR_iconBounds
	print	$seg:$off.${p}FR_nameBounds
	print	$seg:$off.${p}FR_boundBox

}]


##############################################################################
#			print-folder-record-state
##############################################################################
#
# SYNOPSIS:	
#
# CALLED BY:	print-folder-record-info
#
# PASS:		state
# RETURN:	nothing
#
# SIDE EFFECTS:	
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/19/92   	Initial version
#
##############################################################################
[defsubr    print-folder-record-state {state} 
{
	print-char-if-bit-set U $state FRSF_UNPOSITIONED
	print-char-if-bit-set O $state FRSF_OPENED
	print-char-if-bit-set S $state FRSF_SELECTED
        echo -n [format { }]
	print-char-if-bit-set T $state FRSF_HAVE_TOKEN
	print-char-if-bit-set C $state FRSF_CALLED_APPLICATION	
        echo -n [format { }]
	print-char-if-bit-set S $state FRSF_HAVE_SMALL_ICON
	print-char-if-bit-set L $state FRSF_HAVE_LARGE_ICON
	print-char-if-bit-set W $state FRSF_HAVE_NAME_WIDTH
        echo -n [format { }]
	print-char-if-bit-set I $state FRSF_INVERTED
	print-char-if-bit-set D $state FRSF_DELAYED
}]


##############################################################################
#			print-file-flags
##############################################################################
#
# SYNOPSIS:	
#
# CALLED BY:	print-folder-record-info
#
# PASS:		flags	= GeosFileHeaderFlags
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    print-file-flags {flags} 
{
	print-char-if-bit-set T $flags GFHF_TEMPLATE
}]


##############################################################################
#			print-file-attributes
##############################################################################
#
# SYNOPSIS:	
#
# CALLED BY:	print-folder-record-info
#
# PASS:		attr	= FileAttrs
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/16/92   	Initial version
#
##############################################################################
[defsubr    print-file-attributes {attr} 
{
	print-char-if-bit-set A $attr FA_ARCHIVE
	print-char-if-bit-set D $attr FA_SUBDIR
	print-char-if-bit-set V $attr FA_VOLUME
	print-char-if-bit-set S $attr FA_SYSTEM
	print-char-if-bit-set H $attr FA_HIDDEN
	print-char-if-bit-set R $attr FA_RDONLY
	print-char-if-bit-set L $attr FA_LINK
}]

[defsubr    print-char-if-bit-set {char record field}
{
	if {[field $record $field]} {
		echo -n $char
	} else {
		echo -n [format { }]
	}
}]


##############################################################################
#				folder-record-get-name
##############################################################################
#
# SYNOPSIS:	Fetch the name stored in a folder record
# PASS:		addr	= address of the FolderRecord
#   	    	p   	= name of active file manager, followed by ::
# CALLED BY:	INTERNAL
# RETURN:	name
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/16/92	Initial Revision
#
##############################################################################
[defsubr folder-record-get-name {addr p}
{
    var nt [type make array 32 [type char]] null 0
    var name [mapconcat c [value fetch ($addr).${p}FR_name $nt] {
    	if {!$null} {
	    if {[string c $c {\000}]} {
	    	var c
    	    } else {
    	    	var null 1
    	    }
    	}
    }]
    type delete $nt
    return $name
}]

##############################################################################
#				folder-record-print-file-id
##############################################################################
#
# SYNOPSIS:	Print the file-id of a single FolderRecord
# PASS:		addr	= address of the FolderRecord
#   	    	flags	= flags passed to folder-record-enum
#   	    	p   	= name of patient, followed by ::, to allow field names
#			  to be found
# CALLED BY:	pfileids via folder-record-enum
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/11/92	Initial Revision
#
##############################################################################
[defsubr folder-record-print-file-id {addr flags p}
{
    var name [folder-get-name $addr $p]
    var disk [value fetch ($addr).${p}FR_disk]
    var dname [mapconcat c [value fetch FSInfoResource:$disk.DD_volumeLabel] {var c}]
    var id [value fetch ($addr).${p}FR_id]
    echo [format {%32s on %04xh [%s], id %08xh} $name $disk $dname $id]
}]



##############################################################################
#			print-folder-view-size
##############################################################################
#
# SYNOPSIS:	Prints out the size of the view of the given folder.
#
# PASS:		addr	= pointer to FolderClass instance data
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/12/92   	Initial version
#
##############################################################################
[defsubr    print-folder-view-size {{addr ds:si}} 
{
	[addr-preprocess $addr seg off]
	var x        [value fetch $seg:$off.FOI_winWidth word]
	var y        [value fetch $seg:$off.FOI_winHeight word]

	echo  -n {Current folder view size: }
	echo  [format {\t(%d,%d)} $x $y]
	return 0
}]

##############################################################################
#			print-folder-document-size
##############################################################################
#
# SYNOPSIS:	Prints out the size of the icon area of the current folder.
#
# PASS:		nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/12/92   	Initial version
#
##############################################################################
[defsubr    print-folder-document-size {} 
{

	[addr-preprocess folderDocWidth seg off]
	var x        [value fetch $seg:$off word]
	[addr-preprocess folderDocHeight seg off]
	var y        [value fetch $seg:$off word]

	echo  -n {Current folder document size: }
	echo  [format {\t(%d,%d)} $x $y]
	return 0
}]


##############################################################################
#			monitor-icon-positioning
##############################################################################
#
# SYNOPSIS:	Sets a load of useful breakpoints that display information
#		helpful in monitoring icon positioning activity.
#
# NOTES:	If you ever get a "Error: Invalid address" when trying
#               to run this routine, it probably means:
#			1) You are not running this command from the
#			   correct geode.  Try typing "wshellba" at
#			   the swat prompt.
#			2) The code has changed, and one of the
#			   breakpoints defined here is no longer
#			   valid.  To find out which one, examine your
#			   list of breakpoints, and see where it got
#			   cut off. 	 
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	martin	11/11/92   	Initial version
#
##############################################################################
[defsubr monitor-icon-positioning {}
{
	getfmgr
     #
     # Inform us whenever certain routines are called.
     # (Helpful for optimizations)
     #
#	[brk ${p}BuildDisplayList		{whisper {BuildDisplayList}}]

     #
     # Print out vital information whenever the dirinfo has been read.
     #
	[brk ${p}FolderLoadDirInfo::done	{print-positions}]

     #
     # Detect changes in document size
     #
	[brk ${p}BuildLargeMode::done		{print-folder-document-size}]
	[brk ${p}BuildLongMode::done		{print-folder-document-size}]
	[brk ${p}BuildShortMode::done		{print-folder-document-size}]
	[brk ${p}FolderRecalcViewSize::done	{print-folder-document-size}]

     #
     # Detect changes in view size
     #	
	[brk ${p}FolderFixLayout::recalcPositions   {print-folder-view-size}]

}]

[defsubr print-string-and-message-at {stringaddr message} {
	echo -n $message
	pstring $stringaddr
	return 0
}]

[defsubr whisper {message} {
	echo $message
	return 0
}]

##############################################################################
#	poswatch
##############################################################################
#
# SYNOPSIS:	Watch the icon positioning mechanism at work.
#
# PASS:	    	-f  : watch the "find empty slot" process
#   	    	-p  : watch FolderRecordSetPosition
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	6/30/93   	Initial Revision
#
##############################################################################
[defsubr    poswatch {{flags {}}} {

    # Figure out which incarnation of GeoManager this is

    getfmgr

    require getstring	cwd.tcl
    require getcc   setcc.tcl

    global  findEmptySlot setPos
    remove-brk findEmptySlot 
    remove-brk setPos

    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in
	     f {
		 var findEmptySlot [list 
		    [brk ${p}FolderRecordSetPositionAsPercentage {printDSDI}]
		    [brk ${p}FolderRecordSetPositionAsPercentage::done {printPos}]
		    [brk ${p}FolderRecordFindEmptySlot {printDSDI}]
		    [brk ${p}FolderCheckForIconInRect {checkForIcon}]
		    [brk ${p}FolderCheckForIconInRect::done {checkForIconResult}]
		]
	     }   
	     p {
	     	var setPos [list
		    [brk ${p}FolderRecordSetPosition {printSetPos}]
		]
	     }
	     default {
		 error [list Unrecognized flag $i]
		 }
	 ]}
	}
}]

##############################################################################
#	printSetPos
##############################################################################
#
# SYNOPSIS:	Print the position (upper-left corner of icon bounds)
#   	    	of this folder record.
# PASS:		ds:di - FolderRecord
# CALLED BY:	poswatch
# RETURN:	0
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
[defsubr    printSetPos {} {
    echo -n [format {%-25s} [getstring ds:di]]
    if {[field [value fetch ds:di.FR_state] FRSF_PERCENTAGE]} {
	echo [format {(%d%%, %d%%)} 
	      [expr [read-reg cx]*100/16384]
	      [expr [read-reg dx]*100/16384]
	  ]
    } else {
	  printPos
    }
    return 0
}]


##############################################################################
#	printDSDI
##############################################################################
#
# SYNOPSIS:	Show a call to FolderRecordFindEmptySlot
# PASS:		ds:di - FolderRecord
# CALLED BY:	poswatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	6/30/93   	Initial Revision
#
##############################################################################
[defsubr    printDSDI {} {
    pstring ds:di
    return 0
}]

##############################################################################
#	printPos
##############################################################################
#
# SYNOPSIS:	Print the position
# PASS:		cx, dx - position
# CALLED BY:	poswatch
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	6/30/93   	Initial Revision
#
##############################################################################
[defsubr    printPos {} {
    echo [format {(%d, %d)} 
    	    [read-reg cx]
    	    [read-reg dx]
      ]
    return 0
}]


##############################################################################
#	checkForIcon
##############################################################################
#
# SYNOPSIS:	Show a call to FolderCheckForIconInRect
# PASS:		ax, bx, cx, dx - rectangle to check
# CALLED BY:	poswatch
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	6/30/93   	Initial Revision
#
##############################################################################
[defsubr    checkForIcon {} {
    echo [format {    (%d,%d)-(%d,%d):}
	  [read-reg ax]
	  [read-reg bx]
	  [read-reg cx]
	  [read-reg dx]
      ]
    return 0
}]

##############################################################################
#	checkForIconResult
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
#       chrisb 	6/30/93   	Initial Revision
#
##############################################################################
[defsubr    checkForIconResult {} {
    if {[getcc c]} {
	echo [format {        %s (%d,%d)-(%d,%d)}
	      [getstring es:di]
	      [value fetch es:di.FR_iconBounds.R_left]
	      [value fetch es:di.FR_iconBounds.R_top]
	      [value fetch es:di.FR_iconBounds.R_right]
	      [value fetch es:di.FR_iconBounds.R_bottom]]
    } else {
	echo {        OK}
    }
    return 0
}]



[defsubr remove-brk {bname} {

	global	$bname
    if {![null $[var $bname]]} {
	foreach i [var $bname] {
	    catch {brk clear $i}
	}
	var $bname {}
    }
}]


##############################################################################
#				WARNING_FILE_ERROR_IGNORED
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
#	martin	1/17/93   	Initial version
#
##############################################################################
[defsubr    wshellba::WARNING_FILE_ERROR_IGNORED {} 
{
	p FileError ax
}]


