##############################################################################
#
# 	Copyright (c) Geoworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Tools/scripts -- branchpoint analysis
# FILE: 	bpData.awk
# AUTHOR: 	John Wedgwood,  9/17/93
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/17/93	Initial Revision
#
# DESCRIPTION:
#	This file contains the awk stuff for branchpoint analyis.
#
#	$Id: bpData.awk,v 1.4 93/09/17 16:51:43 john Exp $
#
###############################################################################

BEGIN {
    #
    # Initialize the current function to something useful.
    #
    found = 0
    func = "unknown"
}

#############################################################################
#		   Identify the branch instructions
#
# Update the count of the number of branches
#
# Branches are:
#	jcxz
#	jz, je, ja, jb, jg, jl, jc
#	jnz, jne, jna, jnb, jng, jnl, jnc
#	jae, jbe, jge, jle
#	jnae, jnbe, jnge, jnle
#	LONG <followed by any of the basic branches>
#	signed dw instructions
#	signed dwf instructions
#	signed wwf instructions
#	signed wbf instructions
#
/^[ 	]+jcxz[ 	]+/ || \
/^[ 	]+j[zeabglc][ 	]+/ || \
/^[ 	]+jn[zeabglc][ 	]+/ || \
/^[ 	]+j[abgl]e[ 	]+/ || \
/^[ 	]+jn[abgl]e[ 	]+/ || \
/^[ 	]+LONG[ 	]+j[zeabglc][ 	]+/ || \
/^[ 	]+LONG[ 	]+jn[zeabglc][ 	]+/ || \
/^[ 	]+LONG[ 	]+j[abgl]e[ 	]+/ || \
/^[ 	]+LONG[ 	]+jn[abgl]e[ 	]+/ || \
/^[ 	]+j[gl]dw[ 	]+/ || \
/^[ 	]+jn[gl]dw[ 	]+/ || \
/^[ 	]+j[gl]edw[ 	]+/ || \
/^[ 	]+jn[gl]edw[ 	]+/ || \
/^[ 	]+j[gl]dwf[ 	]+/ || \
/^[ 	]+jn[gl]dwf[ 	]+/ || \
/^[ 	]+j[gl]edwf[ 	]+/ || \
/^[ 	]+jn[gl]edwf[ 	]+/ || \
/^[ 	]+j[gl]wwf[ 	]+/ || \
/^[ 	]+jn[gl]wwf[ 	]+/ || \
/^[ 	]+j[gl]ewwf[ 	]+/ || \
/^[ 	]+jn[gl]ewwf[ 	]+/ || \
/^[ 	]+j[gl]wbf[ 	]+/ || \
/^[ 	]+jn[gl]wbf[ 	]+/ || \
/^[ 	]+j[gl]ewbf[ 	]+/ || \
/^[ 	]+jn[gl]ewbf[ 	]+/ \
{
    #
    # It is a conditional branch, up the counter
    #
    branches[func] = branches[func]+1
}

#############################################################################
# Identify method and procedure definitions
#
$2 == "proc" || $2 == "method" {
    func = $1
    branches[func] = 0
    found = 1
}

END {
    #
    # Dump the list of functions with their various counts
    #
    # Lines are preceded with a value that indicates their position in the
    # output, with higher numbers going first.
    #
    if (found) {
	total=0
	count=0
	bigCount = 0
	for (i in branches) {
	    #
	    # Print the function
	    #
	    printf "100 %-50s %3d\n", i, branches[i]
	    
	    #
	    # Update our totals
	    #
	    total = total + branches[i]
	    count = count + 1
	    
	    if (branches[i] > 10) {
	        bigCount = bigCount + 1
	    }
        }
	printf "050 --------------------------------------------------------\n"

	printf "025 %3d functions, avg branch count: %d\n", count, total/count
	
	printf "010 %3d function(s) with branch counts > 10\n", bigCount

    } else {
        print "000 No functions were found"
    }
}
