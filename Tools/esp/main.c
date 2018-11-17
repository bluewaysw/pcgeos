/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Initialization
 * FILE:	  main.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 29, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/29/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Main module for Esp. Initialization and control.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: main.c,v 1.58 95/04/27 18:07:55 jimmy Exp $";
#endif lint

#include    <config.h>
#include    <compat/file.h>
#include    "esp.h"
#include    "scan.h"

#if defined(unix)
#include    <sys/signal.h>
#endif /* unix */

#include <fileargs.h>

#ifdef unix
#	define TMP_DIR "/tmp"
#else
#	define TMP_DIR "."
#endif

VMHandle	    output=0;
VMBlockHandle	    symStrings;	/* Table for strings of symbols that
				 * haven't been referenced yet */
VMBlockHandle	    permStrings;/* Table for strings that must be in the
				 * output file */
#define DEFCOPYRIGHT   	"Copyright GeoWorks 1991"
#define COPYRIGHT_SIZE	32
char	copyright[COPYRIGHT_SIZE] = DEFCOPYRIGHT;

#define INITIAL_DIRS    20
#define DIRS_INCREMENT	10

static int  	dotInPath = 0;	/* Set non-zero if -I. given, meaning files
				 * should not be looked for in the current
				 * directory initially, but should be looked
				 * for there where "." appears in the path */

char		**dirs;

int	    	do_bblock = 0;

int	    	localize = 0;

int		localizationRequired = 0;    /* lastChunk needs localized ? */

int		numDirs = 0;

int	    	makeDepend = 0;

int	    	errors = 0;

int	    	masmCompatible = 0;

int	    	reverseString = 0;

word	    	procType = PROC_8086|PROC_8087;

int	    	debug = 0;

int	    	geosRelease = 2;

int	    	dbcsRelease = 0;

int	    	warn_unref = 0;	    /* Warn if a symbol that can only be
				     * used during this assembly isn't. */

int	    	warn_local_unref=0; /* Warn if a local label isn't ever
				     * referenced */

int	    	warn_field = 0;	    /* Warn if structure field used with
				     * . operator when lhs isn't of the tupe
				     * that contains the field */

int	    	warn_shadow = 0;    /* Warn if a local variable or procedure
				     * overrides a definition in a larger
				     * scope */
int  	    	warn_private=0;	    /* Warn if a private method or instance
				     * variable is used outside a method
				     * handler or friend function related to
				     * the class that defined the thing */
int	    	warn_unreach=0;	    /* Warn about code that cannot be
				     * reached. This is very simplistic */
int		warn_unknown=0;	    /* Warn if a far call is made to a routine
				     * whose segment is unknown */
int	    	warn_record=0;	    /* Warn if a record initializer doesn't
				     * contain all the fields of the record */
int  	    	warn_fall_thru=0;   /* Warn if a function falls into another
				     * one without a .fall_thru directive */
int	    	warn_inline_data=0; /* Warn if a variable is defined where
				     * execution can reach */
int	    	warn_jmp = 0;	    /* Warn if out-of-range jumps are
				     * transformed into short jumps around
				     * near jumps */
int	    	warn_assume = 0;    /* Warn when override is generated based
				     * on segment assumptions */
int		warn_localize = 0;  /* Warn when localizable string doesn't
                                     * have the localization instruction */
int		warn_anonymous_chunk = 0; /* Warn if the chunk has no name */

WarnOpt warnOpts[] = {
    "unref",	    &warn_unref,	    0,
    "field",	    &warn_field,	    0,
    "shadow",	    &warn_shadow,	    0,
    "private",	    &warn_private,	    0,
    "unreach",	    &warn_unreach,	    0,
    "unknown",	    &warn_unknown,	    0,
    "record",	    &warn_record,	    0,
    "fall_thru",    &warn_fall_thru,        0,
    "inline_data",  &warn_inline_data,      0,
    "unref_local",  &warn_local_unref,	    0,
    "jmp",  	    &warn_jmp,	    	    0,
    "assume",	    &warn_assume,   	    0,
    "localize",     &warn_localize,	    0,
    "anonymous_chunk",	&warn_anonymous_chunk,	0,
};
const int   	numWarnOpts = sizeof(warnOpts)/sizeof(warnOpts[0]);


