/*-
 * main.c --
 *	The main file for this entire program. Exit routines etc
 *	reside here.
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
 * Utility functions defined in this file:
 *	Main_ParseArgLine   	Takes a line of arguments, breaks them and
 *	    	  	    	treats them as if they were given when first
 *	    	  	    	invoked. Used by the parse module to implement
 *	    	  	    	the .MFLAGS target.
 *
 *	Error	  	    	Print a tagged error message. The global
 *	    	  	    	MAKE variable must have been defined. This
 *	    	  	    	takes a format string and two optional
 *	    	  	    	arguments for it.
 *
 *	Fatal	  	    	Print an error message and exit. Also takes
 *	    	  	    	a format string and two arguments.
 *
 *	Punt	  	    	Aborts all jobs and exits with a message. Also
 *	    	  	    	takes a format string and two arguments.
 *
 *	Finish	  	    	Finish things up by printing the number of
 *	    	  	    	errors which occured, as passed to it, and
 *	    	  	    	exiting.
 */

/* We have our own version of getopt, so don't use the one in config.h */
#if defined (__BORLANDC__) || defined(_MSC_VER)
#      define HAVE_GETOPT
#endif /* defined (__BORLANDC__) */

#include <config.h>

#ifndef lint
static char     *rcsid = "$Id: main.c,v 1.9 96/06/24 15:05:53 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include    <stdio.h>
#include    <sys/types.h>
#include    <compat/string.h>

#if defined(__BORLANDC__)
#	include    <signal.h>

extern char getopt(int argc, char **argv, char *optstr);
extern time_t time(time_t *tm);

#elif defined(__WATCOMC__)
#	include    <signal.h>

extern time_t time(time_t *tm);

#elif defined(__HIGHC__)
#	include	   <malloc.h>
#	include    <signal.h>

extern char getopt(int argc, char **argv, char *optstr);
extern time_t time(time_t *tm);

#if !defined(Sprite)
#	define malloc hc_malloc
#	define calloc hc_calloc
#	define free hc_free
#	define realloc hc_realloc
#	undef malloc
#	undef calloc
#	undef free
#	undef realloc
#endif /* !defined(Sprite) */

#else
#	include    <sys/signal.h>
#	include    <sys/errno.h>
#	include	   <time.h>
extern int errno;
#endif /* defined(__BORLANDC__) */

#include    <compat/stdlib.h>
#include    <compat/string.h>
#include    <sys/stat.h>
#include    <ctype.h>

#include    <compat/file.h>

#include    "make.h"
#include    "prototyp.h"
#include    "sprite.h"

#if defined (unix)
#      include    "rmt.h"
#      include    "arch.h"
#endif /* unix */

#include    "pmjob.h"

#if defined(_WIN32)
#    include <windows.h>
#endif /* defined(_WIN32) */

int    idfile;

#if defined(DEFMAXJOBS) && !defined(DEFMAXLOCAL)
#      define DEFMAXLOCAL DEFMAXJOBS
#endif /* defined(DEFMAXJOBS) && !defined(DEFMAXLOCAL) */

#define MAKEFLAGS  	".MAKEFLAGS"

static char 	  	*progName;  	/* Our invocation name */

#if defined (unix)
static Boolean	  	lockSet;    	/* TRUE if we set the lock file */
#endif /* defined(unix) */

Lst			create;	    	/* Targets to be made */
time_t			now;	    	/* Time at start of make */
GNode			*DEFAULT;   	/* .DEFAULT node */
Boolean	    	    	allPrecious;	/* .PRECIOUS given on line by itself */

static int              printGraph;	/* -p flag */
static Boolean          noBuiltins;	/* -r flag */
static Boolean	  	noLocking;      /* -l flag */
static Lst  	    	makefiles;  	/* List of makefiles to read (in
					 * order) */
#if defined(unix) || defined(_WIN32) || defined(_LINUX)
int		    	maxJobs;	/* -J argument */
static int  	  	maxLocal;  	/* -L argument */
#endif /* defined(unix) || defined(_WIN32) || defined(_LINUX) */

Boolean	    	  	debug;          /* -d flag */
Boolean	  	  	amMake; 	/* -M flag */
Boolean	    	  	noWarnings; 	/* -W flag */
Boolean	    	    	noExecute;  	/* -n flag */
Boolean	    	    	keepgoing;  	/* -k flag */
Boolean			queryFlag;  	/* -q flag */
Boolean			touchFlag;  	/* -t flag */
#if defined(unix) || defined(_LINUX)
Boolean			usePipes;   	/* !-P flag */
#endif /* defined(unix) */
Boolean			backwards;  	/* -B flag */
Boolean			ignoreErrors;	/* -i flag */
Boolean			beSilent;   	/* -s flag */
Boolean	    	    	sysVmake;   	/* -v flag */
Boolean			oldVars;    	/* -V flag */
Boolean	    	    	checkEnvFirst;	/* -e flag */
static Boolean	  	XFlag=FALSE;   	/* -X flag given */
static Boolean	  	xFlag=FALSE;	/* -x flag given */
Boolean	    	  	noExport;   	/* Set TRUE if shouldn't export */
static Boolean	  	jobsRunning;	/* TRUE if the jobs might be running */

