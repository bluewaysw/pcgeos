/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:57 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hisplit.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

#define isQuot(hq, ch)	 ((ch) == (hq)->squot || (ch) == (hq)->dquot || (ch) == (hq)->bquot)

/*
 *    The purpose of this function is to split the line up into words
 *    along whitespace and special quotings etc..
 */
hiSplit(hq, hi, buf)
HIQUEUE *hq;
HIST *hi;
char *buf;
{
	register int i,
		     wordLen,		/* length of a word	*/
		     words;		/* words on a line	*/

	hi->argc = words = countWords(hq, buf);
	if ((hi->argv = (char **)
		malloc((words+1) * sizeof (char *))) == NULL)
	    return (-1);
	if ((hi->argq = (char *)
		malloc((words+1) * sizeof (char))) == NULL)
	    return (-1);
	hi->argv[words] = NULL;		/* NULL terminate it	*/
	hi->argq[words] = '\0';		/* NULL terminate it	*/
	for ( i=0; i<words; i++) {
	    /*
	     *    While whitespace,  skip it.
	     *    Quoting / escapes will take care of white in words.
	     */
	    while (*buf && isspace(*buf))
		buf++;
	    wordLen = lenWord(hq, buf);
	    if ((hi->argv[i] = (char *) malloc(wordLen+1)) == NULL)
		return (-1);
	    wordCopy(hq, &hi->argq[i], hi->argv[i], &buf);
	}
}

/*
 *    The purpose of this function is to count all of the words
 *    on the line, remembering the backslashes...
 *
 *    Words are delimited by whitespace.  Leading and trailing
 *    whitespace is ignored.
 *
 *    return the count of words on this line.
 */
static
countWords(hq, buf)
HIQUEUE *hq;
register char *buf;
{
	register char quot = '\0';
	register int count = 0;		/* count of words	*/

	while (*buf && isspace(*buf))	/* skip initial white	*/
	    buf++;
	while (*buf) {
	    if (isQuot(hq, *buf)) {
		quot = *buf++;			/* save the quote	*/
		while (*buf && *buf != quot) {
		    buf += (*buf == hq->esc);	/* skip escape		*/
		    buf += (*buf != '\0');	/* maybe at eoln	*/
		}
		buf += (*buf != '\0');	/* over the quote (maybe)	*/
	    } else {
		int	firstch = TRUE;
		while (*buf && !isspace(*buf)) {
#if 0
		    if ( !firstch && *buf == ',' )
			break;
		    if ( firstch )
			firstch = FALSE;
#endif
		    buf += (*buf == hq->esc);	/* skip escape		*/
		    buf += (*buf != '\0');	/* maybe at eoln	*/
		}
	    }
	    /*
	     *    You will now be at eoln or whitespace.
	     *    You covered a word.  Look for the next one.
	     */
	    count++;
	    while (*buf && isspace(*buf))
		buf++;
	}
	return (count);
}

/*
 *    lenWord - find the squeezed length of the current word.
 *
 *    The squeezed length is the length without the quotes and
 *    without hq->esc escapes.   It is this length that needs
 *    to be malloc()-ed in chars to save the word.
 *
 *    return the squeezed length.
 */
static
lenWord(hq, buf)
HIQUEUE *hq;
char *buf;
{
	register char quot = '\0';
	register int squeezeLen = 0;		/* length of squeezed word	*/
	register int firstch = TRUE;

	while (*buf && !isspace(*buf)) {
	    if (*buf == hq->esc || !isQuot(hq, *buf)) {
#if 0
		if ( !firstch && *buf != hq->esc && *buf == ',')
		    break;
		if ( firstch )
		    firstch = FALSE;
#endif
		/*
		 *    If skipping or not a quote char
		 *    If esc char, then inc approprately
		 *    count one more char.
		 */
		buf += (*buf == hq->esc);
		squeezeLen++, buf++;
	    } else {
		/*
		 *    If its a quoted character and not skipping
		 *    Remember the quote;
		 *    While not eoln, and unfound "the" quote
		 *        if skip, go over it.
		 *        count the current char.
		 *   Now after the quote (or at eoln), maybe.
		 */
		quot = *buf++;
		while (*buf && *buf != quot) {
		    buf += *buf == hq->esc;	/* move over escape	*/
		    squeezeLen += (*buf != '\0');/* maybe count one	*/
		    buf += (*buf != '\0');	/* maybe over one more	*/
		}
		/*
		 *    Off of final quote (maybe)
		 */
		buf += (*buf != '\0');	
	    } 
	}
	return (squeezeLen);
}

/*
 *    wordCopy - Copy a word, skipping magic and quotes.
 *
 *    Also advance the from guy because he really doesn't know
 *    how long the word REALLY is, quotings, escapes and all.
 *  
 *    Side effects of filling to and saveQuote, and moving *from.
 */
static
wordCopy(hq, saveQuote, to, from)
HIQUEUE *hq;
char *saveQuote;			/* char quoting this word	*/
register char *to;			/* put at to			*/
register char **from;			/* word is at *from		*/
{
	register char quote = '\0';
	register int  firstch = TRUE;

	if (!isQuot(hq, **from)) {
	    while (**from && !isspace(**from)) {
#if 0
		if ( !firstch && **from == ',' )
			break;
		if ( firstch )
			firstch = FALSE;
#endif
		*from += (**from == hq->esc);
		*to++ = *(*from)++;
	    } 
	} else {
	    /*
	     *    save the quote, (*from)++.
	     *    while not eoln, and not at "the" quote
	     *        if skipping, then from++
	     *        copy one more char
	     */
	    quote = *(*from)++;
	    while (**from && **from != quote) {
		*from += (**from == hq->esc);	/* move over escape	*/
		*to = **from;
		to += (**from != '\0');		/* at eoln maybe	*/
		*from += (**from != '\0');		/* at eoln maybe	*/
	    }
	    *from += (**from != '\0');	/* skip over last quote (maybe)	*/
	} 
	*to = '\0';			/* NULL terminate it	*/
	*saveQuote = quote;		/* save the quote char	*/
}
