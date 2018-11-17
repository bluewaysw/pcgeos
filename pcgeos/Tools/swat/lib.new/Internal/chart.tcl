#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		chart.tcl
# AUTHOR:	John Wedgwood, Oct 24, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pchart			Print information about a chart
#   	paxis			Print information about an axis
#   	pparea			Print information about the plot area
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	10/24/91	Initial revision
#
# DESCRIPTION:
#	Code for producing information about charts.
#
#	$Id: chart.tcl,v 1.6.12.1 97/03/29 11:25:02 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# An assoc list of chart variations and chart types.
#
[var chart-variations {
	{CT_COLUMN		CV_column   	ChartColumnVariation}
	{CT_BAR			CV_bar		ChartBarVariation}
	{CT_AREA		CV_area		ChartAreaVariation}
	{CT_LINE		CV_line		ChartLineVariation}
	{CT_SCATTER		CV_scatter  	ChartScatterVariation}
	{CT_PIE			CV_pie		ChartPieVariation}
}]


##############################################################################
#	printChartObject
##############################################################################
#
# SYNOPSIS:	Print information about a chart object.
# PASS:		address	- chunk handle of chart object
# CALLED BY:	Utility
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defsubr printChartObject {address}
{
    	require get-chunk-addr-from-obj-addr object.tcl

	#
	# Parse the address.
	#

	var addr [addr-parse $address]
	var bl [handle id [index $addr 0]]
	var ch [index [get-chunk-addr-from-obj-addr $address] 1]

	#
	# Fetch the chart-object offset and get the data.
	#

	var coi [value fetch $address ChartObjectInstance]
	
	#
	# Print the information.
	#
	var left [field [field $coi COI_position] P_x]
	var top  [field [field $coi COI_position] P_y]
	var wid  [field [field $coi COI_size] P_x]
	var hgt  [field [field $coi COI_size] P_y]

	#
	# Create strings so that when we print stuff out it will line up.
	#
	echo [format {	^l%04xh:%04xh} $bl $ch]
	echo [format {	%s:  (%d, %d),	%s: (%d, %d)} 	
			Position  $left $top		
			Size $wid	$hgt]
}]

##############################################################################
#				pchart
##############################################################################
#
# SYNOPSIS:	Print information about a chart
# PASS:		address	- Address of the chart block
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defcommand pchart {{address ds:0}} lib_app_driver.chart
{Usage:
    pchart [<address>]

Examples:
    "pchart"	    	print the chart object at *ds:TemplateChartGroup
    "pchart es:0"	print the chart object at *es:TemplateChartGroup

Synopsis:
    Print information about a chart

Notes:
    * The default <address> is ds:0

See also:
    pparea, paxis, pparams
}
{
	var addr [addr-parse $address]
	var han  [handle id [index $addr 0]]
	var seg  [handle segment [index $addr 0]]

	#
	# Print information about the chart object.
	#
	echo {Chart Group}
	printChartGroup $seg
	echo


	echo {Horiz Comp}
	printChartComp *$seg:[getvalue &TemplateHorizComp]

	echo {VertComp}
	printChartComp *$seg:[getvalue &TemplateVertComp]
	
	#
	# Print information about the plot area.
	#
	printPlotArea $seg


	
}]

##############################################################################
#	printChartComp
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
#	cdb 	2/ 6/92   	Initial Revision
#
##############################################################################
[defsubr    printChartComp {address} {

	printChartObject $address

}]


##############################################################################
#				paxis
##############################################################################
#
# SYNOPSIS:	Print information about an axis
# PASS:		address	- Address of the axis
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 7/91	Initial Revision
#
##############################################################################
[defcommand paxis {{address *ds:si}} lib_app_driver.chart
{Usage:
    paxis [<address>]

Examples:
    "paxis"			print the axis at *ds:si
    "paxis ds:di"		print the axis at ds:di

Synopsis:
    Print information about an axis

Notes:
    * The default <address> is *ds:si

See also:
    pchart, pparams
}
{
	#
	# Print information about the chart object.
	#
	echo {Axis}
	printAxis $address
	echo
}]