static Boolean	    	ReadMakefile(char* fname);
static void 		MainParseArgs(int argc, char **argv);

/*
 * Initial value for optind when parsing args. Different getopts start it
 * differently...
 */
static int  	initOptInd;

#ifdef CAN_EXPORT
#define OPTSTR "BCD:I:J:L:MNPSUVWXd:ef:iklnp:qrstuvxh"
#else
#define OPTSTR "BCD:I:J:L:MNPSUVWd:ef:iklnp:qrstuvh"
#endif

static char 	    *help[] = {
"-B	    	Be as backwards-compatible with make as possible without\n\
		being make.",
"-C	    	Cancel any current indications of compatibility.",
"-D<var>	Define the variable <var> with value 1.",
"-I<dir>	Specify another directory in which to search for included\n\
		makefiles.",
#ifdef unix
"-J<num>	Specify maximum overall concurrency.",
"-L<num>	Specify maximum local concurrency.",
"-M		Be Make as closely as possible.",
"-P		Don't use pipes to catch the output of jobs, use files.",
#endif
"-S	    	Turn off the -k flag (see below).",
#ifndef POSIX
"-V		Use old-style variable substitution.",
#endif
"-W		Don't print warning messages.",
#ifdef CAN_EXPORT
"-X		Turn off exporting of commands.",
#endif
"-d<flags>  	Turn on debugging output.",
"-e		Give environment variables precedence over those in the\n\
		makefile(s).",
"-f<file>	Specify a(nother) makefile to read",
"-i		Ignore errors from executed commands.",
"-k		On error, continue working on targets that do not depend on\n\
		the one for which an error was detected.",
#if defined(unix)
#    ifdef DONT_LOCK
"-l	    	Turn on locking of the current directory.",
#    else
"-l	    	Turn off locking of the current directory.",
#    endif /* def DONT_LOCK */
#endif /* defined(unix) */
#if defined(unix)
"-n	    	Don't execute commands, just print them.",
#else
"-n/N	    	Make non error checking geode.",
"-u/U	    	Don't execute commands, just print them.",
#endif /* defined(unix) */
"-p<num>    	Tell when to print the input graph: 1 (before processing),\n\
		2 (after processing), or 3 (both).",
"-q	    	See if anything needs to be done. Exits 1 if so.",
"-r	    	Do not read the system makefile for pre-defined rules.",
"-s	    	Don't print commands as they are executed.",
"-t	    	Update targets by \"touching\" them (see touch(1)).",
"-v	    	Be compatible with System V make. Implies -B, -V and no\n\
		directory locking.",
#ifdef CAN_EXPORT
"-x	    	Allow exportation of commands.",
#endif
#ifdef unix
"System configuration information:",
SYSPATHDOC,
SHELLDOC,
SYSMKDOC,
#endif
};

#if 0
/*********************************************************************
 *			MainHeapWalk
 *********************************************************************
 * SYNOPSIS: 	    check out the heap
 * CALLED BY:	    GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/30/93		Initial version
 *
 *********************************************************************/
MainHeapWalk(void)
{
    struct heapinfo hi;

    hi.ptr = NULL;

    printf("heap left = %lu\n", (unsigned long)coreleft());
    printf("  Size    Status\n");
    printf("  ----    ------\n");
    while(heapwalk(&hi) == _HEAPOK)
    {
	printf("%7u 	%d\n", hi.size, hi.in_use);
    }
}
#endif

#if defined(__HIGHC__)
HeapDump()
{
    malloc_printstats((malloc_printstats_callback *)fprintf, stdout);
}
#endif
/*-
 *----------------------------------------------------------------------
 * MainParseArgs --
 *	Parse a given argument vector. Called from main() and from
 *	Main_ParseArgLine() when the .MAKEFLAGS target is used.
 *
 *	XXX: Deal with command line overriding .MAKEFLAGS in makefile
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	Various global and local flags will be set depending on the flags
 *	given
 *----------------------------------------------------------------------
 */
