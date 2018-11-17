###############################################################################
#
# This search for typedef's.
#
# $Id: typedef.awk,v 1.1 94/01/12 18:31:18 joon Exp $
#
###############################################################################

/typedef/ {
    if (match($1, /typedef/))
    {
	if (match($0, /\{/))
	{
	    #
	    # typedef /typedefType/ {
	    #  	/type/	<keyword>;
	    #  	/type/	<keyword>;
	    #	.
	    #	.
	    #	<keyword>,
	    #	<keyword>
	    #	.
	    #	.
	    # } <keyword>;
	    #

	    if (match($0, /\}/))
	    {
		for (i = 1; i <= NF; i++)
		    if (match($i, /\}/))
		    {
			gsub(/[^A-z0-9_]/, "", $(i+1))
			outputLine = sprintf("%s:%s:%d", $(i+1), FILENAME, NR)
			printf("%-100s\n", outputLine)
			next
		    }
	    }	

	    readnext = 1

	    while (readnext)
	    {
		if (getline == 0)
		    next

		if (match($1, /\}/))
		{
		    gsub(/[^A-z0-9_]/, "", $2)
		    outputLine = sprintf("%s:%s:%d", $2, FILENAME, NR)
		    printf("%-100s\n", outputLine)
		    readnext = 0
		}
		else if (match($1, /,/))
		{
		    gsub(/[^A-z0-9_]/, "", $1)
		    outputLine = sprintf("%s:%s:%d", $1, FILENAME, NR)
		    printf("%-100s\n", outputLine)
		}
		else
		{
		    for (i = 1; i <= NF; i++)
		    {
			if (match($i, /;/))
			{
			    if (match($i, /[A-z0-9_]+\[[A-z0-9_]*\]/))
			    {
				gsub(/\[[A-z0-9_]*\]/, "", $i)
				gsub(/[^A-z0-9_]/, "", $i)
				outputLine = sprintf("%s:%s:%d", $i, FILENAME, NR)
				printf("%-100s\n", outputLine)
			    }
			    else if (match($i, /.*\(\)/))
			    {
				#
				# Ex. (*function)();
				#
				gsub(/[^A-z0-9_]/, "", $i)
				outputLine = sprintf("%s:%s:%d", $i, FILENAME, NR)
				printf("%-100s\n", outputLine)
			    }
			    else if (match($i, /\[[A-z0-9_]*\]/) || 
				match($i, /\(\)/))
			    {
				gsub(/\[[A-z0-9_]*\]/, "", $(i-1))
				gsub(/[^A-z0-9_]/, "", $(i-1))
				outputLine = sprintf("%s:%s:%d", $(i-1), FILENAME, NR)
				printf("%-100s\n", outputLine)
			    }
			    else
			    {
				gsub(/[^A-z0-9_]/, "", $i)
				outputLine = sprintf("%s:%s:%d", $i, FILENAME, NR)
				printf("%-100s\n", outputLine)
			    }
			}
		    }
		}
	    }
	}
	else if (match($NF, /;/))
	{
	    #
	    # typedef /typedefType/ <keyword>;
	    #

	    gsub(/\[.*\]/, "", $3)
	    gsub(/[^A-z0-9_]/, "", $3)
	    outputLine = sprintf("%s:%s:%d", $3, FILENAME, NR)
	    printf("%-100s\n", outputLine)
	}
    }
}
