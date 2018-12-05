/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  NT SDK
 * MODULE:	  Makefile Generation
 * FILE:	  mkmf.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 17, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/17/92	  ardeb	    Initial version
 *	5/21/00   mgroeb    Support for multiple products
 *
 * DESCRIPTION:
 *	C version of mkmf.geode to create makefiles for PC/GEOS in
 *	the NT SDK
 *
 ***********************************************************************/

#ifndef lint
static char *rcsid =
"$Id: mkmf.c,v 1.13 1997/03/26 03:09:19 jacob Exp $";
#endif lint

#include <config.h>

#include    <stdio.h>
#include    <stdlib.h>
#include    <stddef.h>
#include    <compat/string.h>
#include    <ctype.h>

#include    <lst.h>

#ifdef _WIN32
#  include    <compat/dirent.h>
#  define     dirent direct
#  define     strncmpi strnicmp         /* tested with Visual C++ 6.0 */
#  include    <windows.h>
#elif defined(_LINUX)
#  include    <compat/dirent.h>
#  define     dirent direct
#  define     strncmpi strnicmp    
#define MAX_PATH (256)
#else
#  include    <dirent.h>
#endif

#ifndef _LINUX
#include    <direct.h>
#include    <io.h>               /* for access() */
#endif
#include    <sys/stat.h>

#if defined(_MSDOS)
#    define MAX_PATH_LENGTH 80
#    include <dir.h>
#else
#    define MAX_PATH_LENGTH (MAX_PATH)  /*
					 * Not sure that this is a good value
					 * but it's better than 80
					 */
#    define _FAR
#endif /* defined(_MSDOS) */

#ifdef _WIN32
#include <winutil.h>
#endif

#define FILE_EXISTS(filename)   (((access(filename, 0)) == -1) ? 0 : 1)

#define BRANCH_FILE "BRANCH"

typedef struct {    	/* Structure into which MkmfFindSources places
			 * the lists it created for the different types
			 * of sources for which it scans */
    Lst	    asmFiles;
    Lst	    defFiles;
    Lst	    uiFiles;
    Lst	    cFiles; 	    /* Any .c file derived from a .goc file is
			     * removed from this list before MkmfFindSources
			     * returns */
    Lst	    hFiles;
    Lst	    gocFiles;
    Lst	    gohFiles;
} MkmfSources;

typedef struct {    	/* Descriptor of pattern for MkmfScanDir */
    const char 	*pattern;   	/* Wildcard pattern for which to search */
    Lst	    	list;	    	/* List to which to add the filename if the
				 * pattern matches */
} MkmfPattern;

static Lst  vars;		/* All variables defined for the makefile
				 * so far. Elements are MkmfVar * */

typedef struct {    	/* Description of a variable to be written to the
			 * makefile */
    char    *name;		/* Name of the variable */
    Lst	    words;		/* List of words (null-term strings) in
				 * the variable value */
} MkmfVar;

#if defined(_WIN32)
#    define MKMF_SCAN_FILE_BUFSIZE	256
#else /* _MSDOS or unix */
#    define MKMF_SCAN_FILE_BUFSIZE      128
#endif /* defined(_WIN32) */

typedef int MkmfScanFileCallback(FILE *stream,
				 char *buf,	/* Buffer holding first word
						 * of line; may be overwritten
						 * by callback */
				 int   nextc,	/* Character following first
						 * word */
				 void *data);

static void MkmfScanFile(const char *file,
			 MkmfScanFileCallback *callback,
			 void *data);

static int
MkmfStringMatch(register const char *string, 
		register const char *pattern);

					     
					     
static int	revisionControl    = 0;	         /* non-zero if we want to
						  * set up PVCS stuff */
static FILE    *output             = NULL;
static char    rootDir[MAX_PATH_LENGTH];
static char    finalRootComponent[MAX_PATH_LENGTH];
static char    *branch             = NULL;

static char    products[1024]      = {0};

#define EXISTS(filePath)    ((access(filePath, 0) == 0) ? 1 : 0)

#if defined(_WIN32)
/*
 * really only needed inside of SpawnPmakeDepend(), but needs to be
 * global so that it can be taken care of inside of ControlCHandler
 */
static PROCESS_INFORMATION procInfo = {INVALID_HANDLE_VALUE};
#endif /* defined(_WIN32) */


/***********************************************************************
 *				GetBranchFromFile
 ***********************************************************************
 *
 * SYNOPSIS:	       Parses the branch file and figures out what branch
 *                     to use as the installed source
 * CALLED BY:	       main
 * RETURN:	       a char * pointing to the name of the branch if
 *                     there is a branch file and it isn't empty, NULL
 *                     otherwise
 * SIDE EFFECTS:       opens and closes branchFileName and mallocs memory
 *                     if the file isn't empty, otherwise prints a warning
 *                     on the screen
 *
 * STRATEGY:	       open the branch file and read the first line.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	1/09/97   	Initial Revision
 *
 ***********************************************************************/
static char *
GetBranchFromFile (const char *branchFileName)
{
    FILE *branchFile = fopen(branchFileName, "rt"); /* #1 */

    if (branchFile == NULL) {
	return NULL;
    } else {
	char *branch = (char *) malloc ((MAX_PATH_LENGTH + 1) * sizeof(char));
	int   i      = 0;
	char  c;

	while ((c = (char) fgetc(branchFile)) != EOF && i < MAX_PATH_LENGTH) {
	    if (isspace(c)) {
		break;
	    }

	    branch[i] = c;
	    i++;
	}
	fclose(branchFile);	/* #1 */

	if (i == 0) {
	    fprintf(stderr,
		    "mkmf: warning: invalid branch file \"%s\", assuming no branch\n",
		    branchFileName);
	    return NULL;
	}

	branch[i] = '\0';
	return branch;
    }
}	/* End of GetBranchFromFile.	*/


/***********************************************************************
 *				ScanDriverInfoCallback
 ***********************************************************************
 * SYNOPSIS:	    look for a pattern
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *	    	note: data is a char * to the current directory
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	4/19/95   	Initial Revision
 *
 ***********************************************************************/
static int
ScanDriverInfoCallback(FILE *stream, char *buf, int c, void *data)
{
    char       	libname[24];
    char    	protoconst[24];

    if (MkmfStringMatch((char *)data, buf)) {
	if (fscanf(stream, "%s %s", libname, protoconst) == 2) {
	    fprintf(output, "%-15s = %s\n", "LIBNAME", libname);
	    fprintf(output, "%-15s = %s\n", "PROTOCONST", protoconst);
	} else {
	    fprintf(stderr, "mkmf: bad driver.pat file\n");
	}
	return 1;
    }

    return 0;
}	/* End of ScanDriverInfoCallback.	*/


/***********************************************************************
 *				ScanDriverInfo
 ***********************************************************************
 * SYNOPSIS:	    scan ROOT_DIR/INCLUDE/DRIVER.PAT for information
 *	    	    about protocols for drivers
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	4/19/95   	Initial Revision
 *
 ***********************************************************************/
static void
ScanDriverInfo (char *cwd)
{
    char    path[MAX_PATH_LENGTH];

    sprintf(path, "%s/Include/driver.pat", rootDir);
    MkmfScanFile(path, ScanDriverInfoCallback, cwd);
}	/* End of ScanDriverInfo.	*/


/***********************************************************************
 *				MkmfDoDrvierStuff
 ***********************************************************************
 * SYNOPSIS:	    deal with driver things
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    might output LIBNAME and PROTOCONST to makefile
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	4/19/95   	Initial Revision
 *
 ***********************************************************************/
static void 
MkmfDoDriverStuff(void)
{
    char    cwd[MAX_PATH_LENGTH];

    Compat_GetCwd(cwd, MAX_PATH_LENGTH);
    if (!MkmfStringMatch(cwd, "*\\\\Driver\\\\*") &&
	!MkmfStringMatch(cwd, "*/Driver/*")) {
	return;
    }
    ScanDriverInfo(cwd);
}


/*********************************************************************
 *			Strnicmp
 *********************************************************************
 * SYNOPSIS: 	Do a case insensitive string compare
 * CALLED BY:	(GLOBAL)
 * RETURN:  	0 if it's a match, non-zero otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	5/10/94		Initial version			     
 * 
 *********************************************************************/
static int
Strnicmp(char *s1, char *s2, int n)
{
    while (*s1 && *s2 && n) {
	if (toupper(*s1++) != toupper(*s2++)) {
	    return 1;
	}
	--n;
    }
    return 0;
}


/***********************************************************************
 *				MkmfAddVar
 ***********************************************************************
 * SYNOPSIS:	    Add another variable to the makefile
 * CALLED BY:	    INTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    another element is added to the "vars" list.
 *	    	    the passed Lst should no longer be referenced by
 *	    	        the caller.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/92		Initial Revision
 *
 ***********************************************************************/
