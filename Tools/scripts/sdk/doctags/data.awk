###############################################################################
#
# This searches for instance data and vardata.
#
# $Id: data.awk,v 1.1 94/01/12 18:31:06 joon Exp $
#
###############################################################################

/@instance/ {
    if ((NF >= 3) && match($1, /@instance/))
    {
	if (match($3, /[A-z0-9_]/))
	    i = 3
	else
	    i = 4
	gsub(/[^A-z0-9_]/, "", $i)
	outputLine = sprintf("%s:%s:%d", $i, FILENAME, NR)
	printf("%-100s\n", outputLine)
    }
}


/@vardata/ {
    if ((NF >= 3) && match($1, /@vardata/))
    {
	gsub(/[^A-z0-9_]/, "", $3)
	outputLine = sprintf("%s:%s:%d", $3, FILENAME, NR)
	printf("%-100s\n", outputLine)
    }
}
