# $Id: wproc.tcl,v 1.4 93/07/31 21:41:25 jenny Exp $
[defcmd wproc {name file {append 0}} swat_prog
{Writes a command procedure NAME out to the file FILE. If optional third
arg APPEND is non-zero, the procedure will be appended to the file. Otherwise
it will overwrite the file. This does not know if a procedure is a subroutine.}
{
    [var args [info args $name] body [info body $name] pargs {}
     	 help [index [help-get $name] 0]]
    
    map i $args {
    	if {[info default $name $i def]} {
	    [list $i $def]
	} else {
	    var i
    	}
    }
    if {$append} {var mode a} {var mode w}
    var s [stream open $file $mode]
    if {[null $s]} {
    	error [format {couldn't open %s} $file]
    } else {
    	stream write [list defcmd $name $pargs $help $body] $s
	stream close $s
    }
}]

