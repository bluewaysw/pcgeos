/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat/Esp -- String Table Manipulation
 * FILE:	  string.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 20, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	String_Enter	    Enter a string into the table and return
 *	    	    	    its identifier (an address peculiar to that
 *	    	    	    string [i.e. if ever entered again, the
 *	    	    	    same value will be returned]).
 *	String_Lookup	    See if a string is already in the table and
 *	    	    	    return its identifier if so.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/20/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions in this file implement the string table for scanning.
 *	Uniqueness is guaranteed.
 *
 *	The intent is to store only one copy of each identifier
 *	string. The strings are never freed.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: stringt.c,v 1.3 92/11/21 18:53:26 josh Exp $";
#endif lint

#if	defined(ISSWAT)
#include    "swat.h"
#include    "cmd.h"
#define malloc(nb) malloc_tagged(nb, TAG_ID)
#endif	/* ISSWAT */
#include "goc.h"
#include    "stringt.h"
#include <string.h>
#include <malloc.h>

typedef struct _HashElt {
   char	    	    *string;   	/* The string itself */
   int	    	    length;    	/* The length of the string */
   struct _HashElt  *next;  	/* Next in chain */
} HashElt;

static char	    *nextString;    /* Place to store next string */
static int  	    bytesLeft;	    /* Number of bytes in chunk after
				     * nextString */
#define BYTES_PER_CHUNK	1024	    /* Allocate space a K at a time */
#define ELTS_PER_CHUNK	128 	    /* Number of HashElts to allocate
				     * at a time */
#define HASH_SIZE   	1033
static HashElt	    *hashTable[HASH_SIZE];  /* Hash table chains */
static HashElt	    *nextElt;	    /* Next element to use */
static int  	    numElts;	    /* Number of elements left at nextElt */


/***********************************************************************
 *				StringHash
 ***********************************************************************
 * SYNOPSIS:	    Hash a string, of course.
 * CALLED BY:	    String_Enter
 * RETURN:	    The bucket in which the string should reside.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/23/89		Initial Revision
 *
 ***********************************************************************/
static int
StringHash(char	    *string,
	   int	    length)
{
    char        *cp;
    unsigned    hash;
    for (hash = length, cp = string; length >= 0; cp += 1, length -= 1) {
	hash += *cp;
    }
    return((hash*1103515245 + 12345) % HASH_SIZE);
}

/***********************************************************************
 *				String_Enter
 ***********************************************************************
 * SYNOPSIS:	    Enter a string into the table, returning its
 *	    	    new address.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The address where the string may be found
 * SIDE EFFECTS:    Things may be added to the table
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/23/89		Initial Revision
 *
 ***********************************************************************/
ID
String_Enter(char   *string,
	     int    length)
{
    int	    	bucket;
    HashElt 	*hep;

    bucket = StringHash(string, length);

    for (hep = hashTable[bucket]; hep != NULL; hep = hep->next) {
	if ((hep->length == length) && (hep->string[0] == string[0]) &&
	    (strcmp(hep->string, string) == 0))
	{
	    break;
	}
    }
    
    if (hep == NULL) {
	/*
	 * Fetch a new HashElt and link it into the chain
	 */
	if (numElts == 0) {
	    /*
	     * None left -- allocate another chunk of them...
	     */
	    nextElt = (HashElt *)malloc(ELTS_PER_CHUNK * sizeof(HashElt));
	    numElts = ELTS_PER_CHUNK;
	}
	
	hep = nextElt++;
	numElts -= 1;
	
	/*
	 * Link it in
	 */
	hep->next = hashTable[bucket];
	hashTable[bucket] = hep;
	
	/*
	 * Make sure there's enough room in the chunk for this string.
	 * Note that we tend to waste space if we need to allocate a new
	 * chunk, but this stuff is fairly time-critical, so we can afford
	 * to waste some space rather than realloc the thing to the exact
	 * size...
	 */
	if (length+1 > bytesLeft) {
	    if (length+1 > BYTES_PER_CHUNK) {
		/*
		 * Bigger than your average chunk -- just give it a block
		 * to its ownself
		 */
		hep->string = (char *)malloc(length+1);
	    } else {
		nextString = (char *)malloc(BYTES_PER_CHUNK);
		/*
		 * Set bytes remaining in chunk, taking into account the
		 * number of bytes we're snarfing for the string.
		 */
		bytesLeft = BYTES_PER_CHUNK - (length + 1);
		/*
		 * Point the record at the proper storage location in the new
		 * chunk and advance nextString beyond it.
		 */
		hep->string = nextString;
		nextString += length + 1;
	    }
	} else {
	    hep->string = nextString;
	    nextString += length + 1;
	    bytesLeft -= length + 1;
	}
	
	/*
	 * Set up the HashElt first
	 */
	hep->length = length;

	/*
	 * Then perform the copy. Note we use bcopy rather than strcpy since
	 * we know how long the thing is. There's no point in forcing it to
	 * examine each byte. Might as well just blast the characters into
	 * their allotted space...
	 */
	memcpy(hep->string, string, length+1);

    }
    return ((ID)hep->string);
}

/***********************************************************************
 *				String_EnterNoLen
 ***********************************************************************
 * SYNOPSIS:	    Front-end for String_Enter when length of string
 *	    	    not known.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ID for string
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 8/89		Initial Revision
 *
 ***********************************************************************/
ID
String_EnterNoLen(char	*str)
{
    return(String_Enter(str, strlen(str)));
}

/***********************************************************************
 *				String_Lookup
 ***********************************************************************
 * SYNOPSIS:	    See if a string has been entered into the table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The ID for the string, if entered, else NULL.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:	    Much like String_Enter, except no enter occurs...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/23/89		Initial Revision
 *
 ***********************************************************************/
ID
String_Lookup(char   *string,
	      int    length)
{
    int	    	bucket;
    HashElt 	*hep;

    bucket = StringHash(string, length);

    for (hep = hashTable[bucket]; hep != NULL; hep = hep->next) {
	if ((hep->length == length) && (hep->string[0] == string[0]) &&
	    (strcmp(hep->string, string) == 0))
	{
	    break;
	}
    }
    
    if (hep == NULL) {
	return((ID)NULL);
    } else {
	return((ID)hep->string);
    }
}

/***********************************************************************
 *				String_LookupNoLen
 ***********************************************************************
 * SYNOPSIS:	    Front-end for String_Lookup when length of string
 *	    	    not known.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ID for string
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 8/89		Initial Revision
 *
 ***********************************************************************/
ID
String_LookupNoLen(char	*str)
{
    return(String_Lookup(str, strlen(str)));
}

#if	defined(ISSWAT)

/***********************************************************************
 *				StringStatsCmd
 ***********************************************************************
 * SYNOPSIS:	    Print out statistics regarding the string table
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 9/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(string-stats,StringStats,TCL_EXACT,NULL,obscure,
"Print out statistics for identifier hashing")
{
    HashElt *hep;
    int	    num;
    int	    max;
    int	    empty;
    int	    i;

    empty = max = num = 0;

    for (i = 0; i < HASH_SIZE; i++) {
	int j;
	
	for (j= 0, hep = hashTable[i]; hep != NULL; hep = hep->next, j++) {
	    num++;
	}
	if (j == 0) {
	    empty++;
	}
	if (j > max) {
	    max = j;
	}
    }
    Message("%d entries total, %d max, %d empty\n", num, max, empty);

    return(TCL_OK);
}
#endif	/* ISSWAT */
