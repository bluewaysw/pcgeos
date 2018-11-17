#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat
# FILE:		cwatch.tcl
# AUTHOR:	John Wedgwood, Oct 29, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	cwatch	    	    	Watch various chart processes
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	10/29/91	Initial revision
#
# DESCRIPTION:
#
#	$Id: cwatch.tcl,v 1.3 93/07/31 21:06:27 jenny Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# Global variables
#


##############################################################################
#				cwatch
##############################################################################
#
# SYNOPSIS:	What various chart happenings
#
# PASS:		-g: watch geometry
#   	    	-s: watch suspends
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defcommand cwatch {{flags {}}} lib_app_driver.chart
{Usage:
    cwatch [on]

Examples:

    "cwatch -g"     Watch Chart Geometry
    "cwatch -s"     Watch Chart Body suspends/unsuspends
    "cwatch -S"	    Watch ChartObjectState changes
    "cwatch -p"	    Watch positioning
    "cwatch"        Turn off chart watching

Synopsis:
    Lets you watch chart geometry as it happens.

Notes:

See also:
}
{
    require remove-brk showcalls.tcl

    global  cgBrk   susBrk  cgIndent stateBrk posBrk selBrk

    remove-brk cgBrk
    remove-brk susBrk
    remove-brk selBrk
    remove-brk posBrk
    remove-brk selBrk

    var cgIndent 0

    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
    	    [case $i in 
	     g {
		 var cgBrk [list 
		    [brk chart::ChartObjectRecalcSize {showSize}]
		    [brk chart::ChartCompRecalcSize {compRecalc}]
		    [brk chart::ChartCompRecalcSize::CCRS_done {cg-outdent}]
		    ]
		 }
	     s {
		 var susBrk [list
			     [brk chart::ChartBodySuspend {showSus}]
			     [brk chart::ChartBodyUnSuspend {showUnSus}]
			 ]
		 }
	     S {
		 var selBrk [list
		       [brk chart::ChartObjectGrObjSelected	{gainSel}]
		       [brk chart::ChartObjectGrObjUnselected	{lostSel}]]
		 }
	     p {
		 var posBrk [list
		       [brk chart::ChartObjectSetPosition	{showSize}]]
		 }
	 ]}
     }
}]

##############################################################################
#	showSus
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
#       chrisb 	12/31/92   	Initial Revision
#
##############################################################################
[defsubr    showSus {} {
    echo SUSPEND
    return 0
}]

##############################################################################
#	showUnSus
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
#       chrisb 	12/31/92   	Initial Revision
#
##############################################################################
[defsubr    showUnSus {} {
    echo UNSUSPEND
    return 0
}]

##############################################################################
#	compRecalc
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
#       chrisb 	12/30/92   	Initial Revision
#
##############################################################################
[defsubr    compRecalc {} {
    cg-echo [format {Comp passed: (%s, %s)}
	     [read-reg cx]
	     [read-reg dx]
	 ]
    cg-indent
    return 0
}]


##############################################################################
#	showSize
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
#       chrisb 	12/29/92   	Initial Revision
#
##############################################################################
[defsubr    showSize {} {

    require getobjclass	objtree.tcl

    var obj *ds:si
    var objclass [getobjclass ($obj)]
    var addr [addr-parse ($obj)]
    var bl [handle id [index $addr 0]]
    var seg ^h$bl
    var off [index $addr 1]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]

    cg-echo [format {%s (^l%04xh:%04xh) = (%s, %s) } $objclass $bl $ch
	       [read-reg cx]
	       [read-reg dx]
	 ]


    return 0
}]

##############################################################################
#				cg-indent
##############################################################################
#
# SYNOPSIS:	Indent the profiling output
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-indent {}
{
    global  cgIndent
    
    var cgIndent [expr $cgIndent+4]
    return 0
}]

##############################################################################
#				cg-outdent
##############################################################################
#
# SYNOPSIS:	Outdent the profiling output
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-outdent {}
{
    global  cgIndent
    
    var cgIndent [expr $cgIndent-4]
    return 0
}]

##############################################################################
#				cg-echo
##############################################################################
#
# SYNOPSIS:	Echo a string, indented appropriately
# PASS:		str - string to echo
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-echo {str}
{
    global cgIndent

    echo -n [format {%*s} $cgIndent {}]
    echo $str
}]

[defsubr cg-echo-n {str}
{
    global cgIndent

    echo -n [format {%*s} $cgIndent {}]
    echo -n $str
}]


##############################################################################
#	gainSel
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
#       chrisb 	1/13/93   	Initial Revision
#
##############################################################################
[defsubr    gainSel {} {
    echo [format {GAINED: %s => %d}
	    [showObj *ds:si]
	    [expr [value fetch (*ds:si).COI_selection [type word]]+1]]
    return 0
}]

##############################################################################
#	lostSel
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
#       chrisb 	1/13/93   	Initial Revision
#
##############################################################################
[defsubr    lostSel {} {
    echo [format {LOST: %s => %d}
	    [showObj *ds:si]
	    [expr [value fetch (*ds:si).COI_selection [type word]]-1]]
    return 0
}]


##############################################################################
#	showObj
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
#       chrisb 	1/13/93   	Initial Revision
#
##############################################################################
[defsubr    showObj {obj} {
    var objclass [getobjclass ($obj)]
    var addr [addr-parse ($obj)]
    var bl [handle id [index $addr 0]]
    var seg ^h$bl
    var off [index $addr 1]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
    return [format {%s (^l%04xh:%04xh) } $objclass $bl $ch]
}]
