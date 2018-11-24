/*-
 * dir.c --
 *	Directory searching using wildcards and/or normal names...
 *	Used both for source wildcarding in the Makefile and for finding
 *	implicit sources.
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
 * The interface for this module is:
 *	Dir_Init  	    Initialize the module.
 *
 *	Dir_HasWildcards    Returns TRUE if the name given it needs to
 *	    	  	    be wildcard-expanded.
 *
 *	Dir_Expand	    Given a pattern and a path, return a Lst of names
 *	    	  	    which match the pattern on the search path.
 *
 *	Dir_FindFile	    Searches for a file on a given search path.
 *	    	  	    If it exists, the entire path is returned.
 *	    	  	    Otherwise NULL is returned.
 *
 *	Dir_MTime 	    Return the modification time of a node. The file
 *	    	  	    is searched for along the default search path.
 *	    	  	    The path and mtime fields of the node are filled
 *	    	  	    in.
 *
 *	Dir_AddDir	    Add a directory to a search path.
 *
 *	Dir_MakeFlags	    Given a search path and a command flag, create
 *	    	  	    a string with each of the directories in the path
 *	    	  	    preceded by the command flag and all of them
 *	    	  	    separated by a space.
 *
 *	Dir_Destroy	    Destroy an element of a search path. Frees up all
 *	    	  	    things that can be freed for the element as long
 *	    	  	    as the element is no longer referenced by any other
 *	    	  	    search path.
 *	Dir_ClearPath	    Resets a search path to the empty list.
 *
 * For debugging:
 *	Dir_PrintDirectories	Print stats about the directory cache.
 */

#include <config.h>

#ifndef lint
static char     *rcsid = "$Id: dir.c,v 1.12 96/06/24 15:05:23 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include <stdio.h>
#include <compat/stdlib.h>
#include <sys/types.h>

#if !defined(unix)
#	include <malloc.h>
#endif /* !defined(unix) */

#include <sys/stat.h>
#include <compat/string.h>

#include "make.h"
#include "hash.h"

#if defined(unix)
#    include "arch.h"
#endif /* defined(unix) */

/*
 * I put this after everything else, 'cuz that's the only way it
 * seems to compile.  I wish I knew why...  
 */
#include <compat/dirent.h>

/*
 *	A search path consists of a Lst of Path structures. A Path structure
 *	has in it the name of the directory and a hash table of all the files
 *	in the directory. This is used to cut down on the number of system
 *	calls necessary to find implicit dependents and their like. Since
 *	these searches are made before any actions are taken, we need not
 *	worry about the directory changing due to creation commands. If this
 *	hampers the style of some makefiles, they must be changed.
 *
 *	A list of all previously-read directories is kept in the
 *	openDirectories Lst. This list is checked first before a directory
 *	is opened.
 *
 *	The need for the caching of whole directories is brought about by
 *	the multi-level transformation code in suff.c, which tends to search
 *	for far more files than regular make does. In the initial
 *	implementation, the amount of time spent performing "stat" calls was
 *	truly astronomical. The problem with hashing at the start is,
 *	of course, that pmake doesn't then detect changes to these directories
 *	during the course of the make. Three possibilities suggest themselves:
 *
 *	    1) just use stat to test for a file's existence. As mentioned
 *	       above, this is very inefficient due to the number of checks
 *	       engendered by the multi-level transformation code.
 *	    2) use readdir() and company to search the directories, keeping
 *	       them open between checks. I have tried this and while it
 *	       didn't slow down the process too much, it could severely
 *	       affect the amount of parallelism available as each directory
 *	       open would take another file descriptor out of play for
 *	       handling I/O for another job. Given that it is only recently
 *	       that UNIX OS's have taken to allowing more than 20 or 32
 *	       file descriptors for a process, this doesn't seem acceptable
 *	       to me.
 *	    3) record the mtime of the directory in the Path structure and
 *	       verify the directory hasn't changed since the contents were
 *	       hashed. This will catch the creation or deletion of files,
 *	       but not the updating of files. However, since it is the
 *	       creation and deletion that is the problem, this could be
 *	       a good thing to do. Unfortunately, if the directory (say ".")
 *	       were fairly large and changed fairly frequently, the constant
 *	       rehashing could seriously degrade performance. It might be
 *	       good in such cases to keep track of the number of rehashes
 *	       and if the number goes over a (small) limit, resort to using
 *	       stat in its place.
 *
 *	An additional thing to consider is that pmake is used primarily
 *	to create C programs and until recently pcc-based compilers refused
 *	to allow you to specify where the resulting object file should be
 *	placed. This forced all objects to be created in the current
 *	directory. This isn't meant as a full excuse, just an explanation of
 *	some of the reasons for the caching used here.
 *
 *	One more note: the location of a target's file is only performed
 *	on the downward traversal of the graph and then only for terminal
 *	nodes in the graph. This could be construed as wrong in some cases,
 *	but prevents inadvertent modification of files when the "installed"
 *	directory for a file is provided in the search path.
 *
 *	Another data structure maintained by this module is an mtime
 *	cache used when the searching of cached directories fails to find
 *	a file. In the past, Dir_FindFile would simply perform an access()
 *	call in such a case to determine if the file could be found using
 *	just the name given. When this hit, however, all that was gained
 *	was the knowledge that the file existed. Given that an access() is
 *	essentially a stat() without the copyout() call, and that the same
 *	filesystem overhead would have to be incurred in Dir_MTime, it made
 *	sense to replace the access() with a stat() and record the mtime
 *	in a cache for when Dir_MTime was actually called.
 */

Lst          dirSearchPath;	/* main search path */

static Lst   openDirectories;	/* the list of all open directories */

