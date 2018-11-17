/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  asm.c
 * FILE:	  asm.c
 *
 * AUTHOR:  	  Adam de Boor: May 20, 1992
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/20/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for locating tags in .asm and .def files
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: asm.c,v 1.6 95/12/01 13:30:18 adam Exp $";
#endif lint

#include <stdio.h>
#include "ctags.h"
#include <compat/string.h>

static char *GetWord(char **);

static int  inStruct = 0;


/***********************************************************************
 *				ustrcmp
 ***********************************************************************
 * SYNOPSIS:	  Perform an unsigned (case-insensitive) string comparison
 * CALLED BY:	  MapFilename
 * RETURN:	  <0 if s1 is less than s2, 0 if they're equal and >0 if
 *		  s1 is greater than s2. Upper- and lower-case letters are
 *		  equivalent in the comparison.
 *
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Subtract each character in s1 from its corresponding character
 *	in s2 in turn. Save that difference in case the strings are unequal.
 *
 *	If the characters are different, and the one that might be upper case
 *	actually is a letter, map that upper-case letter to lower case and
 *	subtract again (if the difference is < 0, *s1 must come before *s2 in
 *	the character set and vice versa if the difference is > 0).
 *
 *	If the characters are still different, return the original difference.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/88		Initial Revision
 *
 ***********************************************************************/
static int
ustrcmp(char *s1, char *s2)
{
    int		  diff;

    while (*s1 && *s2) {
	diff = *s1 - *s2;
	if (diff < 0) {
	    if (!isalpha(*s1) || (tolower(*s1) - *s2)) {
		return(diff);
	    }
	} else if (diff > 0) {
	    if (!isalpha(*s2) || (*s1 - tolower(*s2))) {
		return(diff);
	    }
	}
	s1++, s2++;
    }
    return(!(*s1 == *s2));
}

/***********************************************************************
 *				NukeComments
 ***********************************************************************
 * SYNOPSIS:	    Truncate any comment on the input line.
 * CALLED BY:	    isTagLine
 * RETURN:	    Position of the semi-colon (for replacement) or NULL
 *	    	    if no comment on the line.
 * SIDE EFFECTS:    The semi-colon is replaced with a null byte.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/28/89		Initial Revision
 *
 ***********************************************************************/
static char *
NukeComments(char   *line)
{
    while (*line) {		/* while not at end of string */
	if (*line == ';') {	/*    if at comment delimeter */
	    *line = '\0';	/*	Nuke comment */
	    return( line );	/*	quit */
	}			/*    else */
	line++;			/*	Advance pointer */
    }				/* endwhile */
    return( NULL );		/* no semi-colon */
}


/***********************************************************************
 *				isTagLine
 ***********************************************************************
 * SYNOPSIS:	    See if the current line contains a tag.
 * CALLED BY:	    CreateTags
 * RETURN:	    The index (1-origin) at which the tag is located, or
 *	    	    0 if the line contains no tag.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *	Extract the words from the line and compare them to the
 *	set of keys for which we search. If a match is found, return
 *	the index recorded for the key.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/28/89		Initial Revision
 *
 ***********************************************************************/
