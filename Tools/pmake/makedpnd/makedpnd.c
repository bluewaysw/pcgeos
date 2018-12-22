/********************************************************************
*
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved
*
* 	PROJECT:	PC GEOS
* 	MODULE:
* 	FILE:		makedpnd.c
*
*	AUTHOR:		jimmy lefkowitz
*
*	REVISION HISTORY:
*
*	Name	Date		Description
*	----	----		-----------
*	jimmy	7/23/92		Initial version
*       TB      8/21/96         WIN32 version
*	mgroeb  5/21/00		Support for multiple products
*
*	DESCRIPTION: DOS and WIN32 code for pmake depend
*
*	$Id: makedpnd.c,v 1.20 94/02/24 14:06:05 jimmy Exp $
*
*********************************************************************/

#include <config.h>

#include <compat/file.h>
#include <compat/string.h>

#include <stdio.h>
#include <process.h>
#include <signal.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
#include <assert.h>

#include "fileargs.h"
#include "hash.h"

#if defined(_MSDOS)
#    define	BUFSIZE	     128 /* buffer for line by line file processing */
#    define     DEPENDS_FILE "depends.mk"
#else /* _WIN32 or unix */
#    define     BUFSIZE      256
#    define     DEPENDS_FILE "dependencies.mk"
#endif /* defined(_MSDOS) */

#define INIT_BUCKETS 20
#define LINE_LENGTH  75
#define	LINE_START   18
#define GO_TO_END    'a'

#define STDOUT	     1

#define Malloc(thePtr, size, type)\
            {\
	        (thePtr) = (type) malloc(size);\
		    if((thePtr) == NULL) {\
                        fprintf(stderr, "makedpnd: out of memory\n");\
	                exit(1);\
	            }\
	    }
#define EXIT(value) err = value; goto cleanup_and_exit

#if defined(_WIN32)
#    define WIN32_LEAN_AND_MEAN
#    include <windows.h>
#    define MAX_PATH_LENGTH (MAX_PATH)
#elif defined(_LINUX)
#    define MAX_PATH_LENGTH (PATH_MAX)
#else /* _MSDOS or unix */
#    define MAX_PATH_LENGTH 80
#endif /* defined(_WIN32) */

#ifdef _WIN32
#define HAS_READ_ACCESS(filename)   FileIsOkay(filename)
#else
#define HAS_READ_ACCESS(filename)   (((access(filename, 4)) == -1) ? 0 : 1)
#endif

typedef struct fileStack {
	struct fileStack	*next;	/* pointer to next element in stack*/
	int 	    	    	linenumber; /* line number, where included*/
	char			*name; /* filename of including file */
} FileStack;

typedef enum {
	FT_NONE,
	FT_BORLAND,
	FT_METAWARE,
	FT_MICROSOFT6,
	FT_MICROSOFT7,
	FT_ESP,
	FT_UI,
	FT_GOC
} FileType;

static char	*gocargsfile    = NULL;
static char	*cargsfile      = NULL;
static char	*asmargsfile    = NULL;

/* these are only access inside of main, but we make them global so
 * that they can be freed inside of SigIntHandler */
static char     *ccommand       = NULL;
static char     *goccommand     = NULL;
static char     *asmcommand     = NULL;
static char     *command        = NULL;

static fpos_t	 gocargsfpos;
static fpos_t	 cargsfpos;
static fpos_t	 asmargsfpos;

static char	*outfile        = "         ";
static int	 cModules       = 0;
static int	 asmModules     = 0;
static int	 saveAsmModules = 0;              /* used for finding
						   * the .ui files */
static int	 got_stdapp_goh = 0;
static int	 got_stdapp_h   = 0;

/* Root of PC/GEOS tree */
static char	*rootDir		= NULL;
/* Root of user's development tree */
static char	*develDir		= NULL;
/* Installed source directory for CWD */
static char	*installDir		= NULL;

static char	 processing_string[20] = "Processing %s...\n";

/* additional parameters for product-specific depdency files */
static char     *product                = NULL;
static char     *dependsFile            = "dependencies.mk";


/***********************************************************************
 *		FileIsOkay
 ***********************************************************************
 *
 * SYNOPSIS:	Return zero if file doesn't exist or is a directory
 * CALLED BY:	(INTERNAL)
 * RETURN:	see SYNOPSIS
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	jacob   	2/07/97   	Initial Revision
 *
 ***********************************************************************/
#ifdef _WIN32
int
FileIsOkay (char *filename)
{
    DWORD attrs = GetFileAttributes(filename);

    return !((attrs == 0xFFFFFFFF) || (attrs & FILE_ATTRIBUTE_DIRECTORY));
}	/* End of FileIsOkay.	*/
#endif /* _WIN32 */


/***********************************************************************
 *				SigIntHandler
 ***********************************************************************
 * SYNOPSIS:	    removes temp files
 * CALLED BY:	    called whenever ^C is pressed
 * RETURN:	    nothing
 * SIDE EFFECTS:    Removes temp files and program exits
 *
 * STRATEGY:	    remove the temp files if they aren't null and then
 *                  exit
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      TB      8/23/96         Initial Revision
 *
 ***********************************************************************/
static void
SigIntHandler (int signo)
{
    if (gocargsfile != NULL) {
	(void) unlink(gocargsfile);
    }
    if (cargsfile   != NULL) {
	(void) unlink(cargsfile);
    }
    if (asmargsfile != NULL) {
	(void) unlink(asmargsfile);
    }
    if (outfile     != NULL) {
	(void) unlink(outfile);
    }

#if defined(_MSDOS)
    if (rootDir   != NULL) {
	(void) free(rootDir);
    }
    if (goccommand != NULL) {
	(void) free(goccommand);
    }
    if (asmcommand != NULL) {
	(void) free(asmcommand);
    }
    if (ccommand   != NULL) {
	(void) free(ccommand);
    }
#endif /* defined _MSDOS */

    (void) unlink(dependsFile);

    exit(3);
}	/* End of SigIntHandler. */


/*********************************************************************
 *			ParseArgs
 *********************************************************************
 * SYNOPSIS:	Put all the args for command into a file for spawn
 * CALLED BY:	main
 * RETURN:	Index into argv following the arguments to command
 * SIDE EFFECTS:
 *		Sets up the a global variable and the argsfile
 * STRATEGY:	Get arguments until we reach the OUTFILE token
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/27/92		Initial version
 *      TB      8/26/96         WIN32 version
 *
 *********************************************************************/
