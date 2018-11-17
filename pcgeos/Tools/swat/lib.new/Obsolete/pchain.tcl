[proc pchain {addr}
{
    var el [value fetch ($addr).VCI_firstChunk] ap [addr-parse $addr]
    var seg [handle segment [index $ap 0]]

    while {$el != 0xffff && ![irq]} {
	print VisInstance *$seg:$el
	var el [value fetch (*$seg:$el).VI_nextChunk]
    }
}]
