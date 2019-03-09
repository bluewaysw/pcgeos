[defsubr check-handles {args}
{
    map i [handle all] {
	var h [handle lookup $i]
	if {[handle ismem $h] && ([handle state $h]&0x480) == 0} {
	    if {([value fetch kdata:$i.HM_flags [type byte]] & 4) == 0 &&
		([handle state $h] & 0x200)} {
		echo Warning: handle [format %04x $i] attached but debug bit clear
	    }
	}
    }
    return EVENT_HANDLED
}]

event handle FULLSTOP check-handles
