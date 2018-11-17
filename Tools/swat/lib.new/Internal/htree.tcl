##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	htree.tcl
# AUTHOR: 	Adam de Boor, Sep  9, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/ 9/93		Initial Revision
#
# DESCRIPTION:
#	Functions for printing out the entire help tree in a couple useful
#	forms
#
#	$Id: htree.tcl,v 1.1 93/09/09 13:25:31 adam Exp $
#
###############################################################################
defvar htree-width 80

[defsubr htree-write {string stream}
{
    if {[null $stream]} {
    	echo -n $string
    } else {
    	stream write $string $stream
    }
}]

[defsubr htree {{file {}}}
{
    protect {
	if {![null $file]} {
	    var str [stream open $file w]
	    if {[null $str]} {
		error [format {unable to open %s} $file]
	    }
	}

	htree-low top $str
    } {
    	if {![null $str]} {
	    stream close $str
    	}
    }
}]

[defsubr htree-low {level str}
{
    global htree-width

    [if {[catch {help-fetch $level} desc] != 0 ||
        [string first \n $desc] != -1}
    {
    	var desc {not documented}
    }]
    var len [length $level char]
    var barlen1 [expr (${htree-width}-($len+2))/2]
    var barlen2 [expr (${htree-width}-1)-($barlen1+$len+2)]
    htree-write [format {\n%.*s %s %.*s\n} $barlen1 {========================================} $level $barlen2 {========================================}] $str
    htree-write [format {Description:\n    %s\n} $desc] $str
    var hastops 0 hassubs 0
    var contents [sort [map t [help-fetch-level $level] {
    	    if {[help-is-leaf $level.$t]} {
	    	var hastops 1
	    	list top $t
	    } else {
	    	var hassubs 1
	    	list sub $t
	    }
    }]]
    
    if {$hastops} {
    	htree-write Topics:\n $str
	htree-print-as-table $contents top $str
    }
    if {$hassubs} {
    	if {$hastops} {htree-write \n $str}
    	htree-write Subtopics:\n $str
	htree-print-as-table $contents sub $str
	foreach t $contents {
	    if {[index $t 0] == sub} {
	    	htree-low $level.[index $t 1] $str
    	    }
    	}
    }
}]

[defsubr htree-print-as-table {topics type str}
{
    global htree-width
    #
    # Find the width of the longest one
    #
    var width 0
    var topics [eval [concat concat [map i $topics {
    	if {[index $i 0] == $type} {
	    var len [length $i chars]
	    if {$len > $width} {
	    	var width $len
	    }
	    list [index $i 1]
	}
    }]]]
    #
    # Up that by the inter-column spacing (2 -- magic)
    #
    var width [expr $width+2]
    #
    # Figure the number of columns we can put up (minimum of 1)
    #
    var nc [expr (${htree-width}-1-4)/$width]
    if {$nc == 0} {
	var nc 1
    }
    var tlen [length $topics]

    #
    # Figure out the distance between topics in a row. This is just
    # the number of topics divided by the number of columns, rounded up
    #
    var inc [expr ($tlen+$nc-1)/$nc]

    #
    # Put up the table. Note that [index list n] when
    # n > [length list] returns empty, so there's no need to check
    # for overflow.
    #
    for {var i 0} {$i < $inc} {var i [expr $i+1]} {
     	htree-write {    } $str
	for {var j 0} {$j < $nc} {var j [expr $j+1]} {
	    htree-write [format {%-*s} $width
			     [index $topics [expr $i+$j*$inc]]] $str
	}
	htree-write \n $str
    }
}]

[defsubr help-tree {{file {}} {noleaf 0}}
{
    protect {
	if {![null $file]} {
	    var str [stream open $file w]
	    if {[null $str]} {
		error [format {unable to open %s} $file]
	    }
	}
        help-tree-internal top {+-} $noleaf $str
    } {
    	if {![null $str]} {
	    stream close $str
    	}
    }
}]

[defsubr help-tree-internal {root prefix noleaf str}
{
    var kids [sort [help-fetch-level $root]]
    var num [length $kids] i 1
    var plen [length $prefix chars]
    if {$plen >= 3} {
    	var prefroot [range $prefix 0 [expr $plen-3] chars]
    } else {
    	var prefroot {}
    }

    foreach kid $kids {
    	if {![help-is-leaf $root.$kid]} {
	    htree-write [format {%s\n} $prefix$kid] $str
	    if {$i == $num} {
	    	help-tree-internal $root.$kid [format {%s  +-} $prefroot] $noleaf $str
    	    } else {
	    	help-tree-internal $root.$kid [format {%s| +-} $prefroot] $noleaf $str
    	    }
    	} elif {!$noleaf} {
	    htree-write [format {%s\n} $prefix$kid] $str
	}
	var i [expr $i+1]
    }
}]