static int
isTagLine(char	*line)
{
    char *commentMark;			/* where the comment is */
    int   retVal;			/* the value to return */
    static int	  commChar = 0; 	/* character delimiter for comments */
    /*
     * Table of keys that will cause us to decide there's a tag here. They
     * are ordered by word number, the idea being to step through the
     * line word by word until we run out of keys or hit the end of the
     * line or find one of the keys in the right position. Some of the keys
     * are case-insensitive.
     */
    int	strcmp(), ustrcmp();
    static struct {
	char	*key;	    /* Key for which to look */
	int 	wordNum;    /* Word number at which to look for it */
	int 	retVal;	    /* Value to return if it's found */
	int 	startStruct:1,	/* If set, then inc inStruct */
		endStruct:1,	/* If set, then dec inStruct */
	        isRecord:1; 	/* If set, it's 'record' and we must make sure
				 * the rest of the line is empty before
				 * obeying startStruct flag */
	int 	(*cmp)();   /* Function for comparison */
    }	    	keys[] = {
	"byte",	    	    2,  1,  0, 0, 0, ustrcmp,
	"word",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dword",    	    2,  1,  0, 0, 0, ustrcmp,
#define LAST_TYPE	2
	":",	    	    2,	1,  0, 0, 0, strcmp,
	"::",	    	    2,	1,  0, 0, 0, strcmp,
	"db",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dw",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dd",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dc",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dsb",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dsw",	    	    2,  1,  0, 0, 0, ustrcmp,
	"dsd",	    	    2,  1,  0, 0, 0, ustrcmp,
	"sbyte",    	    2,  1,  0, 0, 0, ustrcmp,
	"sword",    	    2,  1,  0, 0, 0, ustrcmp,
	"sdword",    	    2,  1,  0, 0, 0, ustrcmp,
	"char",    	    2,  1,  0, 0, 0, ustrcmp,
	"hptr",	    	    2,  1,  0, 0, 0, ustrcmp,
	"lptr",	    	    2,  1,  0, 0, 0, ustrcmp,
	"nptr",	    	    2,  1,  0, 0, 0, ustrcmp,
	"fptr",	    	    2,  1,  0, 0, 0, ustrcmp,
	"sptr",	    	    2,  1,  0, 0, 0, ustrcmp,
	"optr",	    	    2,  1,  0, 0, 0, ustrcmp,
	"proc",	    	    2,  1,  0, 0, 0, ustrcmp,
	"label",    	    2,	1,  0, 0, 0, ustrcmp,
	"equ",		    2,	1,  0, 0, 0, ustrcmp,
	"=",	    	    2, 	1,  0, 0, 0, strcmp,
	"macro",    	    2,	1,  0, 0, 0, ustrcmp,
	"type", 	    2,	1,  0, 0, 0, ustrcmp,
	"enum",	    	    2,	1,  0, 0, 0, ustrcmp,
	"record",   	    2,	1,  1, 0, 1, ustrcmp,
	"struc",    	    2,	1,  1, 0, 0, ustrcmp,
	"struct",    	    2,	1,  1, 0, 0, ustrcmp,
	"union",    	    2,	1,  1, 0, 0, ustrcmp,
	"class",    	    2,	1,  1, 0, 0, ustrcmp,
	"method",    	    2,	1,  0, 0, 0, ustrcmp,
	"message",    	    2,	1,  0, 0, 0, ustrcmp,
	"etype",	    2,	1,  0, 0, 0, ustrcmp,
	"vardata",  	    2,	1,  0, 0, 0, ustrcmp,
	"export",   	    2,	1,  0, 0, 0, ustrcmp,

	/* Things that end structure definitions. They don't indicate a
	 * tag, but they do have the endStruct flag set... */
	"ends",	    	    2,  0,  0, 1, 0, ustrcmp,
	"endc",	    	    2,  0,  0, 1, 0, ustrcmp,
	"end",	    	    2,  0,  0, 1, 0, ustrcmp,
	"", 	    	    0,	0,  0, 0, 0, 0,
    };
    int 	i;  	    	/* Key index */
    char	*word;	    	/* Current word */
    int 	wnum;	    	/* Index of word (1-origin) */
    char	*cp = line; 	/* Pointer for stepping through words */
    
    
    if (commChar != 0) {
	/*
	 * See if we found the last line of the comment block. If so,
	 * set commChar to 0 so we know that next time. In any case, the
	 * whole line is ignored...
	 *
	 * 9/28/89: since classes and so forth are defined within comment
	 * blocks (though that may change), it is bad to skip comment
	 * blocks -- tony.
	 *
	 * 7/12/92: changed to only search inside comment blocks when -c flag
	 * given, as most uses have been eradicated -- ardeb
	 */
	if (index(line, commChar)) {
	    commChar = 0;
	    return( 0 );
	}
	if (!cflag) {
	    return( 0 );
	}
    }
    
    /*
     * Look for start of comment block.
     */
    if (strncmp(line, "COMMENT", 7) == 0) {
	line += 7;
	/*
	 * Find comment terminator
	 */
	while (isspace(*line)) {
	    line++;
	}
	/*
	 * Record that for future lines...
	 */
	commChar = *line;
	return( 0 );
    }

    retVal = 0;		/* default to NOT_A_TAG */
    commentMark = NukeComments( line );

    wnum = 1;
    i = 0;
	
    while ((i < sizeof(keys)/sizeof(keys[0])) &&
	   ((word = GetWord(&cp)) != NULL))
    {
	/*
	 * Compare word against all those at the current word number
	 */
	while (keys[i].wordNum == wnum) {
	    if ((*keys[i].cmp)(word, keys[i].key) == 0) {
		/*
		 * Found a match -- record the tag index and break out of
		 * both loops.
		 */
		retVal = keys[i].retVal;

		/*
		 * Adjust inStruct properly.
		 */
		if (keys[i].isRecord) {
		    /*
		     * For records, we have to detect multi-line things and
		     * only up inStruct for them (this allows record fields
		     * that contain an enumerated type to be found, and allows
		     * us to have "end" as something to decrement inStruct
		     * all the time)
		     */
		    char    *cp2;

		    for (cp2 = cp; isspace(*cp2); cp2++) {
			;
		    }
		    if (*cp2 == '\0') {
			inStruct++;
		    }
		} else if (keys[i].startStruct) {
		    inStruct++;
		} else if (keys[i].endStruct) {
		    if (!inStruct--) {
			/* Cope with possible underflow from incorrect
			 * parsing */
			inStruct = 0;
		    }
		}
		goto done;
	    }
	    i++;
	}
	if (wnum == 2 && isupper(word[0])) {
	    /*
	     * Deal with data definitions of structure/record variables.
	     * If this is the second word and begins with an upper-case
	     * letter (PC/GEOS coding convention), see if the rest of the
	     * line contains a <. Since this is the way structures and
	     * records are initialized, if the line doesn't have a <, it
	     * can't be a variable def. We do some rudimentary checks in the
	     * hope of catching things that match this pattern but aren't
	     * variable definitions, but it's better to catch too many
	     * than too few...
	     *
	     * 5/30/94: added use of inStruct variable to catch structure
	     * fields with no initializer. In essence, we assume that anything
	     * of this form between a struct/ends, or union/ends, or
	     * class/endc pair is something that should be tagged. -- ardeb
	     */
	    char    *cp2 = cp;

	    if (inStruct) {
		/*
		 * Cope with record fields that contain enumerated types by
		 * seeing if the first non-space char after the second word
		 * is a colon, which we assume to be the field-width separator.
		 */
		while (isspace(*cp2)) {
		    cp2++;
		}
		if (*cp2 == ':') {
		    /*
		     * Tag is first word on the line.
		     */
		    retVal = 1;
		    break;
		}
	    }
	    
	    while (*cp2 != '<' && *cp2 != '\0') {
		if (!isalnum(*cp2) && !isspace(*cp2) &&
		    *cp2 != '.' && *cp2 != '+' && *cp2 != '_' &&
		    *cp2 != '-' && *cp2 != '*' && *cp2 != '/' &&
		    *cp2 != '(' && *cp2 != ')')
		{
		    /*
		     * There's a character we don't expect in a structure
		     * variable definition (i.e. not alphanumeric, whitespace,
		     * open/close paren, or one of the simple arithmetic
		     * operator characters).
		     */
		    break;
		}
		cp2++;
	    }
	    if (*cp2 == '<' || (inStruct && *cp2 == '\0')) {
		/*
		 * Tag is first word on the line.
		 */
		retVal = 1;
		break;
	    }
	}
	wnum++;
    }
	
    done:

    if ((i <= LAST_TYPE) && ((word = GetWord(&cp)) != NULL) &&
	(ustrcmp(word, "ptr") == 0))
    {
	/*
	 * Type word followed by "ptr" => type is actually cast
	 * immediately after an unlabeled instruction => not a tag
	 */
	retVal = 0;
    } else if (retVal && commChar && keys[i].key[0] == ':') {
	/*
	 * Label in a comment: don't actually tag it. (why not?)
	 */
	retVal = 0;
    } else if (retVal && keys[i].key[0] == ':') {
	/*
	 * Don't tag numeric labels
	 */
	for (cp = line; isspace(*cp); cp++) {
	    ;
	}
	if (isdigit(*cp)) {
	    retVal = 0;
	}
    }
	    
    /*
     * Replace the comment character in case we need to use the line.
     */
    if (commentMark != NULL) {		/* if there was a comment */
        *commentMark = ';';		/*    replace the comment */
    }
    return( retVal );
}