##############################################################################
#				pparea
##############################################################################
#
# SYNOPSIS:	Print information about the plot area
# PASS:		address	- Segment containing chart data
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 7/91	Initial Revision
#
##############################################################################
[defcommand pparea {{address ds:0}} lib_app_driver.chart
{Usage:
    pparea [<address>]

Examples:
    "pparea"		print plot area at *ds:TemplatePlotArea
    "pparea es:0"	print plot area at *es:TemplatePlotArea

Synopsis:
    Print information about the plot area

Notes:
    * The default <address> is ds:0

See also:
    pchart, paxis, pparams
}
{
	#
	# Print information about the chart object.
	#
	var addr [addr-parse $address]
	var han  [handle id [index $addr 0]]
	var seg  [handle segment [index $addr 0]]

	print-plot-area-info $seg
	echo
}]

##############################################################################
#				co-flags
##############################################################################
#
# SYNOPSIS:	Figure out a string that represents the chart object flags.
# PASS:		flags	- ChartObjectGeometryFlags
# CALLED BY:	printChartObject
# RETURN:	str 	- String containing the flags
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defsubr co-flags {flags}
{
	var str {}
	
	return $str
}]


##############################################################################
#				printTitle
##############################################################################
#
# SYNOPSIS:	Print info about a title.
# PASS:	    	address - chunk handle of title
# CALLED BY:	pchart
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defcommand ptitle {{address *ds:si}} lib_app_driver.chart
{Usage:
    ptitle <address>

Examples:
    "ptitle"	    	print the title at *ds:si
    "ptitle ds:di"	print the title at ds:di

Synopsis:
    Print information about a chart title object

Notes:
    * The default <address> is *ds:si

See also:
    pparea, paxis, pparams, pchart
}

{
    require getstring cwd.tcl
	#
	# Print the basic chart information.
	#

	printChartObject $address
	
	#
	# Print out the title information
	#

	var t [value fetch $address [sym find type TitleInstance]]
	
	var txt [field $t TI_text]
	addr-preprocess $address seg off
	echo [format {	"%s"} [getstring *$seg:$txt]]
	echo
}]

##############################################################################
#	printChartGroup
##############################################################################
#
# SYNOPSIS:	Print information about the chart group
# PASS:		segreg 
# CALLED BY:	pchart
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defsubr printChartGroup {seg}
{
	global  chart-variations


	#
	# Parse the address.
	#
	var address *$seg:[getvalue &TemplateChartGroup]

	printChartObject $address

	var cg   [value fetch $address [sym find type ChartGroupInstance]]
	
	var typ  [type emap [field $cg CGI_type] [sym find type ChartType]]

	var info [assoc [var chart-variations] $typ]
	var fld  [index $info 1]
	var tp   [index $info 2]

	var vr   [type emap [field [field $cg CGI_variation] $fld]
						[sym find type $tp]]

	var fhan [value fetch kdata:[value fetch $seg:0 [type word]]
						[sym find type HandleMem]]

	echo [format {	Data: ^v%04xh:%04xh   }
		[field $fhan HM_owner]
			[field $cg CGI_data]]

	echo [format {	Type: %s   Variation: %s}
		$typ
		$vr]
	echo

	print-legend-info $seg [field $cg CGI_legend]

}]


##############################################################################
#	print-legend-info
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
#	cdb 	1/28/92   	Initial Revision
#
##############################################################################
[defsubr    print-legend-info {seg chunk} {

	echo Legend:

	if { $chunk != 0 } {
		printChartObject *$seg:$chunk
	} else {
		echo none
	}

}]

##############################################################################
#			printPlotArea
##############################################################################
#
# SYNOPSIS:	Print information about the plot area.
# PASS:		segreg	- Segment of the chart block.
# CALLED BY:	printChartGroup
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/25/91	Initial Revision
#
##############################################################################
[defsubr printPlotArea {segreg}
{
	var address *$segreg:[getvalue &TemplatePlotArea]

	#
	# Print information about the plot area.
	#
	echo {Plot Area}
	printChartObject $address
	echo
	
	#
	# Print information about the axes
	#
	var pa [value fetch $address [sym find type PlotAreaInstance]]
	
	var xAxis [field $pa PAI_xAxis]
	var yAxis [field $pa PAI_yAxis]

	if {$xAxis != 0} {
	    echo {Horizontal Axis}
	    printAxis *($segreg:$xAxis)
	}

	if {$yAxis != 0} {
	    echo {Vertical Axis}
	    printAxis *($segreg:$yAxis)
	}
	echo
}]