static int
ParseArgs(char **argv, int st, int args, char **command, char *token)
{
    FILE   *fp;
#ifdef _LINUX
    int    fd;
#endif
    char   *argsfile;
    fpos_t *argsfpos;

    if (stricmp(argv[st], "GOC")        == 0) {
	Malloc(gocargsfile, 13, char *);
	argsfile = gocargsfile;
	argsfpos = &gocargsfpos;
    } else if (stricmp(argv[st], "CPP") == 0) {
	Malloc(cargsfile, 13, char *);
	argsfile = cargsfile;
	argsfpos = &cargsfpos;
    } else if (stricmp(argv[st], "ASM") == 0) {
	Malloc(asmargsfile, 13, char *);
	argsfile = asmargsfile;
	argsfpos = &asmargsfpos;
    }

    /*
     * Create a random temp file
     */
    strcpy(argsfile, "TMPXXXXXX");
#if defined(_LINUX)
    fd = mkstemp(argsfile);
    if (fd == -1) {
	fprintf(stderr, "makedpnd: \"%s\": ", argsfile);
	perror("");
	exit(1);
    }
    fp = fdopen(fd, "w+t");
#else
    mktemp(argsfile);
    fp = fopen(argsfile, "wt"); /* overwrite, if it happens to exist */
#endif
    if (fp == NULL) {
	fprintf(stderr, "makedpnd: \"%s\": ", argsfile);
	perror("");
	exit(1);
    }
    
    /* start from index args, all the argv elements are arguments
     * to the command, so go until we hit the token
     */

    /* the first arg, is the actual instruction, so do that one first */
    Malloc(*command, strlen(argv[args]) + 1, char *);
    strcpy(*command, argv[args]);

    /* the second thing is the output file, so add a -o and then the
     * output file
     */
    args++;
    putc(' ', fp);

    while (stricmp(argv[args], token) != 0) {
	if (argv[args][0] == '-' && argv[args][1] == 'o') {
	    args++;
	} else {
	    fwrite(argv[args], 1, strlen(argv[args]), fp);
	    putc(' ', fp);
	}
	args++;
    }
    *argsfpos = ftell(fp);
    fclose(fp);

    return (args+1);
}


/*********************************************************************
 *			ApplyCommand
 *********************************************************************
 * SYNOPSIS:         Run the current command on the file
 * CALLED BY:	     ProcessFile
 * RETURN:           output filename
 * SIDE EFFECTS:     Output of GOC into a temp file, filename Malloced
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/23/92		Initial version
 *
 *********************************************************************/