/***********************************************************************
 *				GetWord
 ***********************************************************************
 * SYNOPSIS:	    Extract the next word from the input line.
 * CALLED BY:	    isTagLine, CreateTags
 * RETURN:	    Address of a static buffer containing the word, or
 *	    	    NULL if no next word on the line.
 *	    	    *linePtr is advanced to just beyond the word.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Skip to a leading identifier character, then copy in
 *	trailing identifier characters while they're around.
 *
 *	NOTE: This will screw up the word-numbering for lines like
 *
 *	    biff	hptr.Window 0
 *
 *	but that doesn't matter as the tag is earlier in the line anyway.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/28/89		Initial Revision
 *
 ***********************************************************************/
static char *
GetWord(char	**linePtr)
{
    char    	*lp;			/* pointer to the passed line */
    static char buf[256];		/* buffer for the word */
    char    	*bp;	    	    	/* Pointer into buf */

    lp = *linePtr;			/* lp = start of line */
    bp = buf;

    /*
     * Skip to character that may begin an identifier:
     *	alphabetic, ?, @, _ or $.
     */
    while (isspace(*lp)) {
	lp++;
    }

#define isidchar(c) (isalnum(c)||((c)=='?')||((c)=='@')||((c)=='_')||((c)=='$'))
    if (!isidchar(*lp) && (*lp != '\0')) {
	*bp++ = *lp++;
    } else {
	while(isidchar(*lp)) {
	    *bp++ = *lp++;
	    /* XXX: Check for id too large */
	}
    }

    if (bp == buf) {
	/*
	 * No word after all.
	 */
	return(NULL);
    } else {
	*bp = '\0'; 	/* Null-terminate */
	*linePtr = lp;	/* Advance passed pointer */
	return(buf);	/* Return the word */
    }
}


