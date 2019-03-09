/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 89/07/23 20:09:16 $
 *
 *    $Revision: 1.2 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hifmtline.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

#define setskip(skip, word)	((*word == '\\' && !skip) ? (word++, TRUE): FALSE)

/*
 *    The purpose of this function is to format the final output
 *    line for returning to the user.  The hq->head is the
 *    line which was just entered.
 */
hiFmtLine(space, word, size, hq)
char *space;		/* first copy (to be returned)	*/
char *word;		/* 2nd copy to copy from	*/
int size;		/* cant format past this size	*/
HIQUEUE *hq;		/* history to take from		*/
{
	register int i,
		     len = 0,		/* printed len chars do far 	  */
		     skip = FALSE;	/* skip the history substitution  */
	int numLine = 0,		/* number of line sub so far	  */
	    lastLine = FALSE,		/* was there a last line sub	  */
	    subRet,			/* returned value from subthis    */
	    specialSub,			/* don't use hiSubThis() this time*/
	    last;			/* argv[last] for !$ substitute	  */
	HIST *hi;			/* history ptr fo substitutions	  */

	/*
	 *    If a lastc subststution, do it, and clean up.
	 *
	 *    The line goes in in word, and comes out in space.
	 *    The previously entered (but maybe faulty line) will be 
	 *    found in space.    It is then copied back to word.
	 *    Mark as a history substitution.
	 */
	if (*word == hq->lastc) {
	    if (hiUpArrow(space, word, size, hq) < 0)
		return (FM_ERROR);	/* hiErrno set in hiUpArrow()	*/
	    strcpy(word, space);
	    lastLine = TRUE;
	}
	while (*word && len < size) {
	    /*
	     *    If it's not a substitution, then update and go again
	     */
	    if (*word != hq->subc || skip ||
		(hq->subc == '!' && word[1] == '='))
	    {
		*space++ = *word++;
		len++;
		skip = setskip( skip, word );
		continue;
	    }
	    /*
	     *    It is a substitution.
	     *    Record that there was a substitution 
	     *    Get rid of the subc (word++)
	     *    Mark that this is not a specialSub (this may change)
	     *    Switch on kind of substitution
	     */
	    numLine++;
	    word++;
	    specialSub = FALSE;
	    switch (subKind(word, hq)) {
	    case SU_THIS:
		/*
		 *    !:
		 *
		 *    You can always substitute off of the current line
		 *    errors in this kind of substitute get caught later.
		 */
		hi = hq->head;
		break;
	    case SU_LAST:
		/*
		 *    !!
		 *
		 *    Simply check to see that there is a "last" line.
		 *    Get off the subc char
		 */
		if (hq->count < 2)
		    return (hiErrno = HI_TOOFAR, FM_ERROR);
		word++;
		hi = hq->head->next;
		break;
	    case SU_LSEARCH:
		/*
		 *    !?xxx
		 *
		 *    Get rid of '?' 
		 *    Find the proper line w/a word, and then get rid of it.
		 */
		word++;			/* a '?'	*/
		if ((hi = hiWordLine(hq, word)) == NULL) 
		    return(hiErrno = HI_NOTFOUND, FM_ERROR);
		while (*word && *word != ':' && !isspace(*word))
		    word++;
		break;
	    case SU_RELATIVE:
		/*
		 *    !-n 	Could be too far back
		 */
	    case SU_NUMBER:
		/*
		 *    !n	Check to see if in history
		 *
		 *    Find the proper line, and then get rid of the number
		 */
		if ((hi = hiNumLine(hq, word)) == NULL)
		    return (hiErrno = HI_TOOFAR, FM_ERROR);
		word += (*word == '-');
		while (*word && isdigit(*word))
		    word++;
		break;
	    case SU_SEARCH:
		/*
		 *    !xxxx
		 *
		 *    Find the proper line w/a leading word, and then
		 *    get rid of it.  Word ends in ':' or whiTe_space
		 */
		if ((hi = hiFindLine(hq, word)) == NULL) 
		    return (hiErrno = HI_NOTFOUND, FM_ERROR);
		while (*word && *word != ':' && !isspace(*word))
		    word++;
		break;
	    case SU_LASTFIRST:
		/*
		 *    !^
		 *
		 *    You want the first word on the last line.
		 *    Get rid of the '^' char.
		 *    Check for a "last" line, do the substitution, and
		 *    mark that this was a special substitution.
		 */
		word++;
		if (hq->count < 2) 
		    return (hiErrno = HI_TOOFAR, FM_ERROR);
		hi = hq->head->next;
		if ((last = hi->argc) < 2) 
		    return (hiErrno = HI_TOOGREAT, FM_ERROR);
		i = hiWrite(space, size-len, 1, 2, hi, hq->esc);
		space += i;
		len += i;
		specialSub = TRUE;
		break;
	    case SU_LASTLAST:
		/*
		 *    !$
		 *
		 *    You want the last word on the last line.
		 *    Get rid of the '$' char.
		 *    Check for a "last" line, do the substitution, and
		 *    mark that this was a special substitution.
		 */
		word++;
		if (hq->count < 2) 
		    return (hiErrno = HI_TOOFAR, FM_ERROR);
		hi = hq->head->next;
		last = hi->argc;
		i = hiWrite(space, size-len, last-1, last, hi, hq->esc);
		space += i;
		len += i;
		specialSub = TRUE;
		break;
	    case SU_LASTALL:
		/*
		 *	!*
		 *
		 *    want all of the last line, except the first word.
		 *    Get rid of the '*' char, check for a "last" line
		 *    then do the substitution, and mark that it was
		 *    a special substitution.
		 */
		word++;
		if (hq->count < 2)
		    return(hiErrno = HI_TOOFAR, FM_ERROR);
		hi = hq->head->next;
		last = hi->argc;
		i = hiWrite(space, size-len, 1, last, hi, hq->esc);
		space += i;
		len += i;
		specialSub = TRUE;
		break;
	    case SU_NOSEARCH:
		/*
		 *    No search, subc alone.
		 *    This wasn't a substitution, decrement the number.
		 *    of subs.
		 */
		numLine--;
		*space++ = hq->subc;
		len++;
		skip = setskip(skip, word);
		continue;
	    default:
		/*
		 *    Should never get here
		 */
		return (hiErrno = HI_PANIC, FM_ERROR);
	    }
	    if (!specialSub) {
		/*
		 *    Substitute this line, and take care of ':' stuff
		 *    there (in hiSubThis()) too.
		 */
		subRet = hiSubThis(space, size-len, &word, hi, hq->esc);
		if (subRet < 0)
		    return (FM_ERROR);	/* hiErrno already set by subthis  */
		space += subRet;
		len += subRet;		/* the length written is returned  */
	    }
	}
	*space = '\0';
	if (len >= size)
	    return (hiErrno = HI_TOOLONG, FM_ERROR);
	else
	    return ((lastLine || numLine) ? FM_HIST: FM_CLEAN);
}