Expr	    	*entryPoint;	    /* Desired entry point for final
				     * executable */
SymbolPtr   	global;	    	    /* Global segment. Used by expression
				     * parser, mostly... */
char	    	*outFile;   	/* Name of output file (global for cleanup) */
char	    	*dependFile;	/* Name to put on lhs of : when creating
				 * dependencies list */
ID	    	*libNames;     	/* Name(s) of library being compiled */
int	    	numLibNames = 0;

/***********************************************************************
 *				CleanUp
 ***********************************************************************
 * SYNOPSIS:	    Clean up on receiving an evil signal
 * CALLED BY:	    SIGTERM, SIGINT, SIGHUP
 * RETURN:	    Never
 * SIDE EFFECTS:    output file is removed and the process exits
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 8/89	Initial Revision
 *
 ***********************************************************************/
static volatile void
CleanUp(void)
{
#if defined(unix)
    extern volatile void exit(int);
#else
    /* Novell seems to need the file to be closed before deleting it */
    if (output != 0) {
	VMClose(output);
    }
#endif
    (void)unlink(outFile);

    exit(1);
}


/***********************************************************************
 *				Usage
 ***********************************************************************
 * SYNOPSIS:	  Print out an error and usage message and exit
 * CALLED BY:	  main
 * RETURN:	  No
 * SIDE EFFECTS:  Process exits.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
void
Usage(char *fmt, ...)
{
    va_list 	    args;
    int	    	    i;

    va_start(args, fmt);

    vfprintf(stderr, fmt, args);

    fprintf(stderr, "\nUsage: esp [-o <file>] [-I<dir> ...] [-M] [<warnings>] [-L <lmem-align>] [-G <geos-rel>] [-l <loc-out-file>] [-2] <file>\n [-v]");

    fprintf(stderr, "Available warning options:");
    for (i = 0; i < sizeof(warnOpts)/sizeof(warnOpts[0]); i++) {
	fprintf(stderr, " -W%s", warnOpts[i].flag);
    }
    putc('\n', stderr);

    exit(1);
}



/***********************************************************************
 *				FindFile
 ***********************************************************************
 * SYNOPSIS:	  Find a file on our search path.
 * CALLED BY:	  main, yylex
 * RETURN:	  The path of the file (in dynamic mem)
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
char *
FindFile(char  	  *file)
{
    char    	  name[1024];
    int	    	  i;

    if ((!dotInPath || (index(file, PATHNAME_SLASH) != NULL)) &&
	(access(file, F_OK) == 0))
    {
	strcpy(name, file);
    } else {
	for (i = 0; i < numDirs; i++) {
	    if (dirs[i][0] == '.' && dirs[i][1] == '\0') {
		strcpy(name, file);
	    } else {
		sprintf(name, "%s%c%s", dirs[i], PATHNAME_SLASH, file);
	    }
	    if (access(name, F_OK) == 0) {
		break;
	    }
	}
	if (i == numDirs) {
	    return((char *)NULL);
	}
    }
    return((char *)strcpy((char *)malloc(strlen(name)+1), name));
}


/***********************************************************************
 *				NotifyInt
 ***********************************************************************
 * SYNOPSIS:	    Notify the user of a momentous occasion, but take
 *	    	    a varargs list instead of ...
 * CALLED BY:	    Notify and others
 * RETURN:	    Nothing
 * SIDE EFFECTS:    errors is incremented if why is NOTIFY_ERROR
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
NotifyInt(NotifyType	why,	/* What are you telling me? */
	  ID	    	file,	/* File in which event occurred (NullID if
				 * not known) */
	  int	    	line,	/* Line number at which it happened */
	  char	    	*fmt,	/* Format for message */
	  va_list   	args)	/* Args for format */
{
    static SymbolPtr	lastProc = (SymbolPtr)NULL;

    if (why == NOTIFY_DEBUG && !debug) {
	/*
	 * Debugging not enabled -- just return.
	 */
	return;
    }

    /*
     * Precede all notifications by the name of the containing procedure, if
     * any.
     */
    if (curProc != lastProc) {
	lastProc = curProc;

	if (file != NullID) {
	    if (curProc != (SymbolPtr)NULL) {
		fprintf(stderr, "%i: In procedure %i:\n", file, curProc->name);
	    } else {
		fprintf(stderr, "%i: At top level:\n", file);
	    }
	}
    }

    /*
     * First do the type-specific things...
     */
    if (why == NOTIFY_ERROR) {
	/*
	 * Record another error as having happened
	 */
	fprintf(stderr, "error: ");
	errors++;
    } else if (why == NOTIFY_WARNING) {
	/*
	 * Tell the user this is only a warning.
	 */
	fprintf(stderr, "warning: ");
    }

    /*
     * If file and line known, tell the user this.
     */
    if (file != NullID) {
	if (line == -1) {
	    fprintf(stderr, "file \"%i\" at end of file: ", file);
	} else {
	    fprintf(stderr, "file \"%i\", line %d: ", file, line);
	}
    }
    /*
     * Send the message to stderr
     */
    vfprintf(stderr, fmt, args);

    /*
     * If not a debug message, spew a newline out too.
     */
    if (why != NOTIFY_DEBUG) {
	putc('\n', stderr);
    }
}



