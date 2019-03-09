/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:47 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/himisc.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

char *hiErrList[] = {
	"No Error.",				/* things went ok.	*/
	"Number Not In History.",		/* too far back in hq	*/
	"Search Unsuccessful.",			/* hq search failed	*/
	"Word Specifier Too Great.",		/* :nnn too great	*/
	"Malformed History Command.",		/* !couldn't understand	*/
	"Malformed Subsitution Command.",	/* ^couldn't understand	*/
	"Not Enough Memory.",			/* malloc() failed	*/
	"Range Specifier Confused.",		/* :n-n backwards?	*/
	"Empty Line.",				/* empty line entered	*/
	"Expanded Line Too Long.",		/* line too long	*/
	"Unforseen Error, Panic!!!"		/* unplanned error	*/
};

int hiNErrs = sizeof (hiErrList);		/* number of errors	*/

int hiErrno;					/* current error code	*/

int hiHist,		/* there were/were not history substitutions	*/
    hiBufSiz = INTERNAL_BUFSIZ;		/* current internal buffer size	*/

/*
 *    Initialize a history queue, and return a ptr to it
 */
HIQUEUE *
hiQinit(size)
int size;
{
	HIQUEUE *hq;		/* history queue	*/

	if (hq = (HIQUEUE *) malloc(sizeof (*hq))) {
	    hq->max = size;
	    hq->count = 0;
	    hq->line = 0;		/* start at line one		*/
	    hq->esc = STD_ESC;		/* escape character		*/
	    hq->squot = STD_SQUOT;	/* single quote			*/
	    hq->dquot = STD_DQUOT;	/* double quote			*/
	    hq->bquot = STD_BQUOT;	/* back quote			*/
	    hq->subc = STD_SUBC;	/* standard line subs char	*/
	    hq->lastc = STD_LASTC;	/* standard last line subs char	*/
	    hq->head = NULL;
	    hq->tail = NULL;
	}
	return (hq);
}

/*
 *    Set history size of a history to something... If the current
 *    count is greater than the new count, then truncate.
 */
hiSet(hq, newsiz)
HIQUEUE *hq;
int newsiz;
{
	register int i;
	HIST *hrun;		/* run down the list with	*/

	if (newsiz < 0)
	    return (-1);
	hq->max = newsiz;
	if (hq->count > newsiz) {
	    hq->count = newsiz;
	    hrun = hq->head;
	    for ( i=newsiz; --i && hrun != NULL; hrun=hrun->next)
		;
	    if (!newsiz)
		hq->tail = hq->head = NULL;
	    else {
  		hq->tail = hrun;		/* the tail is here	   */
  		if (hrun != NULL)		/* hfree() after tail   */
  		    hrun = hrun->next;
  		hq->tail->next = NULL;	/* terminate the list	   */
	    }
	    hiFree(hrun);
	}
	return (0);
}

/*
 *    hiFprint - Print out the given history this many times,
 *        on this file descriptor.
 *
 *    if hiNum is < 0 then print them all out.
 *    otherwise only print out hiNum
 *
 *    return nothing.
 */
hiFPrint(hq, hiNum, fptr)
HIQUEUE *hq;		/* print with this history	*/
int hiNum;		/* print this many lines	*/
FILE *fptr;		/* output stream		*/
{
	register int i,		/* look around		*/
		     down = 0;	/* down so many lines	*/
	HIST *hi = hq->head;

	/*
	 *    If hiNum < 0 then always print one out.  
	 *    Otherwise print out only hiNum more.
	 *    Get the quoting chars if they are there.
	 */
	while (((hiNum < 0) ? 1: hiNum--) && hi != NULL) {
	    fprintf(fptr, "%4d  ", hq->line - down);
	    hiFEchoLine(hi, fptr);
	    down++;		/* down another one	*/
	    hi = hi->next;
	}
}

/*
 *    Perform the perror style function, on any (FILE *)
 *    s may be NULL.
 */
hiFError(s, fptr)
char *s;
FILE *fptr;
{
	char *theError,
	     *heEof = "End of File.",
	     *heUnKnown = "Unknown Error";

	if (hiErrno < 0)
	    theError = (hiErrno == HI_EOF) ? heEof: heUnKnown;
	else 
	    theError = (hiErrno < hiNErrs) ? hiErrList[hiErrno]: heUnKnown;
	if (s != NULL)
	    fprintf(fptr, "%s: ", s);
	if (theError == heUnKnown)
	    fprintf(fptr, "%s (%d)\n", theError, hiErrno);
	else
	    fprintf(fptr, "%s\n", theError);
}

/*
 *    Free the history list given.  Head and tail ptrs will already
 *    be taken care of elsewhere...
 */
hiFree(hi)
register HIST *hi;
{
	register HIST *ohi;

	while (hi != NULL) {
	    ohi = hi;
	    hi = hi->next;
	    free(ohi);
	}
}

/*
 *    The purpose of this function is to remove the last history
 *    line from the history queue
 */
hiRem(hq)
HIQUEUE *hq;
{
	register int i;
	HIST *hi;

	if (hq->head == NULL)
	    return;
	hi = hq->head;
	if ((hq->head = hq->head->next) == NULL)
	    hq->tail = NULL;
	for ( i=0; i<hi->argc; i++)
	    free(hi->argv[i]);
	free(hi);
	hq->line--;
	hq->count--;
}

/*
 *    The purpose of this function is to find the line in the current
 *    history which matches the word
 */
HIST *
hiFindLine(hq, word)
HIQUEUE *hq;
char *word;
{
	register char *ch = word;		/* count length of word	*/
	register HIST *hi = hq->head;
	register int len = 0;


	while (*ch && *ch != ':' && !isspace(*ch)) 
	    ch++, len++;
	while (hi != NULL) {
	    if (!strncmp(hi->argv[0], word, len))
		break;
	    hi = hi->next;
	}
	return (hi);
}

/*
 *    The purpose of this function is to find the line number requested
 *    If the line number is negative, then figure out what line number
 *    that is relatively, and then go back to it
 */
HIST *
hiNumLine(hq, word)
HIQUEUE *hq;
char *word;
{
	register int i,
		     num;		/* this history line num	*/
	register HIST *hi;

	if ((num = atoi(word)) < 0)
	    num = hq->line + num;	/* back up so many		*/
	/*
	 *    Check to see that it is in the history
	 *    It could be in the future, or too far in the past.
	 */
	if (num > hq->line || num < hq->line - hq->count)
	    return (NULL);
	hi = hq->head;
	i = hq->line;
	while (i-- > num) 
	    hi = hi->next;
	return (hi);
}

/*
 *    The purpose of this function is to find a line with this word
 *    on it.
 */
HIST *
hiWordLine(hq, targ)
HIQUEUE *hq;
char *targ;
{
	register char *ch = targ,
		      *word;
	register int i,
		     len = 0;
	register HIST *hi;

	while (*ch && *ch != ':' && *ch != '?' && !isspace(*ch)) 
	    ch++, len++;
	if ((hi = hq->head->next) == NULL)
	    return (NULL);
	while (hi != NULL) {
	    for ( i=0; i<hi->argc; i++) {
		word = hi->argv[i];
		while (*word) {
		    if (!strncmp(word, targ, len))
			return (hi);
		    word++;
		}
	    }
	    hi = hi->next;
	}
	return (hi);
}
