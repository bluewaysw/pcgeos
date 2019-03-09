
[defcmd selector-and-offset-from-addr {args} top.protected_mode
{Usage:
    selector-and-offset-from-addr <addr or value>

Examples:
    selector-and-offset-from-addr cs         returns cs 0
    selector-and-offset-from-addr 0x19f      returns 0x19f 0
    selector-and-offset-from-addr cs:ip      returns cs ip
    selector-and-offset-from-addr ^h0x1800   returns selector of handle 0
    selector-and-offset-from-addr &Routine   returns Routine's selector offset

Synopsis:
    I got tired of trying to figure out how to evaluate an address
    into it's selector and offset parts.  This solves it.
    Given any address or 16-bit value, this command returns
    the 16-bit selector identifier to the selector followed by the
    offset (if any, else returns 0)
}
{
    var addr [addr-parse $args 0]

    if {[null $addr]} {
        error [concat Couldn't parse the address '$selector'.]
    }
    if {[index $addr 0] == value}  {
        var sel [index $addr 1]
	if {$sel > 65535} {
	    var offset [expr ($sel&65535)]
	    var sel [expr ($sel>>16)]
	} else {
	    var offset 0
	}
    } else {
        if {[index $addr 0] == nil}  {
            var sel [index $addr 1]
            if {$sel > 65535} {
                var offset [expr ($sel&65535)]
                var sel [expr ($sel>>16)]
            } else {
                var offset 0
            }
        } else {
            var sel [handle segment $addr]
	    var offset [index $addr 1]
        }
    }

    return [list $sel $offset]
}]
    
[defcmd	desc-get-linear-addr  {selector} top.protected_mode
{Usage:
    desc-get-addr <selector>

Synopsis:
    Returns the linear address of the given selector or returns 0 if not found

Output:
    32-bit linear address
} {

    var splitaddr [selector-and-offset-from-addr $selector]
    var sel [index $splitaddr 0]
    var offset [index $splitaddr 1]
    var desc [rpc call RPC_GPMI_GET_DESCRIPTOR [type word] $sel
                  [type make array 8 [type byte]]]
    var base [expr [index $desc 2]|([index $desc 3]<<8)|([index $desc
4]<<16)|([index $desc 7]<<24)]

    return [expr ($base+$offset)]
}]
