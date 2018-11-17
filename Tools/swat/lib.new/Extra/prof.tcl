#$Id: prof.tcl,v 3.2.30.1 97/03/29 11:28:13 canavese Exp $
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
	    echo [format {%04xh:%04xh} $cs $ip]
	}
    } while {[sleep $interval] && ![break-taken]}
    if {![break-taken]} {
    	stop-patient
    	event dispatch FULLSTOP {PC Halted}
    }
}]
