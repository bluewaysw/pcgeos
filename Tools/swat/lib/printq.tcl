##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	printq.tcl
# AUTHOR: 	Jim DeFrisco, April 4, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	qwatch			Output interesting things about the print queue
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/29/89		Initial Revision
#
# DESCRIPTION:
#	Functions for print spooler 
#
#	$Id: printq.tcl,v 1.1 90/04/05 11:50:44 jim Exp $
#
###############################################################################
defsubr qstring {addr newline} {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    [for {var c [value fetch $s:$o [type byte]]}
	 {$c != 0}
	 {var c [value fetch $s:$o [type byte]]}
    {
        echo -n [format %c $c]
        var o [expr $o+1]
    }]
    if {$newline} {
        echo 
    }
}


#
# pq
#	Print out the current contents of the print queues
#
[defcommand pq {} output
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
    		[for {}
	 	     {$q != 0}
	 	     {var q [value fetch $seg:$qOff.QI_next [type word]]}
		{
		    var qAddr [addr-parse ^l$qhan:$q]
		    var qOff [index $qAddr 1]
		    echo 
		    echo -n {Print queue for: }
		    qstring $seg:$qOff.QI_device 1
		    echo [format {pos\tparent\t\tfile\t\ttime\t\tmode}]
		    echo [format {---\t------\t\t----\t\t----\t\t----}]
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
			var mode [value fetch $seg:$jOff.JIS_info.JP_printMode [type byte]]
			var hour [value fetch $seg:$jOff.JIS_time.STS_hour [type byte]]
			var min [value fetch $seg:$jOff.JIS_time.STS_minute [type byte]]
			var sec [value fetch $seg:$jOff.JIS_time.STS_second [type byte]]
			var amode [prenum PrinterModes $mode]
			if {$num == 1} {
			    echo -n [format {active\t}]
			} else {
			    echo -n [format {%d\t} $num]
			}
			qstring $seg:$jOff.JIS_info.JP_parent 0
			echo -n [format {\t}]
			qstring $seg:$jOff.JIS_info.JP_fname 0
			echo [format {\t%02d:%02d:%02d\t%s} $hour $min 
							    $sec $amode ]
		    }]

		}]
	}
}]
