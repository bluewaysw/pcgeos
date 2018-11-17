##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	printq.tcl
# AUTHOR: 	Jim DeFrisco, April 4, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	pq			Output interesting things about the print queue
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/29/89		Initial Revision
#
# DESCRIPTION:
#	Functions for print spooler 
#
#	$Id: printq.tcl,v 1.11.11.1 97/03/29 11:25:10 canavese Exp $
#
###############################################################################
defsubr qstring {addr} {
	
    return [mapconcat c [value fetch $addr] {
    	if {[string c $c \\000] == 0} {
	    break
	} else {
	    var c
    	}
    }]
}


#
# pq
#	Print out the current contents of the print queues
#
[defcmd pq {} lib_app_driver.spool
{Prints out the contents of the current print queues.}
{
	#
	# get ptr to spooler queue block 
	# and check for valid PrintQueue block
	#
	var qhan [value fetch spool::queueHandle [type word]]
	var a [addr-parse ^h$qhan:0]
	var seg [handle segment [index $a 0]]

	if {!$qhan} {
		#
		# print queue is empty
		#
		echo Print queue is empty
	} else {
		#
		# else there's something to print, so print out some info
		# get some info out of the header of the block first
		#
		var nJobs [value fetch $seg:PQ_numJobs [type word]]
		var nQueues [value fetch $seg:PQ_numQueues [type word]]
		var q [value fetch $seg:PQ_firstQueue [type word]]
		var qAddr [addr-parse ^l$qhan:$q]
		var qOff [index $qAddr 1]
		#
		# for each queue in the system, print out the jobs there
		#
    	    	var jis [symbol find type spool::JobInfoStruct]
    		[for {}
	 	     {$q != 0}
	 	     {var q [value fetch $seg:$qOff.QI_next [type word]]}
		{
		    var qAddr [addr-parse ^l$qhan:$q]
		    var qOff [index $qAddr 1]
		    echo 
		    echo -n {Print queue for: }
		    echo [qstring $seg:$qOff.QI_device]
		    var linefmt {%3s  %-6s  %-20s  %-13s  %-5s  %-8s  %.4s %3s}
		    echo [format $linefmt pos port parent file page time mode { @ }]
		    echo [format $linefmt --- ---- ------ ---- ---- ---- ---- ---]
		    var j [value fetch $seg:$qOff.QI_curJob [type word]]
		    var jAddr [addr-parse ^l$qhan:$j]
		    var jOff [index $jAddr 1]
		    #
		    # for each job in the queue, print out some info
		    #
    		    [for {var num 1}
	 	         {$j != 0}
	 	         {var j [value fetch $seg:$jOff.JIS_next [type word]]
			  var jAddr [addr-parse ^l$qhan:$j]
		          var jOff [index $jAddr 1]
			  var num [expr $num+1]
			 }
		    {
    	    	    	var hnum [value hstore [concat [range $jAddr 0 1]
			    	    	    	    [list $jis]]]
			
			var mode [value fetch $seg:$jOff.JIS_info.JP_printMode [type byte]]
			var hour [value fetch $seg:$jOff.JIS_time.STS_hour [type byte]]
			var min [value fetch $seg:$jOff.JIS_time.STS_minute [type byte]]
			var sec [value fetch $seg:$jOff.JIS_time.STS_second [type byte]]
			var amode [penum PrinterMode $mode]
			var ptype [penum PrinterPortType [value fetch $seg:$jOff.JIS_info.JP_portInfo.PPI_type]]
			[case $ptype in
			    PPT_CUSTOM {var port CUSTOM}
			    PPT_NOTHING {var port NULL}
			    PPT_FILE {var port FILE}
			    PPT_PARALLEL {var port LPT[expr [value fetch $seg:$jOff.JIS_info.JP_portInfo.PPI_params.PP_parallel.PPP_portNum]/2+1]}
			    PPT_SERIAL {var port COM[expr [value fetch $seg:$jOff.JIS_info.JP_portInfo.PPI_params.PP_serial.SPP_portNum]/2+1]}
			    default {var port ?}
    	    	    	]
			[case $amode in
			 PM_TEXT_NLQ {var amode NLQ}
			 PM_TEXT_DRAFT {var amode DRAFT}
			 PM_GRAPHICS_HI_RES {var amode HIGH}
			 PM_GRAPHICS_MED_RES {var amode MED}
			 PM_GRAPHICS_LOW_RES {var amode LOW}
    	    	    	]
			if {$num == 1} {
			    var int [value fetch $seg:$qOff.QI_error]

			    if {$int != 0} {
				var int [index [type emap $int [symbol find type spool::SpoolInterruptions]] 3 char]/
			    } else {
				var int {}
			    }

			    var pos act pgstr ${int}[expr [value fetch $seg:$qOff.QI_curPage]+1]
			} else {
			    var pos $num pgstr {}
			}
			echo [format $linefmt $pos $port [qstring $seg:$jOff.JIS_info.JP_parent]
			    	[qstring $seg:$jOff.JIS_info.JP_fname] $pgstr
			    	[format {%02d:%02d:%02d} $hour $min $sec]
				$amode $hnum]
		    }]

		}]
	}
}]
