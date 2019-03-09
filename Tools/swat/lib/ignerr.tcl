[defsubr ignerr {{addr {}}}
{
    var f [frame next [frame top]] i 2
    if {[string c [frame function $f] AppFatalError] == 0} {
    	var f [frame next $f] i 4
    }
    assign sp [frame register sp $f]+$i
    if {[null $addr]} {
	assign ip [frame register ip $f]+3
	assign cs [frame register cs $f]
    } else {
    	var a [addr-parse $addr]
	assign ip [index $a 1]
	assign cs [handle segment [index $a 0]]
    }
    cont
}]
