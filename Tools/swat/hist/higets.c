/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:42 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/higets.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

/*
 *    The space to get input into
 */
static char space[INTERNAL_BUFSIZ],		/* first workSpace	*/
	    workSpace[INTERNAL_BUFSIZ];		/* 2nd workSpace	*/

static int size = sizeof (space);

/*
 *    This is the entry point which does not leave on the newline at the end.
 *
 *    This is the entry point when using a file descriptor.
 */
hiGets(retSpace, hq, fptr)
char **retSpace;		/* ptr to ptr to space to be returned	*/
HIQUEUE *hq;			/* history to use			*/
FILE *fptr;			/* file to read out of			*/
{
	register int retError;	/* error frm history subs		*/

	/*
	 *    Get a line, guess that there are no history subs
	 *    Perform history subs on it in shiGets()
	 */
	hiErrno = HI_NOERROR;
	*retSpace = NULL;
	hiHist = 0;			/* 0 == plaintext line		*/
	if (hiGetLine(workSpace, size, fptr) != HI_NOERROR)
	    return (hiErrno);		/* set in hiGetLine()		*/
	retError = histories(retSpace, hq);
	return (retError);
}

/*
 *    This is the entry point which leaves on the newline at the end.
 *
 *    This is the entry point when using a file descriptor.
 */
hiFGets(retSpace, hq, fptr)
char **retSpace;		/* ptr to ptr to space to be returned	*/
HIQUEUE *hq;			/* history to use			*/
FILE *fptr;			/* file to read out of			*/
{
	register int retError;	/* error frm history subs		*/

	/*
	 *    Get a line, guess that there are no history subs
	 *    Perform history subs on it in shiGets()
	 */
	hiErrno = HI_NOERROR;
	*retSpace = NULL;
	hiHist = 0;			/* 0 == plaintext line		*/
	if (hiGetLine(workSpace, size, fptr) != HI_NOERROR)
	    return (hiErrno);		/* set in hiGetLine()		*/
	retError = histories(retSpace, hq);
	/*
	 *    There can be no error on an empty line
	 *    So build an empty line, and make the error HI_NOERROR
	 */
	if (hiErrno == HI_EMPTY) {
	    hiErrno = HI_NOERROR;
	    *retSpace = workSpace;
	    **retSpace = '\0';
	}
	if (hiErrno == HI_NOERROR)	/* only if there was no error	*/
	    strcat(*retSpace, "\n");	/* stick on the '\n'		*/
	return (retError);
}

/*
 *    This is the entry point when using a string.
 */
hiSGets(retSpace, hq, s)
char **retSpace;		/* ptr to ptr to space to be returned	*/
HIQUEUE *hq;			/* history to use			*/
char *s;			/* file to read out of			*/
{
	register int retError;	/* error frm history subs		*/

	hiErrno = HI_NOERROR;
	*retSpace = NULL;
	hiHist = 0;			/* 0 == plaintext line		*/
	/*
	 *    For now assume that this will be big enough.
	 *    Later, however workSpace will have to grow dynamically
	 */
	if (strlen(s) > sizeof (workSpace))
	    return (hiErrno = HI_TOOLONG);
	strcpy(workSpace, s);
	retError = histories(retSpace, hq);
	return (retError);
}

/*
 *    The purpose of this function is to get a string off of the
 *    stdin, and then edit the ! edits as in csh from the current
 *    history.
 */
static
histories(retSpace, hq)
char **retSpace;		/* ptr to ptr to space to be returned	*/
HIQUEUE *hq;			/* history to use			*/
{
	register char *word,		/* another ptr to space	*/
		      *workptr;		/* ptr to workSpace	*/
	register int i;
	int fmRet,		/* return value of hiFmtLine()		*/
	    finalLen;		/* length of final squeezed line	*/

	/*
	 *    Assume a plaintext line.
	 *    If there were history substitutions, then resplit
	 */
	if (hiPuth(workSpace, hq) < 0) 
	    return (hiErrno = HI_MEMERR);
	if ((fmRet = hiFmtLine(space, workSpace, size, hq)) == FM_ERROR) {
	    /*
	     *    A fatal error has occurred, hiErrno will already be set
	     *    to the appropriate value, remove the current "bad" line
	     *    and return the error.
	     */
	    hiRem(hq);
	    return (hiErrno);
	} else if (hq->head->argc == 0) {
	    /*
	     *    If its a clean line, and its zero words, 
	     *    remove it, and return an error.
	     *
	     *    An empty line can occur only zero words parsed
	     *    this includes null lines, and all whiteSpace lines
	     */
	    hiRem(hq);
	    return (hiErrno = HI_EMPTY);
	} else if (fmRet == FM_HIST) {
	    /*
	     *    Make sure that a line exists, mark for history subs.
	     *    Take off the guess and re hiSplit() the line for
	     *    proper saving.  Then give the user back his line
	     *    in the expanded format.
	     */
	    hiHist = 1;			/* history subs occurred	*/
	    hiRem(hq);
	    if (hiPuth(space, hq) < 0)
		return (hiErrno = HI_MEMERR);
	}
	/*
	 *    hiErrno here should contain HI_NOERROR.
	 *
	 *    Recopy the line back to the workSpace; now give the 
	 *    user a ptr to this great thing.
	 *
	 *    NULL for the escape char means that it will never be
	 *    put out there for the special chars.
	 */
	finalLen = hiWrite(workSpace, size, 0, hq->head->argc, hq->head, '\0');
	workSpace[finalLen] = '\0';
	*retSpace = workSpace;
	return (hiErrno);
}