static void
MkmfAddVar(const char	*name,	/* Name of variable to add */
	   Lst	    	value)	/* Words that make up the variable. Control
				 * over the list is hereby bequeathed to
				 * this function and its family. */
{
    MkmfVar 	*new;

    /*
     * Allocate a record for the thing and copy the name in.
     */
    new = (MkmfVar *)malloc(sizeof(MkmfVar) + strlen(name) + 1);
    new->name = (char *)(new + 1);
    strcpy(new->name, name);
    new->words = value;

    (void)Lst_AtEnd(vars, (ClientData)new);
}


/***********************************************************************
 *				MkmfPrintVar
 ***********************************************************************
 * SYNOPSIS:	    Format a single variable for the output file,
 *		    wrapping it nicely, etc.
 * CALLED BY:	    MkmfPrintAllVars via Lst_ForEach
 * RETURN:	    0 (keep going)
 * SIDE EFFECTS:    things are written to the file, of course
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/92		Initial Revision
 *
 ***********************************************************************/
static int
MkmfPrintVar(ClientData	datum,	    /* MkmfVar to print */
	     ClientData	callData)   /* FILE * to which to print it */
{
    MkmfVar        *mv = (MkmfVar *)datum;
    FILE    	   *output = (FILE *)callData;
    LstNode 	    ln;	    	    /* Node of current word in value */
    char    	    outbuf[128];    /* Line being built */
    int	    	    len,    	    /* Current length of line being built */
		    wlen;   	    /* Length of current word */

    /*
     * Set up the initial line containing the name of the variable, followed by
     * an equal sign with a space in front of it. We put the thing in
     * a 16-character field, as it looks nice (well, 15-character, as we always
     * want one space between the name and the equal sign).
     */
    sprintf(outbuf, "%-15s =", mv->name);

    /*
     * Now put out the words of the value one after another, separated by
     * spaces and wrapping at the 75th column.
     */
    len = strlen(outbuf);
    for (ln = Lst_First(mv->words); ln != NILLNODE; ln = Lst_Succ(ln)) {
	const char  *vword = (const char *)Lst_Datum(ln);
	
	wlen = strlen(vword);
	if (len + wlen + 1 > 75) {
	    /*
	     * This word would put the line past 75 characters, so put out the
	     * line as we've got it now, with an escaped newline at the end.
	     */
	    fprintf(output, "%s\\\n", outbuf);

	    /*
	     * Indent the next line to line up with the first character of the
	     * value on the first line of the variable assignment (i.e. after
	     * the space that follows the equal sign). This is actually
	     * the 18th column, but we always stick a space before each word,
	     * so we just put 17 spaces in to start.
	     */
	    sprintf(outbuf, "%17s", "");
	    len = 17;
	}
	sprintf(&outbuf[len], " %s", vword);
	len += wlen + 1;
    }
    /*
     * Print whatever we've got left in our output buffer (there's always
     * something here, even if there are no words in the value).
     */
    fprintf(output, "%s\n", outbuf);

    /*
     * Keep enumerating things...
     */
    return(0);
}
	

/***********************************************************************
 *				MkmfPrintAllVars
 ***********************************************************************
 * SYNOPSIS:	    Print out all the variables defined for the makefile.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    foo
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/92		Initial Revision
 *
 ***********************************************************************/
static void
MkmfPrintAllVars(FILE *output)
{
    Lst_ForEach(vars, MkmfPrintVar, (ClientData)output);
}
    