static void
MainParseArgs (int argc, char** argv)
{
    register int  i;
    extern int	optind;
    extern char	*optarg;
    char    	c;

    optind = initOptInd;

    while((char)(c = getopt(argc, argv, OPTSTR)) != (char)-1) {
	switch(c) {
	    case 'B':
		backwards = oldVars = TRUE;
		Var_Append(MAKEFLAGS, "-B", VAR_GLOBAL);
		break;
	    case 'C':
		oldVars = backwards = sysVmake = amMake = FALSE;
		Var_Append(MAKEFLAGS, "-C", VAR_GLOBAL);
		break;
	    case 'D':
		Var_Set(optarg, "1", VAR_GLOBAL);
		Var_Append(MAKEFLAGS, "-D", VAR_GLOBAL);
		Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
		break;
	    case 'I':
		Parse_AddIncludeDir(optarg);
		Var_Append(MAKEFLAGS, "-I", VAR_GLOBAL);
		Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
		break;
	    case 'M':
		amMake = TRUE;
		Var_Append(MAKEFLAGS, "-M", VAR_GLOBAL);
		break;
#if defined(unix) || defined(_LINUX)
	    case 'J':
		maxJobs = atoi(optarg);
		Var_Append(MAKEFLAGS, "-J", VAR_GLOBAL);
		Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
		break;
	    case 'L':
		maxLocal = atoi(optarg);
		Var_Append(MAKEFLAGS, "-L", VAR_GLOBAL);
		Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
		break;
	    case 'P':
		usePipes = FALSE;
		Var_Append(MAKEFLAGS, "-P", VAR_GLOBAL);
		break;
#endif
	    case 'S':
		keepgoing = FALSE;
		Var_Append(MAKEFLAGS, "-S", VAR_GLOBAL);
		break;
	    case 'V':
		oldVars = TRUE;
		Var_Append(MAKEFLAGS, "-V", VAR_GLOBAL);
		break;
	    case 'W':
		noWarnings = TRUE;
		Var_Append(MAKEFLAGS, "-W", VAR_GLOBAL);
		break;
	    case 'X':
		XFlag = TRUE;
		Var_Append(MAKEFLAGS, "-X", VAR_GLOBAL);
		break;
	    case 'd':
	    {
		char	*modules = optarg;

		while (*modules) {
		    switch (*modules) {
			case 's':
			    debug |= DEBUG_SUFF;
			    break;
			case 'm':
			    debug |= DEBUG_MAKE;
			    break;
			case 'j':
			    debug |= DEBUG_JOB;
			    break;
			case 't':
			    debug |= DEBUG_TARG;
			    break;
			case 'd':
			    debug |= DEBUG_DIR;
			    break;
			case 'v':
			    debug |= DEBUG_VAR;
			    break;
			case 'c':
			    debug |= DEBUG_COND;
			    break;
			case 'p':
			    debug |= DEBUG_PARSE;
			    break;
			case 'r':
			    debug |= DEBUG_RMT;
			    break;
			case 'a':
			    debug |= DEBUG_ARCH;
			    break;
			case '*':
			    debug = ~0;
			    break;
		    }
		    modules++;
		}
		Var_Append(MAKEFLAGS, "-d", VAR_GLOBAL);
		Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
		break;
	    }
	    case 'e':
		checkEnvFirst = TRUE;
		Var_Append(MAKEFLAGS, "-e", VAR_GLOBAL);
		break;
	    case 'f':
		(void)Lst_AtEnd(makefiles, (ClientData)optarg);
		break;
	    case 'i':
		ignoreErrors = TRUE;
		Var_Append(MAKEFLAGS, "-i", VAR_GLOBAL);
		break;
	    case 'k':
		keepgoing = TRUE;
		Var_Append(MAKEFLAGS, "-k", VAR_GLOBAL);
		break;
	    case 'l':
#ifdef DONT_LOCK
		noLocking = FALSE;
#else
		noLocking = TRUE;
#endif
		Var_Append(MAKEFLAGS, "-l", VAR_GLOBAL);
		break;
#if defined(unix)
	    case 'n':
		noExecute = TRUE;
		Var_Append(MAKEFLAGS, "-n", VAR_GLOBAL);
		break;
#else
	    case 'n':
	    case 'N':
		Var_Append(MAKEFLAGS, "-n", VAR_GLOBAL);
		Var_Set("NO_EC", "1", VAR_GLOBAL);
		break;
	    case 'U':
	    case 'u':
		noExecute = TRUE;
		Var_Append(MAKEFLAGS, "-u", VAR_GLOBAL);
		break;
#endif
	    case 'p':
		printGraph = atoi(optarg);
		break;
	    case 'q':
		queryFlag = TRUE;
		Var_Append(MAKEFLAGS, "-q", VAR_GLOBAL); /* Kind of
							  * nonsensical, wot?
							  */
		break;
	    case 'r':
		noBuiltins = TRUE;
		Var_Append(MAKEFLAGS, "-r", VAR_GLOBAL);
		break;
	    case 's':
		beSilent = TRUE;
		Var_Append(MAKEFLAGS, "-s", VAR_GLOBAL);
		break;
	    case 't':
		touchFlag = TRUE;
		Var_Append(MAKEFLAGS, "-t", VAR_GLOBAL);
		break;
	    case 'v':
		sysVmake = oldVars = backwards = noLocking = TRUE;
		Var_Append(MAKEFLAGS, "-v", VAR_GLOBAL);
		break;
	    case 'x':
		xFlag = TRUE;
		Var_Append(MAKEFLAGS, "-x", VAR_GLOBAL);
		break;
	    case 'h':
	    case '?':
	    {
		int 	i;

		for (i = 0; i < sizeof(help)/sizeof(help[0]); i++) {
		    printf("%s\n", help[i]);
		}
		exit(c == '?' ? -1 : 0);
	    }
	}
    }

    /*
     * if we are not on unix, then do everything locally
     * the -M flag will tell PMAKE not to do parallel jobs
     */
#if !defined(unix) && !defined(_WIN32) && !defined(_LINUX)
    if (amMake != TRUE) {
	amMake = TRUE;
	Var_Append(MAKEFLAGS, "-M", VAR_GLOBAL);
    }
#endif
    /*
     * Take care of encompassing compatibility levels...
     */
    if (amMake) {
	backwards = TRUE;
    }
    if (backwards) {
	oldVars = TRUE;
    }

    /*
     * See if the rest of the arguments are variable assignments and perform
     * them if so. Else take them to be targets and stuff them on the end
     * of the "create" list.
     */
    for (i = optind; i < argc; i++) {
	if (Parse_IsVar (argv[i])) {
	    Parse_DoVar(argv[i], VAR_CMD);
	} else {
	    if (argv[i][0] == 0) {
		Punt("Bogus argument in MainParseArgs", 0, 0);
	    }
	    (void)Lst_AtEnd (create, (ClientData)argv[i]);
	}
    }
}

