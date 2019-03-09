

[defcommand mcount {} object
{Gives count of method calls}
{
    global	mvar _mbrk

    var mvar 0
    var _mbrk [brk aset CallMethod _mincr]
}]

defsubr _mincr {} {
    global	mvar

    var mvar [expr $mvar+1]
    return 0
}