/***********************************************************************
 *				Notify
 ***********************************************************************
 * SYNOPSIS:	    Notify the user of a momentous occasion
 * CALLED BY:	    Everyone
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None (but q.v. NotifyInt)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
Notify(NotifyType   why,
       ID   	    file,
       int  	    line,
       char 	    *fmt,
       ...)
{
    va_list args;

    va_start(args, fmt);

    NotifyInt(why, file, line, fmt, args);

    va_end(args);
}

/***********************************************************************
 *				DebugMem
 ***********************************************************************
 * SYNOPSIS:	Dump memory usage stats
 * CALLED BY:	main
 * RETURN:	nothing
 * SIDE EFFECTS:file esp_mem.<suffix> created and filled
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 8/92		Initial Revision
 *
 ***********************************************************************/
static void
DebugMem(char	*suffix)
{
    char    name[32];
    FILE    *stream;

    sprintf(name, "esp_mem.%s", suffix);
    stream = fopen(name, "w");

    if (stream != NULL) {

	malloc_printstats((malloc_printstats_callback *)fprintf, stream);
	fclose(stream);
	fprintf(stderr, "%s memory stats dumped to %s\n", suffix, name);
    }
}


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	  Guess what?
 * CALLED BY:	  UNIX
 * RETURN:	  No
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
void
main(argc, argv)
    int	    	  argc;
    char	  **argv;
{
    int	    	ac; 	    /* Index into argc */
    char	*source;    /* Name of source file */
    char    	*path;	    /* Path to same */
    short   	status;	    /* Status of VMOpen of output file */
    int	    	doDefs=0;   /* Set if -D flag encountered */
    int	    	i;
    int	    	debugmem = 0;
    int	    	currentMaxDirs = INITIAL_DIRS; /* number of spaces available*/
    	    	    	    	    	       /* for directories */
    char    	*libNameStr = 0;

    /*
     * We don't do anything about errors...
     */
    malloc_noerr(1);

    /* allocate a reseanable number of spaces for directories */
    dirs = (char **)malloc(INITIAL_DIRS * sizeof(char *));

#if defined(unix)
    /*
     * Catch all nasty signals now.
     */
    if (signal(SIGINT, SIG_IGN) != SIG_IGN) {
	signal(SIGINT, CleanUp);
    }
    if (signal(SIGTERM, SIG_IGN) != SIG_IGN) {
	signal(SIGTERM, CleanUp);
    }
    if (signal(SIGHUP, SIG_IGN) != SIG_IGN) {
	signal(SIGHUP, CleanUp);
    }
#endif

#if defined(_MSDOS)
    _setmode(stdout, _TEXT);
    _setmode(stdin, _TEXT);
    _setmode(stderr, _TEXT);
    *stderr = *stdout;
#endif

    if ((argc == 2) && HAS_ARGS_FILE(argv))
    {
	GetFileArgs(ARGS_FILE(argv), &argc, &argv);
    }

    /*
     * Allocate and initialize initial curFile record.
     */
    curFile = (File *)malloc(sizeof(File));
    curFile->next = (File *)0;
    outFile = source = (char *)0;

    /*
     * Process arguments
     */
    for (ac = 1; ac < argc; ac++) {
	if (argv[ac][0] == '-') {
	    switch (argv[ac][1]) {
	    	case '2':
		    dbcsRelease = TRUE;
		    break;
		case 'M':
		    makeDepend = TRUE;
		    break;
		case 'I': {
		    char	*cp = rindex(argv[ac], PATHNAME_SLASH);

		    if ((cp != NULL) && (cp[1] == '\0')) {
			/*
			 * Remove trailing PATHNAME_SLASH char so file search
			 * doesn't have to worry about whether it's there;
			 * it can just tack one onto the directory and append
			 * the file for which it's questing.
			 */
			*cp = '\0';
		    }

		    /*
		     * If the path is just ".", it implies files should not
		     * be searched for first in the current directory.
		     */
		    if (argv[ac][2] == '.' && argv[ac][3] == '\0') {
			dotInPath = 1;
		    }

		    /* make sure we don't write beyond our bounds */
		    if (numDirs == currentMaxDirs)
		    {
			currentMaxDirs += DIRS_INCREMENT;
#ifdef unix
			dirs = (char **)realloc(dirs, sizeof(char *) * currentMaxDirs);
#else	    /* this is for  lame METABLAM  */
			dirs = (void *)realloc((malloc_t)dirs, sizeof(char *) * currentMaxDirs);
#endif
		    }

		    dirs[numDirs++] = &argv[ac][2];
		    break;
		}
		case 'o':
		    if (ac + 1 == argc) {
			Usage("-o requires a filename argument");
			/*NOTREACHED*/
		    }
		    outFile = argv[ac+1];
		    ac++;
		    break;
		case 'd': {
#ifdef YYDEBUG
		    extern
#endif
			int yydebug;
#ifdef LEXDEBUG
		    extern
#endif
			int lexdebug;

		    if (argv[ac][2] == '\0') {
			lexdebug = yydebug = 1;
		    } else {
			if (index(argv[ac], 'y')) {
			    yydebug = 1;
			}
			if (index(argv[ac], 'l')) {
			    lexdebug = 1;
			}
			if (index(argv[ac], 'g')) {
			    debug=1;
			}
			if (index(argv[ac], 'm')) {
			    debugmem = 1;
			}
		    }
		    break;
		}
		case 'w':
		case 'W':
		{
		    int 	i;

		    for (i = numWarnOpts-1; i >= 0; i--) {
			if (strcmp(&argv[ac][2], warnOpts[i].flag) == 0) {
			    *warnOpts[i].var = (argv[ac][1] == 'W');
			    break;
			}
		    }

		    if (i < 0 &&
			((strcmp(argv[ac], "-Wall") == 0) ||
			 (strcmp(argv[ac], "-wall") == 0)))
		    {
			/* Temp. for now */
			int oldValue1 = warn_localize;
			int oldValue2 = warn_anonymous_chunk;

			for (i = numWarnOpts-1; i >= 0; i--) {
			    *warnOpts[i].var = (argv[ac][1] == 'W');
			}

			/* Restore the values */
			warn_localize = oldValue1;
			warn_anonymous_chunk = oldValue2;

			break;
		    } else if (i >= 0) {
			break;
		    }
		}
		    /*FALLTHRU*/
		default:
		    Usage("Argument %c unknown", argv[ac][1]);
		    /*NOTREACHED*/
		case 'i':
		    /* Enable I/O instructions */
		    procType |= PROC_IO;
		    break;
		case 'D':
		    /*
		     * Define a string equate. Dealt with after symbol table
		     * is initialized.
		     */
		    if (argv[ac][2] == '\0') {
			Usage("-D argument requires symbol name and optional value");
			/*NOTREACHED*/
		    }
		    doDefs = 1;
		    break;

		case 'N':
		    /*
		     * Specify alternative copyright notice.
		     */
		    if ((ac+1 == argc) || (argv[ac+1][0] == '-')) {
			Usage("-N requires copyright notice argument");
			/*NOTREACHED*/
		    } else {
			strncpy(copyright, argv[ac+1], sizeof(copyright));
			ac++;
		    }
		    break;
		case 'L':
		    /*
		     * Specify LMem alignment
		     */
		    if ((ac+1 == argc) || (argv[ac+1][0] == '-')) {
			Usage("-L requires lmem-alignment argument");
			/*NOTREACHED*/
		    } else {
			int align = atoi(argv[ac+1]);
			int first;

			if (align < 4) {
			    Usage("-L argument must be at least 4");
			    /*NOTREACHED*/
			}

			lmem_Alignment = align;

			/*
			 * Make sure only one bit is set.
			 */
			first=ffs(align);
			if (first != 0) {
			    /*
			     * Remove first set, and make sure no other is.
			     */
			    align &= ~(1 << first-1);
			    first = ffs(align);
			} else {
			    /*
			     * Set "first" non-zero to flag error (no bits set)
			     */
			    first = 1;
			}

			if (first) {
			    Usage("-L argument must be a power of 2");
			    /*NOTREACHED*/
			}

			/*
			 * Change the alignment value to be a bitmask
			 */
			lmem_Alignment -= 1;
			ac++;
		    }
		    break;
		case 'R':
		case 'G':
		    /*
		     * Set the release for which we're assembling.
		     */
		    if ((ac+1 == argc) || (argv[ac+1][0] == '-')) {
			Usage("-R requires release-number argument");
			/*NOTREACHED*/
		    } else {
			geosRelease = atoi(argv[ac+1]);
			/*
			 * Limit to those for which we're prepared.
			 */
			if (geosRelease > 2) {
			    geosRelease = 2;
			} else if (geosRelease == 0) {
			    Usage("There was no release 0 you hoser");
			    /*NOTREACHED*/
			}
			ac++;
		    }
		    break;
	    	case 'l':
		    /*
		     * Set the name of the localization file
		     */
		    if ((ac+1 == argc) || (argv[ac+1][0] == '-')) {
			Usage("-l requires localization-output-file argument");
			/*NOTREACHED*/
		    } else {
			Localize_Init(argv[ac+1], FALSE);
			localize = TRUE;
			ac++;
		    }
		    break;

	        case 'p':
		    /*
		     * Turn on profiling based on 2d letter:
		     *	b   basic-block analysis code.
		     *	c   routine-execution counting
		     */
		    switch(argv[ac][2]) {
		    case 'b':
			do_bblock = TRUE;
			break;
		    case 'c':
			/* fill in later */
			break;
		    default:
			Usage("unknown profiling mode in -p argument");
			/*NOTREACHED*/
		    }
		    break;
	    	case 'n':
		    /*
		     * Set name of the library being assembled
		     */
		    if ((ac+1 == argc) || (argv[ac+1][0] == '-')) {
			Usage("-n requires library-name argument");
			/*NOTREACHED*/
		    }
		    libNameStr = argv[ac+1];
		    ac++;
		    break;
	        case 'v':
		    /*
		     * Display the build date and time of this tool.
		     */
		    printf("esp was built on %s %s\n", __DATE__, __TIME__);
		    exit(1);
		    /*NOTREACHED*/
		    break;
	    }
	} else {
	    if (source) {
		Usage("Only one source file may be given");
	    }
	    source = argv[ac];
	}
    }

    /*
     * Record the default values for all the warning options.
     */
    for (i = 0; i < numWarnOpts; i++) {
	warnOpts[i].defval = *warnOpts[i].var;
    }

    /*
     * Make sure we've got a source file.
     */
    if (source == (char *)0) {
	Usage("Need a file on which to work");
    }
    /*
     * Form name of output file based on source, if not given explicitly
     */
    if (outFile == (char *)0) {
	char	*cp = rindex(source, PATHNAME_SLASH);

	if (cp++ == (char *)0) {
	    cp = source;
	}

	outFile = (char *)malloc(strlen(cp) + 4);
	strcpy(outFile, cp);

	cp = rindex(outFile, '.');

	if (cp++ == (char *)0) {
	    cp = outFile + strlen(outFile);
	}
  	/* in unix we use lower case, in DOS upper case */
#if defined(unix) || defined(_LINUX)
	strcpy(cp, "obj");
#else
	strcpy(cp, "OBJ");
#endif
    }

    /*
     * Locate the source file we're supposed to assemble.
     */
    path = FindFile(source);

    if (path == NULL) {
	fprintf(stderr, "Cannot locate %s\n", source);
	exit(1);
    }

    /*
     * Open the output file now, since we need it for the string table...
     * If in makeDepend mode, we just open a temporary file -- we won't
     * actually be producing output...
     */
    if (!makeDepend) {
	(void)unlink(outFile);
    }
    output = VMOpen(((makeDepend ? VMO_TEMP_FILE : VMO_CREATE_ONLY)|
		     FILE_DENY_RW|FILE_ACCESS_RW),
		    70,
		    (makeDepend ? TMP_DIR : outFile),
		    &status);

    if (output == NULL) {
	perror(outFile);
	exit(1);
    }
    UtilSetIDFile(output);

    if (geosRelease > 1) {
	GeosFileHeader2	gfh;

	VMGetHeader(output, (char *)&gfh);
	gfh.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	gfh.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	bcopy(OBJ_OBJTOKEN, gfh.token.chars, sizeof(gfh.token.chars));
	bcopy("ESP ", gfh.creator.chars, sizeof(gfh.creator.chars));
	strncpy(gfh.notice, copyright, GFH_RESERVED_SIZE);
	VMSetHeader(output, (char *)&gfh);
    } else {
    	GeosFileHeader	gfh;

	VMGetHeader(output, (char *)&gfh);
	gfh.core.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	gfh.core.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	bcopy(OBJ_OBJTOKEN, gfh.core.token.chars, sizeof(gfh.core.token.chars));
	bcopy("ESP ", gfh.core.creator.chars, sizeof(gfh.core.creator.chars));
	strncpy(gfh.reserved, copyright, GFH_RESERVED_SIZE);
	VMSetHeader(output, (char *)&gfh);
    }
    /*
     * Open the source file
     */
    yyin = fopen(path, "r");
    if (yyin == NULL) {
	perror(path);
	VMClose(output);
	exit(1);
    }

    /*
     * Create the temporary string table for the file...
     */
    symStrings = ST_Create(output);

    if (symStrings == 0) {
	fprintf(stderr, "Couldn't create temporary string table in %s\n",
		outFile);
	VMClose(output);
	exit(1);
    }

    /*
     * If library name(s) specified, store it(them) in the string table so we
     * can quickly determine if a library segment should be allowed to be
     * defined.
     */
    if (libNameStr != 0) {
	char	*cp, *cp2;

	/*
	 * Allocate at least one initially so we can just use realloc in the
	 * loop
	 */
	libNames = (ID *)malloc(sizeof(ID));

	cp = libNameStr;
	while (1) {
	    /*
	     * Look for a comma separating this name from the next.
	     */
	    cp2 = strchr(cp, ',');
	    if (cp2 == NULL) {
		/*
		 * This is the last one -- set cp2 to the end of the string.
		 */
		cp2 = cp + strlen(cp);
	    }
	    /*
	     * Enlarge the array to hold this one.
	     */
	    numLibNames += 1;
	    libNames = (ID *)realloc((malloc_t)libNames, numLibNames * sizeof(ID));
	    /*
	     * Enter this name into the table and store its ID in the array
	     */
	    libNames[numLibNames-1] = ST_Enter(output, symStrings, cp, cp2-cp);
	    /*
	     * If this was the last one, stop looping, else advance cp to
	     * the next (right after the comma)
	     */
	    if (*cp2 == '\0') {
		break;
	    } else {
		cp = cp2 + 1;
	    }
	}
    }

    /*
     * Create the permanent string table for the file...
     */
    permStrings = ST_Create(output);

    if (permStrings == 0) {
	fprintf(stderr, "Couldn't create string table in %s\n", outFile);
	VMClose(output);
	exit(1);
    }

    /*
     * Enter the initial source file into the string table and store away
     * the identifier we get back.
     */
    curFile->name = ST_EnterNoLen(output, permStrings, path);

    /*
     * Set up for makedepend mode
     */
    if (makeDepend) {
	if (outFile) {
	    dependFile = outFile;
	} else {
	    char	  *cp = source + strlen(source);

	    cp -= 4;
	    if (strcmp(cp, ".asm") == 0) {
		dependFile = (char *)malloc(cp - source + 4 + 1);
		sprintf(dependFile, "%.*s.obj", cp - source, source);
	    } else {
		dependFile = source;
	    }
	}

	printf("%s : %s\n", dependFile, source);
    }

    /*
     * Initialize scanner
     */
    Scan_Init();

    /*
     * Initialize parser state to be in the global segment.
     */
    global = Sym_Init();
    Parse_Init(global);

    /*
     * Deal with -D flags now we're in the global scope.
     */
    if (doDefs) {
	for (ac = 1; ac < argc; ac++) {
	    if (argv[ac][0] == '-') {
		switch (argv[ac][1]) {
		    case 'M':
		    case 'I':
		    case 'd':
		    case 'W':
		    case 'i':
		    case '2':
		    case 'w':
		    case 'p':
			/* No following arg */
			break;
		    case 'G':
		    case 'R':
		    case 'n':
		    case 'o':
		    case 'l':
		    case 'L':
		    case 'N':
			/* Skip following arg */
			ac++;
			break;
		    case 'D':
		    {
			char	*value;
			char	*name;

			name = argv[ac]+2;
			value = index(name, '=');
			if (value == NULL) {
			    value = "1";
			} else {
			    *value++ = '\0';
			}
			Parse_DefineString(name, value);
			break;
		    }
		}
	    }
	}
    }


    /*
     * Perform initial pass over source code.
     */
    if (yyparse() || errors) {
	goto 	err_exit;
    }

    /*
     * If locating dependencies, that's all we need to do.
     */
    if (makeDepend) {
	VMClose(output);
	exit(0);
    }

    /*
     * Make sure all lexical units (e.g. segments and procedures) are closed
     * properly.
     */
    if (!Parse_Complete()) {
	goto	err_exit;
    }

    if (debugmem) {
	DebugMem("pass1");
    }
    /*
     * Perform remaining passes:
     *	- assertions
     *	- pass 2 (resolve undefined symbols)
     *	- pass 3 (figure optimizations)
     *	- pass 4 (resolve optimizations/final storage)
     *	- symbol write-out
     *	- fixup write-out
     *	- segment write-out
     */
    if (!Assert_DoAll()) {
	goto	err_exit;
    }

    if (debugmem) {
	DebugMem("assert");
    }
    if (!Fix_Pass2()) {
	goto	err_exit;
    }

    if (debugmem) {
	DebugMem("pass2");
    }

    if (!Fix_Pass3()) {
	goto	err_exit;
    }

    if (debugmem) {
	DebugMem("pass3");
    }

    if (!Fix_Pass4()) {
	goto	err_exit;
    }

    if (debugmem) {
	DebugMem("pass4");
    }

    if (!Sym_ProcessSegments() || errors) {
	goto	err_exit;
    }

    if (debugmem) {
	DebugMem("output");
    }

    ST_Destroy(output, symStrings);
    ST_Close(output, permStrings);

    VMClose(output);

    if (debugmem) {
	DebugMem("final");
    }

    if (localize) {
	Localize_DumpLocalizations();
    }

    exit(0);

err_exit:
    /*
     * Remove the output file on error, not bothering to close and
     * update it, then exit non-zero (the number of errors, but make sure
     * it's actually non-zero when trimmed to a byte, as the OS will do).
     */
#if !defined(unix)
    /* Novell seems to need the file to be closed before deleting it */
    if (output != 0) {
	VMClose(output);
    }
#endif
    (void)unlink(outFile);

    exit(errors & 0xff ? errors : errors+1);
}



/***********************************************************************
 *				malloc_err
 ***********************************************************************
 * SYNOPSIS:		Write an error message w/o using malloc
 * CALLED BY:		malloc and friends
 * RETURN:		if 'fatal' is non-zero, exits 1.
 * SIDE EFFECTS:	None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
void
malloc_err(int 	fatal,
	   char	*str,
	   int 	len)
{
    write(2, str, len);
    if (fatal) {
	CleanUp();
    }
}