/*-
 *----------------------------------------------------------------------
 * Main_ParseArgLine --
 *  	Used by the parse module when a .MFLAGS or .MAKEFLAGS target
 *	is encountered and by main() when reading the .MAKEFLAGS envariable.
 *	Takes a line of arguments and breaks it into its
 * 	component words and passes those words and the number of them to the
 *	MainParseArgs function.
 *	The line should have all its leading whitespace removed.
 *
 * Arguments:
 *      char *line : Line to fracture
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	Only those that come from the various arguments.
 *-----------------------------------------------------------------------
 */
void
Main_ParseArgLine (char *line)
{
    char    	  **argv;     /* Manufactured argument vector */
    int     	  argc;	      /* Number of arguments in argv */

    if (line == NULL) return;
    while (*line == ' ') line++;

    argv = Str_BreakString (line, " \t", "\n", TRUE, &argc);

    MainParseArgs(argc, argv);

    Str_FreeVec(argc, argv);
}

#ifdef unix
/*-
 *-----------------------------------------------------------------------
 * MainUnlock --
 *	Unlock the current directory. Called as an ExitHandler.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The locking file LOCKFILE is removed.
 *
 *-----------------------------------------------------------------------
 */
static void
MainUnlock (void)
{
    (void)unlink (LOCKFILE);
}
#endif
/*-
 *----------------------------------------------------------------------
 * main --
 *	The main function, for obvious reasons. Initializes variables
 *	and a few modules, then parses the arguments give it in the
 *	environment and on the command line. Reads the system makefile
 *	followed by either Makefile, makefile or the file given by the
 *	-f argument. Sets the .MAKEFLAGS PMake variable based on all the
 *	flags it has received by then uses either the Make or the Compat
 *	module to create the initial list of targets.
 *
 * Results:
 *	If -q was given, exits -1 if anything was out-of-date. Else it exits
 *	0.
 *
 * Side Effects:
 *	The program exits when done. Targets are created. etc. etc. etc.
 *
 *----------------------------------------------------------------------
 */
