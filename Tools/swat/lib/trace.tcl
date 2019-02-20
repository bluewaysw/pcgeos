[defcommand trace {{addr {}}} whiffle
{}
{
    if {![null $addr]} {
    	var dest [addr-parse $addr]
    } else {
    	var dest {}
    }

    #
    # See if the current patient is the current thread on the PC. The simplest
    # way to do this is to get the current patient stats, switch to the real
    # current thread and see if its patient stats are the same as the ones
    # we've got saved.
    #
    var cp [patient data]
    switch
    if {[string c $cp [patient data]]} {
    	#
	# Nope. Need to wait for the desired patient to wake up.
	#
    	var who [index $cp 0]:[index $cp 2]
	echo Waiting for $who to wake up
	if {![wakeup-thread $who]} {
    	    #
	    # Wakeup unsuccessful -- return after dispatching the proper
	    # FULLSTOP event.
	    #
	    event dispatch FULLSTOP $lastHaltCode
	    return
    	}
	event dispatch FULLSTOP _DONT_PRINT_THIS_
    }

    for {} {[string c [addr-parse cs:ip] $dest]} {if {[break-taken]} break} {
    	var inst [unassemble cs:ip 1]

	format-instruction $inst
	
	safe-step
    }
}]
