#!/bin/awk -f
BEGIN {
    ignore=0
    igtop=0
}
{
    if ($1 ~ /\[include/ && $2 ~ /.*\.def/) {
	ignorestack[igtop++] = ignore
	if (seen[$2]) {
	    ignore=1
	} else {
	    ignore=0
	}
	seen[$2]=1
    } else if ($1 ~ /\[endinclude/ && $2 ~ /.*\.def/) {
	oig = ignore
	ignore = ignorestack[--igtop]
	if (oig) {
	    next
	}
    }

    if ( ! ignore) {
	print
    }
}