/***********************************************************************
 *				asm_entries
 ***********************************************************************
 * SYNOPSIS:	    Find tags within the current file
 * CALLED BY:	    find_entries
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/20/92		Initial Revision
 *
 ***********************************************************************/
void
asm_entries()
{
    int	    	wordNum;    	/* Word number at which tag is located in
				 * current line */
    char    	*line;
    int	    	bufsize;
    char	*firstEnd;
    int	    	oldwflag = wflag;

    /*
     * Local labels get repeated a lot in (our) asm files, so don't warn about
     * duplicates.
     */
    wflag = YES;
    inStruct = 0;   	    /* Always starts at 0... */
    
    /*
     * Record position of first line.
     */

    line = lbuf; bufsize = sizeof(lbuf);
    firstEnd = lbuf;

    while (fgets(line, bufsize, inf) != NULL) {
	char	*cp = line + strlen(line) - 1;

	if (cp != line && cp[-1] == '\\') {
	    /*
	     * Line must be joined to following one to get anything meaninginful
	     */
	    lineno += 1;
	    cp -= 1;		/* point to backslash to overwrite */
	    if (firstEnd == lbuf) {
		firstEnd = cp;
	    }
	    bufsize -= cp - line;
	    line = cp;
	} else {
	    /*
	     * Now have a full line w/o continuation characters. See if it's
	     * taggable
	     */
	    wordNum = isTagLine(lbuf);
	    
	    if (wordNum != 0) {
		char    *word;
		char    *line = lbuf;
		int	i;
		
		/*
		 * Skip to the tag word.
		 */
		for (i = wordNum; i > 0; i--) {
		    word = GetWord(&line);
		}
		
		if (word == NULL) {
		    fprintf(stderr, "file \"%s\", line %d: tag missing\n",
			    curfile, lineno);
		} else {
		    /*
		     * Register the tag. If the tag is the first word of
		     * the line, use the starting line number, rather than
		     * the ending one, on the assumption that the continuation
		     * is
		     */
		    if (wordNum == 1 && firstEnd != lbuf) {
			*firstEnd = 0;
		    }
		    /*
		     * Remove the trailing newline, as pfnote doesn't know
		     * what to do with it...
		     */
		    line = index(lbuf, '\n');
		    if (line != NULL) {
			/*
			 * Truncate at the newline.
			 */
			*line = '\0';
		    } else {
			/*
			 * Find end of the line for possible truncation
			 */
			line = lbuf + strlen(lbuf);
		    }
		    
		    /*
		     * Truncate the pattern to 256 chars, max, so
		     * mergetags doesn't get upset, and to reduce the size of
		     * some tag files...
		     */
		    if (line - lbuf > 256) {
			lbuf[256] = '\0';
		    }
		    pfnote(word, lineno);
		}
	    }
	    /*
	     * Advance file-position counters to the next line.
	     */
	    lineno += 1;
	    firstEnd = line = lbuf;
	    bufsize = sizeof(lbuf);
	}
    }
    wflag = oldwflag;
}


