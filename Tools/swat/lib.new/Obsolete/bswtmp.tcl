require get-address memory
defvar sbase e000h

[proc setbp {addr type}
{
    global sbase

    var n [index [assoc {{inta 0}
			 {rio 0x10}
			 {wio 0x20}
			 {halt 0x30}
			 {ifetch 0x40}
			 {rmem 0x50}
			 {wmem 0x60}
			 {none 0x70}} $type] 1]

    var a [addr-parse [get-address $addr]]
    if {[null [index $a 0]]} {
	var ad [index $a 1]
    } else {
	var ad [expr ([handle segment [index $a 0]]<<4)+[index $a 1]]
    }

    dcache off

    assign {word $sbase:3ff3h} 0
    assign {word $sbase:3ff7h} $ad
    assign {byte $sbase:3ff9h} [expr (($ad>>16)&0xf)|$n]

    assign {byte $sbase:3ffbh} 0
    assign {word $sbase:3ffch} ffffh
    assign {byte $sbase:3ffeh} ffh
    assign {byte $sbase:3fffh} 0
    var p [io 61h]
    var h [string first h $p]
    io 61h [expr [format {0x%s&~0x30} [range $p 0 [expr $h-1] char]]]
    assign {word $sbase:3ff3h} fffeh
    assign {byte $sbase:3ff5h} 4

    dcache on
#    var s [dcache params]
#    dcache bsize 0
#    dcache bsize [index $s 0]
}]

[proc binit {base}
{
    global sbase

    dcache bsize 0

    var sbase ${base}000h

    io 31fh ${base}h

    assign {byte $sbase:3ff5h} 16
    assign {byte $sbase:3ff5h} 0
}]
