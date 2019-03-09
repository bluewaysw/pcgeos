proc pstring addr {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    [for {var c [value fetch $s:$o byte]}
	 {$c != 0}
	 {var c [value fetch $s:$o byte]}
    {
        echo -n [format %c $c]
        var o [expr $o+1]
    }]
    echo
}