void
main (int argc, char** argv)
{
    Lst             targs;     	/* list of target nodes to create. Passed to
				 * Make_Init */
    Boolean         outOfDate = TRUE; 	/* FALSE if all targets up to date */
                                        /* I initialize to TRUE to avoid   */
                                        /* unitilialized variable warning  */
    char    	    *cp;
    extern int	    optind;


    create = Lst_Init (FALSE);
    makefiles = Lst_Init(FALSE);

    beSilent = FALSE;	      	/* Print commands as executed */
    ignoreErrors = FALSE;     	/* Pay attention to non-zero returns */
    noExecute = FALSE;	      	/* Execute all commands */
    keepgoing = FALSE;	      	/* Stop on error */
    allPrecious = FALSE;      	/* Remove targets when interrupted */
    queryFlag = FALSE;	      	/* This is not just a check-run */
    noBuiltins = FALSE;	      	/* Read the built-in rules */
    touchFlag = FALSE;	      	/* Actually update targets */
#if defined(unix) || defined(_LINUX)
    usePipes = TRUE;	      	/* Catch child output in pipes */
#endif /* defined(unix) */
#ifndef DONT_LOCK
    noLocking = FALSE;	      	/* Lock the current directory against other
				 * pmakes */
#else
    noLocking = TRUE;
#endif /* DONT_LOCK */
    debug = 0;	      	    	/* No debug verbosity, please. */
    noWarnings = FALSE;	    	/* Print warning messages */
    sysVmake = FALSE;	    	/* Don't be System V compatible */

    jobsRunning = FALSE;
#ifdef DEFMAXJOBS
    maxJobs = DEFMAXJOBS;     	/* Set the default maximum concurrency */
    maxLocal = DEFMAXLOCAL;   	/* Set the default local max concurrency */
#endif
    /*
     * Deal with disagreement between different getopt's as to what
     * the initial value of optind should be by simply saving the
     * damn thing.
     */
#if 0
    MainHeapWalk();
#endif
    initOptInd = optind;

    /*
     * for debugging
     */
#if 0
    {
	char tempcwd[MAX_PATH];

	_chdrive('S' - 'A' + 1);
	chdir("s:\\pcgeos\\tiger\\tools\\mkmf");
	/* printf("cwd = %s\n", GetCwd(tempcwd, MAX_PATH)); */
    }
#endif

    /*
     * See what the user calls us. If s/he calls us (yuck) "make", then
     * act like it. Otherwise act like our normal, cheerful self.
     */
    cp = Var_LastPathSep(argv[0]);
    if (cp != NULL) {
	cp += 1;
    } else {
	cp = argv[0];
    }
    progName = cp;

    /*
     * win32 names are case-retentive but not case-sensitive so compare
     * case-insensitively
     */
#if defined(_WIN32)
    if (stricmp (cp, "make") == 0) {
#else
    if (strcmp (cp, "make") == 0) {
#endif /* defined (_WIN32) */
	amMake    = TRUE;      	/* Be like make */
	backwards = TRUE;     	/* Do things the old-fashioned way */
	oldVars   = TRUE;      	/* Same with variables */
#if defined (_WIN32)
    } else if (stricmp(cp, "smake") == 0 || stricmp(cp, "vmake") == 0) {
#else
    } else if (strcmp(cp, "smake") == 0 || strcmp(cp, "vmake") == 0) {
#endif /* defined (_WIN32) */
	sysVmake = oldVars = backwards = noLocking = TRUE;
    } else {
	amMake = FALSE;
	backwards = FALSE;    	/* Do things MY way, not MAKE's */
#ifdef DEF_OLD_VARS
	oldVars = TRUE;
#else
	oldVars = FALSE;      	/* don't substitute for undefined variables */
#endif
    }

    /*
     * Initialize the parsing, directory and variable modules to prepare
     * for the reading of inclusion paths and variable settings on the
     * command line
     */
    Dir_Init ();		/* Initialize directory structures so -I flags
				 * can be processed correctly */
    Parse_Init ();		/* Need to initialize the paths of #include
				 * directories */
    Var_Init ();		/* As well as the lists of variables for
				 * parsing arguments */

    /*
     * Initialize various variables.
     *	.PMAKE gets how we were executed.
     *	MAKE also gets this name, for compatibility
     *	.MAKEFLAGS gets set to the empty string just in case.
     *  MFLAGS also gets initialized empty, for compatibility.
     */
    Var_Set (".PMAKE", argv[0], VAR_GLOBAL);
    Var_Set ("MAKE", argv[0], VAR_GLOBAL);
    Var_Set (MAKEFLAGS, "", VAR_GLOBAL);
    Var_Set ("MFLAGS", "", VAR_GLOBAL);
#if defined(_LINUX)
	Var_Set ("linux", "", VAR_GLOBAL);
#endif

    /*
     * First snag any flags out of the PMAKE environment variable.
     * (Note this is *not* MAKEFLAGS since /bin/make uses that and it's in
     * a different format).
     */
#if defined(POSIX)
    Main_ParseArgLine(getenv("MAKEFLAGS"));
#elif defined(unix)
    Main_ParseArgLine (getenv("PMAKE"));
#else
{
    char    *pmakevar, *pmv;
    int	    i;

    pmv = pmakevar = getenv("PMAKE");
    if (pmv != NULL) {
        for(i = 0; pmv[i]; i++) {
	    if (pmv[i] == '\\') {
              pmv[i] = '/';
            }
        }
    }

    Main_ParseArgLine(pmakevar);
}
#endif

    MainParseArgs (argc, argv);

#if defined(unix)
    /*
     * If the user didn't tell us not to lock the directory, attempt to create
     * the lock file. Complain if we can't, otherwise set up an exit handler
     * to remove the lock file...
     */
    if (!noLocking) {
	int	  	oldMask;    /* Previous signal mask */
	int	  	lockID;     /* Stream ID of opened lock file */

#    if !defined(SYSV)
	oldMask = sigblock(sigmask(SIGINT));
#    else
	oldMask = sighold(SIGINT);
#    endif /* !defined(SYSV) */

	lockID = open (LOCKFILE, O_CREAT | O_EXCL, 0666);
	if (lockID < 0 && errno == EEXIST) {
	    /*
	     * Find out who owns the file. If the user who called us
	     * owns it, then we ignore the lock file. Note that we also
	     * do not install an exit handler to remove the file -- if the
	     * lockfile is there from a previous make, it'll still be there
	     * when we leave.
	     */
	    struct stat   fsa;    /* Attributes of the lock file */

	    (void) stat (LOCKFILE,  &fsa);
	    if (fsa.st_uid == getuid()) {
		Error ("Lockfile owned by you -- ignoring it", 0, 0, 0);
		lockSet = FALSE;
	    } else {
		char  	lsCmd[40];
		(void)sprintf (lsCmd, "ls -l %s", LOCKFILE);
		(void)system(lsCmd);
		Fatal ("This directory is already locked (%s exists)",
		       (unsigned long)LOCKFILE, 0);
	    }
	} else if (lockID < 0) {
	    Fatal ("Could not create lock file %s", (unsigned long)LOCKFILE,0);
	} else {
	    /*extern exit();*/

	    lockSet = TRUE;
#    ifdef sun
	    on_exit(MainUnlock);
#    endif /* def sun */

	    signal(SIGINT, exit);
	    (void)close (lockID);
	}

#    ifndef SYSV
	(void) sigsetmask(oldMask);
#    else
	(void) sigrelse(SIGINT);
#    endif /* ndef SYSV */
    }

#endif /* def unix */

    /*
     * Initialize archive, target and suffix modules in preparation for
     * parsing the makefile(s)
     */
#if defined(unix)
    Arch_Init ();
#endif /* defined(unix) */

    Targ_Init ();
    Suff_Init ();

    DEFAULT = NILGNODE;

    now = time(0);

    /*
     * Set up the .TARGETS variable to contain the list of targets to be
     * created. If none specified, make the variable empty -- the parser
     * will fill the thing in with the default or .MAIN target.
     */
    if (!Lst_IsEmpty(create)) {
	LstNode	ln;

	for (ln = Lst_First(create); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    char    *name = (char *)Lst_Datum(ln);

	    Var_Append(".TARGETS", name, VAR_GLOBAL);
	}
    } else {
	Var_Set(".TARGETS", "", VAR_GLOBAL);
    }

    /*
     * Read in the built-in rules first, followed by the specified makefile,
     * if it was (makefile != (char *) NULL), or the default Makefile and
     * makefile, in that order, if it wasn't.
     */
#ifdef unix
    if (!noBuiltins && !ReadMakefile (DEFSYSMK)) {
	Fatal ("Could not open system rules (%s)", (unsigned long)DEFSYSMK, 0);
    }
#endif
    if (!Lst_IsEmpty(makefiles)) {
	LstNode	ln = Lst_Find(makefiles, (ClientData)NULL, ReadMakefile);

	if (ln != NILLNODE) {
	    Fatal ("Cannot open %s", (unsigned long)Lst_Datum(ln), 0);
	}
    } else {
#ifdef POSIX
	if (!ReadMakefile("makefile")) {
	    (void)ReadMakefile("Makefile");
	}
#else
	if (!ReadMakefile ((amMake || sysVmake) ? "makefile" : "Makefile")) {
	    (void) ReadMakefile ((amMake||sysVmake) ? "Makefile" : "makefile");
	}
#endif
    }

    /*
     * Figure "noExport" out based on the current mode. Since exporting each
     * command in make mode is rather inefficient, we only export if the -x
     * flag was given. In regular mode though, we only refuse to export if
     * -X was given. In case the operative flag was given in the environment,
     * however, the opposite one may be given on the command line and cancel
     * the action.
     */
    if (amMake) {
	noExport = !xFlag || XFlag;
    } else {
	noExport = XFlag && !xFlag;
    }

    Var_Append ("MFLAGS", Var_Value(MAKEFLAGS, VAR_GLOBAL), VAR_GLOBAL);

    /*
     * Install all the flags into the PMAKE envariable.
     */
#ifdef POSIX
    setenv("MAKEFLAGS", Var_Value(MAKEFLAGS, VAR_GLOBAL));
#elif defined(__WATCOMC__)
    setenv("PMAKE", Var_Value(MAKEFLAGS, VAR_GLOBAL), TRUE);
#else
    setenv("PMAKE", Var_Value(MAKEFLAGS, VAR_GLOBAL));
#endif

    /*
     * For compatibility, look at the directories in the VPATH variable
     * and add them to the search path, if the variable is defined. The
     * variable's value is in the same format as the PATH envariable, i.e.
     * <directory>:<directory>:<directory>...
     */
    if (Var_Exists ("VPATH", VAR_CMD)) {
	char	  *vpath;
	char	  *path;
	char  	  *cp;
	char  	  savec;
	static char VPATH[] = "${VPATH}";   /* GCC stores string constants in
					     * read-only memory, but Var_Subst
					     * will want to write this thing,
					     * so store it in an array */

	vpath = Var_Subst (VPATH, VAR_CMD, FALSE);

	path = vpath;
	do {
	    /*
	     * Skip to end of directory
	     */
	    for (cp = path; *cp != ':' && *cp != '\0'; cp++) {
		continue;
	    }
	    /*
	     * Save terminator character to figure out when to stop
	     */
	    savec = *cp;
	    *cp = '\0';
	    /*
	     * Add directory to search path
	     */
	    Dir_AddDir (dirSearchPath, path);
	    *cp = savec;
	    path = cp + 1;
	} while (savec == ':');
	free((Address)vpath);
    }

    /*
     * Now that all search paths have been read for suffixes et al, it's
     * time to add the default search path to their lists...
     */
    Suff_DoPaths();

    /*
     * Print the initial graph, if the user requested it
     */
    if (printGraph & 1) {
	Targ_PrintGraph (1);
    }

#ifdef unix
    Rmt_Init();
#endif

    /*
     * Have now read the entire graph and need to make a list of targets to
     * create. If none was given on the command line, we consult the parsing
     * module to find the main target(s) to create.
     */

    if (Lst_IsEmpty (create)) {
	targs = Parse_MainName ();
    } else {

	targs = Targ_FindList (create, TARG_CREATE);
    }

#if !defined(_MSDOS)
    if (!amMake) {
	/*
	 * Initialize job module before traversing the graph, now that any
	 * .BEGIN and .END targets have been read. This is done only if the
	 * -q flag wasn't given (to prevent the .BEGIN from being executed
	 * should it exist).
	 */
#else
    {
#endif /* !defined(_MSDOS) */

#if defined(unix) || defined(_WIN32) || defined(_LINUX)
	if (!queryFlag) {
	    if (maxLocal == -1) {
		maxLocal = maxJobs;
	    }
	    Job_Init (maxJobs, maxLocal);
	    jobsRunning = TRUE;
	}
#endif	/* defined(unix) || defined(_WIN32) */

	/*
	 * Traverse the graph, checking on all the targets
	 */
	outOfDate = Make_Run (targs);
    }

#if !defined(_MSDOS)
    else {
	/*
	 * Compat_Init will take care of creating all the targets as well
	 * as initializing the module.
	 */
	Compat_Run(targs);
    }
#endif /* !defined(_MSDOS) */

    /*
     * Print the graph now it's been processed if the user requested it
     */
    if (printGraph & 2) {
	Targ_PrintGraph (2);
    }

    if (queryFlag && outOfDate) {
	exit (1);
    } else {
	exit (0);
    }
}

/*-
 *-----------------------------------------------------------------------
 * ReadMakefile  --
 *	Open and parse the given makefile.
 *
 * Results:
 *	TRUE if ok. FALSE if couldn't open file.
 *
 * Arguments:
 *      char *fname : Makefile to read
 *
 * Side Effects:
 *	lots
 *-----------------------------------------------------------------------
 */
static Boolean
ReadMakefile (char *fname)
{
    if (strcmp (fname, "-") == 0) {
	Parse_File ("(stdin)", stdin);
	Var_Set("MAKEFILE", "", VAR_GLOBAL);
	return (TRUE);
    } else {
	FILE *	  stream;
	extern Lst parseIncPath, sysIncPath;

	stream = fopen (fname, "r");

	if (stream == (FILE *) NULL) {
	    /*
	     * Look in -I directories...
	     */
	    char    *name = Dir_FindFile(fname, parseIncPath);

	    if (name == NULL) {
		/*
		 * Last-ditch: look in system include directories.
		 */
		name = Dir_FindFile(fname, sysIncPath);
		if (name == NULL) {
		    return (FALSE);
		}
	    }
	    stream = fopen(name, "r");
	    if (stream == (FILE *)NULL) {
		/* Better safe than sorry... */
		return(FALSE);
	    }
	    fname = name;
	}
	/*
	 * Set the MAKEFILE variable desired by System V fans -- the placement
	 * of the setting here means it gets set to the last makefile
	 * specified, as it is set by SysV make...
	 */
	Var_Set("MAKEFILE", fname, VAR_GLOBAL);
	Parse_File (fname, stream);
	fclose (stream);
	return (TRUE);
    }
}
#if defined(_WIN32)

/***********************************************************************
 *				ErrorMessage
 ***********************************************************************
 *
 * SYNOPSIS:	    Get string corresponding to GetLastError().
 * CALLED BY:	    main
 * RETURN:	    string
 * SIDE EFFECTS:    Outputs text to the screen.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	9/07/96   	Initial Revision
 *
 ***********************************************************************/
void
ErrorMessage (char *fmt, ...)
{
    LPVOID lpMessageBuffer;
    va_list argList;

    va_start(argList, fmt);

    /*
     * This turns GetLastError() into a human-readable string.
     */
    (void) FormatMessage(
	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
	NULL,
	GetLastError(),
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* user default language */
	(LPTSTR) &lpMessageBuffer,
	0,
	NULL);			/* #1 */

    vfprintf(stderr, fmt, argList);
    fprintf(stderr, ": %s", (char *) lpMessageBuffer);
    LocalFree(lpMessageBuffer);	/* #1 */

    va_end(argList);
}	/* End of ErrorMessage.	*/
#endif /* defined(_WIN32) */
/*-
 *-----------------------------------------------------------------------
 * Error --
 *	Print an error message given its format and a variable argument list.
 *
 * Results:
 *	None.
 *
 * Arguments:
 *      char         *fmt  : Format string
 *                    ...  : Variable argument list
 *
 * Side Effects:
 *	The message is printed.
 *
 *-----------------------------------------------------------------------
 */
/*VARARGS1*/
void
Error (char *fmt, ...)
{
    va_list ap;

    va_start(ap,fmt);
    VError (fmt,ap);
    va_end(ap);
}

/*-
 *-----------------------------------------------------------------------
 * VError --
 *       Print an error message given a format and a va_list
 *
 * Results:
 *      None.
 *
 * Arguments:
 *      char         *fmt : Format string
 *      va_list       ap  : Variable argument list that has already been
 *                          initialized via va_start.
 *
 * Side Effects:
 *      The message is printed.
 *
 *----------------------------------------------------------------------
 */


void VError (char *fmt, va_list ap)
{
    static char  estr[BSIZE];	    /* output string */
    char        *progName = Var_LastPathSep(Var_Value(".PMAKE", VAR_GLOBAL));

    sprintf (estr, "%s: ",
	     progName ? progName + 1 : Var_Value(".PMAKE", VAR_GLOBAL));
    vsprintf(&estr[strlen (estr)], fmt, ap);
    (void) strcat (estr, "\n");

    fflush(stderr);
    fputs(estr, stderr);
    fflush(stderr);
}


/*-
 *-----------------------------------------------------------------------
 * Fatal --
 *	Produce a Fatal error message. If jobs are running, waits for them
 *	to finish.
 *
 * Results:
 *	None
 *
 * Arguments:
 *      char          *fmt  : Format string
 *      unsigned long  arg1 : First optional argument
 *      unsigned long  arg2 : Second optional argument
 *
 * Side Effects:
 *	The program exits
 *-----------------------------------------------------------------------
 */
/* VARARGS1 */
void
Fatal (char *fmt, ...)
/*unsigned long arg1, unsigned long arg2)*/
{
    va_list ap;

    va_start(ap,fmt);

#if defined(unix) || defined(_WIN32)
    if (jobsRunning) {
	Job_Wait();
    }
#endif /* defined(unix) || defined(_WIN32) */
    VError (fmt, ap);

    if (printGraph & 2) {
	Targ_PrintGraph(2);
    }
    va_end(ap);
    exit (2);			/* Not 1 so -q can distinguish error */
}

/*
 *-----------------------------------------------------------------------
 * Punt --
 *	Major exception once jobs are being created. Kills all jobs, prints
 *	a message and exits.
 *
 * Results:
 *	None
 *
 * Arguments:
 *      char          *fmt  : format string
 *      unsigned long  arg1 : optional argument
 *      unsigned long  arg2 : optional second argument
 *
 * Side Effects:
 *	All children are killed indiscriminately and the program Lib_Exits
 *-----------------------------------------------------------------------
 */
/* VARARGS1 */
void
Punt (char* fmt, ...)
/*unsigned long arg1, unsigned long arg2)*/
{
    va_list ap;

    va_start(ap,fmt);

    VError (fmt, ap);
    va_end(ap);

    DieHorribly();
}

/*-
 *-----------------------------------------------------------------------
 * DieHorribly --
 *	Exit without giving a message.
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	A big one...
 *-----------------------------------------------------------------------
 */
void
DieHorribly(void)
{
#if defined(unix) || defined(_WIN32)
    if (jobsRunning) {
	Job_AbortAll ();
    }
#endif

    if (printGraph & 2) {
	Targ_PrintGraph(2);
    }

#if defined(unix)
    exit (2);			/* Not 1, so -q can distinguish error */
#elif defined(_WIN32)
    ExitProcess(2);
#endif /* defined(unix) */
}

/*
 *-----------------------------------------------------------------------
 * Finish --
 *	Called when aborting due to errors in child shell to signal
 *	abnormal exit.
 *
 * Results:
 *	None
 *
 * Arguments:
 *      int errors : Number of errors encountered in Make_Make
 *
 * Side Effects:
 *	The program exits
 * -----------------------------------------------------------------------
 */
void
Finish (int errors)
{
    Fatal ("%d error%s", errors, (unsigned long)(errors == 1 ? "" : "s"));
}

#if defined(SYSV) || !defined(sun)

#if defined(unix)
exit(status)
{
#ifdef unix
    if (lockSet) {
	MainUnlock();
    }
#endif
    _cleanup();
    _exit(status);
}
#endif /* borlandc */
#endif /* System V || !sun */