##############################################################################
#				printAxis
##############################################################################
#
# SYNOPSIS:	Print information about an axis
# PASS:		address	- Address of the axis
# CALLED BY:	printPlotArea
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/25/91	Initial Revision
#
##############################################################################
[defsubr printAxis {address}
{
    	require format-float    fp.tcl

	#
	# Print general information about the axis.
	#
	addr-preprocess $address seg off

	printChartObject $address

	#
	# Print specific stuff like the plot bounds
	#
	var ai [value fetch $address [sym find type AxisInstance]]
	
	#
	# Show the flags
	#

	echo [format {	Attributes: %s} [axis-attrs [field $ai AI_attr]]]
	echo [format {	Tick attrs: %s} [tick-attrs [field $ai AI_tickAttr]]]


	print-value-or-category-info $address

	#
	# Display related axes
	#
	echo [format {	Related: %04xh  } 
				[field $ai AI_related]]

	# Number of labels
	echo [format {	Number of labels: %d}
				[field $ai AI_numLabels]]
	#
	# Display min/max/etc
	#
	echo [format {	Min: %s   Max: %s   Intersect: %s}
			[format-float [field $ai AI_min]]
			[format-float [field $ai AI_max]]
			[format-float [field $ai AI_intersect]]]

	#
	# Display tick info
	#
	echo [format {	Major: %s   Minor: %s}
			[format-float [field $ai AI_tickMajorUnit]]
			[format-float [field $ai AI_tickMinorUnit]]]



	# Max label size
	var ml [field $ai AI_maxLabelSize]
	echo [format {	Maximum label size X: %d  Y: %d}
			[field $ml P_x]
			[field $ml P_y]]
	#
	# Display plot bounds
	#
	var pb [field $ai AI_plotBounds]

	echo [format {	PlotBounds: (%d,%d),(%d,%d)}
				[field $pb R_left]
				[field $pb R_top]
				[field $pb R_right]
				[field $pb R_bottom]]

	# Display title

	var title [field $ai AI_title]
	if { $title != 0 } {
	    echo {Title}
	    ptitle *($seg:$title)
	}
}]

##############################################################################
#				axis-attrs
##############################################################################
#
# SYNOPSIS:	Get the axis attributes in human readable format
# PASS:		state	- AI_attr field of an axis
# CALLED BY:	printAxis
# RETURN:	str 	- Formatted attributes
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 7/91	Initial Revision
#
##############################################################################
[defsubr axis-attrs {s}
{
	if ([field $s AA_VERTICAL]) {
		var o VERTICAL
	} else {
		var o HORIZONTAL
	}

	if ([field $s AA_OVERLAY]) {
		var ov OVERLAY
	} else {
		var ov PRIMARY
	}

	

	if ([field $s AA_VALUE]) {
		var t VALUE
	} else {
		var t CATEGORY
	}

	if {[field $s AA_USER_SET_BOUNDS]} {
		var u USER_SET
	} else {
		var u UNSET
	}

	return [format {%s %s %s %s }
				$t
		$o
		$u
				$ov]
}]

##############################################################################
#	tick-attrs
##############################################################################
#
# SYNOPSIS: 	print out tick attributes
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
#	cdb 	12/ 2/91		Initial Revision
#
##############################################################################
[defsubr	tick-attrs {s}
{
	if ([field $s ATA_MAJOR_TICKS]) {
		var maj yes
	} else {
		var maj no
	}

	if ([field $s ATA_MINOR_TICKS]) {
		var min yes
	} else {
		var min no
	}

	if ([field $s ATA_LABELS]) {
		var lab yes
	} else {
		var lab no
	}

	return [format {Major: %s	Minor: %s  Labels: %s }
				$maj
		$min
		$lab]

}]

