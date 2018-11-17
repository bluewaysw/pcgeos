/*-
 * str.c --
 *	General utilites for handling strings.
 *
 * Copyright (c) 1988, 1989 by the Regents of the University of California
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any non-commercial purpose
 * and without fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California,
 * Berkeley Softworks and Adam de Boor make no representations about
 * the suitability of this software for any purpose.  It is provided
 * "as is" without express or implied warranty.
 *
 * Interface:
 *	Str_Concat	     	Concatenate two strings, placing some sort
 *	    	  	    	of separator between them and freeing
 *	    	  	    	the two strings, all this under the control
 *	    	  	    	of the STR_ flags given as the third arg.
 *
 *	Str_New	  	    	Duplicate a string and return the copy.
 *
 *	Str_FindSubstring   	Find a substring within a string (from
 *	    	  	    	original Sprite libc).
 *
 *	Str_Match   	    	Pattern match two strings.
 */
#include <config.h>

#ifndef lint
static char     *rcsid = "$Id: str.c,v 1.10 96/06/24 15:07:08 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include <malloc.h>

#if defined(__BORLANDC__) || defined(__WATCOMC__)
typedef char * malloc_t;
#endif

#include <compat/string.h>
#include <compat/stdlib.h>

/**********************prototypes for static routines**********************/
static char	DoBackslash(char c);

#include    "make.h"

/*-
 *-----------------------------------------------------------------------
 * Str_Concat  --
 *	Str_Concatenate and the two strings, inserting a space between them
 *	and/or freeing them if requested
 *
 * Results:
 *	the resulting string
 *
 * Arguments:
 *      char *s1    : First string
 *      char *s2    : Second string
 *      int   flags : Flags governing Str_Concatenation
 *
 * Side Effects:
 *	The strings s1 and s2 are free'd
 *-----------------------------------------------------------------------
 */
char *
Str_Concat (char *s1, char *s2, int flags)
{
    int             len;	/* total length */
    register char  *cp1,	/* pointer into s1 */
                   *cp2,	/* pointer into s2 */
                   *cp;		/* pointer into result */
    char           *result;	/* result string */

    /*
     * get the length of both strings 
     */
    for (cp1 = s1; *cp1; cp1++) {
	 /* void */ ;
    }
    for (cp2 = s2; *cp2; cp2++) {
	 /* void */ ;
    }

    len = (cp1 - s1) +
	(cp2 - s2) +
	    (flags & (STR_ADDSPACE | STR_ADDSLASH) ? 1 : 0) +
		1;

    MallocCheck (result, len);
    for (cp1 = s1, cp = result; *cp1 != '\0'; cp++, cp1++) {
	*cp = *cp1;
    }

    if (flags & STR_ADDSPACE) {
	*cp++ = ' ';
    } else if (flags & STR_ADDSLASH) {
#ifdef _WIN32
	*cp++ = '/';	/* XXX:spock */
#else
	*cp++ = PATHNAME_SLASH;	/* XXX:spock */
#endif /* _WIN32 */
    }

    for (cp2 = s2; *cp2 != '\0'; cp++, cp2++) {
	*cp = *cp2;
    }

    *cp = '\0';

    if (flags & STR_DOFREE) {
	free (s1);
	free (s2);
    }
    return (result);
}

/*-
 *-----------------------------------------------------------------------
 * Str_New  --
 *	Create a new unique copy of the given string
 *
 * Results:
 *	A pointer to the new copy of it
 *
 * Arguments:
 *      char *str : String to duplicate
 *
 * Side Effects:
 *	None
 *-----------------------------------------------------------------------
 */
char *
Str_New (char *str)
{
    register char  *cp;		/* new space */

    MallocCheck (cp, strlen (str) + 1);
    (void) strcpy (cp, str);
    return (cp);
}