/*
 *    The purpose of this function is to figure out whiCh kind of history 
 *    substitution is necessary.
 *
 *    This line ->    ':'		SU_THIS
 *    Last line ->    subc		SU_LAST
 *    Search ->       '?'		SU_LSEARCH
 *    Number ->       isdigit()		SU_NUMBER
 *    Last_last ->    '$'		SU_LASTLAST
 *    Last_all ->     '*'		SU_LASTALL
 *    Relative ->     -isdigit()	SU_RELATIVE   '-' followed by a digit
 *    Line search ->  none of the above	SU_SEARCH
 *    No search	      subc alone	SU_NOSEARCH
 */
static
subKind(subLine, hq)
char *subLine;		/* beginning of substitution type	*/
HIQUEUE *hq;		/* current history			*/
{
	if (*subLine == ':')
	    return (SU_THIS);
	if (*subLine == hq->subc)
	    return (SU_LAST);
	if (*subLine == '?')
	    return (SU_LSEARCH);
	if (*subLine == '^')
	    return (SU_LASTFIRST);
	if (*subLine == '$')
	    return (SU_LASTLAST);
	if (*subLine == '*')
	    return (SU_LASTALL);
	if (isdigit(*subLine))
	    return (SU_NUMBER);
	if (*subLine == '-' && isdigit(subLine[1]))
	    return (SU_RELATIVE);
	if (*subLine != '\0' && !isspace(*subLine))
	    return (SU_SEARCH);
	return (SU_NOSEARCH);
}
