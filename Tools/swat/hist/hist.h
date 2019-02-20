/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:19:03 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hist.h,v $
 *    $State: Exp $
 */

#define HI_EOF		-1	/* end of file			*/
#define HI_NOERROR	0	/* no error			*/
#define HI_TOOFAR	1	/* history from too far back	*/
#define HI_NOTFOUND	2	/* unfound history search	*/
#define HI_TOOGREAT	3	/* word specifier too great	*/
#define HI_SUBC		4	/* malformed line expr		*/
#define HI_LASTC	5	/* malformed last line expr	*/
#define HI_MEMERR	6	/* not enough memory for hist	*/
#define HI_MIXUP	7	/* range specifier bad		*/
#define HI_EMPTY	8	/* history line empty		*/
#define HI_TOOLONG	9	/* line too long		*/
#define HI_PANIC	10	/* panic, unforseen error	*/

typedef struct hist {
	int argc;			/* count in argv	*/
	char *argq;			/* quotes on words	*/
	char **argv;			/* ptrs to words	*/
	struct hist *next;		/* next in list		*/
} HIST;

typedef struct hiqueue {
	int max;			/* max nodes here	*/
	int line;			/* current line number	*/
	int count;			/* current nodes here	*/
	char esc;			/* escape '\\'		*/
	char squot;			/* single quote '\''	*/
	char dquot;			/* double quote '"'	*/
	char bquot;			/* back quote '`'	*/
	char subc;			/* history sub - '!'	*/
	char lastc;			/* last line sub - '^'	*/
	HIST *head;			/* head of the list	*/
	HIST *tail;			/* tail of the list	*/
} HIQUEUE;

/*
 *    Argument to hiFPrint(), hiPrint() to print out all 
 *    entries in the history.
 */
#define HI_ALL	-1

#define hiPrint(hi, num)	hiFPrint((hi), (num), stdout)
#define hiError(s)		hiFError((s), stderr)

#define hiFEchoWord(hi, i, fp)	{ \
					if ((hi)->argq[i]) putc((hi)->argq[i], (fp)); \
					fputs((hi)->argv[i], (fp)); \
					if ((hi)->argq[i]) putc((hi)->argq[i], (fp)); \
					if (i+1 < (hi)->argc) putc(' ', (fp)); \
				}
#define hiFEchoLine(hi, fp)	{ \
					register int i; \
					for ( i=0; i<(hi)->argc; i++) \
					    hiFEchoWord((hi), (i), (fp)); \
					putc('\n', (fp)); \
				}
#define hiEchoWord(hi, i)	hiFEchoWord((hi), (i), stdout)
#define hiEchoLine(hi)		hiFEchoLine((hi), stdout)

extern char *hiErrList[];	/* vector of error names	*/

extern int hiErrno,		/* current error code		*/
	   hiNErrs;		/* number of max errs		*/

extern int hiHist,		/* were (not) substitutions	*/
	   hiBufSiz;		/* current internal buf length	*/

extern int hiGets(),		/* history, use a (FILE *)	*/
	   hiFGets(),		/* history, use a (FILE *) '\n'	*/
	   hiSGets();		/* history, use a (char *)	*/

extern hiSet(),			/* set size of a history	*/
       hiRem(),			/* remove the last line entered	*/
       hiFree(),		/* free up a history list	*/
       hiFPrint(),		/* fprint out a history list	*/
       hiFError();		/* fprint out a history error	*/

extern HIQUEUE *hiQinit();	/* init a history mechanism	*/

