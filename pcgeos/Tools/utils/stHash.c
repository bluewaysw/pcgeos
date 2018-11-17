/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stHash.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  4, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Hash function for string table.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: stHash.c,v 1.7 92/06/03 16:34:57 adam Exp $";
#endif lint

#include <config.h>
#include "stInt.h"


/***********************************************************************
 *				STHash
 ***********************************************************************
 * SYNOPSIS:	    Hash a string to one of a table's buckets
 * CALLED BY:	    ST_Enter, ST_Lookup (INTERNAL)
 * RETURN:	    The bucket index
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 4/89		Initial Revision
 *
 ***********************************************************************/
int
STHash(const char *name,    	/* String to hash */
       int  	len,	    	/* Length of name */
       word 	*hashvalPtr)	/* Place to store actual hash value */
{
    const byte 	*cp;
    word    	hashval;

    /*
     * Sum all the characters in the string and the length of the string,
     * multiplying the sum by 7 before adding in each character. '7'
     * because it's prime and < 16 (we've only got a word, remember). Multiply
     * because...
     */
    for (hashval = len, cp = (const byte *)name; len > 0; len -= 1) {
	hashval = (hashval << 3) - hashval + *cp++;
    }

    /*
     * Bring the resulting sum within range of the hash table.
     */
    *hashvalPtr = hashval;
    return(ST_HASH_TO_BUCKET(hashval));
}