##############################################################################
#	print-series-info
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
#	cdb 	12/10/91		Initial Revision
#
##############################################################################
[defsubr	print-series-info {segreg firstSeries} {
	#
	# Print information about the series themselves
	#
	var addr [addr-parse *$segreg:$firstSeries]
	var han  [handle id [index $addr 0]]
	var seg  [handle segment [index $addr 0]]
	var off  [index $addr 1]

	var hasSeries 0

	[for {var off [value fetch $seg:$off [type word]]}
	 {$off != 0}
	 {var off [value fetch (*$seg:$off).SI_nextSeries [type word]]} {#2

	 var series [value fetch *$seg:$off [sym find type SeriesInstance]]
	 echo [format {Series #%-3d:  *%04xh:%04xh}
			[field $series SI_seriesNum]
			$seg $off]
		 var hasSeries 1
	}]
	
	if {! $hasSeries} {
		echo {No Series}
	}
}]


##############################################################################
#	print-value-or-category-info
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
#	cdb 	12/13/91		Initial Revision
#
##############################################################################
[defsubr	print-value-or-category-info {address} {

	var ai [value fetch $address [sym find type AxisInstance]]

	var attr [field $ai AI_attr]

	if ([field $attr AA_VALUE]) {
		print-value-info $address
	} else {
		print-category-info $address
	}
}]


##############################################################################
#	print-value-info
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
#	cdb 	12/13/91		Initial Revision
#
##############################################################################
[defsubr	print-value-info {address} {

	var vai [value fetch $address [sym find type ValueAxisInstance]]

	echo [format {	First series: %d	 Last series: %d}
				[field $vai VAI_firstSeries]
				[field $vai VAI_lastSeries]
	]

}]


##############################################################################
#	print-category-info
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
#	cdb 	12/13/91		Initial Revision
#
##############################################################################
[defsubr print-category-info {address} {

}]

##############################################################################
#	charttree
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
#	cdb 	6/ 1/92   	Initial Revision
#
##############################################################################
[defcommand charttree {{address nil} {extra nil}} lib_app_driver.chart
{Usage:
    charttree [<address> [<extra-field>]]

Examples:

Synopsis:
    Some day chris might fill this in.

Notes:

See also:

}
{

    require objtree-enum objtree.tcl
    if {[null $address]} {
	var address *ds:[getvalue &TemplateChartGroup]
	}

    echo [objtree-enum $address 0 6 charttreeCB charttree-link charttree-comp $extra]

}]

##############################################################################
#	charttreeCB
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
#	cdb 	6/ 2/92   	Initial Revision
#
##############################################################################
[defsubr    charttreeCB {obj extra} {
    printChartObject $obj
    if {[string c $extra -g] == 0 } {
    	print-grobj-info $obj
    }
}]

##############################################################################
#	print-grobj-info
##############################################################################
#
# SYNOPSIS:	spit out ODs of the grobjects for this chart object
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
#       chrisb 	12/17/92   	Initial Revision
#
##############################################################################
[defsubr    print-grobj-info {obj} {

    if {[is-obj-in-class $obj ChartObjectMultipleClass]} {
	pobjarray $obj.COMI_array1
	pobjarray $obj.COMI_array2
    } elif {[is-obj-in-class $obj ChartObjectDualClass]} {
	_print ($obj).CODI_grobj1
	_print ($obj).CODI_grobj2
    } else {
	    _print ($obj).COI_grobj
    }
}]

##############################################################################
#	charttree-link
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
#	cdb 	6/ 1/92   	Initial Revision
#
##############################################################################
[defsubr    charttree-link {obj} {

    var addr [addr-parse $obj]
    var hid [handle id [index $addr 0]]
    var off [index $addr 1]
    return  [fetch-optr	$hid $off.COI_link]

}]



##############################################################################
#	charttree-comp
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
#	cdb 	6/ 1/92   	Initial Revision
#
##############################################################################
[defsubr    charttree-comp {obj} {

	var addr [addr-parse $obj]
	var hid [handle id [index $addr 0]]
	var off [index $addr 1]

    if {[is-obj-in-class $obj ChartCompClass]} {
	return  [fetch-optr	$hid $off.chart::CCI_comp]
    } elif {[is-obj-in-class $obj ChartBodyClass]} {
	return  [fetch-optr	$hid $off.chart::CBI_comp]
    } 
    return nil
}]
