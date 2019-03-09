/* 
 * tclUtil.c --
 *
 *	This file contains utility procedures that are used by many Tcl
 *	commands.
 *
 * Copyright 1987 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */

#ifndef lint
static char *rcsid =
"$Id: tclUtil.c,v 1.41 96/06/13 17:23:09 dbaumann Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <ctype.h>
#include "tcl.h"
#include "tclInt.h"

#include <stdio.h>
#include <stdarg.h>
#include <malloc.h>
#include <compat/string.h>
#include <assert.h>

/*
 * Library imports:
 */


/*
 *----------------------------------------------------------------------
 *
 * TclFindElement --
 *
 *	Given a pointer into a Tcl list, locate the first (or next)
 *	element in the list.
 *
 * Results:
 *	The return value is normally TCL_OK, which means that the
 *	element was successfully located.  If TCL_ERROR is returned
 *	it means that list didn't have proper list structure;
 *	interp->result contains a more detailed error message.
 *
 *	If TCL_OK is returned, then *elementPtr will be set to point
 *	to the first element of list, and *nextPtr will be set to point
 *	to the character just after any white space following the last
 *	character that's part of the element.  If this is the last argument
 *	in the list, then *nextPtr will point to the NULL character at the
 *	end of list.  If sizePtr is non-NULL, *sizePtr is filled in with
 *	the number of characters in the element.  If the element is in
 *	braces, then *elementPtr will point to the character after the
 *	opening brace and *sizePtr will not include either of the braces.
 *	If there isn't an element in the list, *sizePtr will be zero, and
 *	both *elementPtr and *termPtr will refer to the null character at
 *	the end of list.  Note:  this procedure does NOT collapse backslash
 *	sequences.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TclFindElement(Tcl_Interp	*interp,	/* Interpreter to use for error
						 * reporting. */
	       register const char *list,	/* String containing Tcl list
						 * with zero or more elements
						 * (possibly in braces). */
	       const char	**elementPtr,	/* Fill in with location of
						 * first significant character
						 * in first element of list. */
	       const char	**nextPtr,	/* Fill in with location of
						 * character just after all
						 * white space following end of
						 * argument (i.e. next argument
						 * or end of list). */
	       int		*sizePtr,	/* If non-zero, fill in with
						 * size of element. */
	       int		*bracePtr)	/* If non-zero fill in with
						 * non-zero/zero to indicate
						 * that arg was/wasn't in
						 * braces. */
{
    register const char *p;
    int openBraces = 0;
    int size;

    /*
     * Skim off leading white space and check for an opening brace.
     */

    while (isspace(*list)) {
	list++;
    }
    if (*list == '{') {
	openBraces = 1;
	list++;
    }
    if (bracePtr != 0) {
	*bracePtr = openBraces;
    }
    p = list;

    /*
     * Find the end of the element (either a space or a close brace or
     * the end of the string).
     */

    while (1) {
	switch (*p) {

	    /*
	     * Open brace: don't treat specially unless the element is
	     * in braces.  In this case, keep a nesting count.
	     */

	    case '{':
		if (openBraces != 0) {
		    openBraces++;
		}
		break;

	    /*
	     * Close brace: if element is in braces, keep nesting
	     * count and quit when the last close brace is seen.
	     */

	    case '}':
		if (openBraces == 1) {
		    const char *p2;

		    size = p - list;
		    p++;
		    if (isspace(*p) || (*p == 0)) {
			goto done;
		    }
		    for (p2 = p; (*p2 != 0) && (!isspace(*p2)) && (p2 < p+20);
			    p2++) {
			/* null body */
		    }
		    Tcl_RetPrintf(interp, 
				  "list element in braces followed by \"%.*s\" instead of space",
				  p2-p, p);
		    return TCL_ERROR;
		} else if (openBraces != 0) {
		    openBraces--;
		}
		break;

	    /*
	     * Backslash:  skip over everything upp to the end of the
	     * backslash sequence.
	     */

	    case '\\': {
		int size;

		(void) Tcl_Backslash(p, &size);
		p += size - 1;
		break;
	    }

	    /*
	     * Space: ignore if element is in braces;  otherwise
	     * terminate element.
	     */

	    case ' ':
	    case '\t':
	    case '\n':
		if (openBraces == 0) {
		    size = p - list;
		    goto done;
		}
		break;

	    /*
	     * End of list:  terminate element.
	     */

	    case 0:
		if (openBraces != 0) {
		    Tcl_Return(interp, "unmatched open brace in list",
			    TCL_STATIC);
		    return TCL_ERROR;
		}
		size = p - list;
		goto done;

	}
	p++;
    }

    done:
    while (isspace(*p)) {
	p++;
    }
    *elementPtr = list;
    *nextPtr = p;
    if (sizePtr != 0) {
	*sizePtr = size;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TclCopyAndCollapse --
 *
 *	Copy a string and eliminate any backslashes that aren't in braces.
 *
 * Results:
 *	There is no return value.  Count chars. get copied from src
 *	to dst.  Along the way, if backslash sequences are found outside
 *	braces, the backslashes are eliminated in the copy.
 *	After scanning count chars. from source, a null character is
 *	placed at the end of dst.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TclCopyAndCollapse(int 	    	    count,
		   register const char *src,/* Copy from here... */
		   register char    *dst)   /* ... to here. */
{
    register char c;
    int numRead;

    for (c = *src; count > 0; dst++, src++, c = *src, count--) {
	if (c == '\\') {
	    *dst = Tcl_Backslash(src, &numRead);
	    src += numRead-1;
	    count -= numRead-1;
	} else {
	    *dst = c;
	}
    }
    *dst = 0;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_Merge --
 *
 *	Given a collection of strings, merge them together into a
 *	single string that has proper Tcl list structured (i.e.
 *	TclFindElement and TclCopyAndCollapse may be used to retrieve
 *	strings equal to the original elements, and Tcl_Eval will
 *	parse the string back into its original elements).
 *
 * Results:
 *	The return value is the address of a dynamically-allocated
 *	string containing the merged list.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

char *
Tcl_Merge(int	argc,	/* How many strings to merge. */
	  char 	**argv)	/* Array of string values. */
{
    /*
     * This procedure operates in two passes.  In the first pass it figures
     * out how many bytes will be needed to store the result (actually,
     * it overestimates slightly).  The first pass also collects information
     * about each element in the form of a flags word.  If there are only
     * a few elements, local storage gets used for the flags;  if there are
     * a lot of elements, a new array is dynamically allocated.
     *
     * In the second pass this procedure copies the arguments into the
     * result string.  The special cases to worry about are:
     *
     * 1. Argument contains embedded spaces, or starts with a brace:  must
     * add another level of braces when copying to the result.
     *
     * 2. Argument contains unbalanced braces:  backslash all of the
     * braces when copying to the result.  In this case, don't add another
     * level of braces (they would prevent the backslash from
     * being removed when the argument is extracted from the list later).
     *
     * 3. Argument contains backslashed brace/bracket:  if possible,
     * group the argument in braces:  then no special action needs to be taken
     * with the backslashes.  If the argument can't be put in braces, then
     * add another backslash in front of the sequence, so that upon
     * extraction the original sequence will be restored.
     *
     * These potential problems are the reasons why particular information
     * is gathered during pass 1.
     */
#   define WANT_PARENS			1
#   define PARENS_UNBALANCED		2
#   define PARENTHESIZED		4
#   define CANT_PARENTHESIZE		8

#   define LOCAL_SIZE 20
    int localFlags[LOCAL_SIZE];
    int *flagPtr;
    int numChars;
    char *result;
    register const char *src;
    register char *dst;
    register int curFlags;
    int i;

    /*
     * Pass 1: estimate space, gather information.
     */

    if (argc <= LOCAL_SIZE) {
	flagPtr = localFlags;
    } else {
	flagPtr = (int *) malloc((unsigned) argc*sizeof(int));
    }
    numChars = 0;
    for (i = 0; i < argc; i++) {
	int braceCount, nestingLevel, nestedBS, whiteSpace, brackets, dollars;

	curFlags = braceCount = nestingLevel = nestedBS = whiteSpace = 0;
	brackets = dollars = 0;
	src = argv[i];
	if (*src == '{') {
	    curFlags |= PARENTHESIZED|WANT_PARENS;
	}
	if (*src == 0) {
	    curFlags |= WANT_PARENS;
	} else {
	    for (; ; src++) {
		switch (*src) {
		    case '{':
			braceCount++;
			nestingLevel++;
			break;
		    case '}':
			braceCount++;
			nestingLevel--;
			break;
		    case ']':
		    case '[':
			curFlags |= WANT_PARENS;
			brackets++;
			break;
		    case '$':
			curFlags |= WANT_PARENS;
			dollars++;
			break;
		    case ' ':
		    case '\n':
		    case '\t':
			curFlags |= WANT_PARENS;
			whiteSpace++;
			break;
		    case '\\':
			src++;
			if (*src == 0) {
			    goto elementDone;
			} else if ((*src == '{') || (*src == '}')
				|| (*src == '[') || (*src == ']')) {
			    curFlags |= WANT_PARENS;
			    nestedBS++;
			}
			break;
		    case 0:
			goto elementDone;
		}
	    }
	}
	elementDone:
	numChars += (char *)src - argv[i];
	if (nestingLevel != 0) {
	    numChars += braceCount + nestedBS + whiteSpace
		    + brackets + dollars;
	    curFlags = CANT_PARENTHESIZE;
	}
	if (curFlags & WANT_PARENS) {
	    numChars += 2;
	}
	numChars++;		/* Space to separate arguments. */
	flagPtr[i] = curFlags;
    }

    /*
     * Pass two: copy into the result area.
     */

    result = (char *) malloc((unsigned) numChars + 1);
    dst = result;
    for (i = 0; i < argc; i++) {
	curFlags = flagPtr[i];
	if (curFlags & WANT_PARENS) {
	    *dst = '{';
	    dst++;
	}
	for (src = argv[i]; *src != 0 ; src++) {
	    if (curFlags & CANT_PARENTHESIZE) {
		switch (*src) {
		    case '{':
		    case '}':
		    case ']':
		    case '[':
		    case '$':
		    case ' ':
			*dst = '\\';
			dst++;
			break;
		    case '\n':
			*dst = '\\';
			dst++;
			*dst = 'n';
			goto loopBottom;
		    case '\t':
			*dst = '\\';
			dst++;
			*dst = 't';
			goto loopBottom;
		    case '\\':
			*dst = '\\';
			dst++;
			src++;
			if ((*src == '{') || (*src == '}') || (*src == '[')
				|| (*src == ']')) {
			    *dst = '\\';
			    dst++;
			} else if (*src == 0) {
			    goto pass2ElementDone;
			}
			break;
		}
	    }
	    *dst = *src;
	    loopBottom:
	    dst++;
	}
	pass2ElementDone:
	if (curFlags & WANT_PARENS) {
	    *dst = '}';
	    dst++;
	}
	*dst = ' ';
	dst++;
    }
    if (dst == result) {
	*dst = 0;
    } else {
	dst[-1] = 0;
    }

    if (flagPtr != localFlags) {
	free((char *) flagPtr);
    }
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_Return --
 *
 *	Arrange for "string" to be the Tcl return value.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	interp->result is left pointing either to "string" (if status
 *	is TCL_STATIC or TCL_DYNAMIC) or to a copy of "string" (if
 *	status is TCL_VOLATILE).
 *
 *----------------------------------------------------------------------
 */

void
Tcl_Return(Tcl_Interp	*interp,    /* Interpreter with which to associate the
				     * return value. */
	   const char	*string,    /* Value to be returned.  If NULL, the
				     * result is set to an empty string. */
	   int		status)	    /* Gives information about the string:
				     * TCL_STATIC, TCL_DYNAMIC, TCL_VOLATILE.
				     * Ignored if string is NULL. */
{
    register Interp *iPtr = (Interp *) interp;
    int length;
    int wasDynamic = iPtr->dynamic;
    const char *oldResult = iPtr->result;
    char *res;

    if (string == NULL) {
	iPtr->resultSpace[0] = 0;
	iPtr->result = iPtr->resultSpace;
	iPtr->dynamic = 0;
    } else if (status == TCL_STATIC) {
	extern char **environ;
#ifdef unix
	/* make sure the string isn't on the stack */
	assert(string < (const char *)&string || string >= (const char *)environ);
#endif
	iPtr->result = string;
	iPtr->dynamic = 0;
    } else if (status == TCL_DYNAMIC) {
	assert(malloc_tag((malloc_t)string) != 255);
	iPtr->result = string;
	iPtr->dynamic = 1;
    } else {
	length = strlen(string);
	if (length > TCL_RESULT_SIZE) {
	    iPtr->dynamic = 1;
	    res = (char *) malloc((unsigned) length+1);
	} else {
	    iPtr->dynamic = 0;
	    res = iPtr->resultSpace;
	}
	bcopy(string, res, length+1);
	iPtr->result = res;
    }

    /*
     * If the old result was dynamically-allocated, free it up.  Do it
     * here, rather than at the beginning, in case the new result value
     * was part of the old result value.
     */

    if (wasDynamic) {
	free((malloc_t)oldResult);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_RetPrintf --
 *
 *	Return a formatted string from a procedure. Handles the freeing
 *	of any dynamically-allocated previous result.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	interp->result is left pointing to tclResultSpace, which contains
 *	the properly-formatted result.
 *
 *----------------------------------------------------------------------
 */
/*VARARGS2*/
void
Tcl_RetPrintf(Tcl_Interp    *interp,	/* Interpreter with which to associate
					 * the return value. */
	      const char    *format,	/* Format string */
	      ...)
{
    va_list 	  	args;
    register Interp 	*iPtr = (Interp *) interp;
    int     	  	wasDynamic = iPtr->dynamic;
    const char 	  	*oldResult = iPtr->result;
#if defined(isi)
    FILE    	  	f;
#endif

    /*
     * Initialize result for printing
     */
    iPtr->dynamic = 0;
    iPtr->result = iPtr->resultSpace;

    va_start(args, format);

#if defined(isi)
    /*
     * AAACCCCKKK GAG CHOKE. ISI doesn't provide vsprintf, so we must
     * do it ourselves. _buf and _ptr point to the buffer and the current
     * place in it, respectively. _bufsiz is the actual size of the buffer,
     * while _cnt is the number of characters remaining in it (in our case,
     * the number of characters that may still be written). Since there
     * must be room for the null termination, we make the _cnt be 1 minus
     * the buffer size. _flag is just a collection of flags. We use write
     * mode and tell it it's a string (so it doesn't try to write the
     * buffer anywhere). Finally, we set _file to be -1 to make sure it
     * can't be written anywhere.
     *
     * Once the setup is done, we can call _doprnt with the proper args and
     * it will format it into the string (w/o overflow), but it won't null-
     * terminate the thing -- we do that using putc.
     */
    f._base = f._ptr = (unsigned char *)iPtr->resultSpace;
    f._cnt = TCL_RESULT_SIZE - 1;
    f._bufsiz = TCL_RESULT_SIZE;
    f._flag = _IOWRT|_IOSTRG;
    f._file = -1;

    _doprnt(format, args, &f);
    putc('\0', &f);
#else
    /*
     * Ahhhh. Simplicity. vsprintf is set up to do all that automatically.
     */
    vsprintf(iPtr->resultSpace, format, args);
#endif /* 0 */

    /*
     * Finish using the args (on most systems, this is a nop)
     */
    va_end(args);

    /*
     * If the old result was dynamically-allocated, free it up.  Do it
     * here, rather than at the beginning, in case the new result value
     * was part of the old result value.
     */

    if (wasDynamic) {
	free((malloc_t)oldResult);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_Backslash --
 *
 *	Figure out how to handle a backslash sequence.
 *
 * Results:
 *	The return value is the character that should be substituted
 *	in place of the backslash sequence that starts at src.  If
 *	readPtr isn't NULL then it is filled in with a count of the
 *	number of characters in the backslash sequence.  Note:  if
 *	the backslash isn't followed by characters that are understood
 *	here, then the backslash sequence is only considered to be
 *	one character long, and it is replaced by a backslash char.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

char
Tcl_Backslash(const char  *src,	/* Points to the backslash character of a
				 * backslash sequence. */
	      int   *readPtr)	/* Fill in with number of characters read from
				 * src, unless NULL. */
{
    register const char *p = src+1;
    char result;
    int count;

    count = 2;

    switch (*p) {
	case 'b':
	    result = '\b';
	    break;
	case 'e':
	    result = 033;
	    break;
	case 'n':
	    result = '\n';
	    break;
	case 't':
	    result = '\t';
	    break;
	case 'r':
	    result = '\r';
	    break;
	case 'f':
	    result = '\f';
	    break;
	case 'C':
	    p++;
	    if (isspace(*p) || (*p == 0)) {
		result = 'C';
		count = 1;
		break;
	    }
	    count = 3;
	    if (*p == 'M') {
		p++;
		if (isspace(*p) || (*p == 0)) {
		    result = 'M' & 037;
		    break;
		}
		count = 4;
		result = (*p & 037) | 0200;
		break;
	    }
	    count = 3;
	    result = *p & 037;
	    break;
	case 'M':
	    p++;
	    if (isspace(*p) || (*p == 0)) {
		result = 'M';
		count = 1;
		break;
	    }
	    count = 3;
	    result = *p + 0200;
	    break;
	case '}':
	case '{':
	case ']':
	case '[':
	case '$':
	case ' ':
	case '\\':
	    result = *p;
	    break;
	default:
	    if (isdigit(*p)) {
		result = *p - '0';
		p++;
		if (!isdigit(*p)) {
		    break;
		}
		count = 3;
		result = (result << 3) + (*p - '0');
		p++;
		if (!isdigit(*p)) {
		    break;
		}
		count = 4;
		result = (result << 3) + (*p - '0');
		break;
	    }
	    result = '\\';
	    count = 1;
	    break;
    }

    if (readPtr != NULL) {
	*readPtr = count;
    }
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_SplitList --
 *
 *	Splits a list up into its constituent fields.
 *
 * Results
 *	The return value is normally TCL_OK, which means that
 *	the list was successfully split up.  If TCL_ERROR is
 *	returned, it means that "list" didn't have proper list
 *	structure;  interp->result will contain a more detailed
 *	error message.
 *
 *	*argvPtr will be filled in with the address of an array
 *	whose elements point to the elements of list, in order.
 *	*argcPtr will get filled in with the number of valid elements
 *	in the array.  A single block of memory is dynamically allocated
 *	to hold both the argv array and a copy of the list (with
 *	backslashes and braces removed in the standard way).
 *	The caller must eventually free this memory by calling free()
 *	on *argvPtr.  Note:  *argvPtr and *argcPtr are only modified
 *	if the procedure returns normally.
 *
 * Side effects:
 *	Memory is allocated.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_SplitList(Tcl_Interp    *interp,	/* Interpreter to use for error
					 * reporting. */
	      const char    *list,	/* Pointer to string with list
					 * structure. */
	      int	    *argcPtr,	/* Pointer to location to fill in with
					 * the number of elements in the list.
					 */
	      char	    ***argvPtr)	/* Pointer to place to store pointer to
					 * array of pointers to list elements.
					 */
{
    char **argv;
    register char *p;
    int size, i, result, elSize, brace;
    const char *element;

    /*
     * Figure out how much space to allocate.  There must be enough
     * space for both the array of pointers and also for a copy of
     * the list.  To estimate the number of pointers needed, count
     * the number of space characters in the list.
     */

    for (size = 1, p = (char *)list; *p != 0; p++) {
	if (isspace(*p)) {
	    size++;
	}
    }
    argv = (char **) malloc((unsigned)
	    ((size * sizeof(char *)) + ((const char *)p - list) + 1));

    for (i = 0, p = ((char *) argv) + size*sizeof(char *);
	 *list != 0;
	 i++)
    {
	result = TclFindElement(interp, list, &element, &list, &elSize, &brace);
	if (result != TCL_OK) {
	    free((char *) argv);
	    return result;
	}
	if (*element == 0) {
	    break;
	}
	if (i >= size) {
	    Tcl_Return(interp, "internal error in Tcl_SplitList", TCL_STATIC);
	    return TCL_ERROR;
	}
	argv[i] = p;
	if (brace) {
	    strncpy(p, element, elSize);
	    p += elSize;
	    *p = 0;
	    p++;
	} else {
	    TclCopyAndCollapse(elSize, element, p);
	    p += elSize+1;
	}
    }

    *argvPtr = argv;
    *argcPtr = i;
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_StringMatch --
 *
 *      See if a particular string matches a particular pattern.
 *
 * Results:
 *      Non-zero is returned if string matches pattern, 0 otherwise.
 *      The matching operation permits the following special characters
 *      in the pattern: *?\[] (see the man page for details on what
 *      these mean).
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_StringMatch(register const char *string,  /* String. */
		register const char *pattern) /* Pattern, which may contain
					       * special characters.
					       */
{
    char    	    c2;
    register char   pchar = *pattern;
    register char   schar = *string;

    while (1) {
	switch (pchar) {
	case 0:
	    /* See if we're at the end of both the pattern and the string.
	     * If, we succeeded.  If we're at the end of the pattern but
	     * not at the end of the string, we failed.
	     */
            return (schar == 0);
	case '*':
	    /* Check for a "*" as the next pattern character.  It matches
	     * any substring.  We handle this by calling ourselves
	     * recursively for each postfix of string, until either we
	     * match or we reach the end of the string.
	     */
	    if (*++pattern == 0) {
		return 1;
	    }
	    while (*string != 0) {
		if (Tcl_StringMatch(string++, pattern)) {
                    return 1;
                }
            }
            return 0;
	case '?':
	    /* Check for a "?" as the next pattern character.  It matches
	     * any single character.
	     */
	    if (schar == 0) {
		/*
		 * Except null...
		 */
		return(0);
	    }
	    break;
	case '[':
	    /* Check for a "[" as the next pattern character.  It is followed
	     * by a list of characters that are acceptable, or by a range
	     * (two characters separated by "-").
	     */
	    
            pattern += 1;
	    if (*pattern == '^') {
		/*
		 * Inverse class -- want a character not in any of the ranges
		 * in the class.
		 */
		pattern++;
		while (1) {
		    pchar = *pattern;
		    if ((pchar == ']') || (pchar == 0)) {
			/* success */
			break;
		    }
		    
		    if (pchar == (schar = *string)) {
			return 0;
		    }
		    if (*++pattern == '-') {
			c2 = *++pattern;
			if (c2 == 0) {
			    break;
			}
			/*
			 * XXX: Used to allow both 0-9 and 9-0, but why? The
			 * range is inherently character-set specific, so
			 * the user knows which comes first and will,
			 * probably w/o exception, put the characters in the
			 * correct order, so this generality is a waste
			 * of time.
			 */
			if ((pchar < schar) && (c2 >= schar)) {
			    /* in-bounds: no match */
			    return 0;
			} else {
			    pattern += 1;
			}
		    }
		}
	    } else {
		while (1) {
		    pchar = *pattern;
		    if ((pchar == ']') || (pchar == 0)) {
			return 0;
		    }
		    
		    if (pchar == (schar = *string)) {
			break;
		    }
		    if (*++pattern == '-') {
			c2 = *++pattern;
			if (c2 == 0) {
			    return 0;
			}
			/*
			 * XXX: Used to allow both 0-9 and 9-0, but why? The
			 * range is inherently character-set specific, so
			 * the user knows which comes first and will,
			 * probably w/o exception, put the characters in the
			 * correct order, so this generality is a waste
			 * of time.
			 */
			if ((pchar < schar) && (c2 >= schar)) {
			    break;
			} else {
			    pattern += 1;
			}
		    }
		}
	    }

	    /*
	     * Skip to the end of the class
	     */
            while ((*pattern != ']') && (*pattern != 0)) {
                pattern++;
            }
	    break;
	case '\\':
	    /* If the next pattern character is '\', just strip off the '\'
	     * so we do exact matching on the character that follows.
	     */
	    if ((pchar = *++pattern) == 0) {
		return 0;
	    }
	    /*FALLTHRU*/
	default:
	    /* There's no special character.  Just make sure that the next
	     * characters of each string match.
	     */
        
	    if (pchar != schar) {
		return 0;
	    }
	    break;
	}

        pchar = *++pattern;
        schar = *++string;
    }
}


/***********************************************************************
 *				Tcl_StringSubst
 ***********************************************************************
 * SYNOPSIS:	    Perform string substitution.
 * CALLED BY:	    GLOBAL
 * RETURN:	    The resulting string after substitution. The caller
 *	    	    must free it.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/24/91		Initial Revision
 *
 ***********************************************************************/
char *
Tcl_StringSubst(const char *string, 	/* String to manipulate */
		const char *search, 	/* String for which to search */
		const char *replace,	/* String with which to replace it */
		int 	    global)
{
    char    *result;	    	    	/* Base of result space */
    int	    size = strlen(string)+1;	/* Initial size of same */
    char    *resptr;	    	    	/* Next free char in result space */
    int	    searchLen=strlen(search);
    int	    replaceLen=strlen(replace);
    int	    done = 0;	    	    	/* Set non-zero if found search
					 * string and global is false */

    /*
     * Start out with the result space the same size as the string itself.
     * Seems the only reasonable assumption...
     */
    resptr = result = (char *)malloc(size);

    /*
     * Basic algorithm:
     *	if next chars in string match the search string, store the
     *	    replacement string and advance over the found search-string
     *	else store the first char and advance to the next.
     */
    while (*string != '\0') {
	/*
	 * If already done a replacement in a non-global substitution, or
	 * the string at "string" doesn't match the search string, just
	 * copy the current character in.
	 */
	if (done || strncmp(string, search, searchLen)) {
	    *resptr++ = *string++;
	    /*
	     * If buffer now full, double its size.
	     */
	    if (resptr - result == size) {
		result = (char *)realloc(result, size*2);
		resptr = result + size;
		size *= 2;
	    }
	} else {
	    /*
	     * Found the search string, so store the replace string in the
	     * result buffer.
	     */
	    int	newsize;    	    /* Number of chars needed, minimum (includes
				     * null terminator needed eventually) */

	    newsize = (resptr - result) + replaceLen + 1;
	    if (newsize >= size) {
		size = resptr-result;	    /* remember where resptr was */

		newsize += 100;	    	    /* Give it 100 extra bytes, for
					     * luck... */
		result = (char *)realloc(result, newsize);
		resptr = result + size;
		size = newsize;
	    }

	    /*
	     * Copy the replacement string into the result space.
	     */
	    bcopy(replace, resptr, replaceLen);

	    /*
	     * Advance resptr over the replacement, and string over the search
	     * string.
	     */
	    resptr += replaceLen;
	    string += searchLen;

	    /*
	     * If substitution not global, set "done" so we just copy things
	     * in without searching.
	     */
	    if (!global) {
		done = 1;
	    }
	}
    }

    /*
     * Null-terminate and shrink to fit.
     */
    *resptr = '\0';
    result = (char *)realloc(result, (resptr+1) - result);

    return(result);
}

/***********************************************************************
 *				TclCmdCheckUsage
 ***********************************************************************
 * SYNOPSIS:	    Check the args passed to a command, etc.
 * CALLED BY:	    Tcl
 * RETURN:	    Whatever the command returns
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
int
TclCmdCheckUsage(ClientData clientData,
		 Tcl_Interp *interp,
		 int	    argc,
		 char  	    **argv)
{
    Tcl_CommandRec  *crp = (Tcl_CommandRec *)clientData;
    const Tcl_SubCommandRec *match, *cur;
    int	    	    cmdLen;
    int	    	    err;
    int 	result;

    /*
     * Switch the frame's cmdProc vector so Swat's TCL debugger can tell
     * if Tcl_CatchCmd has been called...
     */
    ((Interp *)interp)->top->ext.cmdProc = crp->proc;
    
    cur = crp->data;

    if ((argc < 2) && (cur->subCommand == TCL_CMD_END)) {
	/*
	 * We're just here to provide a uniform interface to something
	 * that takes no arguments. Pass it on through.
	 */
	result = (*crp->proc) ((ClientData)0,
			       interp,
			       argc,
			       argv);
	if (result == TCL_SUBUSAGE || result == TCL_USAGE) {
	    goto make_usage;
	}
    } else if (argc < 2) {
	/*
	 * Create a usage message based on all the possible sub-commands.
	 * It looks like:
	 *  Usage: <cmd> (<sub1>|<sub2>|...|<subn>) ...
	 */
	char	    *cp;
	const char  *last;
	const char  *sep;
	const char  *term;

make_usage:

	last = (const char *)NULL;
	sep = " (";
	term = ") ...";

	Tcl_RetPrintf(interp, "Usage: %s", argv[0]);
	cp = (char *)interp->result + strlen(interp->result);
	
	for (cur = crp->data; cur->subCommand != TCL_CMD_END; cur++) {
	    if (*cur->subCommand != '\0') {
		/*
		 * Subcommand is for real -- stick it into the usage string.
		 */
		sprintf(cp, "%s%s", sep, cur->subCommand);
		cp += strlen(cp);
		sep = "|";
		last = cur->subCommand;
	    } else if (cur->usage != NULL) {
		/*
		 * Subcommand matches anything, but we kinda want to put
		 * something meaningful in here. If the usage string holds
		 * something nice, use it.
		 */
		const char *end = (char *)index(cur->usage, ' ');

		if (end == NULL && *cur->usage != '\0') {
		    /*
		     * Only one word in the usage string -- use it.
		     */
		    end = cur->usage + strlen(cur->usage);
		}
		if (end != NULL) {
		    sprintf(cp, "%s%.*s", sep, end - (const char *)cur->usage,
			    cur->usage);
		    cp += strlen(cp);
		    sep = "|";
		    last = cur->usage;
		}
	    }
	}

	if (interp->helpFetch != 0) {
	    if (last == NULL) {
		/*
		 * No valid arguments other then -help, so mark -help as
		 * optional.
		 */
		sep = " [";
		term = "]";
	    }
	    last = "-help";
	    sprintf(cp, "%s%s", sep, last);
	    cp += strlen(cp);
	}

	if (last != NULL) {
	    /*
	     * At least one option was present, so append the proper
	     * terminator.
	     */
	    strcpy(cp, term);
	}
	result = TCL_ERROR;
    } else {
	/*
	 * Look for a match in the set of possible subcommands.
	 */
	char	*cmd = argv[1];
	char	first = *cmd;
	int 	numAmbig = 0;

	match = NULL;
	cmdLen = strlen(cmd);
	err = 0;
	
	/*
	 * Handle the -help switch.
	 */
	if (interp->helpFetch != 0 && strcmp(cmd, "-help") == 0) {
	    Tcl_Return(interp, (*interp->helpFetch)(crp->name, crp->helpClass),
		       TCL_DYNAMIC);
	    return(TCL_OK);
	}
	
	for (cur = crp->data; cur->subCommand != NULL; cur++) {
	    if ((cur->subCommand[0] == first) &&
		(strncmp(cur->subCommand, argv[1], cmdLen) == 0))
	    {
		if (strlen(cur->subCommand) == cmdLen) {
		    /*
		     * Prefer an exact match...
		     */
		    match = cur;
		    if (err) {
			/*
			 * Make sure we don't return an error
			 */
			Tcl_Return(interp, NULL, TCL_STATIC);
			err = 0;
		    }
		    break;
		} else if (match == NULL) {
		    /*
		     * Nothing matched yet. Record this one as a possible...
		     */
		    match = cur;
		} else {
		    if (!err) {
			/*
			 * Second possible match. Initialize the error message
			 * and flag an error.
			 */
			Tcl_RetPrintf(interp, "%s ambiguous. Matches: %s, %s",
				      cmd, match->subCommand, cur->subCommand);
			numAmbig = 2;
			err = 1;
		    } else {
			/*
			 * Add yet another possible match.
			 */
			if (numAmbig < 5) {
			    strcat(((Interp *)interp)->resultSpace, ", ");
			    strcat(((Interp *)interp)->resultSpace,
				   cur->subCommand);
			} else if (numAmbig == 5) {
			    strcat(((Interp *)interp)->resultSpace, "...");
			}
			numAmbig += 1;
		    }
		}
	    }
	}

	if (match == NULL) {
	    /*
	     * No match. Look for the match-anything token (an empty string)
	     */
	    for (cur = crp->data; cur->subCommand != NULL; cur++) {
		if (*cur->subCommand == '\0') {
		    /*
		     * Empty -- pretend it matches
		     */
		    match = cur;
		    break;
		}
	    }
	    if (match == NULL) {
		/*
		 * Still null -- tell the user the things s/he can type.
		 */
		goto make_usage;
	    }
	}
	if (err) {
	    return(TCL_ERROR);
	}

	/*
	 * Make sure it's got the right number of arguments. If either
	 * limit is 0, it means not to check that one. In addition, if the
	 * procedure returns TCL_SUBUSAGE, it wants us to provide a usage
	 * message for the subcommand.
	 */
	if ((match->minArgs != TCL_CMD_NOCHECK && (argc-2) < match->minArgs) ||
	    (match->maxArgs != TCL_CMD_NOCHECK && (argc-2) > match->maxArgs) ||
	    ((result = (* crp->proc) (match->data,
				      interp,
				      argc,
				      argv)) == TCL_SUBUSAGE))
	{
	    if (*match->subCommand) {
		Tcl_RetPrintf(interp, "Usage: %s %s %s", argv[0], argv[1],
			      match->usage);
	    } else {
		Tcl_RetPrintf(interp, "Usage: %s %s", argv[0], match->usage);
	    }
	    return(TCL_ERROR);
	} else if (result == TCL_USAGE) {
	    /*
	     * Return usage message for the whole command
	     */
	    goto make_usage;
	}

    }
    return(result);
}

