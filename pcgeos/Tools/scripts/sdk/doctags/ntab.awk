###############################################################################
#
# This searches for "^n\t" followed by a series of keywords separated
# by commas.  The series of keywords may span multiple lines.
#
# Note:	A list of words not separated by commas are not considered keywords
#	since they are normally section titles and not really keywords.
#
# $Id: ntab.awk,v 1.1 94/01/12 18:31:13 joon Exp $
#
###############################################################################

/^n\t/ {

    if (match($2, /,/))
    {
	#
	# "^n\t" followed by a list of keywords separated
	# by commas.
	#

	readnext = match($NF, /,/)

	for (i = 2; i <= NF; i++) {
	    gsub(/[^A-z0-9_\-]/, "", $i)
	    outputLine = sprintf("%s:%s:%d", $i, FILENAME, NR)
	    printf("%-100s\n", outputLine)
	}

	while (readnext)
	{
	    if (getline == 0)
		next

	    readnext = match($NF, /,/)

	    for (i = 1; i <= NF; i++) {
		gsub(/[^A-z0-9_\-]/, "", $i)
		outputLine = sprintf("%s:%s:%d", $i, FILENAME, NR)
		printf("%-100s\n", outputLine)
	    }
	}
    }
    else if (NF == 2)
    {
	#
	# Simple case of "^n\t" followed by single keyword.
	#

	gsub(/[^A-z0-9_\-]/, "", $2)
	outputLine = sprintf("%s:%s:%d", $2, FILENAME, NR)
	printf("%-100s\n", outputLine)
    }
}
