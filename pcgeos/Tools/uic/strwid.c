/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  UIC -- string widths
 * FILE:	  strwid.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * DESCRIPTION:
 *	Output routines for UIC
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: strwid.c,v 1.2 93/01/18 20:57:13 tony Exp $";
#endif lint

#include    <config.h>
#include    "uic.h"
#include    "strwid.h"

#include    <ctype.h>
#include    <compat/string.h>

int Berkeley9WidthTable[] = {
	4, 3, 6, 6, 8, 11, 8, 4, 5, 5, 6, 7, 4, 6, 3, 6,
	7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 4, 6, 6, 6,
	7, 10, 7, 7, 7, 7, 6, 6, 7, 7, 3, 7, 8, 6, 9,
	8, 7, 7, 7, 7, 7, 7, 7, 7, 9, 7, 7, 6, 4, 6,
	4, 6, 6, 4, 7, 7, 7, 7, 7, 6, 7, 7, 3, 5, 7,
	3, 11, 7, 7, 7, 7, 6, 7, 5, 7, 7, 11, 7, 7, 6,
	5, 3, 5, 7, 0, 7, 7, 7, 6, 8, 7, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7, 3, 3, 3, 3, 7, 7, 7,
	7, 7, 7, 6, 7, 7, 7, 5, 6, 8, 7, 8, 6, 9, 9,
	11, 11, 12, 4, 4, 7, 10, 9, 12, 7, 5, 5, 7, 7, 7,
	8, 9, 10, 5, 7, 7, 10, 11, 8, 7, 3, 7, 9, 5, 8,
	8, 9, 10, 9, 4, 7, 7, 7, 10, 11, 7, 9, 7, 7, 4,
	4, 7, 10, 7, 7, 8, 9, 5, 5, 7, 7, 5, 4, 4, 7,
	14, 7, 6, 7, 6, 6, 3, 3, 3, 3, 7, 7, 9, 7, 7,
	7, 7, 3, 4, 7, 6, 5, 3, 5, 3, 5, 3, 4
};

int Berkeley10WidthTable[] = {
	4, 3, 6, 8, 7, 11, 8, 4, 5, 5, 8, 7, 4, 5, 3,
	6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 4, 5, 6,
	5, 7, 10, 7, 7, 7, 7, 6, 6, 7, 7, 3, 7, 8, 6,
	10, 8, 7, 7, 7, 7, 8, 7, 7, 7, 10, 8, 7, 7, 4,
	6, 4, 6, 7, 4, 7, 7, 7, 7, 7, 6, 7, 7, 3, 5,
	7, 3, 11, 7, 7, 7, 7, 6, 7, 5, 7, 7, 11, 8, 7,
	6, 5, 3, 5, 7, 0, 7, 7, 7, 6, 8, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 3, 4, 3, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7, 5, 7, 8, 8, 8, 6, 9,
	9, 11, 11, 14, 3, 4, 7, 10, 9, 13, 7, 6, 6, 7, 8,
	7, 8, 8, 9, 5, 6, 6, 8, 11, 8, 7, 3, 6, 9, 5,
	9, 9, 9, 9, 9, 5, 7, 7, 7, 10, 11, 6, 9, 7, 7,
	4, 4, 7, 9, 6, 7, 8, 9, 5, 5, 7, 7, 4, 3, 4,
	8, 14, 7, 6, 7, 6, 6, 3, 3, 3, 3, 7, 7, 9, 7,
	7, 7, 7, 3, 4, 7, 6, 5, 2, 4, 3, 5, 3, 4
};

 /*
  *	Name: GetStringWidth
  *	Author: Tony Requist
  *
  *	Synopsis: Calculate the width of a string
  *
  */
int GetStringWidth(char *string, int widthTable[], int ptsize)
{
    int width = 0;
    int c;

    while (*string != '\0') {
	/*
	 * Deal with octal numbers
	 */
	if (*string == '\\') {
	    int i;

	    string++;
	    c = 0;
	    for (i = 0; (i < 3) && (*string != '\0'); i++) {
		c = (c * 8) + ((*string++)-'0');
	    }
	} else {
	    c = *string++;
	}
	/*
	 * In Pizza (the only current DBCS release), we use 12 and 16 point,
	 * but the values are in the same place.  We don't have a 12 point
	 * yet, so just stuff 0 in for now, which will cause the width to
	 * be calculated when needed.
	 */
	if (dbcsRelease && ptsize == 10) {
	    if (c < 256) {
	    	width += 8;
	    } else {
		width += 16;
	    }
	} else {
	    width += widthTable[c-32];
	}
    }
    return(width);
}

/*
 *	Name: CalcHintedWidth
 *	Author: Tony Requist
 *
 *	Synopsis: Calculate the hinted width for a string
 *
 */
int CalcHintedWidth(char *string)
{
    int width9, width10;

    if ((string == NULL) || (*string == '\0')) {
	return(0);
    }

    width9 = GetStringWidth(string, Berkeley9WidthTable, 9);
    if (width9 > MAX_WIDTH_9) {
	return(0);
    }
    width10 = GetStringWidth(string, Berkeley10WidthTable, 10);
    if (width9 > MAX_WIDTH_10) {
	return(0);
    }
    return (VMCW_HINTED |
	    (width9 << VMCW_BERKELEY_9_OFFSET) |
	    (width10 << VMCW_BERKELEY_10_OFFSET));
}
