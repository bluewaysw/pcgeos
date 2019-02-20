[defsubr prof {who {interval .5}}
{
    continue-patient
    switch $who
    do {
    	var regs [current-registers]
	var cs [index $regs 9] ip [index $regs 12]
	var s [symbol faddr func $cs:$ip]
	if {![null $s]} {
	    echo [symbol fullname $s]
	} else {
	    echo [format {%04x:%04x} $cs $ip]
	}
    } while {[sleep $interval] && ![break-taken]}
    if {![break-taken]} {
    	stop-patient
    	event dispatch FULLSTOP {PC Halted}
    }
}]