static char
DoBackslash (char c)
{
    switch (c) {
	case 'n': return ('\n');
	case 't': return ('\t');
	case 'b': return ('\b');
	case 'r': return ('\r');
	case 'f': return ('\f');
	default:  return (c);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Str_BreakString --
 *	Fracture a string into an array of words, taking quotation marks
 *	into account. The string should have its leading 'breaks'
 *	characters removed.
 *
 * Results:
 *	Pointer to the array of pointers to the words. This array must
 *	be freed by the caller. To make life easier, the first word is
 *	always the value of the .PMAKE variable.
 *
 * Arguments:
 *      register char *str     : String to fracture
 *      register char *breaks  : Word delimiters
 *      register char *end     : Characters to end on
 *      Boolean        parseBS : TRUE if should parse backslash sequences
 *                               and convert them to standard characters.
 *      int           *argcPtr : OUT -- Place to stuff number of words
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
char **
Str_BreakString (register char *str, register char *breaks, 
		 register char *end, Boolean parseBS, int *argcPtr)
{
    char            	*defargv[256]; 	/* Temporary argument vector.
					 * Big enough for most purposes. */
    char    	    	**argv;	    	/* Argv being built */
    int	    	    	maxargc;    	/* Length of argv */
    register int    	argc;	    	/* Count of words */
    char            	**av;	    	/* Returned vector */
    register char   	*tstr;	    	/* Pointer into tstring */
    char            	tstring[512];	/* Temporary storage for the
					 * current word */

    argc = 1;
    argv = defargv;
    maxargc = sizeof(defargv)/sizeof(defargv[0]);
    argv[0] = Var_Value (".PMAKE", VAR_GLOBAL);

    tstr = tstring;
    while ((*str != '\0') && (strchr (end, *str) == (char *)NULL)) {
	if (strchr (breaks, *str) != (char *)NULL) {
	    *tstr++ = '\0';
	    argv[argc++] = Str_New(tstring);
	    while ((*str != '\0') &&
		   (strchr (breaks, *str) != (char *)NULL) &&
		   (strchr (end, *str) == (char *)NULL)) {
		       str++;
		   }
	    tstr = tstring;
	    /*
	     * Enlarge the argument vector, if necessary
	     */
	    if (argc == maxargc) {
		maxargc *= 2;
		if (argv == defargv) {
		    MallocCheck(argv, maxargc*sizeof(char *));
		    memcpy(argv, defargv, sizeof(defargv));
		} else {
		    argv = (char **)realloc((malloc_t)argv,
					    maxargc*sizeof(char *));
		}
	    }
	} else if (*str == '"') {
	    str += 1;
	    while ((*str != '"') &&
		   (strchr (end, *str) == (char *)NULL)) {
		       if (*str == '\\') {
			   str += 1;
			   *tstr = DoBackslash(*str);
		       } else {
			   *tstr = *str;
		       }
		       str += 1;
		       tstr += 1;
		   }

	    if (*str == '"') {
		str+=1;
	    }
	} else if (*str == '\'') {
	    str += 1;
	    while ((*str != '\'') &&
		   (strchr (end, *str) == (char *)NULL)) {
		       if (*str == '\\') {
			   str += 1;
			   *tstr = DoBackslash(*str);
		       } else {
			   *tstr = *str;
		       }
		       str += 1;
		       tstr += 1;
		   }
		   
	    if (*str == '\'') {
		str+=1;
	    }
	} else if (parseBS && *str == '\\') {
	    str += 1;
	    *tstr = DoBackslash(*str);
	    str += 1;
	    tstr += 1;
	} else {
	    *tstr = *str;
	    tstr += 1;
	    str += 1;
	}
    }
    if (tstr != tstring) {
	/*
	 * If any word is left over, add it to the vector
	 */
	*tstr = '\0';
	argv[argc++] = Str_New(tstring);
    }
    argv[argc] = (char *) 0;
    *argcPtr = argc;
    if (argv == defargv) {
	MallocCheck (av, (argc+1) * sizeof(char *));
	memcpy ((char *)av, (char *)argv, (argc + 1) * sizeof(char *));
    } else {
	/*
	 * Shrink vector to match actual number of args.
	 */
	av = (char **)realloc((malloc_t)argv, (argc+1) * sizeof(char *));
    }
    
    return av;
}

/*-
 *-----------------------------------------------------------------------
 * Str_FreeVec --
 *	Free a string vector returned by Str_BreakString. Frees all the
 *	strings in the vector and then frees the vector itself.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The blocks addressed by the vector are freed.
 *
 *-----------------------------------------------------------------------
 */
void
Str_FreeVec (register int count, register char **vecPtr)
{
    for (count -= 1; count > 0; count -= 1) {
	free (vecPtr[count]);
    }
    free ((malloc_t)vecPtr);
}

#if !defined(Sprite) && !defined(_WIN32)

/*
 *----------------------------------------------------------------------
 * Str_FindSubstring --
 *	See if a string contains a particular substring.
 *
 * Results:
 *	If string contains substring, the return value is the
 *	location of the first matching instance of substring
 *	in string.  If string doesn't contain substring, the
 *	return value is NULL.  Matching is done on an exact
 *	character-for-character basis with no wildcards or special
 *	characters.
 *
 * Arguments:
 *      register char *string    : String to search
 *      char          *substring : Substring to try to find in string
 *
 * Side effects:
 *	None.
 *----------------------------------------------------------------------
 */
char *
Str_FindSubstring(register char *string, char *substring)
{
    register char *a, *b;

    /*
     * First scan quickly through the two strings looking for a
     * single-character match.  When it's found, then compare the
     * rest of the substring.
     */
    
    b = substring;
    for ( ; *string != 0; string += 1) {
	if (*string != *b) {
	    continue;
	}
	a = string;
	while (TRUE) {
	    if (*b == 0) {
		return string;
	    }
	    if (*a++ != *b++) {
		break;
	    }
	}
	b = substring;
    }
    return (char *) NULL;
}
#endif /* !defined(Sprite) && !defined(_WIN32) */

#if defined(_WIN32)

/***********************************************************************
 *				Str_FindSubstringI
 ***********************************************************************
 *
 * SYNOPSIS:	     See if a string contains a particular substring
 *                   using case-insensitive matching
 * CALLED BY:	     Job module, Var module
 * RETURN:	     If string contains a case-insensitive version of
 *                   substring, the return value is the location of the
 *                   first matching instance of substring in string.
 *                   Otherwise the return value is NULL.  Matching is
 *                   done without wildcards or special characters.
 * SIDE EFFECTS:     None.
 *
 * STRATEGY:	     Search the string for a single character match and
 *                   if one is found, see if it's the beginning of the
 *                   substring.  If it's not the beginning of the
 *                   substring, reset the pointer to the beginning of the
 *                   substring and start over.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/17/96   	Initial Revision
 *
 ***********************************************************************/
char *
Str_FindSubstringI (register char *string, char *substring)
{
    char *sptr = string;

    /* either string isn't valid */
    if (string == NULL || substring == NULL) {
	return NULL;
    }

    do {
	if (toupper(*sptr) == toupper(*substring)) {
	    return ((strnicmp(sptr, substring, strlen(substring)) == 0) 
		    ? sptr 
		    : Str_FindSubstringI(sptr + 1, substring));
	}
	sptr++;
    } while (*sptr != '\0');

    return NULL;
}	/* End of Str_FindSubstringI.	*/
#endif /* defined(_WIN32) */


/*
 *----------------------------------------------------------------------
 *
 * Str_Match --
 *
 *      See if a particular string matches a particular pattern.
 *
 * Results:
 *      Non-zero is returned if string matches pattern, 0 otherwise.
 *      The matching operation permits the following special characters
 *      in the pattern: *?\[] (see the man page for details on what
 *      these mean).
 *
 * Arguments:
 *      register char  *string  : String
 *      register char  *pattern : Pattern which may conatin special chars
 *      char          **index   : Index of /(
 *      char          **index2  : Index of /)
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */

int
Str_Match(register char *string, register char *pattern, char **index1,
	  char **index2)
{
    char c2;

    while (1) {
        /* See if we're at the end of both the pattern and the string.
         * If so, we succeeded.  If we're at the end of the pattern but
         * not at the end of the string, we failed.
         */
        
        if (*pattern == 0) 
	{
            if (*string == 0) 
	    {
                return 1;
            } 
	    else 
	    {
                return 0;
            }
        }

	/* if the string is done and the only thing left is
	 * a \] in the pattern, then we actually have a match
	 * we just need to update the index2 and return a match found
	 * value, otherwise if the pattern hasn't ended, then we don't
	 * have a match
	 */
	if (*string == 0)
	{
	    if ((*pattern == '\\') && (pattern[1] == ']'))
	    {
	    	*index2 = string;
	    	return 1;
	    }

            if ((*pattern != '*'))
	    {
            	return 0;
            }
	}

        /* Check for a "*" as the next pattern character.  It matches
         * any substring.  We handle this by calling ourselves
         * recursively for each postfix of string, until either we
         * match or we reach the end of the string.

	 * if the "*" is the last thing in the pattern, then we have match
	 * or in a" * / ]" (no spaces) is the last thing in the pattern we
	 * also have a match
         */
        
        if (*pattern == '*') {
            pattern += 1;
            if (*pattern == 0) 
	    {
                return 1;
            }
	    if ((*pattern == '\\') && (pattern[1] == ']') && (pattern[2] == 0))
	    {
		/* since we know the string matches, we need to get the
		 * address of the end of the stirng to return in the index
		 */
		while(*string++);
		--string;
	    	*index2 = string;
	    	return 1;
	    }

            while (*string != 0) {
                if (Str_Match(string, pattern, index1, index2)) {
                    return 1;
                }
                string += 1;
            }
            return 0;
        }
    
        /* Check for a "?" as the next pattern character.  It matches
         * any single character.
         */

        if (*pattern == '?') {
            goto thisCharOK;
        }

        /* Check for a "[" as the next pattern character.  It is followed
         * by a list of characters that are acceptable, or by a range
         * (two characters separated by "-").
         */
        
        if (*pattern == '[') {
            pattern += 1;
            while (1) {
                if ((*pattern == ']') || (*pattern == 0)) {
                    return 0;
                }
#if defined(_WIN32)
                if (toupper(*pattern) == toupper(*string)) {
                    break;
                }
#else /* unix or _MSDOS */
		if (*pattern == *string) {
		    break;
		}
#endif /* defined(_WIN32) */
                if (pattern[1] == '-') {
                    c2 = pattern[2];
                    if (c2 == 0) {
                        return 0;
                    }
#if defined(_WIN32)
                    if ((toupper(*pattern) <= toupper(*string)) &&
			(toupper(c2) >= toupper(*string))) {
                        break;
                    }
                    if ((toupper(*pattern) >= toupper(*string)) &&
			(toupper(c2) <= toupper(*string))) {
                        break;
                    }
#else /* unix or _MSDOS */
		    if ((*pattern <= *string) && (c2 >= *string)) {
                        break;
                    }
                    if ((*pattern >= *string) && (c2 <= *string)) {
                        break;
                    }
#endif /* defined(_WIN32) */
                    pattern += 2;
                }
                pattern += 1;
            }
            while ((*pattern != ']') && (*pattern != 0)) {
                pattern += 1;
            }
            goto thisCharOK;
        }
    

	
        /* If the next pattern character is '/', just strip off the '/'
         * so we do exact matching on the character that follows.

	 * But first we must make sure that we aren't really encountering
	 * a /[ /] pair which is a special token used by the :X option
	 * which extracts part of a string on a match, so we want to
	 * ignore these tokens and match the string, the tokens will be
	 * used later on by Var_Extract if we actually have a match
	 * I used the [] braces rather than the () as the paranthesis 
	 * were used as the endc of variable expansion stuff, the [] are
	 * also used for character classes, but since they are escaped
	 * for this use, it won't be a problem
         */
  
        if (*pattern == '\\') 
	{
            pattern += 1;
	    if (*pattern == '[' || *pattern == ']')
	    {
		if (*pattern == '[')
		{
		    *index1 = string;
		}
		else
		{
		    *index2 = string;
		}
		pattern += 1;
		/* if one of these two escape sequences is followed 
		 * by any of the special characters then we
		 * must do something special,otherwise they algorithm 
		 * will just punt, if we continue to the next round of the
		 * main while loop, it will do the right thing
		 */
		continue;
	    }
            if (*pattern == 0) {
                return 0;
            }
        }

        /* There's no special character.  Just make sure that the next
         * characters of each string match.
         */
#if defined(_WIN32)
        /* case insensitive */
        if (toupper(*pattern) != toupper(*string)) {
            return 0;
        }
#else /* unix and _MSDOS */
	if (*pattern != *string) {
	    return 0;
	}
#endif /* defined(_WIN32) */
        thisCharOK: pattern += 1;
        string += 1;
    }
}
