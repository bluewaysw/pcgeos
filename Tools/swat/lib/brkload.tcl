# $Id: brkload.tcl,v 1.1 90/03/18 19:38:27 andrew Exp $
[defdsubr brkload {{handle {}}} top
{Stop the machine when the data for the given handle (a handle ID) is loaded}
{
    global brkload_interest
    if {![null $brkload_interest]} {
    	handle nointerest $brkload_interest
    }
    if {![null $handle]} {
    	var h [handle lookup $handle]
    	var brkload_interest [handle interest $h brkload-interest-proc
    	    	    	    [handle id $h]]
    }
}]

[defsubr brkload-interest-proc {h change hid}
{
    [case $change in
     load|swapin {
	echo [format {Handle %04xh loaded} $hid]
     	stop-patient
     }]
}]
