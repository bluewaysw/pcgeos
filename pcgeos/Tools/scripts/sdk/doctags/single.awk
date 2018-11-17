###############################################################################
#
# This searches for a keyword at the beginning of a line
#
# $Id: single.awk,v 1.1 94/01/12 18:31:15 joon Exp $
#
###############################################################################

/[A-Z0-9_]+_[A-Z0-9_]+/ {
    if (match($1, /_/)  && !match($1, /[^A-Z0-9_]/)) {
	gsub(/^\t/, "")

	if ((NF == 1) || match($0, /\t/)) {
	    outputLine = sprintf("%s:%s:%d", $1, FILENAME, NR)
	    printf("%-100s\n", outputLine)
	}
    }
}