/*
 * Variables for gathering statistics on the efficiency of the hashing
 * mechanism.
 */
static int    hits,	      /* Found in directory cache */
	      misses,	      /* Sad, but not evil misses */
	      nearmisses,     /* Found under search path */
	      bigmisses;      /* Sought by itself */


/**********************prototypes for static routines****************/
static Path 	*DirAddDir(Lst path, char *name);
static int	DirFindName(Path *p, char *dname);
static int	DirMatchFiles(char *pattern, Path *p, Lst expansions);
static void	DirExpandCurly(char *myword, char *brace, Lst path,
					Lst expansions);
static void	DirExpandInt(char *myword, Lst path, Lst expansions);
static int	DirPrintWord(char *myword);

static Path    	  *dot;	    /* contents of current directory */
static Hash_Table mtimes;   /* Results of doing a last-resort stat in
			     * Dir_FindFile -- if we have to go to the
			     * system to find the file, we might as well
			     * have its mtime on record. XXX: If this is done
			     * way early, there's a chance other rules will
			     * have already updated the file, in which case
			     * we'll update it again. Generally, there won't
			     * be two rules to update a single file, so this
			     * should be ok, but... */


/*-
 *-----------------------------------------------------------------------
 * Dir_Init --
 *	initialize things for this module
 *
 * Results:
 *	none
 *
 * Side Effects:
 *	some directories may be opened.
 *-----------------------------------------------------------------------
 */
void
Dir_Init (void)
{
    dirSearchPath = Lst_Init (FALSE);
    openDirectories = Lst_Init (FALSE);
#if !defined(__HIGHC__) && !defined(__WATCOMC__)
    Hash_InitTable(&mtimes, 0, HASH_STRING_KEYS);
#else
    Hash_InitTable(&mtimes, 0, HASH_STRING_KEYS, 0);
#endif    
    /*
     * Since the Path structure is placed on both openDirectories and
     * the path we give Dir_AddDir (which in this case is openDirectories),
     * we need to remove "." from openDirectories and what better time to
     * do it than when we have to fetch the thing anyway?
     */
    Dir_AddDir (openDirectories, ".");
    dot = (Path *) Lst_DeQueue (openDirectories);

    /*
     * We always need to have dot around, so we increment its reference count
     * to make sure it's not destroyed.
     */
    dot->refCount += 1;
}

/*-
 *-----------------------------------------------------------------------
 * DirFindName --
 *	See if the Path structure describes the same directory as the
 *	given one by comparing their names. Called from Dir_AddDir via
 *	Lst_Find when searching the list of open directories.
 *
 * Results:
 *	0 if it is the same. Non-zero otherwise
 *
 * Arguments:
 *      Path *p     : Current name
 *      char *dname : Desired name
 *
 * Side Effects:
 *	None
 *-----------------------------------------------------------------------
 */
static int
DirFindName (Path *p, char *dname)
{
#if defined (_WIN32)
    return (stricmp (p->name, dname));
#else
    return (strcmp (p->name, dname));
#endif /* defined (_WIN32) */
}

/*-
 *-----------------------------------------------------------------------
 * Dir_HasWildcards  --
 *	see if the given name has any wildcard characters in it
 *
 * Results:
 *	returns TRUE if the word should be expanded, FALSE otherwise
 *
 * Arguments:
 *      char *name : name to check
 *
 * Side Effects:
 *	none
 *-----------------------------------------------------------------------
 */