static char *
ApplyCommand(char    **argv,
	     int       args,
	     char     *command,
	     FileType  filetype,
	     int      *cpid)
{
#ifdef _WIN32
    char     cmdline[(MAX_PATH_LENGTH * 2) + 1]; /* two filenames and an @ */
#else
    char     cmdline[40];                        /* 24 bytes for two 8.3
						  * filenames and an @ */
#endif
    char     cwd[MAX_PATH_LENGTH];
#ifdef _LINUX
    int 		fd;
    char*		cmdline2 = NULL;
#endif
    FILE    *fp;                                 /* the argument file handle */
    int      accessOk;                           /* int to test for the
						  * existence of files */
    int	     i                  = 0;
    char    *cl;
    int	     fptr, oldstdout;                    /* file descriptors for
						  * redirecting output */
    int      startModule, endModule;
    char     fullfilename[MAX_PATH_LENGTH];
    fpos_t  *argsfpos;
    char    *argsfile;
    Boolean  found              = FALSE;

    switch (filetype) {
	case FT_ESP:
		fp = fopen(asmargsfile, "r+t");
		if (fp == NULL) {
		    fprintf(stderr, "makedpnd: ");
		    perror(asmargsfile);
		}
		argsfpos = &asmargsfpos;
		argsfile = asmargsfile;
		break;

	case FT_UI:
	case FT_BORLAND:
	case FT_METAWARE:
	case FT_MICROSOFT6:
	case FT_MICROSOFT7:
		fp = fopen(cargsfile, "r+t");
		if (fp == NULL) {
		    fprintf(stderr, "makedpnd: ");
		    perror(cargsfile);
		}
		argsfpos = &cargsfpos;
		argsfile = cargsfile;
		break;

	case FT_GOC:
		fp = fopen(gocargsfile, "r+t");
		if (fp == NULL) {
		    fprintf(stderr, "makedpnd: ");
		    perror(gocargsfile);
		}
		argsfpos = &gocargsfpos;
		argsfile = gocargsfile;
		break;
    }

    if (fp == NULL) {
	*cpid = 1;

	return NULL;
    }
    fseek(fp, *argsfpos, SEEK_SET);
    
    /*
     * If we are doing a UI file, go through the asm modules
     * until we find the file. Or look through all the C modules
     * for non-asm, non-ui files.
     */
    if (filetype == FT_UI) {
	startModule = saveAsmModules + cModules + 1;
	endModule   = cModules + 1;
    } else {
	startModule = cModules;
	endModule   = 0;
    }

    /*
     * Set the whole string to spaces so no leftover stuff might be
     * be left around in the GOC case where this gets put into the
     * argsfile
     */
    memset(fullfilename, ' ', MAX_PATH_LENGTH);
#ifdef _LINUX
    if (getcwd(cwd, MAX_PATH_LENGTH) == NULL) {
#else
    if (Compat_GetCwd(cwd, MAX_PATH_LENGTH) == NULL) {
#endif
	perror("makedpnd");

	return NULL;
    }

    strcpy(fullfilename, argv[args]);
    printf("Searching for %s in . ", argv[args]);
    accessOk = HAS_READ_ACCESS(fullfilename);

    /*
     * Check the installed directory if not found in local one.
     */
    if (!accessOk) {
	sprintf(fullfilename,
		"%s/%s",
		installDir,
		argv[args]);

	printf("\nSearching for %s in %s ", argv[args], installDir);
	accessOk = HAS_READ_ACCESS(fullfilename);
#ifdef _LINUX
	if(accessOk) {

		struct stat info;

		if( stat( fullfilename, &info ) != 0 ) {
		    accessOk = FALSE;
		}
		else if( info.st_mode & S_IFDIR ) {
		    accessOk = FALSE;
		}
	}
#endif
    }

    /* If the file is not in the current directory look through the
     * module directories for it */
    if (!accessOk && filetype != FT_ESP) {
	int sm = startModule;

	while (sm > endModule) {
	    sprintf(fullfilename, "%s/%s", argv[sm], argv[args]);
	    printf("\nSearching for %s in %s ", argv[args], argv[sm]);
	    accessOk = HAS_READ_ACCESS(fullfilename);
#ifdef _LINUX
	    if(accessOk) {

		struct stat info;

		if( stat( fullfilename, &info ) != 0 ) {
		    accessOk = FALSE;
		}
		else if( info.st_mode & S_IFDIR ) {
		    accessOk = FALSE;
		}
	    }
#endif
	    if (accessOk) {
		found = TRUE;
		break;
	    }

	    sm--;
	}

	/* if we haven't found the file, and we are in a local development
	 * tree, then try the installed one
	 */
	if (found == FALSE) {
	    sm = startModule;
	    while (sm > endModule) {
	    	sprintf(fullfilename, "%s/%s/%s",
			installDir,
			argv[sm],
			argv[args]);

		printf("\nSearching for %s in %s/%s ",
		       argv[args], installDir, argv[sm]);
		accessOk = HAS_READ_ACCESS(fullfilename);
		if (accessOk) {
		    found = TRUE;
		    break;
		}
		sm--;
	    }
	}

    } else if (!accessOk && (filetype == FT_ESP))  {

	/*
	 * for asm files, use the manager file
	 */
	sprintf(fullfilename, "%s/%sManager.asm", argv[args], argv[args]);
	printf("\nSearching for %s/%sMANAGER.ASM in . ",
	       argv[args], argv[args]); fflush(stdout);
	accessOk = HAS_READ_ACCESS(fullfilename);

	/*
	 * if that's not there and we are in a local tree then try the
	 * installed one
	 */
	if (!accessOk) {
	    sprintf(fullfilename, "%s/%s",
		    installDir,
		    argv[args]);

	    printf("\nSearching for %s in %s", argv[args], installDir);
	    accessOk = HAS_READ_ACCESS(fullfilename);
#ifdef _LINUX
	    if(accessOk) {

		struct stat info;

		if( stat( fullfilename, &info ) != 0 ) {
		    accessOk = FALSE;
		}
		else if( info.st_mode & S_IFDIR ) {
		    accessOk = FALSE;
		}
	    }
#endif
	    /*
	     * try an installed manager file
	     */
	    if (!accessOk) {
	    	sprintf(fullfilename, "%s/%s/%sManager.asm",
			installDir,
			argv[args],
			argv[args]);

		{
			int  i= strlen(installDir) + strlen(argv[args]) + 2;
			int total = i + strlen(argv[args]);
			while(i< total) {
				fullfilename[i] = tolower(fullfilename[i]);
				i++;
			}
		}
		printf("\nSearching for %sMANAGER.ASM in %s/%s ",
		       argv[args], installDir, argv[args]);
		accessOk = HAS_READ_ACCESS(fullfilename);
	    }
	}

	if (!accessOk) {
	    fprintf(stderr, "\nmakedpnd: ");
	    perror(argv[args]);

	    *cpid = 0;		/* already printed error message */
	    return NULL;	/* ...and NULL signals error */
	}
	found = TRUE;

    } else {
	/*
	 *we found the file so we are fine
	 */
	found =  TRUE;
    }

    if (found == FALSE) {
	fprintf(stderr, "\nmakedpnd: ");
	perror(argv[args]);
	return NULL;
    /*
     * convert all /'s in the filename to \'s since some apps don't accept
     * the former as path seps
     */
    } else {
	int i = 0;
	while (fullfilename[i] != '\0') {
	    if (fullfilename[i] == '/') {
#if !defined(_LINUX)
		fullfilename[i] = '\\';
#endif
	    }
	    i++;
	}
    }
    if (filetype == FT_GOC) {
	char  cfilename[MAX_PATH_LENGTH];
	char *cp;

	/*
	 * write in the -o flag for GOC, make sure to overwrite any oldfile
	 * filenames that could have been longer by always padding out the
	 * filename with spaces upto the 8.3 length
	 */
	sprintf(cfilename, "-o %s", argv[args]);
	cp = strrchr(cfilename, '.');
	strcpy(cp + 1, "cpp");
	fwrite(cfilename, 1, strlen(cfilename), fp);
	fputc(' ', fp);
    }

    printf("-- Found it.\n");
    printf(processing_string, fullfilename);
    fwrite(fullfilename, 1, MAX_PATH_LENGTH, fp);
    
    if (filetype != FT_MICROSOFT6) {
	fclose(fp);
	//cmdline[i++] = ' ';
	cmdline[i]   = '@';
	strcpy(cmdline + i + 1, argsfile);
    }
    
    /*
     * we must redirect the ouput to a file since MetaBlam refuses to send
     * the stuff out to a file, therefore we must use system, rather than
     * spawn, unless its borland which outputs the useful info to a .i file
     */

    switch (filetype) {
#ifndef _LINUX
        case FT_UI:
#endif
        //case FT_BORLAND: /* no redirection here */
	    break;

	/* now our good friends microblam in there highly advanced and much
	 * acclaimed version 6.0 compiler don't have a f*cking clue.  they
	 * don't take argument files, so the only way to pass more than 128
	 * characters is through the CL enviroment variable, what a hunk of
	 * sh*t!, since I jammed all the variables into a file earlier, I
	 * just read them back out and stuff them into the CL enviroment
	 * variable, not optimal, but since every other type of file I deal
	 * with works using the argument file this was easier... */
	case FT_MICROSOFT6:
	{
	    long fpos;
	    int	 len;

	    len = strlen("CL=");
	    fseek(fp, 0L, SEEK_END);
	    fpos = ftell(fp);
	    fseek(fp, 0L, SEEK_SET);
	    Malloc(cl, fpos + len + 1, char *);
	    strcpy(cl, "CL=");
	    fread(cl + len, 1, fpos, fp);
	    cl[fpos + len] = '\0';
	    putenv(cl);
	    fclose(fp);
	}
#ifdef _LINUX
	case FT_UI:
	case FT_BORLAND: /* no redirection here */
#endif
		/* FALLTHRU! */
	default:
	    strcpy(outfile, "TMPXXXXXX");
#ifdef _LINUX
	    fd = mkstemp(outfile);
	    if (fd == -1) {
		fprintf(stderr, "makedpnd: ");
		perror(outfile);
		outfile[0] = '\0';

		return outfile;
	    }
	    close(fd);
	    fptr = open(outfile, O_CREAT | O_RDWR, S_IREAD | S_IWRITE);
#else
	    mktemp(outfile);
	    fptr = open(outfile, O_CREAT | O_RDWR, S_IREAD | S_IWRITE);
#endif
	    if (!fptr) {
		fprintf(stderr, "makedpnd: ");
		perror(outfile);
		outfile[0] = '\0';

		return outfile;
	    }
	    fflush(stdout);
	    oldstdout = dup(STDOUT);	/* save old STDOUT descriptor */
	    dup2(fptr, STDOUT);	        /* redirect STDOUT to our file */
	    close(fptr);
    }

    *cpid = spawnlp(P_WAIT, command, command, /*cl ? cl+3:*/cmdline, NULL);

    switch(filetype) {
	case FT_MICROSOFT6:
	    /* unset the CL environment variable and free the string */
	    putenv("CL=");
	    free(cl);
	    break;

	case FT_UI:
        case FT_BORLAND:
	case FT_GOC:
	case FT_ESP:
	    /* let error go through for makedpnd mode */
	    *cpid = 0;
	    /* FALL THRU */
	default:
	    /* if we redirected STDOUT, then fix it back up.... */
	    fflush(stdout);
	    dup2(oldstdout, STDOUT);
	    close(oldstdout);
	    break;
    }

    return outfile;
}

/*********************************************************************
 *			ScanNextWord
 *********************************************************************
 * SYNOPSIS:      scan in the next word in the file
 * CALLED BY:	  global
 * RETURN:        the last character read in
 * SIDE EFFECTS:  the next word written to buf
 * STRATEGY:      filter out double quotes, translate / into \ and use
 *                upper case
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/24/92		Initial version
 *
 *********************************************************************/
static signed char
ScanNextWord(FILE *fp, char *buf, int *index)
{
    signed char c;
    char condenseQuote;  /* turn all \\ into \ */

    /* first get to start of next word */
    while(isspace(c = (char) getc(fp))) {
	;
    }

    condenseQuote = 0;
    do {
	if(*index == BUFSIZE) {
		int a = 0;
		while(a < BUFSIZE) {
			if(buf[a] == 0) {
				buf[a] = ' ';
			}
			a++;
		}

		buf[BUFSIZE-1] = 0;
	}
	assert (*index < BUFSIZE);

	if (c == EOF) {
	    return c;
	}

	if (c == '\\') {
	    if (condenseQuote) {
		condenseQuote = 0;
		continue;
	    }
	    condenseQuote = 1;
	} else {
	    condenseQuote = 0;
	}

#if defined _MSDOS
	if (c == '/') {
	    c = '\\';
	}
#else /* _WIN32 */
	if (c == '\\') {
	    c = '/';
	}
#endif /* defined _MSDOS */

	if (c != '"') {
	    buf[*index] = c;
	    *index += 1;
	}
    } while (!isspace(c = (char) getc(fp)));

    return c;
}

/*********************************************************************
 *			ScanToEndOfLine
 *********************************************************************
 * SYNOPSIS:         scan to the end of the line
 * CALLED BY:	     global
 * RETURN:           last character read
 * SIDE EFFECTS:     file pointer moved to next line
 * STRATEGY:	     go until EOF or \n
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/24/92		Initial version
 *      TB      8/27/96         WIN32 version
 *
 *********************************************************************/
static char
ScanToEndOfLine(FILE *fp, signed char c)
{
    while(c != EOF && c != '\n') {
	c = (char) getc(fp);
    }

    return c;
}


/*********************************************************************
 *			FilterDuplicates
 *********************************************************************
 * SYNOPSIS:          set up a hash table and check for duplicates
 * CALLED BY:	      GetDependsFromGoc....
 * RETURN:            TRUE if added, FALSE if already there
 * SIDE EFFECTS:      entry added to hash tableif not already there
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/28/92		Initial version
 *
 *********************************************************************/
static Boolean
FilterDuplicates(Hash_Table *ht, char *key)
{
    if (Hash_FindEntry(ht, key) == NULL) {
	Boolean added;

	Hash_CreateEntry(ht, key, &added);
	return (TRUE);
    }

    return (FALSE);
}

/*********************************************************************
 *			WriteStringToDepfile
 *********************************************************************
 * SYNOPSIS: 	    this routine writes out stuff from the buffer
 *	    	    to the depends file
 * CALLED BY:	    the various GetDepends... routines
 * RETURN:  	    position in buffer to write to next
 * SIDE EFFECTS:    DEPENDS_FILE file written to sometimes
 * STRATEGY:	    if the new word goes over the line length then output
 *	    	    the buffer and take the new word and move it to the
 *	    	    start of the buffer
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	9/ 9/93		Initial version
 *
 *********************************************************************/
static int
WriteStringToDepfile(char *buf, int *length, int lasti, int i, FILE *depfile)
{
    if (lasti > 0) {
	buf[lasti - 1] = ' '; /* replace null with a space */
    }

    *length += strlen(buf + lasti) + 1;

    if (*length > LINE_LENGTH) {
	char	tempc;
	char	buf2[LINE_START + 4];


	/* because I read the stuff into the output buffer
	 * directly, if the line gets too long, I output the
	 * stuff that fits, then copy the last thing from the
	 * end of the output buffer to the beginning
	 */
	tempc = buf[lasti];	    	    	    /* save char and null */
	buf[lasti] = '\0';         	    	    /* terminate the line */
	fwrite(buf, 1, strlen(buf), depfile);       /* write out line */
	sprintf(buf2, "\\\n%16s", "");	    	    /* set up new line */
	fwrite(buf2, 1, LINE_START, depfile);       /* and write it out */
	buf[lasti] = tempc;	    	    	    /* restore the char */
	strcpy(buf, buf + lasti);     /* copy new word to start of buffer */
	lasti = strlen(buf);          /* and set up buffer ponter for next */
	*length = lasti + LINE_START; /* word */
	lasti++;
    } else {
	/* the new word fits on this line so just advance the pointer */
    	lasti = i + 1;
    }

    return lasti;
}


/*********************************************************************
 *			FindRelativePath
 *********************************************************************
 * SYNOPSIS: 	    take a full path name and try to make it a relative
 *	    	    one so that having a local and installed tree will work
 *                  If the buffer is returned as an empty string, this
 *                  indicates that the file should be ignored.
 * CALLED BY:	    GetDependsFrom... routines
 * RETURN:
 * SIDE EFFECTS:    the string in the buffer may be changed
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/22/94		Initial version
 *
 *********************************************************************/
static void
FindRelativePath(char *buf, int *end)
{
    char    path[MAX_PATH_LENGTH];
    char    cwd[MAX_PATH_LENGTH];
    int     oldlength, length;
    char    *goc_compiler_dir;
    int     i;

#define IS_RELATIVE() \
    { \
	  strcpy(buf, buf + length); \
	  *end -= (oldlength - strlen(buf)); \
	  return; \
    }
#define IS_NOT_RELEVANT() \
    { \
          *buf = 0; \
          *end -= oldlength; \
	  return; \
    }

    /*
     * See if it's already a relative path.
     */
    if (buf[1] != ':' && !IS_PATHSEP(buf[0])) {
	return;
    }
    
    oldlength = strlen(buf);

    /*
     * See if it's a standard include file.
     */
    sprintf(path, "%s/CInclude/", rootDir);
    length = strlen(path);
    if (strnicmp(buf, path, length) == 0) {
	IS_RELATIVE();
    }
    sprintf(path, "%s/Include/", rootDir);
    length = strlen(path);
    if (strnicmp(buf, path, length) == 0) {
	IS_RELATIVE();
    }
    /*
     * See if it's a "standard" include file the user hasn't installed yet.
     */
    sprintf(path, "%s/CInclude/", develDir);
    length = strlen(path);
    if (strnicmp(buf, path, length) == 0) {
	IS_RELATIVE();
    }
    sprintf(path, "%s/Include/", develDir);
    length = strlen(path);
    if (strnicmp(buf, path, length) == 0) {
	IS_RELATIVE();
    }

    /*
     * See if we can make it relative to the current path.
     */
#ifdef _LINUX
    if (getcwd(cwd, MAX_PATH_LENGTH) == NULL) {
#else
    if (Compat_GetCwd(cwd, MAX_PATH_LENGTH) == NULL) {
#endif
	perror("makedpnd");
	exit(1);
    }
    sprintf(path, "%s/", cwd);
    length = strlen(path);
    if (strnicmp(buf, path, length) == 0) {
	IS_RELATIVE();
    }

    /*
     * Try the installed directory.
     */
    sprintf(path, "%s/", installDir);
    length = strlen(path);
    if (strnicmp(buf, path, length) == 0) {
	IS_RELATIVE();
    }

    /*
     * Try the GOC_COMPILER_DIR. These files are not included
     * in the dependency list at all.
     */
    goc_compiler_dir = getenv("GOC_COMPILER_DIR");
    if(!goc_compiler_dir) 
    {
	goc_compiler_dir = getenv("WATCOM");
    }
    if(goc_compiler_dir)
    {
      sprintf(path, "%s/", goc_compiler_dir);
      for(i=0; path[i]; i++)
        if(path[i]=='\\')
          path[i] = '/';
      length = strlen(path);
      if (strnicmp(buf, path, length) == 0) {
          IS_NOT_RELEVANT();
      }
    }

#undef IS_NOT_RELEVANT
#undef IS_RELATIVE
}


/*********************************************************************
 *			GetStdappStuff
 *********************************************************************
 * SYNOPSIS: 	deal with stdapp hack
 * CALLED BY:	GetDependsOutputAsm_Esp/_Borland
 * RETURN:  	nothing
 * SIDE EFFECTS:    depends info stuff into DEPENDS_FILE
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/ 8/93		Initial version
 *
 *********************************************************************/
static int
GetStdappStuff(FILE *depfile, 	/* file pointer to DEPENDS_FILE */
	       int   goc_or_c,	/* flag to say if we are doing C or GOC */
	       int  *length, 	/* legth of data in buffer so far */
	       int  *lasti,  	/* pointer into buffer */
	       char *buf)   	/* buffer of data going to output file */
{
    signed char    stdappc;
    char    pathbuf[MAX_PATH_LENGTH];
    FILE   *stdappfp;
    int	    i;

    if (goc_or_c) {
	sprintf(pathbuf, "%s/CInclude/stdapp.pdg", rootDir);
    } else {
    	sprintf(pathbuf, "%s/CInclude/stdapp.h", rootDir);
    }

    stdappfp = fopen(pathbuf, "rt");
    if (stdappfp != NULL) {
    	/* now just write out the stuff from the file as
	 * if it were coming from the output file
	 */

	/* the first line in a comment line */
	i       = *lasti;
	ScanNextWord(stdappfp, buf, &i);

	i       = *lasti;
	stdappc = ScanNextWord(stdappfp, buf, &i);
	buf[i]  = '\0';

	while (stdappc != EOF) {
	    *lasti  = WriteStringToDepfile(buf, length, *lasti, i, depfile);
	    i       = *lasti;
	    stdappc = ScanNextWord(stdappfp, buf, &i);

	    if (strncmp(buf + (*lasti), "*/", 2) == 0) {
		i       = *lasti;
		stdappc = EOF;
	    }
	    buf[i] = '\0';
	}
	fclose(stdappfp);
    }

    return 0;
}


/*********************************************************************
 *			GetDependsFromAsmOutput_Esp
 *********************************************************************
 * SYNOPSIS:  get the dependencies info from ESP output
 * CALLED BY:	ProcessFile
 * RETURN:  nothing
 * SIDE EFFECTS: dependencies info dumped into DEPENDS_FILE file
 * STRATEGY:	use ESP -M, it does all the work :)
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/24/92		Initial version
 *
 *********************************************************************/
static void
GetDependsFromAsmOutput_Esp(FILE *depfile, char *filename)
{
    char       *buf, c;
    FILE       *fp;
    int	        i, length = LINE_START - 2;
    int         lasti     = 0;
    Hash_Table	ht;
    int	        stdapp    = 0;
    int         err       = 0;

    Hash_InitTable(&ht, INIT_BUCKETS, HASH_STRING_KEYS, -1);
    Malloc(buf, BUFSIZE, char *);

    fp = fopen(filename, "rt");
    if (fp == NULL) {
	fprintf(stderr, "makedpnd: \"%s\": ", filename);
	perror("");
	EXIT(1);
    }

    if (ScanToEndOfLine(fp, GO_TO_END) == EOF) {
	goto cleanup_and_exit;
    }
    while (1) {
	i = lasti;
	/* each line has three words, the third of which is what I want */
	if (ScanNextWord(fp, buf, &i) == EOF) {
	    buf[i] = '\0';
	    goto cleanup_and_exit;
	}
	buf[i] = '\0';

	if ((strncmp(buf + lasti, "WARNING", 7) == 0) ||
	    (strncmp(buf + lasti, "ERROR", 5)   == 0) ||
	    (strncmp(buf + lasti, "FILE", 4)    == 0)) {
	    char	msgBuf[256];

	    fgets(msgBuf, 256, fp);
	    printf("%s %s\n", buf+lasti, msgBuf);
	    fflush(stdout);
	    buf[lasti] = '\0';
	    goto finish_line;
	}

	i = lasti;
	if (ScanNextWord(fp, buf, &i) == EOF) {
	    goto cleanup_and_exit;
	}
	i = lasti;
	c = ScanNextWord(fp, buf, &i);
	buf[i] = '\0';      		/* null terminate the string */
	FindRelativePath(buf + lasti, &i);
        if (buf[lasti] && FilterDuplicates(&ht, buf + lasti) != FALSE) {
	    int	notstdapp;

	    notstdapp = stricmp(buf + lasti, "STDAPP.GOH");
	    lasti     = WriteStringToDepfile(buf, &length, lasti, i, depfile);
	    /* special case stdapp.goh as an optimization */
	    if (notstdapp == 0 && !got_stdapp_goh) {
		got_stdapp_goh = 1;
		stdapp         = 1;
	    }
	}

finish_line:
	if (ScanToEndOfLine(fp, c) == EOF) {
	    goto cleanup_and_exit;
	}
    }

cleanup_and_exit:
    if (!err) {
	fwrite(buf, 1, strlen(buf), depfile);
#if 0
	/*
	 * Removed because, well, see Scan_Include() in Tools/goc/scan.c.
	 */
	if (stdapp) {
	    fwrite("\nstdapp.goh    : ", 1, 17, depfile);
	    length = LINE_START-2;
	    lasti = 0;

	    if (!GetStdappStuff(depfile, 1, &length, &lasti, buf)) {
		fwrite(buf, 1, strlen(buf), depfile);
	    }
	}
#endif
    } else {
	exit(1);
    }

    free(buf);
    Hash_DeleteTable(&ht);
    fclose(fp);
    (void) unlink(filename);
}

/*********************************************************************
 *			GetDependsFromCppOutput_MetaWare
 *********************************************************************
 * SYNOPSIS: get the dependencies info from a metware format file
 * CALLED BY:	ProcessFile
 * RETURN:
 * SIDE EFFECTS:    dependencies info out into DEPENDS_FILE file
 * STRATEGY:   all the includes will be  in #line expresssionss so
 *	    	they are a piece of cake to scan for
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/24/92		Initial version
 *
 *********************************************************************/
static void
GetDependsFromCppOutput_Metaware(FILE *depfile, char *filename, FileType ft)
{
    char       *buf, c;
    FILE       *fp;
    int	        i      = 0, lasti = 0;
    int	        first  = 1;             /* ignore the first #line directive
					 * as it's a temp file */
    Hash_Table  ht;
    int	        length = LINE_START-2;
    int	        err    = 0;

    Malloc(buf, BUFSIZE, char *);
    Hash_InitTable(&ht, INIT_BUCKETS, HASH_STRING_KEYS, -1);

    fp = fopen(filename, "rt");
    if (fp == NULL) {
	fprintf(stderr, "makedpnd: \"%s\": ", filename);
	perror("");
	EXIT(1);
    }

    while(1) {
	if ((c = (char) getc(fp)) == '#') {
	    /* see if the next word is "line" */

	    i = lasti;
	    if (ScanNextWord(fp, buf, &i) == EOF) {
		buf[i] = '\0';
		goto cleanup_and_exit;
	    }

	    buf[i] = '\0';
	    if (strcmp(buf+lasti, "LINE") == 0) {
		char	*suffix;

		/* the next word is a line number, we don't need it */
		c = ScanNextWord(fp, buf, &i);
		if (c == '\n') {
		    goto finish_line;
		}

		i = lasti;

		/* the next word is the file name */

		c = ScanNextWord(fp, buf, &i);

		/* skip the fist one as its lame, but only if its metablam */
		if (first && ft == FT_METAWARE) {
			first = 0;
			i     = lasti;
			goto finish_line;
		}

		buf[i] = '\0';

		suffix = strrchr(buf + lasti, '.');

		if (stricmp(suffix, ".GOH") && stricmp(suffix, ".POH")) {
		    FindRelativePath(buf + lasti, &i);
                        if (buf[lasti] && FilterDuplicates(&ht, buf+lasti) != FALSE) {
			lasti = WriteStringToDepfile(buf, &length, lasti,
						     i, depfile);
		    } /* duplicates */
		}

	    } /* strcmp LINE */
	} /* if line starts with # */
finish_line:
	if (ScanToEndOfLine(fp,c) == EOF) {
		goto cleanup_and_exit;
	}
	i = 0;
    }
cleanup_and_exit:
    if (!err) {
	fwrite(buf, 1, strlen(buf), depfile);
    } else {
	exit(1);
    }

    Hash_DeleteTable(&ht);
    fclose(fp);
    unlink(filename);
    free(buf);

    return;
}

/*********************************************************************
 *			GetDependsFromCppOutput_Borland
 *********************************************************************
 * SYNOPSIS: go throught the output of the Processors and get the
 *	     depenndenncies info they so kindly spit out
 * CALLED BY:	ProcessFile
 * RETURN:  nothing
 * SIDE EFFECTS:    add dependencies from file to DEPENDS_FILE
 * STRATEGY:	add the beginning of each line is the path and filename
 *	    	as well as line number info
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/24/92		Initial version
 *
 *********************************************************************/
static void
GetDependsFromCppOutput_Borland(FILE *depfile, char *filename)
{
    FILE       *fp;
    signed char        c;
    char       *buf, *tmpPtr;
    int	        lineno, i = 0, err = 0, lasti = 0, tempi;
    Hash_Table	ht;
    int	        length = LINE_START - 2;
    int	        stdapp = 0;

    Hash_InitTable(&ht, INIT_BUCKETS, HASH_STRING_KEYS, -1);
    Malloc(buf, BUFSIZE, char *);    /* input buffer */

    fp = fopen(filename, "rt");
    if (fp == NULL) {
	fprintf(stderr, "makedpnd: \"%s\": ", filename);
	perror("");
	EXIT(1);
    }

    /* first get the first line, this is the name of the source file */

    ScanNextWord(fp, buf, &i);
    buf[i] = '\0';

    if (ScanToEndOfLine(fp, GO_TO_END) == EOF) {
	goto cleanup_and_exit;
    }

    lasti = 0;
    while (1) {
	i = lasti;
	c = ScanNextWord(fp, buf, &i);  /* scan in filename */
	if (c == EOF) {
	    fprintf(stderr, "makedpnd: error: bad output file\n");
	    EXIT(1);
	}
	buf[i] = '\0';
	tempi  = i + 1;
	tmpPtr = buf + tempi;
	c = ScanNextWord(fp, buf, &tempi);  /* scan in line number */
	buf[tempi - 1] = '\0'; 		    /* get rid of `:` */
	lineno = atoi(tmpPtr);

	if (lineno == 1) {
	    char   *suffix;

	    suffix = strrchr(buf + lasti, '.');
	    if (stricmp(suffix, ".GOH") && stricmp(suffix,".POH")) {
		FindRelativePath(buf + lasti, &i);
                if (buf[lasti] && FilterDuplicates(&ht, buf + lasti) != FALSE) {
		    int	notstdapp;

		    suffix = buf + lasti + strlen(buf + lasti);
		    while(!IS_PATHSEP(*suffix) && suffix > (buf + lasti)) {
			suffix--;
		    }

		    if (suffix > (buf + lasti)) {
			notstdapp = stricmp(suffix + 1, "STDAPP.H");
		    } else {
			notstdapp = stricmp(suffix, "STDAPP.H");
		    }

		    lasti = WriteStringToDepfile(buf, &length, lasti,
						 i, depfile);

		    if (notstdapp == 0 && !got_stdapp_h) {
			stdapp       = 1;
			got_stdapp_h = 1;
		    }
		}
	    }
	}

	if (ScanToEndOfLine(fp, c) == EOF) {
		EXIT(0);
	}
    }

cleanup_and_exit:
    if (!err) {
	fwrite(buf, 1, strlen(buf), depfile);
	if (stdapp) {
	    fwrite("\nSTDAPP.H      : ", 1, 17, depfile);
	    length = LINE_START - 2;
	    lasti = 0;
	    if (GetStdappStuff(depfile, 0, &length, &lasti, buf)) {
		err = 1;
	    } else {
		fwrite(buf, 1, strlen(buf), depfile);
	    }
	}
    }

    Hash_DeleteTable(&ht);
    free(buf);
    if(fp) fclose(fp);

    if (err) {
	if (cargsfile   != NULL) { unlink(cargsfile);   }
	if (asmargsfile != NULL) { unlink(asmargsfile); }
	if (gocargsfile != NULL) { unlink(gocargsfile); }
	if (outfile     != NULL) { unlink(outfile); }
	exit(err);
    }
}

/*********************************************************************
 *			GetDependsFromCppOutput_Uicpp
 *********************************************************************
 * SYNOPSIS: go throught the output of the Processors and get the
 *	     depenndenncies info they so kindly spit out
 * CALLED BY:	ProcessFile
 * RETURN:  nothing
 * SIDE EFFECTS:    add dependencies from file to DEPENDS_FILE
 * STRATEGY:	add the beginning of each line is the path and filename
 *	    	as well as line number info
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/24/92		Initial version
 *
 *********************************************************************/
static void
GetDependsFromCppOutput_Uicpp(FILE *depfile, char *filename)
{
    FILE       *fp;
    signed char        c;
    char       *buf, *tmpPtr;
    int	        lineno, i = 0, err = 0, lasti = 0, tempi;
    Hash_Table	ht;
    int	        length = LINE_START - 2;
    int	        stdapp = 0;

    Hash_InitTable(&ht, INIT_BUCKETS, HASH_STRING_KEYS, -1);
    Malloc(buf, BUFSIZE, char *);    /* input buffer */

    fp = fopen(filename, "rt");
    if (fp == NULL) {
	fprintf(stderr, "makedpnd: \"%s\": ", filename);
	perror("");
	EXIT(1);
    }

    /* first get the first line, this is the name of the source file */
    i = 0;
    c = ScanNextWord(fp, buf, &i);  /* scan in filename */
    i = 0;
    c = ScanNextWord(fp, buf, &i);  /* scan in filename */


    lasti = 0;
    while (1) {
	i = lasti;
	c = ScanNextWord(fp, buf, &i);  /* scan in filename */
	if (c == EOF) {
	    //fprintf(stderr, "makedpnd: error: bad output file\n");
	    //EXIT(1);
	    break;
	}

	buf[i] = '\0';

	if (strcmp(buf + lasti, "/")) {
	    char   *suffix;

	    suffix = strrchr(buf + lasti, '.');
	    if (stricmp(suffix, ".GOH") && stricmp(suffix,".POH")) {
		FindRelativePath(buf + lasti, &i);
                if (buf[lasti] && FilterDuplicates(&ht, buf + lasti) != FALSE) {
		    int	notstdapp;

		    suffix = buf + lasti + strlen(buf + lasti);
		    while(!IS_PATHSEP(*suffix) && suffix > (buf + lasti)) {
			suffix--;
		    }

		    if (suffix > (buf + lasti)) {
			notstdapp = stricmp(suffix + 1, "STDAPP.H");
		    } else {
			notstdapp = stricmp(suffix, "STDAPP.H");
		    }

		    lasti = WriteStringToDepfile(buf, &length, lasti,
						 i, depfile);

		    if (notstdapp == 0 && !got_stdapp_h) {
			stdapp       = 1;
			got_stdapp_h = 1;
		    }
		}
	    }
	}
    }

cleanup_and_exit:
    if (!err) {
	fwrite(buf, 1, strlen(buf), depfile);
	if (stdapp) {
	    fwrite("\nSTDAPP.H      : ", 1, 17, depfile);
	    length = LINE_START - 2;
	    lasti = 0;
	    if (GetStdappStuff(depfile, 0, &length, &lasti, buf)) {
		err = 1;
	    } else {
		fwrite(buf, 1, strlen(buf), depfile);
	    }
	}
    }

    Hash_DeleteTable(&ht);
    free(buf);
    if(fp) fclose(fp);

    if (err) {
	if (cargsfile   != NULL) { unlink(cargsfile);   }
	if (asmargsfile != NULL) { unlink(asmargsfile); }
	if (gocargsfile != NULL) { unlink(gocargsfile); }
	if (outfile     != NULL) { unlink(outfile); }
	exit(err);
    }
}

/*********************************************************************
 *			ProcessFile
 *********************************************************************
 * SYNOPSIS: produced dependency information for a C or GOC or UI file
 * CALLED BY:	main
 * RETURN:  non-zero unless there is an error
 * SIDE EFFECTS: outputs dependency info for the files passed in
 * STRATEGY:	let CPP and GOC do all the hard work and just
 *	    	collect the stuff we need from their output
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/23/92		Initial version
 *
 *********************************************************************/
static int
ProcessFile(FILE     *depfile,   /* DEPENDS_FILE file handle */
	    char     *filename,  /* file to process */
	    char    **argv, 	 /* command line arguments */
	    int       args,   	 /* index into argv */
	    FileType  filetype,  /* type of file to process */
	    char     *command)   /* what command to run on the source file */
{
    char    *outfile;
    char     objfile[MAX_PATH_LENGTH];
    int	     i = 0, cpid;

    /* write out the target (*.c -> *.obj) to the depends file
     * I always want to output the same length string for the second
     * one (the ebj line), so i space pad the name out to
     * MAX_PATH_LENGTH characters
     */
    memset(objfile, ' ', MAX_PATH_LENGTH);
    strcpy(objfile, filename);
    while(objfile[i] != '.') {
	//objfile[i] = (char) toupper(objfile[i]);
	i++;
    }
    i++;

    switch (filetype) {
	case FT_ESP:
	    if (asmModules) {
		char *cp;

		cp = objfile + strlen(objfile);
		while(!IS_PATHSEP(*cp) && (cp > objfile)) {
		    cp--;
		}

		strcpy(cp, ".obj");
                if(product) {
                  fwrite(product, 1, strlen(product), depfile);
                  fwrite("/", 1, 1, depfile);
                }
		fwrite(objfile, 1, strlen(objfile), depfile);
                fwrite(" \\\n", 3, 1, depfile);
                strcpy(cp, ".eobj");
                if(product) {
                  fwrite(product, 1, strlen(product), depfile);
                  fwrite("/", 1, 1, depfile);
                }
                fwrite(objfile, 1, strlen(objfile), depfile);
		fwrite(": ", 1, 2, depfile);
		fwrite(filename, 1, strlen(filename), depfile);
		fwrite(" \\\n                ", 19, 1, depfile);

		break;
	    }
		/* FALLTHRU */

        case FT_BORLAND:
	case FT_METAWARE:
	case FT_MICROSOFT6:
	case FT_MICROSOFT7:
	case FT_GOC:
		strcpy(objfile + i, "obj");
                if(product) {
                  fwrite(product, 1, strlen(product), depfile);
                  fwrite("/", 1, 1, depfile);
                }
                fwrite(objfile, 1, strlen(objfile), depfile);
		fwrite(" \\\n", 3, 1, depfile);
		strcpy(objfile + i, "eobj");
                if(product) {
                  fwrite(product, 1, strlen(product), depfile);
                  fwrite("/", 1, 1, depfile);
                }
                fwrite(objfile, 1, strlen(objfile), depfile);
		fwrite(": ", 1, 2, depfile);
		break;

	case FT_UI:
		strcpy(objfile + i, "rdef");
                if(product) {
                  fwrite(product, 1, strlen(product), depfile);
                  fwrite("/", 1, 1, depfile);
                }
                fwrite(objfile, 1, strlen(objfile), depfile);
		fwrite(": ", 1, 2, depfile);
		break;
    }

    outfile = ApplyCommand(argv, args, command, filetype, &cpid);
    if (cpid != 0) {
	fprintf(stderr, "makedpnd: error running %s\n", command);

	if (cpid < 0) {
	    perror(command);
	    return 0;
	}
    }
    if (outfile == NULL) {
	return 0;
    }

    /* now GOC has been run, and so has CPP */
    switch (filetype) {
        case FT_BORLAND:
	    GetDependsFromCppOutput_Uicpp(depfile, outfile);
	    break;

	case FT_MICROSOFT6:
	case FT_MICROSOFT7:
	case FT_METAWARE:
	    GetDependsFromCppOutput_Metaware(depfile, outfile, filetype);
	    break;

	case FT_ESP:
	case FT_GOC:
	    GetDependsFromAsmOutput_Esp(depfile, outfile);
	    if (cpid != 0)
	    {
		unlink(outfile);
		return 0;	/* error code */
	    }
	    break;

	case FT_UI:
	    //GetDependsFromCppOutput_Borland(depfile, outfile);
	    GetDependsFromCppOutput_Uicpp(depfile, outfile);
	    break;
    }

    putc('\n', depfile);
    (void) unlink(outfile);
    return 1;
}

/*********************************************************************
 *			ParseFileType
 *********************************************************************
 * SYNOPSIS: get type of file
 * CALLED BY:	main
 * RETURN:  FileType
 * SIDE EFFECTS: set the global variable filetype to the appropriate value
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/23/92		Initial version
 *
 *********************************************************************/
static FileType
ParseFileType(char *type)
{
    if (stricmp(type, "GOC")        == 0) {
	return FT_GOC;
    }

    if (stricmp(type, "BORLAND")    == 0) {
	return FT_BORLAND;
    }

    if (stricmp(type, "METAWARE")   == 0) {
	return FT_METAWARE;
    }

    if (stricmp(type, "MICROSOFT6") == 0) {
	return FT_MICROSOFT6;
    }

    if (stricmp(type, "MICROSOFT7") == 0) {
	return FT_MICROSOFT7;
    }

    if (stricmp(type, "ESP")        == 0) {
	return FT_ESP;
    }

    if (stricmp(type, "UI")         == 0) {
	return FT_UI;
    }

    fprintf(stderr, "makedpnd: illegal file type '%s'\n", type);
    return FT_NONE;
}

/*********************************************************************
 *			main
 *********************************************************************
 * SYNOPSIS:     Create a dependencies file.
 * CALLED BY:    OS
 * RETURN:
 * SIDE EFFECTS: Creates a DEPENDS_FILE file.
 * STRATEGY:	 Look through all the files for includes.
 *
 *
 * 	the arguments come as follows:
 *	directories: a bunch of -Idirectory parameters
 *	    	     these are the paths in which to look for included files
 *	"CCOM" followed by flags for CPP and GOC
 *	C: a "C" parameter followd by C and GOC files
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/23/92		Initial version
 *      TB      8/20/96         WIN32 version
 *
 *********************************************************************/
void
main(int argc, char **argv)
{
    int	      i;
    FILE     *fp;
    int	      err        = 0;
    FileType  gocfiletype;
    FileType  asmfiletype;
    FileType  cfiletype;
    FileType  filetype;
    int	      firstAsmModule;

    signal(SIGINT, SigIntHandler);

    /* the following is for debugging */
#if 0
    {
	char tempcwd[MAX_PATH];

	_chdrive('U' - 'A' + 1);
	chdir("u:\\pcgeos\\tbradley\\appl\\sdk_9000\smsttt");
	printf("cwd = %s\n", Compat_GetCwd(tempcwd, MAX_PATH));
    }
#endif /* 0 */

    /*
     * first count up the number of include directories, always look in
     * the current directory first
     */

#ifdef TESTBORLAND
	fp = fopen ("test.mk", "wt");
	GetDependsFromCppOutput_Borland(fp, argv[1]);
	fclose(fp);
    	return;
#endif
#ifdef TESTMETAWARE
	fp = fopen("test.mk", "wt");
	GetDependsFromGocOutput_MetaWare(fp, argv[1]);
    	fclose(fp);
    	return;
#endif

#ifdef TESTESP
	fp = fopen("test.mk", "wt");
	GetDependsFromAsmOutput_Esp(fp, argv[1]);
    	fclose(fp);
    	return;
#endif
    if ((argc == 2) && HAS_ARGS_FILE(argv)) {
	GetFileArgs(ARGS_FILE(argv), &argc, &argv);
    }

    if (argc < 4) {
	fprintf(stderr,
                "Usage: makedpnd <root> <devel> <installed> [-o<outfile>] [-D<defines>]\n"
		"                <C module names>* ENDCMODULES\n"
		"                <ASM module names>* ENDASMMODULES\n"
		"                <various invocation flags>\n");
	EXIT(1);
    }

    /*
     * Various useful directories passed to us by pmake.
     *
     * We could figure these out without having anyone pass them
     * to us, but since we're always invoked by pmake, why bother?
     * It's much safer than trying to read branch files and stuff
     * ourselves...
     */
    rootDir = argv[1];
    develDir = argv[2];
    installDir = argv[3];

    /*
     * Since the rootDir stuff is recently-added code, I didn't
     * want to change the rest of the very argc-dependent code,
     * so just going to fake it into thinking that rootDir
     * and friends weren't there.
     */
    argc -= 3;
    argv = &argv[3];

    /*
     * We do the same trick for the output file...
     */
    if(argv[1][0]=='-' && argv[1][1]=='o')
    {
      dependsFile = &argv[1][2];
      argc--;
      argv = &argv[1];
    }

    /*
     * ...and the product switches.
     */
    while(argc>1 && argv[1][0]=='-')
    {
      /* Extract a switch in the form of -DPRODUCT_<product> */
      if(strncmp(argv[1], "-DPRODUCT_", 10)==0 && argv[1][10])
      {
        product = &argv[1][10];
      }
      argc--;
      argv = &argv[1];
    }

    /*
     * Gather up a list of all the subdirectories that are expected
     * to contain any .c or .goc files.
     */
    for (i = 1; i < argc;) {
	if (strcmp(argv[i++], "ENDCMODULES")) {
	    cModules++;
	} else {
	    break;
	}
    }

    /*
     * Gather up a list of all the subdirectories that are expected
     * to contain any .asm or .ui files.
     */
    for (firstAsmModule = i; i <= argc;) {
	if (strcmp(argv[i++], "ENDASMMODULES")) {
	    asmModules++;
	} else {
	    break;
	}
    }

    if (i >= argc) {
	fprintf(stderr,
		"makedpnd: error: no source files, no dependencies created\n");
	EXIT(1);
    }

    if ((fp = fopen(dependsFile, "wt")) == NULL) {
        fprintf(stderr, "makedpnd: \"%s\": ", dependsFile);
	perror("");
	EXIT(1);
    }

    while ((stricmp(argv[i], "GOC") == 0) ||
	   (stricmp(argv[i], "CPP") == 0) ||
	   (stricmp(argv[i], "ASM") == 0)) {
	int sourceType = i++;

	if ((filetype = ParseFileType(argv[i++])) == FT_NONE) {
	    EXIT(1);
	}

	if (stricmp(argv[sourceType], "CPP") == 0) {
	    cfiletype   = filetype;
	    i = ParseArgs(argv, sourceType, i, &ccommand, "ENDFLAGS");
	} else if (stricmp(argv[sourceType], "GOC") == 0) {
	    i = ParseArgs(argv, sourceType, i, &goccommand, "ENDFLAGS");
	    gocfiletype = filetype;
	} else if (stricmp(argv[sourceType], "ASM") == 0) {
	    i = ParseArgs(argv, sourceType, i, &asmcommand, "ENDFLAGS");
	    asmfiletype = filetype;
	}

    }

    /* save the number of asmModules for finding the .ui files */
    saveAsmModules = asmModules;

    while (asmModules > 0) {
	char managerfile[MAX_PATH_LENGTH];

	sprintf(managerfile, "%s/%sManager.asm",
		argv[firstAsmModule], argv[firstAsmModule]);

	{
		int begin = strlen(argv[firstAsmModule]) + 1;
		int len = strlen(argv[firstAsmModule]);
		int a = 0;
		while(a < len) {

			managerfile[begin + a] = tolower(managerfile[begin + a]);
			a++;
		}
	}
	if (!ProcessFile(fp, managerfile, argv, firstAsmModule,
			 asmfiletype, asmcommand)) {
            fprintf(stderr, "makedpnd: %s removed\n", dependsFile);
	    fclose(fp);
            (void) unlink(dependsFile);
	    err = 1;
	    goto cleanup_and_exit;
	}
    	asmModules--;
    	firstAsmModule++;
    }

    /*
     * Process all the cfiles, files and the asm files in the
     * top directory.  And the passed ui files
     */
    while(strcmp(argv[i], "ENDFILES") != 0 && i < argc) {
	char *suffix;
	int   gocfile;

	gocfile = FALSE;
	suffix  = strrchr(argv[i], '.');
	if (suffix == NULL) {
	    fprintf(stderr,
		    "makedpnd: incorrect command line argument '%s'\n",
		    argv[i]);
	    err = 1;
	    goto cleanup_and_exit;
	}

	if (stricmp(suffix, ".GOC") == 0) {
	    gocfile  = TRUE;
	    command  = goccommand;
	    filetype = gocfiletype;
	} else if (stricmp(suffix, ".C") == 0) {
	    command  = ccommand;
	    filetype = cfiletype;
	} else if (stricmp(suffix, ".ASM") == 0) {
	    command  = asmcommand;
	    filetype = asmfiletype;
	} else if (stricmp(suffix, ".UI") == 0) {
	    command  = ccommand;
	    filetype = FT_UI;
	}

	fflush(stdout);
	if (!ProcessFile(fp, argv[i], argv, i, filetype, command)) {
            fprintf(stderr, "makedpnd: %s removed\n", dependsFile);
	    fclose(fp);
            (void) unlink(dependsFile);
	    err = 1;
	    goto	cleanup_and_exit;
	}

	/* if we just did a GOC file then do the created C file and then
	 * nuke it
	 */
	if (gocfile != FALSE) {
	    strcpy(suffix, ".cpp");
	    fflush(stdout);
	    if (!ProcessFile(fp, argv[i], argv, i, cfiletype, ccommand))
	    {
		fprintf(stderr, "makedpnd: %s removed\n", dependsFile);
		fclose(fp);
		(void) unlink(dependsFile);
		err = 1;
		goto cleanup_and_exit;
	    }
	    (void) unlink(argv[i]);
	}
	/* get rid of the temp file */
	i++;
	if (i >= argc) {
		break;
	}
    }

    /*
     * Close the file before cleanup_and_exit, 'cuz in the error
     * case fp has already been closed.
     */
    fclose(fp);

cleanup_and_exit:
#if defined(_MSDOS)
    if (goccommand  != NULL) {
	(void) free(goccommand);
    }
    if (asmcommand  != NULL) {
	(void) free(asmcommand);
    }
    if (ccommand    != NULL) {
	(void) free(ccommand);
    }
#endif
    if (cargsfile   != NULL) {
	(void) unlink(cargsfile);
    }
    if (asmargsfile != NULL) {
	(void) unlink(asmargsfile);
    }
    if (gocargsfile != NULL) {
	(void) unlink(gocargsfile);
    }
    if (outfile     != NULL) {
	(void) unlink(outfile);
    }
    exit(err);
}