/*
 *----------------------------------------------------------------------
 *
 * MkmfStringMatch --
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
static int
MkmfStringMatch(register const char *string,  /* String. */
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
		if (MkmfStringMatch(string++, pattern)) {
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
		    
		    if (toupper(pchar) == toupper(schar = *string)) {
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
		    
		    if (toupper(pchar) == toupper(schar = *string)) {
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
			if ((toupper(pchar) < toupper(schar)) &&
			    (toupper(c2) >= toupper(schar))) {
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
        
#if defined(unix)
	    if (pchar != schar) {
		return 0;
	    }
#else
	    if (toupper(pchar) != toupper(schar)) {
		return(0);
	    }
	    break;
	}
#endif
        pchar = *++pattern;
        schar = *++string;
    }
}


/***********************************************************************
 *				MkmfScanDir
 ***********************************************************************
 * SYNOPSIS:	    Scan a directory, looking for files that match
 *		    one or more patterns.
 * CALLED BY:	    INTERNAL
 * RETURN:	    the number of matches
 * SIDE EFFECTS:    strings are appended to lists in the given array of
 *		    patterns.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/92		Initial Revision
 *
 ***********************************************************************/
static int
MkmfScanDir(const char	    	*dir,	    	/* Directory to scan */
	    const MkmfPattern	*patterns,  	/* Array of patterns for which
						 * to search */
	    int	    	    	numPatterns)	/* Length of same */
{
    DIR	          _FAR *dirp;  	/* Stream open to directory */
    struct dirent _FAR *dep;   	/* Current entry being checked */
    int	    	        i;   	/* Current pattern number being checked */
    char    	       *name;  	/* Copy of current entry name */
    int	    	        matches;/* Number of matches seen so far */

    dirp = opendir((char *)dir);
    if (dirp == NULL) {
	return(0);
    }

    matches = 0;
    
    while ((dep = readdir(dirp)) != (struct dirent *)NULL) {
	name = NULL;
	
	for (i = 0; i < numPatterns; i++) {
	    LstNode    ln;
	    if (!MkmfStringMatch(dep->d_name, "*_e.c") && 
		!MkmfStringMatch(dep->d_name, "*_g.c")) {
		if (MkmfStringMatch(dep->d_name, patterns[i].pattern)) {
		    /*
		     * Record another match for our caller
		     */
		    matches += 1;
		    
		    /*
		     * Make a copy of this entry's name, if we've not done so
		     * already.
		     */
		    if (name == (char *)NULL) {
			name = (char *)malloc(strlen(dep->d_name)+1);
			strcpy(name, dep->d_name);
		    }

		    /* check for dupliactes */
		    for (ln = Lst_First(patterns[i].list);
			 ln != NILLNODE;
			 ln = Lst_Succ(ln)) {
			char    *fname;
			
			fname = (char *)Lst_Datum(ln);
#if defined(_WIN32) || defined(_LINUX)
			/*
			 * case insensitive search
			 */
			if (stricmp(fname, name) == 0) {
			    break;
			}
#else /* unix or _MSDOS */
			if (strcmp(fname, name) == 0) {
			    break;
			}
#endif /* defined(_WIN32) */
		    }

		    if (ln == NILLNODE) {
			/*
			 * Add it to the end of the list for this pattern.
			 * if its not a duplicate
			 */
			Lst_AtEnd(patterns[i].list, (ClientData)name);
		    }
		}
	    }
	}
    }

    closedir(dirp);

    return(matches);
}


/***********************************************************************
 *				MkmfScanInstalledDir
 ***********************************************************************
 * SYNOPSIS:	    calls MkmfScanDir on the installed directory
 * CALLED BY:	    various routines
 * RETURN:	    number of files found
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	3/17/95   	Initial Revision
 *
 ***********************************************************************/
static int
MkmfScanInstalledDir (const char	    	*dir,
		      const MkmfPattern	    	*patterns,
		      int   	    	    	numPatterns)
{
    /*
     * also check for the installed one if this is a local one
     */
    char    installedDir[MAX_PATH_LENGTH];
    char    cwd[MAX_PATH_LENGTH];
    
    Compat_GetCwd(cwd, MAX_PATH_LENGTH);
    sprintf(installedDir,
	    "%s/%s/%s",
	    rootDir,
	    Compat_GetTrailingPath(finalRootComponent, cwd),
	    dir);
    
    return (MkmfScanDir(installedDir, patterns, numPatterns));
}	/* End of MkmfScanInstalledDir.	*/


/***********************************************************************
 *				MkmfFindSources
 ***********************************************************************
 * SYNOPSIS:	    Locate all the source files in the given directory,
 *	    	    returning their names on a sequence of lists. This
 *	    	    is pretty much a front-end for MkmfScanDir, with
 *	    	    the exception that any .c file for which there's
 *	    	    a corresponding .goc file is removed from the list
 *	    	    of .c files returned.
 * CALLED BY:	    MkmfCreateLargeModel, MkmfCreateSmallOrMediumModel
 * RETURN:	    number of found sources.
 * SIDE EFFECTS:    created lists stored in passed structure.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/92		Initial Revision
 *
 ***********************************************************************/
static int
MkmfFindSources(const char  *dir,   	/* Directory to scan */
		MkmfSources *srcs)  	/* Place to store the created lists */
{
    static MkmfPattern	patterns[] = {
	{"*.asm",    0},
	{"*.def",    0},
	{"*.ui",     0},
	{"*.c",      0},
	{"*.h",	     0},
	{"*.goc",    0},
	{"*.goh",    0}
    };
    static const int   	lstOffs[] = {
	offsetof(MkmfSources, asmFiles),
	offsetof(MkmfSources, defFiles),
	offsetof(MkmfSources, uiFiles),
	offsetof(MkmfSources, cFiles),
	offsetof(MkmfSources, hFiles),
	offsetof(MkmfSources, gocFiles),
	offsetof(MkmfSources, gohFiles)
    };
    int	    i;

    /*
     * Create lists for all the patterns we have to match.
     */
    for (i = 0; i < sizeof(patterns)/sizeof(patterns[0]); i++) {
    	Lst 	*listPtr;

	listPtr = (Lst *)((char *)srcs + lstOffs[i]);
	*listPtr = patterns[i].list = Lst_Init(FALSE);
    }

    /*
     * Scan the passed directory looking for those patterns.
     */
    i  = MkmfScanDir(dir, patterns, sizeof(patterns)/sizeof(patterns[0]));
    i += MkmfScanInstalledDir(dir, patterns, 
			      sizeof(patterns)/sizeof(patterns[0]));

    return(i);
}
	

/***********************************************************************
 *				MkmfOutputSources
 ***********************************************************************
 * SYNOPSIS:	    Put out all the source files found by MkmfFindSources
 *		    as the value for a given variable.
 * CALLED BY:	    MkmfCreateSmallOrMediumModel, MkmfCreateLargeModel
 * RETURN:	    nothing
 * SIDE EFFECTS:    all lists in the given MkmfSources structure are
 *		    destroyed or usurped.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/19/92		Initial Revision
 *
 ***********************************************************************/
static void
MkmfOutputSources(const char 	*varName, MkmfSources	*srcs)
{
    Lst	    srcList = srcs->asmFiles;
    
    /*
     * Concatenate all the other lists with the list of all .asm files to
     * create the SRCS variable. Lst_Concat will destroy the component lists
     * since we've told it to steal all the elements from them.
     */
    Lst_Concat(srcList, srcs->defFiles, LST_CONCLINK);
    Lst_Concat(srcList, srcs->uiFiles, LST_CONCLINK);
    Lst_Concat(srcList, srcs->cFiles, LST_CONCLINK);
    Lst_Concat(srcList, srcs->hFiles, LST_CONCLINK);
    Lst_Concat(srcList, srcs->gocFiles, LST_CONCLINK);
    Lst_Concat(srcList, srcs->gohFiles, LST_CONCLINK);

    MkmfAddVar(varName, srcList);
}


/***********************************************************************
 *				MkmfFindSubdirsCommon
 ***********************************************************************
 * SYNOPSIS:	    Locate all subdirectories of the passed in directory
 *		    and place their names on the passed list.
 * CALLED BY:	    main
 * RETURN:	    number of subdirectories found
 * SIDE EFFECTS:    strings are appended to the passed list
 *
 * STRATEGY:	    
 *	    	if the sub-directory has an NO_MKMF file than ignore it
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/92		Initial Revision
 *	jimmy	12/18/82    	added support for NO_MKMF
 *
 ***********************************************************************/
static int
MkmfFindSubdirsCommon(Lst list)
{
    DIR	    	    *dirp;
    struct dirent   *dep;
    struct stat	    stb;
    int	    	    numdirs = 0;

    dirp = opendir(".");
    if (dirp == (DIR *)NULL) {
	return(0);
    }

    while ((dep = readdir(dirp)) != (struct dirent *)NULL) {
	if ((dep->d_name[0] == '.') &&
	    (dep->d_name[1] == '\0' ||
	     (dep->d_name[1] == '.' && dep->d_name[2] == '\0'))) {
	    continue;
	} else {
#if defined(unix)
	    if (dep->d_fileno == 0) {
		continue;
	    }
#endif

	    if (stat(dep->d_name, &stb) == 0) {
		if (((stb.st_mode & S_IFMT) == S_IFDIR) &&
		    !MkmfStringMatch(dep->d_name, "[Dd]oc") &&
		    !MkmfStringMatch(dep->d_name, "src") &&
		    !MkmfStringMatch(dep->d_name, "RCS") &&
		    !MkmfStringMatch(dep->d_name, "*.md") &&
		    !MkmfStringMatch(dep->d_name, "OLD")) {

		    
		    char *name;
		    char  nomkmfname[24];

		    /*
		     * now see if the subdirectory has a NO_MKMF file in it
		     */
		    sprintf(nomkmfname, "%s/NO_MKMF", dep->d_name);
		    if (!EXISTS(nomkmfname)) {
			LstNode	ln;

		    	name = strdup(dep->d_name); /* #1 */

			/* now check for duplicates */
			
			for (ln = Lst_First(list); ln != NILLNODE;
			     ln = Lst_Succ(ln)) {
			    char    *fname;

			    fname = (char *)Lst_Datum(ln);
#if defined(_WIN32)
                            /*
			     * case insensitive comparison
			     */
			    if (stricmp(fname, name) == 0) {
				break;
			    }
#else /* unix or _MSDOS */
			    if (strcmp(fname, name) == 0) {
				break;
			    }
#endif /* defined(_WIN32) */
			}
			if (ln == NILLNODE) {
		    	    (void)Lst_AtEnd(list, (ClientData)name);
		    	    numdirs += 1;
			}
		    }
		}
	    }
	}
    }

    closedir(dirp);

    return(numdirs);
}
	    

/*********************************************************************
 *			MkmfFindSubdirs
 *********************************************************************
 * SYNOPSIS:	    Locate all subdirectories of the current directory
 *	    	    and the installed directory if there is one
 *		    and place their names on the passed list.
 * CALLED BY:	    main
 * RETURN:	    number of subdirectories found
 * SIDE EFFECTS:    strings are appended to the passed list
 *
 * STRATEGY:	    
 *	    	if the sub-directory has NO_MKMF file than ignore it
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/18/94 	initial version
 * 
 *********************************************************************/
static int
MkmfFindSubdirs(Lst list)
{
    int   numDirs = MkmfFindSubdirsCommon(list);
    char  cwd[MAX_PATH_LENGTH];
    char  installedDir[MAX_PATH_LENGTH];

    Compat_GetCwd(cwd, MAX_PATH_LENGTH);
    sprintf(installedDir,
	    "%s/%s",
	    rootDir,
	    Compat_GetTrailingPath(finalRootComponent, cwd));

    if (chdir(installedDir) == 0) {
	numDirs += MkmfFindSubdirsCommon(list);
	chdir(cwd);
    }

    return numDirs;
}


/***********************************************************************
 *				MkmfConvertToObj
 ***********************************************************************
 * SYNOPSIS:	    Convert the passed source file name to that of an
 *		    object file.
 * CALLED BY:	    MkmfCreateSmallOrMediumModel via Lst_Duplicate
 * RETURN:	    string for new list
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/19/92		Initial Revision
 *
 ***********************************************************************/
static ClientData
MkmfConvertToObj(ClientData datum)
{
    const char	*src = (const char *)datum;
    char    	*obj;
    const char 	*suffix;

    suffix = (const char *)strrchr(src, '.');
    obj = (char *)malloc(suffix - src + 4 + 1);
#if defined(unix)
    sprintf(obj, "%.*s.obj", suffix - src, src);
#else
    /*
     * Turbo C doesn't like the above...
     */
    memcpy(obj, src, suffix - src);
    strcpy(&obj[suffix - src], ".obj");
#endif

    return((ClientData)obj);
}


/***********************************************************************
 *				MkmfConvertToModuleVar
 ***********************************************************************
 * SYNOPSIS:	    Convert the passed subdirectory to the corresponding
 *	    	    module-source variable expansion.
 * CALLED BY:	    MkmfCreateLargeModel via Lst_Duplicate
 * RETURN:	    string for new list
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/19/92		Initial Revision
 *
 ***********************************************************************/
static ClientData
MkmfConvertToModuleVar(ClientData datum)
{
    const char	*src = (const char *)datum;
    char    	*dest;
    const char 	*cp1;
    char    	*cp2;

    dest = (char *)malloc(2 + strlen(src) + 1 + 1);
    cp1 = src; cp2 = dest;

    /*
     * Prepend $( to start variable expansion.
     */
    *cp2++ = '$';
    *cp2++ = '(';

    /*
     * Now copy the directory name, converting lower-case to upper-case
     * as necessary.
     */
    while (*cp1 != '\0') {
	*cp2++ = (char) toupper(*cp1);
	cp1 += 1;
    }

    /*
     * Append ) to finish the variable expansion.
     */
    *cp2++ = ')';
    *cp2   = '\0';

    return((ClientData)dest);
}


/***********************************************************************
 *				MkmfScanFile
 ***********************************************************************
 * SYNOPSIS:	    Scan through a file, calling a callback with the
 *		    first word of every line
 * CALLED BY:	    (INTERNAL) MkmfScanForRdfIncludes,
 *			       MkmfPrintLIBOBJ
 * RETURN:	    nothing
 * SIDE EFFECTS:    file is opened and closed
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/16/95		Initial Revision
 *
 ***********************************************************************/
static void
MkmfScanFile(const char *file, MkmfScanFileCallback *callback, void *data)
{
    FILE    	*stream;
    int	    	 c;
    char    	 buf[MKMF_SCAN_FILE_BUFSIZE];
    char    	*cp;

    stream = fopen(file, "rb");
    if (stream == NULL) {
	/*
	 * Scan the installed one if local one can't be found.
	 */
	char	installedFile[MAX_PATH_LENGTH];
	char	cwd[MAX_PATH_LENGTH];

	Compat_GetCwd(cwd, MAX_PATH_LENGTH);

	sprintf(installedFile, "%s/%s/%s",
		rootDir,
		Compat_GetTrailingPath(finalRootComponent, cwd),
		file);
	stream = fopen(installedFile, "rb");
    }
    if (stream == NULL) {
	return;
    }
    
    while ((c = fgetc(stream)) != EOF) {
	/*
	 * Skip to the first word of the line.
	 */
	while (isspace(c)) {
	    c = fgetc(stream);
	}

	/*
	 * Read the first word of the line into buf.
	 */
	cp = buf;
	while (!isspace(c) && c != EOF && cp != &buf[sizeof(buf)-1]) {
	    *cp++ = (char) c;
	    c     = fgetc(stream);
	}
	if (c == EOF) {
	    break;
	}

	*cp = '\0';

	if ((*callback) (stream, buf, c, data)) {
	    break;
	}
	
	/*
	 * Skip to the end of the line or the end of the file, whichever
	 * comes first.
	 */
	while ((c != EOF) && (c != '\n')) {
	    c = fgetc(stream);
	}
	if (c == EOF) {
	    break;
	}
    }
    fclose(stream);
}


/***********************************************************************
 *				MkmfScanFileCheckInclude
 ***********************************************************************
 * SYNOPSIS:	    See if the buffer contains an include directive, and
 *		    fetch the name of the file it's including if it does.
 * CALLED BY:	    (INTERNAL) MkmfScanForRdfIncludesCallback,
 *			       MkmfScanForAsmIncludesCallback
 * RETURN:	    non-zero if it's an include directive
 * SIDE EFFECTS:    buffer overwritten with filename if non-zero returned
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/16/95		Initial Revision
 *
 ***********************************************************************/
static int
MkmfScanFileCheckInclude(FILE *stream, char *buf, int c)
{
    char    *cp;
    
    if (strcmp(buf, "include") == 0 || strcmp(buf, "INCLUDE") == 0) {
	/*
	 * First word is include. Skip to the next word, which is the file
	 * to be included.
	 */
	while (isspace(c)) {
	    c = fgetc(stream);
	}
	/*
	 * Fetch the file to be included.
	 */
	cp = buf;
	while (!isspace(c) && c != ';' && cp != &buf[MKMF_SCAN_FILE_BUFSIZE-1])
	{
	    *cp++ = (char) c;
	    c     = fgetc(stream);
	}
	
	/* if its a newline, move the file pointer back one so ScanFile
	 * gets it as well
	 */
	if (c == '\n') {
	    fseek(stream, -1, SEEK_CUR);
	}
	*cp = '\0';
	return (1);
    } else {
	return (0);
    }
}
	

/***********************************************************************
 *			MkmfScanForRdfIncludesCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback function to look for inclusion of .rdf or
 *	    	    .rdef files and add them to the list of such files.
 * CALLED BY:	    (INTERNAL) MkmfScanForRdfIncludes via MkmfScanFile
 * RETURN:	    0 to continue scanning
 * SIDE EFFECTS:    file name may be allocated and placed at end of rdFiles
 *		    list
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/16/95		Initial Revision
 *
 ***********************************************************************/
static int
MkmfScanForRdfIncludesCallback(FILE *stream,
			       char *buf,
			       int c,
			       void *data) /* Lst for recording found files */
{
    Lst	rdfFiles = (Lst)data;
    
    if (MkmfScanFileCheckInclude(stream, buf, c)) {
	/*
	 * See if it's a .rdf or .rdef file.
	 */
	if (MkmfStringMatch(buf, "*.rdf") || MkmfStringMatch(buf, "*.rdef")) {
	    /* 
	     * It is. Change the file name suffix to .UI. Then add
	     * the .ui file name to the list rdfFiles.
	     */
	    char	*cp;
#if defined(_MSDOS)
	    int 	i;

	    /*
	     * Force name to be 8.3 and all uppercase, as that's what we
	     * will have found from the filesystem. Set the suffix to .UI
	     */
	    for (i = 0, cp = buf; i < 8; i++, cp++) {
		if (islower(*cp)) {
		    *cp = toupper(*cp);
		} else if (*cp == '.' || *cp == '\0') {
		    break;
		}
	    }
	    if (*cp != '\0') {
		strcpy(cp, ".UI");
	    }
#else
#if defined(_WIN32)
	    /*
	     * don't need to truncate to 8.3 like in DOS, but upcase alphas
	     */
	    cp = buf;
	    while(*cp) {
		*cp = (char) toupper(*cp);
		cp++;
	    }
#endif /* defined(_WIN32) */
	    /*
	     * If unix, just set the suffix to .UI
	     */
	    cp = strrchr(buf, '.');
	    strcpy(cp, ".UI");
#endif /* defined(_MSDOS) */
	    /*
	     * Add the .ui file to the rdfFiles list.
	     */
	    cp = (char *)malloc(strlen(buf)+1);
	    strcpy(cp, buf);
	    (void)Lst_AtEnd(rdfFiles, (ClientData)cp);
	}
    }
    return(0);			/* Keep looking */
}


/***********************************************************************
 *				MkmfScanForRdfIncludes
 ***********************************************************************
 * SYNOPSIS:	    Look through an asm file for include directives that
 *	    	    are for .rdf or .rdef files.
 * CALLED BY:	    MkmfCreateSmallOrMediumModel, MkmfCreateLargeModel
 * RETURN:	    nothing
 * SIDE EFFECTS:    Files may be added to the rdfFiles list.
 *
 * STRATEGY:	    If we find an include directive for a .rdf or .rdef
 *                  file, convert the file name to its .ui form and add 
 *                  it to the rdfFiles list.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	lester	12/ 8/93   	Initial Revision
 *
 ***********************************************************************/
static void
MkmfScanForRdfIncludes(const char   *file,  	    /* File to scan */
		       Lst  	    rdfFiles)	    /* List of files that
						     * will be UIC'd.
						     * Already open, so don't
						     * use Lst_Open/Lst_Next
						     * on it */
{
    MkmfScanFile(file, MkmfScanForRdfIncludesCallback, (void *)rdfFiles);
}	/* End of MkmfScanForRdfIncludes.	*/
    

/***********************************************************************
 *				MkmfCreateLargeModel
 ***********************************************************************
 * SYNOPSIS:	    Create all the appropriate variables for a large-
 *		    model geode.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    variables are added to the makefile
 *
 * STRATEGY:	    foreach module:
 *	    	    	locate sources in subdir
 *	    	    	if any .c or .goc files, add to CMODULES
 *	    	    	if any .asm, add to MODULES
 *                      for each .asm file:
 *                          Seach the .asm file for include directives 
 *                          for .rdf or .rdef files. Add the included 
 *                          file name in its .ui form to the variable 
 *                          UI_TO_RDFS.
 *	    	    	output all source files as value for variable
 *	    	    	    whose name comes from upcasing the subdir name
 *	    	    if any .c or .goc files, change suffix to .obj and
 *		    	append to OBJS variable
 *	    	    look for .def, .ui, .uih, .h or .goh files in top
 *		    	level and set as COMMON
 *	    	    output MODULES and CMODULES
 *	    	    put out SRCS made from expanding all module vars
 *		    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/92		Initial Revision
 *	lester	12/ 8/93   	added UI_TO_RDFS variable support
 *
 ***********************************************************************/
static void
MkmfCreateLargeModel(Lst    modules)	    /* List of directories
					     * identified as modules by
					     * MkmfConfirmLargeModel */
{
    LstNode 	ln;
    MkmfSources	srcs;
    Lst	    	cModules;
    Lst	    	asmModules;
    Lst	    	obj;
    Lst         rdfFiles;
    static MkmfPattern	commonPatterns[] = {
	{"*.uih",    0},
	{"*.h",      0},
	{"*.goh",    0},
	{"*.def",    0}
    };
    int	    	i;
    Lst	    	common;

    cModules   = Lst_Init(FALSE);
    asmModules = Lst_Init(FALSE);
    obj        = Lst_Init(FALSE);
    rdfFiles   = Lst_Init(FALSE);  /* list for .ui files to be uic'd */

    for (ln = Lst_First(modules); ln != NILLNODE; ln = Lst_Succ(ln)) {
	const char  *subdir = (const char *)Lst_Datum(ln);
	char	    *varName;
	const char  *cp1;
	char	    *cp2;

	if (MkmfFindSources(subdir, &srcs)) {
	    /*
	     * If any .c or .goc files, add the directory to the list of
	     * C modules.
	     */
	    if (!Lst_IsEmpty(srcs.cFiles) || !Lst_IsEmpty(srcs.gocFiles)) {
		(void)Lst_AtEnd(cModules, (ClientData)subdir);
	    }
	    /*
	     * If any .asm files, add the directory to the list of assembly
	     * modules.
	     */
	    if (!Lst_IsEmpty(srcs.asmFiles)) {
		LstNode 	asmLn;

		(void)Lst_AtEnd(asmModules, (ClientData)subdir);

		/*
		 * Search all the .asm files for include directives for 
		 * .rdef or .rdf files. Add the included file in its .ui 
		 * form to the list rdfFiles.
		 */
		if (!Lst_Open(srcs.asmFiles)) {
		    while ((asmLn = Lst_Next(srcs.asmFiles)) != NILLNODE) {
#ifdef _WIN32
			char            fullAsmFile[MAX_PATH_LENGTH];
#else
			char            fullAsmFile[128];
#endif
			const char	*asmFile;

			asmFile = (const char *)Lst_Datum(asmLn);

			/*
			 * add the path to the asm file
			 */
			sprintf(fullAsmFile, "%s/%s", subdir, asmFile);
			MkmfScanForRdfIncludes(fullAsmFile, rdfFiles);
		    }
		}
	    }

	    /*
	     * Transform any .c or .goc files into .obj files on the obj list
	     */
	    Lst_Concat(obj, Lst_Duplicate(srcs.cFiles, MkmfConvertToObj),
		       LST_CONCLINK);
	    Lst_Concat(obj, Lst_Duplicate(srcs.gocFiles, MkmfConvertToObj),
		       LST_CONCLINK);

	    /*
	     * Upcase the directory name to form the module variable.
	     */
	    varName = (char *)malloc(strlen(subdir) + 1);
	    for (cp1 = subdir, cp2 = varName; *cp1 != '\0'; cp1++) {
		*cp2++ = (char) toupper(*cp1);
	    }
	    *cp2 = '\0';
	    /*
	     * Output all source files for the module.
	     */
	    MkmfOutputSources(varName, &srcs);
	    free(varName);
	} else {
	    fprintf(stderr, "mkmf: warning: no sources in %s\n", subdir);
	}
    }

    /*
     * Help out dependency generation by putting out the list of UI
     * files that are actually run through UIC.
     */
    MkmfAddVar("UI_TO_RDFS", rdfFiles);

    /*
     * Put out OBJS variable.
     */
    MkmfAddVar("OBJS", obj);

    /*
     * Look for headers in top level and set as COMMON variable.
     */
    common = Lst_Init(FALSE);
    for (i = 0; i < sizeof(commonPatterns)/sizeof(commonPatterns[0]); i++) {
	commonPatterns[i].list = common;
    }
    MkmfScanDir(".", commonPatterns,
		sizeof(commonPatterns)/sizeof(commonPatterns[0]));
    MkmfScanInstalledDir(".", commonPatterns,
			 sizeof(commonPatterns)/sizeof(commonPatterns[0]));
    MkmfAddVar("COMMON", common);

    /*
     * Put out the lists o' modules of the two varieties.
     */
    MkmfAddVar("MODULES", asmModules);
    MkmfAddVar("CMODULES", cModules);

    /*
     * Convert all the modules to their corresponding module-source variable
     * expansion for the SRCS variable. Have to append COMMON to the modules
     * list so SRCS contains the common include files as well.
     */
    Lst_AtEnd(modules, (ClientData)"COMMON");
    MkmfAddVar("SRCS", Lst_Duplicate(modules, MkmfConvertToModuleVar));
}

typedef struct {
    Lst	    asmFiles;
    Lst	    allasmFiles;
} MkmfScanForAsmData;


/***********************************************************************
 *			MkmfScanForAsmIncludesCallback
 ***********************************************************************
 * SYNOPSIS:	    Look for inclusion of .asm files and record those
 * CALLED BY:	    (INTERNAL) MkmfScanForAsmIncludes via MkmfScanFile
 * RETURN:	    0 to continue scanning
 * SIDE EFFECTS:    included file will be removed from the asmFiles list
 *	    	    	if it was there
 *	    	    included file will be added to the allasmFiles list
 *	    	    	if it wasn't known before
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/16/95		Initial Revision
 *
 ***********************************************************************/
static int
MkmfScanForAsmIncludesCallback(FILE *stream,
			       char *buf,
			       int c,
			       void *data)
{
    if (MkmfScanFileCheckInclude(stream, buf, c)) {
	/*
	 * See if it's a .asm file.
	 */
	if (MkmfStringMatch(buf, "*.asm")) {
	    /*
	     * It is. See if it's in the asmFiles list so we know whether
	     * we think we're supposed to assemble this thing or not.
	     */
	    LstNode	ln;
	    char    	*cp;
#if !defined(unix)

#    if defined(_MSDOS)
	    int 	i;
#    endif /* defined(_MSDOS) */
	    
	    /*
	     * Force name to be 8.3 and all uppercase, as that's what we
	     * will have found from the filesystem.
	     */
	    
	    /* 
	     * Find the front of the filename by searching backwards in the 
	     * string for a '/' or a '\'. If neither character is in the
	     * string, it means that the string does not contain a path to
	     * the filename so the front of the file name is the front of 
	     * the string.
	     */
	    for (cp = buf + strlen(buf);
		 cp != buf && !IS_PATHSEP(cp[-1]);
		 cp--) {
		;
	    }
#    if defined(_MSDOS)	    
	    for (i = 0; i < 8; i++, cp++) {
		if (islower(*cp)) {
		    *cp = toupper(*cp);
		} else if (*cp == '.' || *cp == '\0') {
		    break;
		}
	    }
#    else /* _WIN32 */
	    /* don't need to truncate to 8.3, but we do upcase */
	    while (*cp && *cp != '.') {
		*cp = (char) toupper(*cp);
		cp++;
	    }
#    endif /* defined(_MSDOS) */
	    
	    if (*cp != '\0') {
		strcpy(cp, ".ASM");
	    }

#endif /* !defined(unix) */
		
	    for (ln=Lst_First(((MkmfScanForAsmData *)data)->asmFiles);
		 ln != NILLNODE;
		 ln = Lst_Succ(ln)) {
		const char	*asmFile;
		
		asmFile = (const char *)Lst_Datum(ln);

#if defined(_WIN32)
		/*
		 * case insensitive comparison
		 */
		if (stricmp(asmFile, buf) == 0) {
		    break;
		}
#else /* unix or _MSDOS */
		if (strcmp(asmFile, buf) == 0) {
		    break;
		}
#endif /* defined(_WIN32) */

	    }
	    
	    if (ln == NILLNODE) {
		/*
		 * Not seen before, so slap the thing on the list of all
		 * .asm files.
		 */
		cp = (char *)malloc(strlen(buf) + 1);
		strcpy(cp, buf);
		(void)Lst_AtEnd(((MkmfScanForAsmData *)data)->allasmFiles,
				(ClientData)cp);
	    } else {
		/*
		 * One of the asm files supposedly to be assembled, but
		 * it's not actually, so remove it from that list.
		 */
		Lst_Remove(((MkmfScanForAsmData *)data)->asmFiles, ln);
	    }
	}
    }
    return (0);
}


/***********************************************************************
 *				MkmfScanForAsmIncludes
 ***********************************************************************
 * SYNOPSIS:	    Look through a file for include directives that
 *	    	    are for other .asm files.
 * CALLED BY:	    MkmfCreateSmallOrMediumModel
 * RETURN:	    nothing
 * SIDE EFFECTS:    Files may be removed from the asmFiles list or
 *		    added to the allasmFiles list.
 *
 * STRATEGY:	    If we find one, it either is something we need to
 *		    remove from the asmFiles list (as it's not something
 *		    that gets assembled separately) or it's something we
 *		    need to add to the list of all .asm files (for the
 *		    SRCS variable). 
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/19/92		Initial Revision
 *
 ***********************************************************************/
static void
MkmfScanForAsmIncludes(const char   *file,  	    /* File to scan */
		       Lst  	    asmFiles,	    /* List of files that
						     * will be assembled.
						     * Already open, so don't
						     * use Lst_Open/Lst_Next
						     * on it */
		       Lst  	    allasmFiles)    /* List of all .asm files
						     * that make up the geode,
						     * whether they're assembled
						     * or not */
{
    MkmfScanForAsmData	data;

    data.asmFiles    = asmFiles;
    data.allasmFiles = allasmFiles;
    
    MkmfScanFile(file, MkmfScanForAsmIncludesCallback, &data);
}


/*********************************************************************
 *			MkmfInitPVCSForDirectory
 *********************************************************************
 * SYNOPSIS: 	create a pvcs.cfg file for the directory
 * CALLED BY:	MkmfConfirmLargeModel
 * RETURN:
 * SIDE EFFECTS:    creates a file in the directory
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	5/10/94		Initial version			     
 * 
 *********************************************************************/
static void
MkmfInitPVCSForDirectory(char *dir)
{
    char    cwd[MAX_PATH_LENGTH];

    /* the directory passed is a relative directory from the current
     * working directory, so save the cwd, go the relative directory
     * run mpvcscfg and restore the current directory
     */
    Compat_GetCwd(cwd, MAX_PATH_LENGTH);
    chdir(dir);
    system("MPVCSCFG");
    chdir(cwd);
}


/***********************************************************************
 *				MkmfCreateSmallOrMediumModel
 ***********************************************************************
 * SYNOPSIS:	    Create all the appropriate variables for a small-
 *	    	    or medium-model geode.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    variables are added to the makefile.
 *
 * STRATEGY:	    find all sources (.asm, .def, .ui, .c, .h, .goc, .goh)
 *	    	    duplicate .asm list as list of all asm sources
 *	    	    for each .asm file:
 *		    	search for include directives for .asm files
 *	    	    	if included file in list of .asm files, remove it
 *	    	    	else add to list of all .asm files
 *                  for each .asm file:
 *                      Seach the .asm file for include directives 
 *                      for .rdf or .rdef files. Add the included 
 *                      file name in its .ui form to the variable 
 *                      UI_TO_RDFS.
 *	    	    put out allasm, def, ui, c, h, goc, goh lists as
 *		        SRCS variable (concatenate all lists into one and
 *			set variable to union)
 *	    	    put out asm, c, goc lists as OBJS after replacing
 *		        suffix with .obj (duplicate lists and concat
 *			results)
 *	    	    create a pvcs.cfg file if -[vV] flag passed
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/92		Initial Revision
 *	lester	12/ 8/93   	added UI_TO_RDFS variable support
 *
 ***********************************************************************/
static void
MkmfCreateSmallOrMediumModel(void)
{
    MkmfSources	srcs;
    Lst	    	allasmFiles;
    Lst         rdfFiles;
    LstNode 	ln;
    Lst	    	objList;

    if (!MkmfFindSources(".", &srcs)) {
	fprintf(stderr, "No source files in current directory\n");
	exit(1);
    }

    /*
     * Search all the .asm files for include directives for .rdef or
     * .rdf files. Add the included file in its .ui form to the list
     * rdfFiles.
     */
    rdfFiles = Lst_Init(FALSE);

    if (!Lst_Open(srcs.asmFiles)) {
	while ((ln = Lst_Next(srcs.asmFiles)) != NILLNODE) {
	    const char	*asmFile;

	    asmFile = (const char *)Lst_Datum(ln);
	    MkmfScanForRdfIncludes(asmFile, rdfFiles);
	}
    }

    /* 
     * Find out which .asm files to assemble.
     */
    allasmFiles = Lst_Duplicate(srcs.asmFiles, NOCOPY);

    if (!Lst_Open(srcs.asmFiles)) {
	while ((ln = Lst_Next(srcs.asmFiles)) != NILLNODE) {
	    const char	*asmFile;

	    asmFile = (const char *)Lst_Datum(ln);
	    MkmfScanForAsmIncludes(asmFile, srcs.asmFiles, allasmFiles);
	}
    }

    /*
     * Create the list of all objects by concatenating the list of assemblable
     * .asm files, non-GOC-derived .c files, and .goc files, after having
     * changed the suffix to .obj. This is done most easily by duplicating
     * the lists involved, using MkmfConvertToObj to perform the
     * transformation.
     * LST_CONCLINK will cause the duplicated lists to be destroyed once all
     * their elements have been stolen.
     */
    objList = Lst_Duplicate(srcs.asmFiles, MkmfConvertToObj);
    Lst_Concat(objList, Lst_Duplicate(srcs.cFiles, MkmfConvertToObj),
	       LST_CONCLINK);
    Lst_Concat(objList, Lst_Duplicate(srcs.gocFiles, MkmfConvertToObj),
	       LST_CONCLINK);

    /*
     * Help out dependency generation by putting out the list of assembly
     * files that are actually assembled.
     */
    MkmfAddVar("ASM_TO_OBJS", srcs.asmFiles);

    /*
     * Help out dependency generation by putting out the list of UI
     * files that are actually run through UIC.
     */
    MkmfAddVar("UI_TO_RDFS", rdfFiles);

    /*
     * Output all the sources to the SRCS variable (allasm takes the place of
     * the assembled asm files here).
     */
    srcs.asmFiles = allasmFiles;
    MkmfOutputSources("SRCS", &srcs);

    MkmfAddVar("OBJS", objList);

}


/***********************************************************************
 *				MkmfConfirmLargeModel
 ***********************************************************************
 * SYNOPSIS:	    Having found subdirectories of the current dir,
 *		    make sure they are actually source modules by
 *	    	    looking for a manager.asm file or any .c or .goc
 *	    	    file in the subdirectory.
 * CALLED BY:	    main
 * RETURN:	    non-zero if large-model nature confirmed
 * SIDE EFFECTS:    the module directories are appended to the
 *		    passed modules list.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/92		Initial Revision
 *
 ***********************************************************************/
static int
MkmfConfirmLargeModel(Lst   subdirs,	    /* Directories to search */
		      Lst   modules)	    /* Place to put them if they
					     * turn out to be source
					     * modules. */
{
    MkmfPattern	searchPatterns[3];
    Lst	    	files;
    LstNode 	ln;

    /*
     * Create a list onto which all files that are located in all
     * subdirectories
     * (manager.asm, *.c, or *.goc files) are put, awaiting their final
     * freedom at the end of the run.
     */
    files = Lst_Init(FALSE);

    /*
     * Set up the search patterns for the scan of each subdirectory. We only
     * care about the presence of these files, not their names, nor segregating
     * them into their own lists, so they all use the list we just created.
     */
#if defined(unix) || defined(_WIN32) || defined(_LINUX)
    searchPatterns[0].pattern = "*Manager.asm";
#else
    searchPatterns[0].pattern = "manager.asm";
#endif
    searchPatterns[0].list    = files;
    searchPatterns[1].pattern = "*.c";
    searchPatterns[1].list    = files;
    searchPatterns[2].pattern = "*.goc";
    searchPatterns[2].list    = files;

    /*
     * Loop over all the subdirectories, looking for those with files that
     * match the above patterns. Any match makes us consider that directory
     * to be a module.
     */
    for (ln = Lst_First(subdirs); ln != NILLNODE; ln = Lst_Succ(ln)) 
    {
	const char *subdir = (const char *)Lst_Datum(ln);

	if (MkmfScanDir(subdir, searchPatterns,
			sizeof(searchPatterns)/sizeof(searchPatterns[0]))) {
	    /*
	     * Record this subdirectory at the end of the list of known
	     * modules.
	     */
	    (void)Lst_AtEnd(modules, (ClientData)subdir);
	} else if (MkmfScanInstalledDir(subdir, searchPatterns, 
					sizeof(searchPatterns) /
					sizeof(searchPatterns[0]))) {
		(void)Lst_AtEnd(modules, (ClientData)subdir);
	}

	/* for each subdirectory, create a PVCS.CFG file for PVCS to use 
	 * if the -[vV] flag was passed to mkmf 
	 */
	if (revisionControl) {
	    MkmfInitPVCSForDirectory((char *)subdir);
	}
    }
	

    /*
     * Nuke the list of files we found everywhere, freeing the strings stored
     * in the list, as well.
     */
    Lst_Destroy(files, (void (*)())free);

    /*
     * Return as appropriate.
     */
    return (!Lst_IsEmpty(modules));
}


/***********************************************************************
 *				MkmfFindLibNameCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback routine to locate the "name" directive in
 *		    a .gp file and produce the requisite LIBNAME
 *		    variable in the makefile
 * CALLED BY:	    (INTERNAL) MkmfPrintLIBOBJ via MkmfScanFile
 * RETURN:	    0 to continue reading/1 to stop
 * SIDE EFFECTS:    the FILE * in MkmfPrintLIBOBJ whose address is
 *		    passed as *data is set to 0 if the thing is found.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/16/95		Initial Revision
 *
 ***********************************************************************/
static int
MkmfFindLibNameCallback(FILE *stream, char *buf, int c, void *data)
{
    if ((strcmp(buf, "name") == 0) || (strcmp(buf, "NAME") == 0)) {
#if defined(_MSDOS)
	char	name[9];	           /* 8 chars of permanent name +
					    * null char */
#else /* unix or _WIN32 */
	char    name[MAX_PATH_LENGTH + 1]; /* MAX_PATH_LENGTH chars of
					    * permanent name + null char */
#endif /* defined(_MSDOS) */
	char	*cp;

	/*
	 * Skip to the start of the permanent name.
	 */
	while (isspace(c)) {
	    c = fgetc(stream);
	}
	
	/*
	 * Read the chars of the permanent name, minus the extension.
	 */
	for (cp = name;
	     cp < &name[sizeof(name)-1] &&
	     !isspace(c) && c != '.' && c != EOF;
	     c = fgetc(stream)){
	    *cp++ = (char) c;
	}
	*cp = '\0';

	fprintf(*(FILE **)data, "%-15s = %s\n", "LIBNAME", name);
	/*
	 * Signal that we found the name.
	 */
	*(FILE **)data = NULL;
	return(1);
    } else {
	return(0);
    }
}

	
/*********************************************************************
 *			MkmfPrintLIBOBJ
 *********************************************************************
 * SYNOPSIS: put out the LIBOBJ (if needed)
 * CALLED BY:	main
 * RETURN: nothing
 * SIDE EFFECTS: outputs stuff to outfile (if needed)
 * STRATEGY: check if we are in a sub-directory of Library
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/ 8/92	Initial version			     
 * 
 *********************************************************************/
static void
MkmfPrintLIBOBJ(FILE *outfile)
{
    char    cwd[MAX_PATH_LENGTH];
    char    *cp;
    int	    i;

    Compat_GetCwd(cwd, MAX_PATH_LENGTH);

#define LIBPATTERN1  "*/Library/*"
#define LIBPATTERN2  "*\\\\Library\\\\*"

    if (MkmfStringMatch(cwd, LIBPATTERN1) ||
	MkmfStringMatch(cwd, LIBPATTERN2)) {
	char	     ldfname[13];
	MkmfPattern  gpPattern;

	fprintf(outfile, "%-15s =", "LIBOBJ");
	cp = Compat_LastPathSep(cwd);

	strcpy(ldfname, cp + 1);
	cp = (char *)ldfname + strlen(ldfname);
	strcpy(cp, ".ldf");
#ifdef _MSDOS
	fprintf(outfile, " %s/Include/Ldf/%s\n", rootDir, ldfname);
#else
	/*
	 * Under Unix/NT, the system makefiles figure everything
	 * out for us.
	 */
	fprintf(outfile, " $(DEVEL_DIR)/Include/$(GEODE).ldf\n");
#endif

	/*
	 * Look for the permanent name in the .gp file for passing to GOC
	 * (-L name) and Esp (-n name)
	 */
	gpPattern.pattern = "*.gp";
	gpPattern.list    = Lst_Init(FALSE);

	i = MkmfScanDir(".", &gpPattern, 1);
	if (i == 0) {
	    i = MkmfScanInstalledDir(".", &gpPattern, 1);
	}

	if (i) {
	    LstNode  ln;
	    FILE    *of = outfile;

	    for (ln = Lst_First(gpPattern.list);
		 ln != NILLNODE && of != NULL;
		 ln = Lst_Succ(ln)) {
		MkmfScanFile((char *)Lst_Datum(ln),
			     MkmfFindLibNameCallback,
			     &of);
	    }
	}

	Lst_Destroy(gpPattern.list, (void (*)())free);
    }
}


/***********************************************************************
 *				MkmfPrintPRODUCTS
 ***********************************************************************
 *
 * SYNOPSIS:	      Checks to see how to define the PRODUCTS variable.
 * CALLED BY:	      main
 * RETURN:	      nothing.
 * SIDE EFFECTS:      may output some data to outFile.
 *
 * STRATEGY:	      check every subdir and see if there's a "is_a_product"
 *                    file in it, if there is, add the directory name to
 *                    the PRODUCTS assignment
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	12/05/96   	Initial Revision
 *
 ***********************************************************************/
void
MkmfPrintPRODUCTS (FILE *outFile)
{
    DIR           *dir;
    struct dirent *dp;

    if ((dir = opendir(".")) == NULL) {
	fprintf(stderr, "mkmf: \".\": ");
	perror("");
	exit(1);
    }

    while ((dp = readdir(dir)) != NULL) {
	if (strcmp(dp->d_name, ".") != 0 && strcmp(dp->d_name, "..") != 0) {
	    DIR  *subDir;

	    if ((subDir = opendir(dp->d_name)) != NULL) {
		char  file[MAX_PATH_LENGTH];
		
		sprintf(file, "%s/is_a_product", dp->d_name);
		if (FILE_EXISTS(file)) {
		    if (strlen(products) == 1023) {
			fprintf(stderr,
				"mkmf: error: product definition exceeds 1024"
				" characters.\n");
		    } else {
			strcat(products, dp->d_name);
			strcat(products, " ");
		    }
		}
		closedir(subDir);
	    }
	}
    }

    if (*products != NULL) {
	fprintf(outFile, "\nPRODUCTS        = %s\n", products);
    }
    
    closedir(dir);
}	/* End of MkmfPrintPRODUCTS.	*/

#if defined(_WIN32)

/***********************************************************************
 *				SpawnPmakeDepend
 ***********************************************************************
 *
 * SYNOPSIS:	     Spawns pmake depend
 * CALLED BY:	     main
 * RETURN:	     exit code of spawned process
 * SIDE EFFECTS:     spawns a child process
 *
 * STRATEGY:	     Call CreateProcess with the command line string
 *                   "pmake depend"
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/24/96   	Initial Revision
 *
 ***********************************************************************/
static int
SpawnPmakeDepend (void)
{
    STARTUPINFO         startInfo = {0};
    DWORD               exitCode  = 0;

    startInfo.cb         = sizeof(STARTUPINFO);

    if (!CreateProcess(NULL, "pmake depend", NULL, NULL, TRUE, 0, NULL,
		       NULL, &startInfo, &procInfo)) {
	fprintf(stderr, "mkmf: Failed to spawn \"pmake depend\"");
	return 1;
    }

    switch(WaitForSingleObject(procInfo.hProcess, INFINITE)) {
    case WAIT_FAILED:
	fprintf(stderr, "mkmf: Failed to wait for pmake (id %x)",
			   procInfo.dwProcessId);
	exitCode = 1;
	break;

    /* this case shouldn't be reached because we blocked for infinity, but...*/
    case WAIT_TIMEOUT:
	fprintf(stderr, "mkmf: Wait for pmake (id %x) timed out.\n",
		procInfo.dwProcessId);
	exitCode = 1;
	break;

    case WAIT_OBJECT_0:
	if (!GetExitCodeProcess(procInfo.hProcess, &exitCode)) {
	    fprintf(stderr, "mkmf");
	    exitCode = 1;
	}
	break;

    /* Should never get here, either, but... */
    default:
	fprintf(stderr, "mkmf: error while waiting for pmake (id %x).\n",
		procInfo.dwProcessId);
	exitCode = 1;
	break;
    }
    
    if (procInfo.hProcess != INVALID_HANDLE_VALUE) {
	CloseHandle(procInfo.hProcess);
    }

    return exitCode;
}	/* End of SpawnPmakeDepend.	*/


/***********************************************************************
 *				ControlCHandler
 ***********************************************************************
 *
 * SYNOPSIS:	      Handles control c processing
 * CALLED BY:	      Whenever ^C or ^BREAK event is generated
 * RETURN:	      TRUE
 * SIDE EFFECTS:      removes the makefile, closes the handles opened
 *                    by SpawnPmakeDepend, and Generates a console
 *                    ctrl event.
 *
 * STRATEGY:	      just call unlink, CloseHandle, and
 *                    GenerateConsoleCtrlEvent.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/24/96   	Initial Revision
 *
 ***********************************************************************/
static BOOL WINAPI
ControlCHandler (DWORD signo)
{
    if (output != NULL) {
	(void) fclose(output);
	(void) unlink("Makefile");
    }

    if (procInfo.hProcess != INVALID_HANDLE_VALUE) {
	(void) CloseHandle(procInfo.hProcess);
    }

    if (!GenerateConsoleCtrlEvent(CTRL_C_EVENT, 0)) {
	fprintf(stderr, "mkmf: unable to generate ^C event.\n");
    }

    ExitProcess(1);

    return TRUE;
}	/* End of ControlCHandler.	*/
#endif /* defined(_WIN32) */    


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    do everything
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/92		Initial Revision
 *
 ***********************************************************************/
int
main(int argc, char **argv)
{
    Lst	    subdirs;
    Lst	    modules;
    char    *cp;
    char    *oldcp;
    char    branchFile[MAX_PATH_LENGTH] = {0};
    char    cwd[MAX_PATH_LENGTH];
    Lst	    geodeName;
    int	    args;
    char   *envRootDir;
    int	    i;
    char   *finalRootWithSlash;
    int     hitSlash = 0;
    int	    hitPcgeos = 0;
    

#if defined(_WIN32)
    int     runPmakeDepend = 1;

    SetConsoleCtrlHandler(ControlCHandler, TRUE);
#endif /* defined(_WIN32) */

    /*
     * for debugging
     */
#if 0
    chdir("u:\\pcgeos\\tbradley\\appl\\sdk_9000\\filesel");
#endif /* 1 */

    envRootDir = getenv("ROOT_DIR");
    if (envRootDir == NULL) {
	fprintf(stderr,
		"mkmf: error: ROOT_DIR environment variable not set\n");
	exit(1);
    }
    strcpy(rootDir, envRootDir);
    Compat_CanonicalizeFilename(rootDir);

    /*
     * This is usually going to be "pcgeos", but that's not actually
     * required by any of the tools, so we won't require it here.
     */
    strcpy(finalRootComponent, Compat_GetPathTail(rootDir));

    /*
     * Complain if we can't figure out the subdirectory
     * of LOCAL_ROOT that we're in.  This is just a check.
     */
    Compat_GetCwd(cwd, sizeof(cwd));
    if (Compat_GetTrailingPath(finalRootComponent, cwd) == NULL) {
	fprintf(stderr, 
		"mkmf: error: current directory's pathname must contain '%s'\n",
		finalRootComponent + 1); /* +1 to skip '/' */
	exit(1);
    }

    /*
     * Find the BRANCH file.  
     *
     * 1) Take final component of ROOT_DIR (usually "pcgeos).  Doesn't
     *    matter what leads up to it in ROOT_DIR (e.g., we don't care
     *    if it's s:/yo/mamma/sucks/eggs/pcgeos or just s:/pcgeos).
     * 2) Find that same final compnenent in CWD.
     *    (e.g., c:/blah/blah/blah/pcgeos/jacob/Appl)
     *		                   ^^^^^^
     * 3) Path up to and including that element, plus one beyond,
     *    is LOCAL_ROOT (e.g., c:/blah/pcgeos/jacob).
     *                                
     */
    finalRootWithSlash = 
	(char *) malloc(strlen(finalRootComponent) + 2); /* #4 */
    strcpy(finalRootWithSlash, finalRootComponent);
    strcat(finalRootWithSlash, "/");
    /*
     * Copy cwd into branchFile, up to and including finalRootWithSlash.
     */
    for (i = 0; cwd[i] != '\0'; i++) {
	branchFile[i] = cwd[i];
	if (!hitPcgeos
	    && (strncmpi(&cwd[i], 
			 finalRootWithSlash, strlen(finalRootWithSlash))
		== 0)) {
	    hitPcgeos = 1;
	    continue;
	} else if (hitPcgeos) {
	    if (cwd[i] == '/') {
		if (hitSlash) {
		    break;	/* 2nd slash follows username, so stop here */
		} else {
		    hitSlash = 1;
		}
	    }
	}
    }
    free(finalRootWithSlash);	/* #4 */
    /*
     * We were able to identify LOCAL_ROOT, so see if there's
     * a branch file.
     */
    if (hitPcgeos) {
	if (!hitSlash) {
	    strcat(branchFile, "/");
	}
	strcat(branchFile, BRANCH_FILE);

	branch             = GetBranchFromFile(branchFile); /* #5 */
	if (branch != NULL) {
	    strcat(rootDir, "/");
	    strcat(rootDir, branch);
	}
	free(branch);		/* #5 */
    }


    for (args = argc; args > 1; args--) {
	if (argv[args-1][0] == '-' || argv[args-1][0] == '/') {

	    switch (argv[args-1][1]) {
	    /*
	     * do PVCS revision control stuff
	     */
	    case 'v':
	    case 'V':	
		revisionControl = 1;
		break;

#if defined(_WIN32)
	     /*
	      * don't run pmake depend
	      */
	    case 'd':
	    case 'D':
		runPmakeDepend = 0;
		break;
#endif /* defined(_WIN32) */

	    }
    	}
    }

    /*
     * Create the global list of all variables that are to be defined.
     */
    vars = Lst_Init(FALSE);

    /*
     * Figure the name of the geode from the final component of the current
     * directory. No need to downcase/upcase, as DOS is case-insensitive.
     */
#if !defined(unix)
    /*
     * this is mainly for in-house use, but have it make a PVCS config file
     * if it finds you not in the root tree and the VCSCFG environment
     * variable is set
     */
    if (getenv("VCSCFG") != NULL) {
	if (Strnicmp(rootDir, cwd, strlen(rootDir)) != 0) {
	    revisionControl = 1;
	}
    }
#endif /* !defined(unix) */

    cp = Compat_LastPathSep(cwd);

    if (cp == NULL) {
	fprintf(stderr,
		"Couldn't determine geode name "
		"(no path separator in current directory)\n");
	return(1);
    }
    
    oldcp = cp;
    while(*cp) {
	*cp = (char) tolower(*cp);
	cp++;
    }
    cp = oldcp;
    
    geodeName = Lst_Init(FALSE);
    (void)Lst_AtEnd(geodeName, (ClientData)(cp + 1));
    MkmfAddVar("GEODE", geodeName);
    
    /*
     * Create lists for the subdirectories and to figure whether the thing's
     * a large-model geode.
     */
    subdirs = Lst_Init(FALSE);
    modules = Lst_Init(FALSE);

    /*
     * Locate all subdirectories and see if they hold source modules.
     */
    if (MkmfFindSubdirs(subdirs) && MkmfConfirmLargeModel(subdirs, modules)) {
	MkmfCreateLargeModel(modules);
    } else {
	MkmfCreateSmallOrMediumModel();
    }

    /* create a pvcs.cfg for the root directory if -[vV] flag passed */
    if (revisionControl) {
	MkmfInitPVCSForDirectory(".");
    }


    /*
     * Create the new makefile.
     */
    output = fopen("Makefile", "w+t");
    if (output == NULL) {
	perror("mkmf: Makefile");
	return(1);
    }

    /*
     * Put out warning notice as header.
     */
    fprintf(output,
	    "#\n"
	    "# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.\n"
	    "#\n"
	    "# If you edit it, you will lose your changes, should it be regenerated.\n"
	    "#\n");

    /*
     * Spew all variables.
     */
    MkmfPrintAllVars(output);

    /*
     * As far as mkmf.exe is concerned, LOBJS is just a dummy var.
     */
    fprintf(output, "LOBJS           =\n");

    /* check to see if we need to put out a LIBOBJ variable
     * do this by check the current directory again the pattern
     * "*\\LIBRARY\\*" if we get a match the put out a LIBOBJ
     * variable
     */
    MkmfPrintLIBOBJ(output);
    MkmfDoDriverStuff();

    /*
     * Check to see if we need to set the PRODUCTS variable
     */
    MkmfPrintPRODUCTS(output);
    /*
     * Put out definition of SYSMAKEFILE and include the requisite system
     * makefiles.
     */
    fprintf(output,
	    "\nSYSMAKEFILE     = geode.mk\n\n"
	    "#include <geos.mk>\n"
	    "#include <gpath.mk>\n\n"
	    "#if exists(local.mk)\n"
	    "#include \"local.mk\"\n"
#if defined(_MSDOS)
	    /*
	     * This ain't needed under NT or Unix
	     */
	    "#elif exists($(INSTALLED_SOURCE)/local.mk)\n"
	    "#include <$(INSTALLED_SOURCE)/local.mk>\n"
#endif
	    "#else\n"
	    "#include <$(SYSMAKEFILE)>\n"
	    "#endif\n");

    /*
     * Put out inclusion of dependencies file.
     */
    fprintf(output,
	    "\n#if exists($(DEPFILE))\n"
	    "#include \"$(DEPFILE)\"\n"
	    "#endif\n");
    /*
     * Dependency files for products.
     */
    for(cp = strtok(products," \t"); cp; cp = strtok(NULL, " \t"))
    {
      fprintf(output,
              "\n#if exists(%s/$(DEPFILE))\n"
              "#include \"%s/$(DEPFILE)\"\n"
              "#endif\n", cp, cp);
    }

    /*
     * Close up and finish.
     */
    fclose(output);
    output = NULL;

    printf("Makefile generation complete.\n");

#if defined(_WIN32)
    if (runPmakeDepend) {
	printf("Running \"pmake depend\".\n");
	return(SpawnPmakeDepend());
    }
#else
    printf("Don't forget to run \"pmake depend\".\n");
#endif /* defined(_WIN32) */

    return(0);
}
