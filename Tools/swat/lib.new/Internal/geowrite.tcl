##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- GeoWrite tcl functions
# FILE: 	geowrite.tcl
# AUTHOR: 	Tony Requist, Mar 16, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	3/16/92		Initial Revision
#
# DESCRIPTION:
#	Routines for geowrite
#
#	$Id: geowrite.tcl,v 1.3 93/07/31 21:42:58 jenny Exp $
#
###############################################################################

require carray-enum chunkarr.tcl vm.tcl

##############################################################################
#				pwritedoc
##############################################################################
#
# SYNOPSIS:	Print information about a geowrite document object
# CALLED BY:	user
# PASS:		args	= List containing:
#   	    	    	    -h : Print out the map block header (default)
#    	    	    	    -s : Print section array
#    	    	    	    -a : Print article array
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defcommand pwritedoc {args} lib_app_driver.geowrite
{ptext [-lsrt] ADDR - Prints out a GeoWrite document object
	-c: print out the characters (the default)
}
{
    var default 1
    var header 0
    var sections 0
    var articles 0
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		h {var header 1 default 0}
		s {var sections 1 default 0}
		a {var articles 1 default 0}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }
    if {[length $args] == 0} {
	var address *ds:si
    } else {
	var address [index $args 0]
    }

    var addr [addr-parse $address]
    var dseg [handle segment [index $addr 0]]
    var doff [index $addr 1]
    echo [format {GeoWrite document object: *%04xh:%04xh} $dseg $doff]

    var geninstance [expr $doff+[value fetch $dseg:$doff.ui::Gen_offset word]]
    var file [value fetch $dseg:$geninstance.GDI_fileHandle word]
    var mapblock [get-map-block-from-vm-file $file]
    var mapseg [handle segment [index [addr-parse ^v$file:$mapblock] 0]]
    if {$default || $header} {
    	echo {--- Map block header ---}
    	print MapBlockHeader $mapseg:0
    }

    if {$sections} {
    	echo {--- Section array ---}
    	pcarray -tSectionArrayElement -N *$mapseg:SectionArray
    }

    if {$articles} {
    	echo {--- Article array ---}
    	pcarray -tArticleArrayElement -N *$mapseg:ArticleArray
    }
}]
