###############################################################################
#
# This section searches for "^DOC:" followed by a series of keywords separated
# by commas.  The series of keywords may span multiple lines.
#
# $Id: doc.awk,v 1.4 96/09/18 01:25:55 joon Exp $
#
###############################################################################

#
# 'nDoc' was used to adjust the line number to account for the fact that the
# "^DOC:" lines were stripped out before being sent out on the sdk.  But since
# it appears that this is no longer happening ("^DOC:" lines being stripped),
# we no longer need 'nDoc'.
#

BEGIN { nDoc = 0 }

/^DOC:/ {

    if (match($2, /,/))
    {
	#
	# "^DOC:" followed by a list of keywords separated
	# by commas.
	#

	readnext = match($NF, /,/)

	for (i = 2; i <= NF; i++) {
	    gsub(/[^A-z0-9_\-]/, "", $i)
#	    nr = NR + 1 - nDoc
	    nr = NR
	    if (nr < 1)
		nr = 1
	    outputLine = sprintf("%s:%s:%d", $i, FILENAME, nr)
	    printf("%-100s\n", outputLine)
#	    nDoc = nDoc + 1
	}

	while (readnext)
	{
	    if (getline == 0)
		next

	    readnext = match($NF, /,/)

	    for (i = 1; i <= NF; i++) {
		gsub(/[^A-z0-9_\-]/, "", $i)
#		nr = NR + 1 - nDoc
		nr = NR
		if (nr < 1)
		    nr = 1
		outputLine = sprintf("%s:%s:%d", $i, FILENAME, nr)
		printf("%-100s\n", outputLine)
#		nDoc = nDoc + 1
	    }
	}
    }
    else if (NF == 2)
    {
	#
	# Simple case of "^n\t" followed by single keyword.
	#

	gsub(/[^A-z0-9_\-]/, "", $2)
#	nr = NR + 1 - nDoc
	nr = NR
	outputLine = sprintf("%s:%s:%d", $2, FILENAME, nr)
	printf("%-100s\n", outputLine)
#	nDoc = nDoc + 1
    }
}