Boolean
Dir_HasWildcards (char *name)
{
    register char *cp;
    
    for (cp = name; *cp; cp++) {
	switch(*cp) {
	case '{':
	case '[':
	case '?':
	case '*':
	    return (TRUE);
	}
    }
    return (FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * DirMatchFiles --
 * 	Given a pattern and a Path structure, see if any files
 *	match the pattern and add their names to the 'expansions' list if
 *	any do. This is incomplete -- it doesn't take care of patterns like
 *	src/*src/*.c properly (just *.c on any of the directories), but it
 *	will do for now.
 *
 * Results:
 *	Always returns 0
 *
 * Arguments:
 *      char *pattern    : Pattern to look for
 *      Path *p          : Directory to search
 *      Lst   expansions : Place to store the results
 *
 * Side Effects:
 *	File names are added to the expansions lst. The directory will be
 *	fully hashed when this is done.
 *-----------------------------------------------------------------------
 */
static int
DirMatchFiles (char *pattern, Path *p, Lst expansions)
{
    Hash_Search	  search;   	/* Index into the directory's table */	
    Hash_Entry	  *entry;   	/* Current entry in the table */
    /*char    	  *f;*/	    	/* Current entry in the directory */
    Boolean 	  isDot;    	/* TRUE if the directory being searched is . */
    
    isDot = (*p->name == '.' && p->name[1] == '\0');
    
    for (entry = Hash_EnumFirst(&p->files, &search);
	 entry != (Hash_Entry *)NULL;
	 entry = Hash_EnumNext(&search))
    {
	char *i,*j;
	/*
	 * See if the file matches the given pattern. Note we follow the UNIX
	 * convention that dot files will only be found if the pattern
	 * begins with a dot (note also that as a side effect of the hashing
	 * scheme, .* won't match . or .. since they aren't hashed).
	 */
	if (Str_Match(entry->key.name, pattern, &i, &j) &&
	    ((entry->key.name[0] != '.') ||
	     (pattern[0] == '.')))
	{
	    (void)Lst_AtEnd(expansions,
			   (ClientData) (isDot ? Str_New(entry->key.name) :
			     Str_Concat(p->name, entry->key.name,
					STR_ADDSLASH)));
	}
    }
    return (0);
}

/*-
 *-----------------------------------------------------------------------
 * DirExpandCurly --
 *	Expand curly braces like the C shell. Does this recursively.
 *	Note the special case: if after the piece of the curly brace is
 *	done there are no wildcard characters in the result, the result is
 *	placed on the list WITHOUT CHECKING FOR ITS EXISTENCE.
 *
 * Results:
 *	None.
 *
 * Arguments:
 *      char *myword     : Entire word to expand
 *      char *brace      : First curly brace in it
 *      Lst   path       : Search path to use
 *      Lst   expansions : Place to store the expansions
 *
 * Side Effects:
 *	The given list is filled with the expansions...
 *
 *-----------------------------------------------------------------------
 */
static void
DirExpandCurly(char *myword, char *brace, Lst path, Lst expansions)
{
    char    	  *end;	    	/* Character after the closing brace */
    char    	  *cp;	    	/* Current position in brace clause */
    char    	  *start;   	/* Start of current piece of brace clause */
    int	    	  bracelevel;	/* Number of braces we've seen. If we see a
				 * right brace when this is 0, we've hit the
				 * end of the clause. */
    char    	  *file = NULL; /* Current expansion */
    int	    	  otherLen; 	/* The length of the other pieces of the
				 * expansion (chars before and after the
				 * clause in 'myword') */
    char    	  *cp2;	    	/* Pointer for checking for wildcards in
				 * expansion before calling Dir_Expand */

    start = brace+1;

    /*
     * Find the end of the brace clause first, being wary of nested brace
     * clauses.
     */
    for (end = start, bracelevel = 0; *end != '\0'; end++) {
	if (*end == '{') {
	    bracelevel++;
	} else if ((*end == '}') && (bracelevel-- == 0)) {
	    break;
	}
    }
    if (*end == '\0') {
	Error("Unterminated {} clause \"%s\"", (unsigned long)start, 0, 0);
	return;
    } else {
	end++;
    }
    otherLen = brace - myword + strlen(end);

    for (cp = start; cp < end; cp++) {
	/*
	 * Find the end of this piece of the clause.
	 */
	bracelevel = 0;
	while (*cp != ',') {
	    if (*cp == '{') {
		bracelevel++;
	    } else if ((*cp == '}') && (bracelevel-- <= 0)) {
		break;
	    }
	    cp++;
	}
	/*
	 * Allocate room for the combination and install the three pieces.
	 */
	MallocCheck(file, otherLen + cp - start + 1);
	if (brace != myword) {
	    strncpy(file, myword, brace-myword);
	}
	if (cp != start) {
	    strncpy(&file[brace-myword], start, cp-start);
	}
	strcpy(&file[(brace-myword)+(cp-start)], end);

	/*
	 * See if the result has any wildcards in it. If we find one, call
	 * Dir_Expand right away, telling it to place the result on our list
	 * of expansions.
	 */
	for (cp2 = file; *cp2 != '\0'; cp2++) {
	    switch(*cp2) {
	    case '*':
	    case '?':
	    case '{':
	    case '[':
		Dir_Expand(file, path, expansions);
		goto next;
	    }
	}
	if (*cp2 == '\0') {
	    /*
	     * Hit the end w/o finding any wildcards, so stick the expansion
	     * on the end of the list.
	     */
	    (void)Lst_AtEnd(expansions, (ClientData)file);
	} else {
	next:
	    free(file);
	    file = NULL;
	}
	start = cp+1;
    }
}


/*-
 *-----------------------------------------------------------------------
 * DirExpandInt --
 *	Internal expand routine. Passes through the directories in the
 *	path one by one, calling DirMatchFiles for each. NOTE: This still
 *	doesn't handle patterns in directories...
 *
 * Results:
 *	None.
 *
 * Arguments:
 *      char *myword     : Word to expand
 *      Lst   path       : Path on which to look
 *      Lst   expansions : Place to store the results
 *
 * Side Effects:
 *	Things are added to the expansions list.
 *
 *-----------------------------------------------------------------------
 */
static void
DirExpandInt(char *myword, Lst path, Lst expansions)
{
    LstNode 	  ln;	    	/* Current node */
    Path	  *p;	    	/* Directory in the node */

    if (Lst_Open(path) == SUCCESS) {
	while ((ln = Lst_Next(path)) != NILLNODE) {
	    p = (Path *)Lst_Datum(ln);
	    DirMatchFiles(myword, p, expansions);
	}
	Lst_Close(path);
    }
}

/*-
 *-----------------------------------------------------------------------
 * DirPrintWord --
 *	Print a word in the list of expansions. Callback for Dir_Expand
 *	when DEBUG(DIR), via Lst_ForEach.
 *
 * Results:
 *	=== 0
 *
 * Side Effects:
 *	The passed word is printed, followed by a space.
 *
 *-----------------------------------------------------------------------
 */
static int
DirPrintWord(char *myword)
{
    printf("%s ", myword);

    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * Dir_Expand  --
 *	Expand the given word into a list of words by globbing it looking
 *	in the directories on the given search path.
 *
 * Results:
 *	A list of words consisting of the files which exist along the search
 *	path matching the given pattern.
 *
 * Arguments:
 *      char *myword     : The word to expand
 *      Lst   path       : The list of directories in which to find the
 *                         resulting files
 *      Lst   expansions : The list on which to place the results
 *
 * Side Effects:
 *	Directories may be opened. Who knows?
 *-----------------------------------------------------------------------
 */
void
Dir_Expand (char *myword, Lst path, Lst expansions)
{
    char    	  *cp;

    if (DEBUG(DIR)) {
	printf("expanding \"%s\"...", myword);
    }
    
    cp = strchr(myword, '{');
    if (cp) {
	DirExpandCurly(myword, cp, path, expansions);
    } else {
	cp = Var_FirstPathSep(myword);
	if (cp) {
	    /*
	     * The thing has a directory component -- find the first wildcard
	     * in the string.
	     */
	    for (cp = myword; *cp; cp++) {
		if (*cp == '?' || *cp == '[' || *cp == '*' || *cp == '{') {
		    break;
		}
	    }
	    if (*cp == '{') {
		/*
		 * This one will be fun.
		 */
		DirExpandCurly(myword, cp, path, expansions);
		return;
	    } else if (*cp != '\0') {
		/*
		 * Back up to the start of the component
		 */
		char  *dirpath;

		while (cp > myword && !IS_PATHSEP(*cp)) {
		    cp--;
		}
		if (cp != myword) {
		    /*
		     * If the glob isn't in the first component, try and find
		     * all the components up to the one with a wildcard.
		     */
		    *cp = '\0';
		    dirpath = Dir_FindFile(myword, path);
#ifdef _WIN32
		    *cp = '/';
#else
		    *cp = PATHNAME_SLASH;
#endif
		    /*
		     * dirpath is null if can't find the leading component
		     * XXX: Dir_FindFile won't find internal components.
		     * i.e. if the path contains ../Etc/Object and we're
		     * looking for Etc, it won't be found. Ah well.
		     * Probably not important.
		     */
		    if (dirpath != (char *)NULL) {
			path = Lst_Init(FALSE);
			Dir_AddDir(path, dirpath);
			DirExpandInt(cp+1, path, expansions);
			Lst_Destroy(path, NOFREE);
		    }
		} else {
		    /*
		     * Start the search from the local directory
		     */
		    DirExpandInt(myword, path, expansions);
		}
	    } else {
		/*
		 * Return the file -- this should never happen.
		 */
		DirExpandInt(myword, path, expansions);
	    }
	} else {
	    /*
	     * First the files in dot
	     */
	    DirMatchFiles(myword, dot, expansions);
    
	    /*
	     * Then the files in every other directory on the path.
	     */
	    DirExpandInt(myword, path, expansions);
	}
    }
    if (DEBUG(DIR)) {
	Lst_ForEach(expansions, DirPrintWord, NULL);
	putchar('\n');
    }
}

/*-
 *-----------------------------------------------------------------------
 * Dir_FindFile  --
 *	Find the file with the given name along the given search path.
 *
 * Results:
 *	The path to the file or NULL. This path is guaranteed to be in a
 *	different part of memory than name and so may be safely free'd.
 *
 * Arguments:
 *      char *name : The file to find
 *      Lst   path : The Lst of directories to search
 *
 * Side Effects:
 *	If the file is found in a directory which is not on the path
 *	already (either 'name' is absolute or it is a relative path
 *	[ dir1/.../dirn/file ] which exists below one of the directories
 *	already on the search path), its directory is added to the end
 *	of the path on the assumption that there will be more files in
 *	that directory later on. Sometimes this is true. Sometimes not.
 *-----------------------------------------------------------------------
 */
char *
Dir_FindFile (char *name, Lst path)
{
    register char *p1;	    /* pointer into p->name */
    register char *p2;	    /* pointer into name */
    LstNode       ln;	    /* a list element */
    register char *file;    /* the current filename to check */
    register Path *p;	    /* current path member */
    register char *cp;	    /* index of first slash, if any */
    Boolean	  hasSlash; /* true if 'name' contains a / */
    struct stat	  stb;	    /* Buffer for stat, if necessary */
    Hash_Entry	  *entry;   /* Entry for mtimes table */
    
#if defined (_MSDOS) || defined (_WIN32)
    /* the stupid #^%$^! dos world does everything in upper case...*/
     {
    	int i = strlen(name);

	while (i--) {
	    if (IS_PATHSEP(name[i])) {
#ifdef _MSDOS
		name[i] = '\\';
#else
		/* XXX: testing this out.. maybe we don't need
		   \'s at all under Win32*/
		name[i] = '/';
#endif
		  
	    } else {
		/*name[i] = (char) toupper(name[i]);*/
	    }
	}
    }
#endif /* defined (_MSDOS) || defined (_WIN32) */

    /*
     * Find the final component of the name and note whether it has a
     * slash in it (the name, I mean)
     */
    cp = Var_LastPathSep (name);
    if (cp != NULL) {
	hasSlash = TRUE;
	cp += 1;
    } else {
	hasSlash = FALSE;
	cp = name;
    }
    
    if (DEBUG(DIR)) {
	printf("Searching for %s...", name);
    }
    /*
     * No matter what, we always look for the file in the current directory
     * before anywhere else and we *do not* add the ./ to it if it exists.
     * This is so there are no conflicts between what the user specifies
     * (fish.c) and what pmake finds (./fish.c).
     */
    if ((!hasSlash || (cp - name == 2 && *name == '.')) &&
	(Hash_FindEntry (&dot->files, (Address)cp) != (Hash_Entry *)NULL)) {
	    if (DEBUG(DIR)) {
		printf("in '.'\n");
	    }
	    hits += 1;
	    dot->hits += 1;
	    return (Str_New (name));
    }
    
    if (Lst_Open (path) == FAILURE) {
	if (DEBUG(DIR)) {
	    printf("couldn't open path, file not found\n");
	}
	misses += 1;
	return ((char *) NULL);
    }
    
    /*
     * We look through all the directories on the path seeking one which
     * contains the final component of the given name and whose final
     * component(s) match the name's initial component(s). If such a beast
     * is found, we concatenate the directory name and the final component
     * and return the resulting string. If we don't find any such thing,
     * we go on to phase two...
     */
    while ((ln = Lst_Next (path)) != NILLNODE) {
	p = (Path *) Lst_Datum (ln);
	if (DEBUG(DIR)) {
	    printf("%s...", p->name);
	}
	if (Hash_FindEntry (&p->files, (Address)cp) != (Hash_Entry *)NULL) {
	    if (DEBUG(DIR)) {
		printf("here...");
	    }

	    if (hasSlash) {
		/*
		 * If the name had a slash, its initial components and p's
		 * final components must match. This is false if a mismatch
		 * is encountered before all of the initial components
		 * have been checked (p2 > name at the end of the loop), or
		 * we matched only part of one of the components of p
		 * along with all the rest of them (*p1 != PATHNAME_SLASH).
		 */
		p1 = p->name + strlen (p->name) - 1;
		p2 = cp - 2;
		while (p2 >= name && *p1 == *p2) {
		    p1 -= 1; p2 -= 1;
		}

		if (p2 >= name || (p1 >= p->name && !IS_PATHSEP(*p1))) {
		    if (DEBUG(DIR)) {
			printf("component mismatch -- continuing...");
		    }
		    continue;
		}
	    }
	    file = Str_Concat (p->name, cp, STR_ADDSLASH);
	    if (DEBUG(DIR)) {
		printf("returning %s\n", file);
	    }
	    Lst_Close (path);
	    p->hits += 1;
	    hits += 1;
	    return (file);
	} 
#if 0	    /* nuked 9/28/95, as it screws up finding subdirectories in
	     * later directories on the path --ardeb */
	/* this stuff gets in the way if you want to set up pseudo installed
	 * branches on the PC by using the .PATH in the local.mk, so I am
	 * nuking it from the PC version of pmake...I don't think this will
	 * cause any problems...jimmy 8/93
	 */
	else if (hasSlash) 
	{
	    /*
	     * If the file has a leading path component and that component
	     * exactly matches the entire name of the current search
	     * directory, we assume the file doesn't exist and return NULL.
	     */
	    for (p1 = p->name, p2 = name; *p1 && *p1 == *p2; p1++, p2++) 
	    {
		continue;
	    }
	    if (*p1 == '\0' && p2 == cp - 1) 
	    {
		if (DEBUG(DIR)) {
		    printf("must be here but isn't -- returing NULL\n");
		}
		Lst_Close (path);
		return ((char *) NULL);
	    }
	}
#endif
    }
    
    /*
     * We didn't find the file on any existing members of the directory.
     * If the name doesn't contain a slash, that means it doesn't exist.
     * If it *does* contain a slash, however, there is still hope: it
     * could be in a subdirectory of one of the members of the search
     * path. (eg. /usr/include and sys/types.h. The above search would
     * fail to turn up types.h in /usr/include, but it *is* in
     * /usr/include/sys/types.h) If we find such a beast, we assume there
     * will be more (what else can we assume?) and add all but the last
     * component of the resulting name onto the search path (at the
     * end). This phase is only performed if the file is *not* absolute.
     */
    if (!hasSlash) {
	if (DEBUG(DIR)) {
	    printf("failed.\n");
	}
	misses += 1;
	return ((char *) NULL);
    }

    if (!IS_PATHSEP(*name)
#ifdef _WIN32
	/*
	 * Under Win32, we are sorry people.  To check if the path is
	 * absolute, we must also check to see if the 2nd character
	 * is a colon.
	 */
	|| name[1] != ':'
#endif
	) {

	Boolean	checkedDot = FALSE;
	char	*subdir;
	int 	subdirlen;

	subdirlen = cp - name - 1;
	subdir = (char *)malloc(subdirlen+1);
	strncpy(subdir, name, subdirlen);
	subdir[subdirlen] = '\0';
	
	if (DEBUG(DIR)) {
	    printf("failed. Trying subdirectories...");
	}
	(void) Lst_Open (path);
	/*
	 * 9/28/95: start the search with dot so we look in any local
	 * subdirectories before any subdirectories on the path, just as we
	 * look in the local directory before any directories on the path.
	 *  	    	    	-- ardeb
	 */
	for (p = dot;
	     p != NULL;
	     p = (((ln = Lst_Next(path)) != NILLNODE ?
		   (Path *)Lst_Datum(ln) :
		   (Path *)NULL)))
	{
	    if (p != dot) {
		file = Str_Concat (p->name, subdir, STR_ADDSLASH);
	    } else {
		/*
		 * Checking in dot -- DON'T put a leading ./ on the thing.
		 */
		file = Str_New(subdir);
		checkedDot = TRUE;
	    }
	    if (DEBUG(DIR)) {
		printf("checking %s...", file);
	    }
	    
	    /*
	     * Use the internal DirAddDir to see if the subdirectory exists,
	     * as (a) this will keep us from stat'ing the directory if we've
	     * already discovered it, and (b) will give us the directory
	     * hash table to use right away.
	     *
	     * We look for and cache the subdirectories, rather than looking
	     * directly for the file first to see if it exists before we
	     * bother caching the directory, so subdirectories of things
	     * on the original path are searched in the same order as the
	     * directories originally on the path. -- ardeb 9/28/95
	     */
	    p = DirAddDir(path, file);
	    if ((p != NULL) &&
		Hash_FindEntry(&p->files, (Address)cp) != (Hash_Entry *)NULL)
	    {
		/*
		 * Found the thing in this directory. Free the directory
		 * name (we no longer need it) so we can use the file variable
		 * again...
		 */
		free(file);
		nearmisses += 1;
		/*
		 * Create the pathname of the file, as we found it.
		 */
		file = Str_Concat(p->name, cp, STR_ADDSLASH);
		if (DEBUG(DIR)) {
		    printf("returning %s\n", file);
		}
		Lst_Close(path);

		return (file);
	    }

	    free(file);
	}
	
	if (DEBUG(DIR)) {
	    printf("failed. ");
	}
	Lst_Close (path);

	if (checkedDot) {
	    /*
	     * Already checked by the given name, since . was in the path,
	     * so no point in proceeding...
	     */
	    if (DEBUG(DIR)) {
		printf("Checked . already, returning NULL\n");
	    }
	    return(NULL);
	}
    }
    
    /*
     * Didn't find it that way, either. Sigh. Phase 3. Add its directory
     * onto the search path in any case, just in case, then look for the
     * thing in the hash table. If we find it, grand. We return a new
     * copy of the name. Otherwise we sadly return a NULL pointer. Sigh.
     * Note that if the directory holding the file doesn't exist, this will
     * do an extra search of the final directory on the path. Unless something
     * weird happens, this search won't succeed and life will be groovy.
     *
     * Sigh. We cannot add the directory onto the search path because
     * of this amusing case:
     * $(INSTALLDIR)/$(FILE): $(FILE)
     *
     * $(FILE) exists in $(INSTALLDIR) but not in the current one.
     * When searching for $(FILE), we will find it in $(INSTALLDIR)
     * b/c we added it here. This is not good...
     */
#ifdef notdef
    cp[-1] = '\0';
    Dir_AddDir (path, name);
#ifdef _WIN32
    /* XXX: spock */
    cp[-1] = '/';
#else
    cp[-1] = PATHNAME_SLASH;
#endif
    
    bigmisses += 1;
    ln = Lst_Last (path);
    if (ln == NILLNODE) {
	return ((char *) NULL);
    } else {
	p = (Path *) Lst_Datum (ln);
    }
    
    if (Hash_FindEntry (&p->files, (Address)cp) != (Hash_Entry *)NULL) {
	return (Str_New (name));
    } else {
	return ((char *) NULL);
    }
#else /* !notdef */
    if (DEBUG(DIR)) {
	printf("Looking for \"%s"QUOTED_SLASH"...", name);
    }
    
    bigmisses += 1;
    entry = Hash_FindEntry(&mtimes, name);
    if (entry != (Hash_Entry *)NULL) {
	if (DEBUG(DIR)) {
	    printf("got it (in mtime cache)\n");
	}
	return(Str_New(name));
    } else if (stat (name, &stb) == 0) {
	entry = Hash_CreateEntry(&mtimes, name, (Boolean *)NULL);
	if (DEBUG(DIR)) {
	    printf("Caching %s for %s\n", Targ_FmtTime(stb.st_mtime),
		    name);
	}
	Hash_SetValue(entry, stb.st_mtime);
	return (Str_New (name));
    } else {
	if (DEBUG(DIR)) {
	    printf("failed. Returning NULL\n");
	}
	return ((char *)NULL);
    }
#endif /* notdef */
}

/*-
 *-----------------------------------------------------------------------
 * Dir_MTime  --
 *	Find the modification time of the file described by gn along the
 *	search path dirSearchPath.
 * 
 * Results:
 *	The modification time or 0 if it doesn't exist
 *
 * Arguments:
 *      GNode *gn : The file whose modification time is desired
 *
 * Side Effects:
 *	The modification time is placed in the node's mtime slot.
 *	If the node didn't have a path entry before, and Dir_FindFile
 *	found one for it, the full name is placed in the path slot.
 *-----------------------------------------------------------------------
 */
time_t
Dir_MTime (GNode *gn)
{
    char          *fullName;  /* the full pathname of name */
    struct stat	  stb;	      /* buffer for finding the mod time */
    Hash_Entry	  *entry;

#ifdef unix    
    if (gn->type & OP_ARCHV) {
	return Arch_MTime (gn);
    } else 
#endif
	if (gn->path == (char *)NULL) 
	{
	    fullName = Dir_FindFile (gn->name, dirSearchPath);
	} 
	else 
	{
	    fullName = gn->path;
    	}
    
    if (fullName == (char *)NULL) {
	fullName = gn->name;
    }

    entry = Hash_FindEntry(&mtimes, fullName);
    if (entry != (Hash_Entry *)NULL) {
	/*
	 * Only do this once -- the second time folks are checking to
	 * see if the file was actually updated, so we need to actually go
	 * to the file system.
	 */
	if (DEBUG(DIR)) {
	    printf("Using cached time %s for %s\n",
		    Targ_FmtTime((int)Hash_GetValue(entry)), fullName);
	}
	stb.st_mtime = (time_t)Hash_GetValue(entry);
	Hash_DeleteEntry(&mtimes, entry);
    } else if (stat (fullName, &stb) < 0) {
	if (gn->type & OP_MEMBER) {
#ifdef unix
	    return Arch_MemMTime (gn);
#else
	    return 0;
#endif
	} else 	{
	    stb.st_mtime = 0;
	}
    }
    if (fullName && gn->path == (char *)NULL) {
	gn->path = fullName;
    }
    
    gn->mtime = stb.st_mtime;
    return (gn->mtime);
}

#if defined(__HIGHC__)
#include <system.cf>
#include <errno.h>
#endif


/***********************************************************************
 *				DirAddDir
 ***********************************************************************
 * SYNOPSIS:	    Add the given name to the end of the given path.
 * CALLED BY:	    (INTERNAL) Dir_AddDir, Dir_FindFile
 * RETURN:	    the Path * for the directory
 * SIDE EFFECTS:    an entry *may* be appended.
 *
 * Arguments:
 *      Lst   path : The path to which the directory should be added
 *      char *name : The name of the directory to add
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/28/95		Initial Revision
 *
 ***********************************************************************/
static Path *
DirAddDir(Lst path, char *name)
{
    LstNode       ln;	      /* node in case Path structure is found */
    register Path *p;	      /* pointer to new Path structure */
    DIR     	  *d;	      /* for reading directory */

#if defined(_WIN32)
    const struct   direct *dp;
#else
    const struct   dirent *dp; /* entry in directory */
#endif /* defined(_WIN32) */

#ifdef _WIN32
    /*
     * I'm desperate, man...
     */
    /*Parse_UpCaseString(name);*/
#endif /* _WIN32 */
    
    ln = Lst_Find (openDirectories, (ClientData)name, DirFindName);
    if (ln != NILLNODE) {
	p = (Path *)Lst_Datum (ln);
	if (Lst_Member(path, (ClientData)p) == NILLNODE) {
	    p->refCount += 1;
	    (void)Lst_AtEnd (path, (ClientData)p);
	}
    } else {
	/*
	 * As an optimization, look through our open directories to see if we
	 * have an ancestor of the path about to be cached and see if the
	 * following component is in the hash table.
	 */
	for (ln = Lst_First(openDirectories);
	     ln != NILLNODE;
	     ln = Lst_Succ(ln))
	{
	    int	    plen;   	/* Length of p->name */
	    
	    p = (Path *)Lst_Datum(ln);

	    plen = strlen(p->name);
	    if ((strncmp(p->name, name, plen) == 0) && IS_PATHSEP(name[plen]))
	    {
		/*
		 * Found an ancestor. See if the following component is in
		 * the hash table.
		 */
		char	*cp;
		int 	len = plen;

		while (1) {
		    cp = Var_FirstPathSep(&name[len+1]);
		    if (cp == NULL) {
			/*
			 * Next component is entire rest -- just dup it.
			 */
			cp = Str_New(&name[len+1]);
		    } else {
			/*
			 * Make a copy of the final component w/o tromping on
			 * the passed path.
			 */
			int	clen = cp-&name[len+1];

			cp = (char *)malloc(clen+1);
			strncpy(cp, &name[len+1], clen);
			cp[clen] = '\0';
		    }
		    if (strcmp(cp, ".") == 0) {
			/*
			 * Component is just ".", so advance to next component,
			 * as this one is just a nop.
			 */
			len += 2;
			free(cp);
		    } else {
			break;
		    }
		}
		/*
		 * See if the component is in the cache. Note that if the
		 * component is "..", p isn't actually an ancestor, so we
		 * can't use this check.
		 */
		if (strcmp(cp, "..") != 0 &&
		    Hash_FindEntry(&p->files, (Address)cp)==(Hash_Entry *)NULL)
		{
		    free(cp);
		    break;
		}
		free(cp);
	    }
	}
	
	if (ln == NILLNODE) {	   
	    if (DEBUG(DIR)) {
		printf("Caching %s...", name);
		fflush(stdout);
	    }
	    d = opendir(name);
	} else {
	    d = NULL;
	}

	if (d != NULL) {
	    MallocCheck (p, sizeof (Path));
	    p->name = Str_New (name);
	    p->hits = 0;
	    p->refCount = 1;
#if !defined(__HIGHC__) && !defined(__WATCOMC__)
	    Hash_InitTable (&p->files, -1, HASH_STRING_KEYS);
#else
	    Hash_InitTable (&p->files, -1, HASH_STRING_KEYS, 0);
#endif

	    /* 
	     * it turns out that in DOS the first two entries
	     *  are not . and ..
	     */
	    while ((dp = readdir (d)) != NULL)
	    {
#if defined(sun)
		/*
		 * The sun directory library doesn't check for a 0 inode
		 * (0-inode slots just take up space), so we have to do
		 * it ourselves.
		 */
		if (dp->d_fileno == 0) {
		    continue;
		}
#endif sun
		if (! (dp->d_name[0] == '.' &&
		       (dp->d_name[1] == '\0' ||
			(dp->d_name[1] == '.' && dp->d_name[2] == '\0'))))
		{

		  /*
		   * In M$DOS land all files are caps and so when we search
		   * to see if a filename exists that is in a makefile or
		   * whatever, we simply upcase the filename before we search
		   * the appropriate hash tables.  In WIN32, however, filenames
		   * are case-retentive but not case-sensitive.  This means
		   * we should still upcase the filenames before we search any
		   * hash tables, but we must also upcase the filenames before
		   * storing them in any hash tables.  Big pain in ASS.
		   */
#if defined (_WIN32)
		  {
		    int i = 0;
		    char *filename;
		    
		    MallocCheck(filename, strlen(dp->d_name) + 1);
		    while (dp->d_name[i] != '\0') {
			if (IS_PATHSEP(dp->d_name[i])) {
			    /* XXX: testing this out.. maybe we don't need
			       \'s at all under Win32 */
			    filename[i] = '/';
			} else {
			    /*filename[i] = (char) toupper(dp->d_name[i]);*/
				filename[i] = (char) (dp->d_name[i]);
			}
			i++;
		    }
		    filename[i] = '\0';
		    Hash_CreateEntry(&p->files, (Address) filename, NULL);
		  }
#else
		    Hash_CreateEntry(&p->files, (Address)dp->d_name, NULL);
#endif /* defined (_WIN32) */
		}

	    }
	    (void) closedir (d);
	    (void)Lst_AtEnd (openDirectories, (ClientData)p);
	    (void)Lst_AtEnd (path, (ClientData)p);
	    if (DEBUG(DIR)) {
		printf("done\n");
	    }
	} else {
	    if (DEBUG(DIR) && ln == NILLNODE) {
		printf("non-existent...");
	    }
	    p = NULL;
	}
    }
    return (p);
}
/*-
 *-----------------------------------------------------------------------
 * Dir_AddDir --
 *	Add the given name to the end of the given path. The order of
 *	the arguments is backwards so ParseDoDependency can do a
 *	Lst_ForEach of its list of paths...
 *
 * Results:
 *	none
 *
 * Arguments:
 *      Lst   path : The path to which the directory should be added
 *      char *name : The name of the directory to add
 *
 * Side Effects:
 *	A structure is added to the list and the directory is 
 *	read and hashed.
 *-----------------------------------------------------------------------
 */
void
Dir_AddDir (Lst path, char *name)
{
    (void)DirAddDir(path, name);
}


/*-
 *-----------------------------------------------------------------------
 * Dir_CopyDir --
 *	Callback function for duplicating a search path via Lst_Duplicate.
 *	Ups the reference count for the directory.
 *
 * Arguments:
 *      Path *p : Directory descriptor to copy
 *
 * Results:
 *	Returns the Path it was given.
 *
 * Side Effects:
 *	The refCount of the path is incremented.
 *
 *-----------------------------------------------------------------------
 */
ClientData
Dir_CopyDir(Path *p)
{
    p->refCount += 1;

    return ((ClientData)p);
}

/*-
 *-----------------------------------------------------------------------
 * Dir_MakeFlags --
 *	Make a string by taking all the directories in the given search
 *	path and preceding them by the given flag. Used by the suffix
 *	module to create variables for compilers based on suffix search
 *	paths.
 *
 * Arguments:
 *      char *flag : Flag which should precede each directory
 *      Lst   path : List of directories
 *
 * Results:
 *	The string mentioned above. Note that there is no space between
 *	the given flag and each directory. The empty string is returned if
 *	Things don't go well.
 *
 * Side Effects:
 *	None
 *-----------------------------------------------------------------------
 */
char *
Dir_MakeFlags (char *flag, Lst path)
{
    char	  *str;	  /* the string which will be returned */
    char	  *tstr;  /* the current directory preceded by 'flag' */
    LstNode	  ln;	  /* the node of the current directory */
    Path	  *p;	  /* the structure describing the current directory */
    
    str = Str_New ("");
    
    if (Lst_Open (path) == SUCCESS) {
	while ((ln = Lst_Next (path)) != NILLNODE) {
	    p = (Path *) Lst_Datum (ln);
	    tstr = Str_Concat (flag, p->name, 0);
	    str = Str_Concat (str, tstr, STR_ADDSPACE | STR_DOFREE);
	}
	Lst_Close (path);
    }
    
    return (str);
}

/*-
 *-----------------------------------------------------------------------
 * Dir_Destroy --
 *	Nuke a directory descriptor, if possible. Callback procedure
 *	for the suffixes module when destroying a search path.
 *
 *      p is the directory descriptor to nuke
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If no other path references this directory (refCount == 0),
 *	the Path and all its data are freed.
 *
 *-----------------------------------------------------------------------
 */
void
Dir_Destroy (Path *p)
{
    /*Hash_Search	  thing1;*/
    /*Hash_Entry	  *thing2;*/
    
    p->refCount -= 1;

    if (p->refCount == 0) {
	LstNode	ln;

	ln = Lst_Member (openDirectories, (ClientData)p);
	(void) Lst_Remove (openDirectories, ln);

	Hash_DeleteTable (&p->files);
	free((Address)p->name);
	free((Address)p);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Dir_ClearPath --
 *	Clear out all elements of the given search path. This is different
 *	from destroying the list, notice.
 *
 * Results:
 *	None.
 *
 * Arguments:
 *      Lst path : Path to clear
 *
 * Side Effects:
 *	The path is set to the empty list.
 *
 *-----------------------------------------------------------------------
 */
void
Dir_ClearPath(Lst path)
{
    Path    *p;
    while (!Lst_IsEmpty(path)) {
	p = (Path *)Lst_DeQueue(path);
	Dir_Destroy(p);
    }
}
	    

/*-
 *-----------------------------------------------------------------------
 * Dir_Concat --
 *	Concatenate two paths, adding the second to the end of the first.
 *	Makes sure to avoid duplicates.
 *
 * Arguments:
 *      Lst path1 : Dest
 *      Lst path2 : Source
 * 
 * Results:
 *	None
 *
 * Side Effects:
 *	Reference counts for added dirs are upped.
 *
 *-----------------------------------------------------------------------
 */
void
Dir_Concat(Lst path1, Lst path2)
{
    LstNode ln;
    Path    *p;

    for (ln = Lst_First(path2); ln != NILLNODE; ln = Lst_Succ(ln)) {
	p = (Path *)Lst_Datum(ln);
	if (Lst_Member(path1, (ClientData)p) == NILLNODE) {
	    p->refCount += 1;
	    (void)Lst_AtEnd(path1, (ClientData)p);
	}
    }
}

/********** DEBUG INFO **********/
void
Dir_PrintDirectories(void)
{
    LstNode	ln;
    Path	*p;
    
    printf ("#*** Directory Cache:\n");
    printf ("# Stats: %d hits %d misses %d near misses %d losers (%d%%)\n",
	      hits, misses, nearmisses, bigmisses,
	      (hits+bigmisses+nearmisses ?
	       hits * 100 / (hits + bigmisses + nearmisses) : 0));
    printf ("# %-20s referenced\thits\n", "directory");
    if (Lst_Open (openDirectories) == SUCCESS) {
	while ((ln = Lst_Next (openDirectories)) != NILLNODE) {
	    p = (Path *) Lst_Datum (ln);
	    printf ("# %-20s %10d\t%4d\n", p->name, p->refCount, p->hits);
	}
	Lst_Close (openDirectories);
    }
}

static int DirPrintDir (Path *p)
{
    printf ("%s ", p->name);
    return (0);
}

void
Dir_PrintPath (Lst path)
{
    Lst_ForEach (path, DirPrintDir, (ClientData)0);
}
