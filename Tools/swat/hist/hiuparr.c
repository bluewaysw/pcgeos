/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:19:13 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hiuparrow.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

static char *findMatch();	/* find a match in the argvs	*/

/*
 *    The purpose of this function is to do uparrow substitutions.
 *    Write from word onto space.  Regular hist substution (subc)
 *    chars are interpreted in a later pass.
 *
 *    The line comes in in word, and leaves in space.  
 */
hiUpArrow(space, word, size, hq)
char *space;		/* place to put subsituted text	*/
char *word;		/* original unsubstituted text	*/
int size;		/* no longer than this		*/
HIQUEUE *hq;		/* hist for the last line	*/
{
	char *after,			/* after the match string	*/
	     *search,			/* search string		*/
	     *sub,			/* substitute with ...		*/
	     *optional,			/* after substitute		*/
	     *match,			/* where the sub occurred	*/
	     *spaceEnd;			/* end of space 		*/
	int diff,			/* size diff bet/search && sub	*/
	    searchLen,			/* length of search string	*/
	    subLen,			/* length of sub string		*/
	    spaceLen;			/* length of space strin	*/

        /*
	 *    ^search^sub^optional
	 *
         *    search		must exist
         *    substitution	might be there if replacing
         *    optional		could be there...
	 *
	 *    Check to see if there is a last line.
	 *    You know you are on a lastc char, if there is stuff after it
	 *    (e.g.  not an error), look for the next lastc.
	 *    There must be at least two lastc chars.  Anything more is
	 *    "optional".  NULL the lastc char and move off of it.  
	 *
	 *    You have two strings now, search and sub.
         */
	if (hq->count < 2)
	    return (hiErrno = HI_TOOFAR, -1);
 	/*
 	 *   ^\000  or  ^^sub given
 	 */
 	if ((search = word+1) == NULL || *search == hq->lastc)
	    return (hiErrno = HI_LASTC, -1);
 	/*
 	 *    ^search  given  must be ^search^
 	 */
	if ((sub = index(search, hq->lastc)) == NULL)
	    return (hiErrno = HI_LASTC, -1);
	*sub++ = NULL;
	/*
	 *    Attempt to find the optional string (whiCh won't be there if
	 *    there was no sub string).  If you find it, NULL the lastc char
	 *    and move off it.
	 */
	optional = (*sub != NULL) ? index(sub, hq->lastc): NULL;
	if (optional && *optional != NULL)
	    *optional++ = NULL;
	/*
	 *    Get the search length, sub length and the length of the space.
	 *    Figure out where to copy the sub string, (if its not found,
	 *    then its an error).
	 */
	searchLen = strlen(search);
	subLen = strAndLen(sub, search);	/* count &'s too	*/
	spaceLen = strlen(space);
	if ((match = findMatch(search, space)) == NULL)
	    return (hiErrno = HI_LASTC, -1);
	/*
	 *    If the substitute string is smaller than the search string,
	 *    (remembering about the '&' expansions being already counted
	 *    in subLen) then put in the sub, and shiFt everybody closer (easy).
	 *
	 *    If they are the same length, then copy in the sub string.
	 *
	 *    Otherwise... (the ugly stuff) shiFt away (ugly), and insert
	 */
	if ((diff = searchLen - subLen) > 0) {
	    after = match+searchLen;	/* save start of after match	*/
	    copySub(match, sub, search);	 /* copy sub string*/
	    match += subLen;		/* match after sub (copied in)	*/
	    while (*after)		/* shift the rest closer	*/
		*match++ = *after++;
	    *match = '\0';
	    spaceLen -= diff;
	} else if (diff == 0) {
	    copySub(match, sub, search);	 /* copy sub string*/
	} else {
	    /*
	     *    The shifting down for the sub string would make it too
	     *    long.  This is an error.
	     */
	    after = space + spaceLen - searchLen + subLen;
	    if (after > space + size)
		return (hiErrno = HI_TOOLONG, -1);
	    /*
	     *    Shift down the chars after the match string,
	     *    Then slip in the substitute string.
	     */
	    spaceEnd = space + spaceLen;
	    while (spaceEnd != match)		/* shift everybody down	*/
		*after-- = *spaceEnd--;
	    copySub(match, sub, search);	/* copy sub string*/
	    spaceLen -= diff;
	}
	/*
	 *    Now try to add on the optional string.
	 */
	space += spaceLen;
	while (optional && *optional && spaceLen++ < size)
		*space++ = *optional++;
	*space = '\0';
	return ((spaceLen < size) ? 0: (hiErrno = HI_TOOLONG, -1));
}

/*
 *    The purpose of this function is to find where the match is in the
 *    line given (in a HIST) or to return NULL
 */
static char *
findMatch(match, lastlin)
char *match;			/* match with this	*/
char *lastlin;			/* last times input	*/
{
	int lLen,			/* length of last line		*/
	    mLen;			/* length of a string to match	*/

	mLen = strlen(match);
	lLen = strlen(lastlin);
 	while (lLen-- >= mLen) {
	    if (!strncmp(lastlin, match, mLen)) 
		return (lastlin);
	    lastlin++;
	}
	return (NULL);
}

/*
 *    The purpose of this function is to add in the search pattern on an '&'
 */
static
copySub(match, sub, search)
char *match; 			/* copy to here		*/
char *sub;			/* this substitute text	*/
char *search;			/* sub for an '&'	*/
{
	char *sptr;
	int skip = FALSE;

	while (*sub) {			
	    if (!skip && *sub == '&') {
		sub++; sptr = search; skip = FALSE;
		while (*sptr)
		    *match++ = *sptr++;
	    } else {
		*match++ = *sub++; skip = (*sub == '\\');
	    }
	}
}

/*
 *    The purpose of this function is to get the length of the sub string,
 *    counting the occurrences of '&' which are not backslashed.
 */
static
strAndLen(sub, search)
char *sub;
char *search;
{
	register int len = 0,
		     skip = FALSE,
		     sLen = strlen(search);

	while (*sub) {			
	    if (!skip && *sub == '&') {
		sub ++; len += sLen; skip = FALSE;
	    } else {
		len++; sub++; skip = (*sub == '\\');
	    }
	}
	return (len);
}
